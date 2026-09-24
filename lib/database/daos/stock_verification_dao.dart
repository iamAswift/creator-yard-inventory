// lib/database/daos/stock_verification_dao.dart

import 'package:drift/drift.dart';

import '../../core/session.dart';
import '../app_database.dart';
import '../tables/product_table.dart';
import '../tables/stock_verification_table.dart';
import '../tables/user_profiles_table.dart';
import '../tables/user_table.dart';
import 'stock_movement_dao.dart';

part 'stock_verification_dao.g.dart';

@DriftAccessor(
  tables: [
    StockVerifications,
    StockVerificationItems,
    Products,
    UserProfiles,
    Users,
  ],
)
class StockVerificationDao extends DatabaseAccessor<AppDatabase>
    with _$StockVerificationDaoMixin {
  StockVerificationDao(super.db);

  DateTime _normalizeBusinessDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // ============================================================
  // START VERIFICATION
  // ============================================================

  /// Starts a new physical stock verification for the supplied
  /// calendar/business date.
  ///
  /// The current user's permission to count stock is enforced
  /// before a verification can be created.
  ///
  /// Each product receives an expectedStock snapshot taken from
  /// Products.stock at the time the verification is started.
  Future<int> startVerification({
    required DateTime businessDate,
    int? countedByUserId,
    String? notes,
  }) async {
    final sessionUserId = Session.currentUserId;

    if (sessionUserId == null || sessionUserId <= 0) {
      throw Exception(
        'A logged-in user is required to start a stock verification.',
      );
    }

    if (countedByUserId != null && countedByUserId != sessionUserId) {
      throw Exception(
        'The stock counter must be the currently logged-in user.',
      );
    }

    final userId = sessionUserId;
    final normalizedBusinessDate = _normalizeBusinessDate(businessDate);

    final profile = await (select(
      userProfiles,
    )..where((p) => p.userId.equals(userId))).getSingleOrNull();

    if (profile == null) {
      throw Exception('The user does not have a staff profile.');
    }

    if (!profile.canCountStock) {
      throw Exception('This user is not permitted to perform stock counts.');
    }

    final existing =
        await (select(stockVerifications)..where(
              (v) =>
                  v.businessDate.equals(normalizedBusinessDate) &
                  v.status.equals('rejected').not(),
            ))
            .getSingleOrNull();

    if (existing != null) {
      throw Exception('A stock verification already exists for this date.');
    }

    return transaction(() async {
      final verificationId = await into(stockVerifications).insert(
        StockVerificationsCompanion.insert(
          businessDate: normalizedBusinessDate,
          countedByUserId: userId,
          notes: Value(notes),
        ),
      );

      final productsRows =
          await (select(products)..orderBy([
                (p) => OrderingTerm(expression: p.name, mode: OrderingMode.asc),
                (p) => OrderingTerm(expression: p.id, mode: OrderingMode.asc),
              ]))
              .get();

      for (final product in productsRows) {
        await into(stockVerificationItems).insert(
          StockVerificationItemsCompanion.insert(
            verificationId: verificationId,
            productId: product.id,
            expectedStock: product.stock,
            physicalCount: product.stock,
            variance: 0,
          ),
        );
      }

      return verificationId;
    });
  }

  // ============================================================
  // GET VERIFICATION
  // ============================================================

  Future<StockVerification?> getVerificationById(int verificationId) {
    return (select(
      stockVerifications,
    )..where((v) => v.id.equals(verificationId))).getSingleOrNull();
  }

  // ============================================================
  // GET VERIFICATION ITEMS
  // ============================================================

  Future<List<StockVerificationItem>> getVerificationItems(int verificationId) {
    return (select(stockVerificationItems)
          ..where((item) => item.verificationId.equals(verificationId))
          ..orderBy([
            (item) => OrderingTerm(
              expression: item.productId,
              mode: OrderingMode.asc,
            ),
          ]))
        .get();
  }

  // ============================================================
  // GET VERIFICATION FOR DATE
  // ============================================================

  Future<StockVerification?> getVerificationForDate(DateTime businessDate) {
    final normalizedBusinessDate = _normalizeBusinessDate(businessDate);

    return (select(stockVerifications)..where(
          (v) =>
              v.businessDate.equals(normalizedBusinessDate) &
              v.status.equals('rejected').not(),
        ))
        .getSingleOrNull();
  }

  // ============================================================
  // UPDATE PHYSICAL COUNT
  // ============================================================

  /// Records a physical count only.
  ///
  /// IMPORTANT:
  /// This method does NOT update Products.stock.
  /// Stock is changed only after an approved verification.
  Future<void> updatePhysicalCount({
    required int verificationItemId,
    required int physicalCount,
  }) async {
    if (physicalCount < 0) {
      throw Exception('Physical stock count cannot be negative.');
    }

    final item = await (select(
      stockVerificationItems,
    )..where((i) => i.id.equals(verificationItemId))).getSingleOrNull();

    if (item == null) {
      throw Exception('Stock verification item was not found.');
    }

    final verification = await getVerificationById(item.verificationId);

    if (verification == null) {
      throw Exception('Stock verification was not found.');
    }

    if (verification.status != 'draft') {
      throw Exception(
        'Physical counts can only be changed while the verification is a draft.',
      );
    }

    final variance = physicalCount - item.expectedStock;

    await (update(
      stockVerificationItems,
    )..where((i) => i.id.equals(verificationItemId))).write(
      StockVerificationItemsCompanion(
        physicalCount: Value(physicalCount),
        variance: Value(variance),
        countedAt: Value(DateTime.now()),
      ),
    );
  }

  // ============================================================
  // SUBMIT VERIFICATION
  // ============================================================

  Future<void> submitVerification(int verificationId) async {
    final verification = await getVerificationById(verificationId);

    if (verification == null) {
      throw Exception('Stock verification was not found.');
    }

    if (verification.status != 'draft') {
      throw Exception('Only a draft verification can be submitted.');
    }

    final items = await getVerificationItems(verificationId);

    if (items.isEmpty) {
      throw Exception(
        'A stock verification must contain at least one product.',
      );
    }

    final now = DateTime.now();

    await (update(
          stockVerifications,
        )..where((v) => v.id.equals(verificationId) & v.status.equals('draft')))
        .write(
          StockVerificationsCompanion(
            status: const Value('submitted'),
            submittedAt: Value(now),
          ),
        );
  }

  // ============================================================
  // APPROVE VERIFICATION
  // ============================================================

  /// Approves a submitted verification.
  ///
  /// Only owner/manager users can approve.
  ///
  /// Every non-zero variance becomes a signed adjustment movement:
  ///
  ///   physical - expected = adjustment quantity
  ///
  /// Stock itself is changed only through
  /// StockMovementDao.insertMovement().
  ///
  /// The status transition and all stock adjustments happen inside
  /// one outer transaction.
  ///
  /// A verification can only transition from submitted -> approved,
  /// making repeated approval attempts idempotent.
  Future<void> approveVerification({
    required int verificationId,
    int? reviewedByUserId,
    String? notes,
  }) async {
    final sessionReviewerId = Session.currentUserId;

    if (sessionReviewerId == null || sessionReviewerId <= 0) {
      throw Exception('A logged-in reviewer is required.');
    }

    if (reviewedByUserId != null && reviewedByUserId != sessionReviewerId) {
      throw Exception('The reviewer must be the currently logged-in user.');
    }

    if (!Session.isOwnerOrManager) {
      throw Exception(
        'Only an owner or manager can approve stock verification.',
      );
    }

    final reviewerId = sessionReviewerId;

    final reviewer = await (select(
      users,
    )..where((u) => u.id.equals(reviewerId))).getSingleOrNull();

    if (reviewer == null) {
      throw Exception('The reviewing user was not found.');
    }

    final reviewerRole = reviewer.role.trim().toLowerCase();

    if (reviewerRole != 'owner' && reviewerRole != 'manager') {
      throw Exception(
        'Only an owner or manager can approve stock verification.',
      );
    }

    await transaction(() async {
      final verification =
          await (select(stockVerifications)..where(
                (v) =>
                    v.id.equals(verificationId) & v.status.equals('submitted'),
              ))
              .getSingleOrNull();

      if (verification == null) {
        throw Exception(
          'Stock verification was not found or has already been reviewed.',
        );
      }

      final items = await getVerificationItems(verificationId);

      if (items.isEmpty) {
        throw Exception('Cannot approve an empty stock verification.');
      }

      final movementDao = StockMovementDao(db);

      for (final item in items) {
        if (item.variance == 0) {
          continue;
        }

        final product = await (select(
          products,
        )..where((p) => p.id.equals(item.productId))).getSingleOrNull();

        if (product == null) {
          throw Exception('Product ${item.productId} no longer exists.');
        }

        await movementDao.insertMovement(
          StockMovementsCompanion(
            productId: Value(item.productId),
            supplierId: const Value.absent(),
            type: const Value('adjustment'),
            deliveryId: const Value.absent(),
            quantity: Value(item.variance),
            unitPrice: Value(product.costPrice),
          ),
        );
      }

      final now = DateTime.now();

      await (update(stockVerifications)..where(
            (v) => v.id.equals(verificationId) & v.status.equals('submitted'),
          ))
          .write(
            StockVerificationsCompanion(
              status: const Value('approved'),
              reviewedByUserId: Value(reviewerId),
              reviewedAt: Value(now),
              notes: Value(notes ?? verification.notes),
            ),
          );
    });
  }

  // ============================================================
  // REJECT VERIFICATION
  // ============================================================

  Future<void> rejectVerification({
    required int verificationId,
    int? reviewedByUserId,
    String? notes,
  }) async {
    final sessionReviewerId = Session.currentUserId;

    if (sessionReviewerId == null || sessionReviewerId <= 0) {
      throw Exception('A logged-in reviewer is required.');
    }

    if (reviewedByUserId != null && reviewedByUserId != sessionReviewerId) {
      throw Exception('The reviewer must be the currently logged-in user.');
    }

    if (!Session.isOwnerOrManager) {
      throw Exception(
        'Only an owner or manager can reject stock verification.',
      );
    }

    final reviewerId = sessionReviewerId;

    final reviewer = await (select(
      users,
    )..where((u) => u.id.equals(reviewerId))).getSingleOrNull();

    if (reviewer == null) {
      throw Exception('The reviewing user was not found.');
    }

    final reviewerRole = reviewer.role.trim().toLowerCase();

    if (reviewerRole != 'owner' && reviewerRole != 'manager') {
      throw Exception(
        'Only an owner or manager can reject stock verification.',
      );
    }

    final verification = await getVerificationById(verificationId);

    if (verification == null) {
      throw Exception('Stock verification was not found.');
    }

    if (verification.status != 'submitted') {
      throw Exception('Only a submitted verification can be rejected.');
    }

    await (update(stockVerifications)..where(
          (v) => v.id.equals(verificationId) & v.status.equals('submitted'),
        ))
        .write(
          StockVerificationsCompanion(
            status: const Value('rejected'),
            reviewedByUserId: Value(reviewerId),
            reviewedAt: Value(DateTime.now()),
            notes: Value(notes ?? verification.notes),
          ),
        );
  }
}
