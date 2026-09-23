import '../domain/auth_models.dart';
import '../domain/family_models.dart';
import 'family_repository.dart';
import 'smoke_data_store.dart';

class SmokeFamilyRepository implements FamilyRepository {
  SmokeFamilyRepository({required this.store, required this.session});

  final SmokeDataStore store;
  final AuthSession session;

  @override
  Future<FamilyOverview> fetchOverview() async {
    await _delay();
    final current = _currentAccount();
    if (current.householdId == null) {
      throw const FamilyRepositoryException('请先通过家庭码加入家庭');
    }
    final selectedContacts =
        store.emergencyContactsByOwner[current.memberId] ??
        const <String, int>{};
    return FamilyOverview(
      internalHouseholdId: smokeFamilyId,
      householdName: 'Anko开发家庭',
      familyCode: smokeFamilyCode,
      contacts: store.accounts
          .where((account) => account.householdId == smokeFamilyId)
          .map(
            (account) => FamilyContact(
              internalId: account.memberId,
              nickname: account.nickname,
              memberNickname: account.memberNickname,
              phoneMasked: account.phoneMasked,
              permissions: account.permissions,
              isCurrentUser: account.ankoAccount == session.ankoAccount,
              emergencyContactPriority: selectedContacts[account.memberId],
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<JoinedFamily> joinFamily({
    required String familyCode,
    required String memberNickname,
  }) async {
    await _delay();
    if (familyCode.toUpperCase() != smokeFamilyCode) {
      throw const FamilyRepositoryException('家庭码不存在');
    }
    final account = _currentAccount();
    account
      ..householdId = smokeFamilyId
      ..memberNickname = memberNickname;
    return const JoinedFamily(
      internalId: smokeFamilyId,
      name: 'Anko开发家庭',
      familyCode: smokeFamilyCode,
    );
  }

  @override
  Future<void> replaceEmergencyContacts({
    required String householdId,
    required List<EmergencyContactSelection> contacts,
  }) async {
    await _delay();
    final current = _currentAccount();
    if (contacts.length > 2) {
      throw const FamilyRepositoryException('最多设置两位紧急联系人');
    }
    final contactIds = contacts.map((contact) => contact.contactMemberId);
    if (contactIds.contains(current.memberId)) {
      throw const FamilyRepositoryException('不能将自己设为紧急联系人');
    }
    final priorities = contacts.map((contact) => contact.priority).toSet();
    if (contactIds.toSet().length != contacts.length ||
        priorities.length != contacts.length ||
        priorities.any((priority) => priority < 1 || priority > 2)) {
      throw const FamilyRepositoryException('紧急联系人顺序无效');
    }
    store.emergencyContactsByOwner[current.memberId] = {
      for (final contact in contacts) contact.contactMemberId: contact.priority,
    };
  }

  SmokeAccount _currentAccount() {
    final account = store.findByAnkoAccount(session.ankoAccount);
    if (account == null) {
      throw const FamilyRepositoryException('Smoke账号不存在');
    }
    return account;
  }

  Future<void> _delay() =>
      Future<void>.delayed(const Duration(milliseconds: 120));
}
