// lib/database/tables/stock_verification_table.dart

import 'package:drift/drift.dart';

import 'product_table.dart';
import 'user_table.dart';

/// One physical stock verification / closing session.
///
/// This table records the verification itself.
/// Individual product counts are stored in StockVerificationItems.
class StockVerifications extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Calendar/business date being verified.
  DateTimeColumn get businessDate => dateTime()();

  /// User who physically performed the count.
  @ReferenceName('stockVerificationCountedBy')
  IntColumn get countedByUserId =>
      integer().references(Users, #id)();

  /// When the verification was started.
  DateTimeColumn get startedAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// When the verification was submitted for review.
  DateTimeColumn get submittedAt => dateTime().nullable()();

  /// Workflow status:
  /// draft → submitted → approved/rejected
  TextColumn get status =>
      text().withDefault(const Constant('draft'))();

  /// Manager/owner who reviewed the verification.
  @ReferenceName('stockVerificationReviewedBy')
  IntColumn get reviewedByUserId =>
      integer().nullable().references(Users, #id)();

  /// When the verification was reviewed.
  DateTimeColumn get reviewedAt => dateTime().nullable()();

  /// Optional review/submission notes.
  TextColumn get notes => text().nullable()();
}

/// One product counted during a stock verification.
class StockVerificationItems extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Parent stock verification.
  IntColumn get verificationId =>
      integer().references(StockVerifications, #id)();

  /// Product being counted.
  IntColumn get productId =>
      integer().references(Products, #id)();

  /// System stock at the point the verification item was created.
  IntColumn get expectedStock => integer()();

  /// Physical quantity entered by the counter.
  IntColumn get physicalCount => integer()();

  /// physicalCount - expectedStock.
  IntColumn get variance => integer()();

  /// When this product was counted.
  DateTimeColumn get countedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
