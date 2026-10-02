import 'package:drift/drift.dart';
import 'package:habito/core/database/app_database.dart' as db;
import 'package:habito/core/models/domain_models.dart';

abstract class UserRepository {
  Future<User?> getUser(String id);
  Future<void> saveUser(User user);
}

class UserRepositoryImpl implements UserRepository {
  final db.AppDatabase _db;

  UserRepositoryImpl(this._db);

  @override
  Future<User?> getUser(String id) async {
    final query = _db.select(_db.usersTable)..where((t) => t.id.equals(id));
    final dbUser = await query.getSingleOrNull();

    if (dbUser == null) return null;
    return _mapToDomain(dbUser);
  }

  @override
  Future<void> saveUser(User user) async {
    await _db.into(_db.usersTable).insertOnConflictUpdate(_mapToDb(user));
  }

  User _mapToDomain(db.UsersTableData data) {
    return User(
      id: data.id,
      name: data.name,
      email: data.email,
      profileImageUrl: data.profileImageUrl,
      timezone: data.timezone,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      syncStatus: data.syncStatus,
      isDeleted: data.isDeleted,
    );
  }

  db.UsersTableCompanion _mapToDb(User user) {
    return db.UsersTableCompanion.insert(
      id: user.id,
      name: user.name,
      email: user.email,
      profileImageUrl: driftValue(user.profileImageUrl),
      timezone: user.timezone,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      syncStatus: user.syncStatus,
      isDeleted: driftValue(user.isDeleted),
    );
  }

  Value<T> driftValue<T>(T? val) => val == null ? const Value.absent() : Value(val);
}
