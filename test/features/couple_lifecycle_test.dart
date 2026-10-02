import 'package:flutter_test/flutter_test.dart';
import 'package:habito/features/us/data/couple_api.dart';
import 'package:habito/features/us/data/us_repository.dart';
import 'package:habito/core/database/app_database.dart' as db;
import 'package:habito/core/database/enums.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';

class FakeCoupleApi implements CoupleApi {
  @override
  Future<Map<String, dynamic>> createCouple() async {
    return {
      'id': 'test-couple-id',
      'status': 'active',
      'created_at': '2023-01-01T00:00:00Z',
      'updated_at': '2023-01-01T00:00:00Z',
    };
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late db.AppDatabase database;
  late FakeCoupleApi fakeApi;
  late UsRepositoryImpl repository;

  setUp(() {
    database = db.AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    fakeApi = FakeCoupleApi();
    repository = UsRepositoryImpl(database, fakeApi);
  });

  tearDown(() async {
    await database.close();
  });

  test('createCouple syncs local DB', () async {
    final couple = await repository.createCouple();
    expect(couple.id, 'test-couple-id');
    expect(couple.status, CoupleStatus.active);
  });
}
