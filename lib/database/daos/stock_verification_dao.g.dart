// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_verification_dao.dart';

// ignore_for_file: type=lint
mixin _$StockVerificationDaoMixin on DatabaseAccessor<AppDatabase> {
  $UsersTable get users => attachedDatabase.users;
  $StockVerificationsTable get stockVerifications =>
      attachedDatabase.stockVerifications;
  $CategoriesTable get categories => attachedDatabase.categories;
  $ProductsTable get products => attachedDatabase.products;
  $StockVerificationItemsTable get stockVerificationItems =>
      attachedDatabase.stockVerificationItems;
  $UserProfilesTable get userProfiles => attachedDatabase.userProfiles;
  StockVerificationDaoManager get managers => StockVerificationDaoManager(this);
}

class StockVerificationDaoManager {
  final _$StockVerificationDaoMixin _db;
  StockVerificationDaoManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db.attachedDatabase, _db.users);
  $$StockVerificationsTableTableManager get stockVerifications =>
      $$StockVerificationsTableTableManager(
        _db.attachedDatabase,
        _db.stockVerifications,
      );
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$StockVerificationItemsTableTableManager get stockVerificationItems =>
      $$StockVerificationItemsTableTableManager(
        _db.attachedDatabase,
        _db.stockVerificationItems,
      );
  $$UserProfilesTableTableManager get userProfiles =>
      $$UserProfilesTableTableManager(_db.attachedDatabase, _db.userProfiles);
}
