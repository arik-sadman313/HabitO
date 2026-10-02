import '../../../../core/network/dio_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final coupleApiProvider = Provider<CoupleApi>((ref) {
  return CoupleApi(ref.read(dioClientProvider));
});

class CoupleApi {
  final DioClient _dioClient;

  CoupleApi(this._dioClient);

  Future<Map<String, dynamic>> createCouple() async {
    final response = await _dioClient.dio.post('/couples/');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> generateInvite() async {
    final response = await _dioClient.dio.post('/couples/invite');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> joinCouple(String inviteCode) async {
    final response = await _dioClient.dio.post('/couples/join', data: {
      'invite_code': inviteCode,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<void> leaveCouple() async {
    await _dioClient.dio.delete('/couples/leave');
  }

  Future<Map<String, dynamic>> getMyCouple() async {
    final response = await _dioClient.dio.get('/couples/me');
    return response.data as Map<String, dynamic>;
  }
}
