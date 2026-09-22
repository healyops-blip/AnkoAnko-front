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
        store.emergencyContactsByOwner[current.memberId] ?? const <String>{};
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
              isEmergencyContact: selectedContacts.contains(account.memberId),
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
  Future<void> setEmergencyContact({
    required String householdId,
    required String contactId,
    required bool selected,
  }) async {
    await _delay();
    final current = _currentAccount();
    if (contactId == current.memberId) {
      throw const FamilyRepositoryException('不能将自己设为紧急联系人');
    }
    final contacts = store.emergencyContactsByOwner.putIfAbsent(
      current.memberId,
      () => <String>{},
    );
    selected ? contacts.add(contactId) : contacts.remove(contactId);
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
