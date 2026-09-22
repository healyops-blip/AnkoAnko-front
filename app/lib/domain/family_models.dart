class FamilyContact {
  const FamilyContact({
    required this.internalId,
    required this.nickname,
    required this.memberNickname,
    required this.phoneMasked,
    required this.permissions,
    required this.isCurrentUser,
    required this.isEmergencyContact,
    this.avatarUrl,
  });

  factory FamilyContact.fromJson(Map<String, dynamic> json) {
    return FamilyContact(
      internalId: json['id'] as String,
      nickname: json['nickname'] as String,
      memberNickname: json['memberNickname'] as String,
      phoneMasked: json['phoneMasked'] as String,
      permissions: Map<String, bool>.from(
        json['permissions'] as Map<String, dynamic>,
      ),
      isCurrentUser: json['isCurrentUser'] as bool,
      isEmergencyContact: json['isEmergencyContact'] as bool,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  final String internalId;
  final String nickname;
  final String memberNickname;
  final String phoneMasked;
  final Map<String, bool> permissions;
  final bool isCurrentUser;
  final bool isEmergencyContact;
  final String? avatarUrl;
}

class FamilyOverview {
  const FamilyOverview({
    required this.internalHouseholdId,
    required this.householdName,
    required this.familyCode,
    required this.contacts,
  });

  factory FamilyOverview.fromJson(Map<String, dynamic> json) {
    return FamilyOverview(
      internalHouseholdId: json['householdId'] as String,
      householdName: json['householdName'] as String,
      familyCode: json['familyCode'] as String,
      contacts: (json['members'] as List<dynamic>)
          .map(
            (member) => FamilyContact.fromJson(member as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  final String internalHouseholdId;
  final String householdName;
  final String familyCode;
  final List<FamilyContact> contacts;
}

class JoinedFamily {
  const JoinedFamily({
    required this.internalId,
    required this.name,
    required this.familyCode,
  });

  factory JoinedFamily.fromJson(Map<String, dynamic> json) {
    return JoinedFamily(
      internalId: json['id'] as String,
      name: json['name'] as String,
      familyCode: json['familyCode'] as String,
    );
  }

  final String internalId;
  final String name;
  final String familyCode;
}
