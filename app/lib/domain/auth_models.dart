class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.ankoAccount,
    required this.nickname,
    this.householdId,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return AuthSession(
      accessToken: json['accessToken'] as String,
      ankoAccount: user['ankoAccount'] as String,
      nickname: user['nickname'] as String,
      householdId: json['householdId'] as String?,
    );
  }

  final String accessToken;
  final String ankoAccount;
  final String nickname;
  final String? householdId;
}

class SmsChallenge {
  const SmsChallenge({required this.id, this.devCode});

  factory SmsChallenge.fromJson(Map<String, dynamic> json) {
    return SmsChallenge(
      id: json['challengeId'] as String,
      devCode: json['devCode'] as String?,
    );
  }

  final String id;
  final String? devCode;
}
