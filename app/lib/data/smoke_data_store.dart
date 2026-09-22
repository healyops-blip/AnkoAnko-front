import '../domain/auth_models.dart';

const smokeFamilyId = 'smoke-family-devanko1';
const smokeFamilyCode = 'DEVANKO1';

const administratorPermissions = <String, bool>{
  'viewMembers': true,
  'inviteMembers': true,
  'editMembers': true,
  'sendMessages': true,
  'requestCalls': true,
  'viewEventEvidence': true,
  'claimNormalEvents': true,
  'claimEmergencyEvents': true,
  'manageDevices': true,
  'manageRooms': true,
  'managePrivacy': true,
  'manageHousehold': true,
};

const memberPermissions = <String, bool>{
  'viewMembers': true,
  'inviteMembers': false,
  'editMembers': false,
  'sendMessages': true,
  'requestCalls': true,
  'viewEventEvidence': true,
  'claimNormalEvents': true,
  'claimEmergencyEvents': false,
  'manageDevices': false,
  'manageRooms': false,
  'managePrivacy': false,
  'manageHousehold': false,
};

final childPermissions = <String, bool>{
  ...memberPermissions,
  'requestCalls': false,
  'viewEventEvidence': false,
  'claimNormalEvents': false,
};

class SmokeAccount {
  SmokeAccount({
    required this.phone,
    required this.ankoAccount,
    required this.nickname,
    required this.memberNickname,
    required this.memberId,
    required this.phoneMasked,
    required this.permissions,
    this.householdId = smokeFamilyId,
  });

  final String phone;
  final String ankoAccount;
  final String nickname;
  String memberNickname;
  final String memberId;
  final String phoneMasked;
  final Map<String, bool> permissions;
  String? householdId;

  AuthSession toSession() => AuthSession(
    accessToken: 'smoke-token-$ankoAccount',
    ankoAccount: ankoAccount,
    nickname: nickname,
    householdId: householdId,
  );
}

class SmokeDataStore {
  SmokeDataStore() : accounts = _seedAccounts();

  final List<SmokeAccount> accounts;
  final Map<String, Set<String>> emergencyContactsByOwner = {};

  SmokeAccount? findByPhone(String phone) {
    for (final account in accounts) {
      if (account.phone == phone) return account;
    }
    return null;
  }

  SmokeAccount? findByAnkoAccount(String ankoAccount) {
    for (final account in accounts) {
      if (account.ankoAccount == ankoAccount) return account;
    }
    return null;
  }

  SmokeAccount register({
    required String phone,
    required String ankoAccount,
    required String nickname,
  }) {
    final account = SmokeAccount(
      phone: phone,
      ankoAccount: ankoAccount,
      nickname: nickname,
      memberNickname: nickname,
      memberId: 'smoke-member-$ankoAccount',
      phoneMasked: _maskPhone(phone),
      permissions: Map.of(memberPermissions),
      householdId: null,
    );
    accounts.add(account);
    return account;
  }

  static List<SmokeAccount> _seedAccounts() => [
    SmokeAccount(
      phone: '+8613800001001',
      ankoAccount: 'dev_mom',
      nickname: '妈妈',
      memberNickname: '妈妈',
      memberId: 'smoke-member-mom',
      phoneMasked: '+86 **** 1001',
      permissions: Map.of(administratorPermissions),
    ),
    SmokeAccount(
      phone: '+8613800001002',
      ankoAccount: 'dev_grandma',
      nickname: '奶奶',
      memberNickname: '奶奶',
      memberId: 'smoke-member-grandma',
      phoneMasked: '+86 **** 1002',
      permissions: Map.of(memberPermissions),
    ),
    SmokeAccount(
      phone: '+8613800001003',
      ankoAccount: 'dev_child',
      nickname: '孩子',
      memberNickname: '孩子',
      memberId: 'smoke-member-child',
      phoneMasked: '+86 **** 1003',
      permissions: Map.of(childPermissions),
    ),
  ];

  static String _maskPhone(String phone) {
    final countryCode = phone.startsWith('+86') ? '+86' : phone.substring(0, 2);
    return '$countryCode **** ${phone.substring(phone.length - 4)}';
  }
}
