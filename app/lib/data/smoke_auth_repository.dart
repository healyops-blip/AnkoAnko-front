import '../domain/auth_models.dart';
import 'auth_repository.dart';
import 'smoke_data_store.dart';

class SmokeAuthRepository implements AuthRepository {
  SmokeAuthRepository({required this.store, this.initialSession});

  final SmokeDataStore store;
  final AuthSession? initialSession;
  String? _requestedPhone;
  String? _challengeId;

  @override
  Future<AuthSession?> restoreSession() async {
    await _delay();
    return initialSession;
  }

  @override
  Future<SmsChallenge> requestCode({
    required String countryCode,
    required String phoneNumber,
  }) async {
    await _delay();
    _requestedPhone =
        '$countryCode${phoneNumber.replaceAll(RegExp(r'\D'), '')}';
    _challengeId = 'smoke-challenge-${_requestedPhone.hashCode.abs()}';
    return SmsChallenge(id: _challengeId!, devCode: '123456');
  }

  @override
  Future<AuthSession> verifyCode({
    required String challengeId,
    required String code,
    String? ankoAccount,
    String? nickname,
  }) async {
    await _delay();
    if (_requestedPhone == null || challengeId != _challengeId) {
      throw const AuthRepositoryException('请先获取验证码');
    }
    if (code != '123456') {
      throw const AuthRepositoryException('验证码错误');
    }
    final existing = store.findByPhone(_requestedPhone!);
    if (existing != null) return existing.toSession();
    if (ankoAccount == null || nickname == null) {
      throw const AuthRepositoryException('该手机号尚未注册，请切换到注册');
    }
    if (store.findByAnkoAccount(ankoAccount) != null) {
      throw const AuthRepositoryException('Anko账号已被使用');
    }
    return store
        .register(
          phone: _requestedPhone!,
          ankoAccount: ankoAccount,
          nickname: nickname,
        )
        .toSession();
  }

  Future<void> _delay() =>
      Future<void>.delayed(const Duration(milliseconds: 120));
}
