import 'package:flutter/material.dart';

import '../data/family_repository.dart';
import '../domain/family_models.dart';
import 'join_family_screen.dart';

typedef EmergencyContactSelected = void Function(
  int priority,
  FamilyContact? contact,
);

class ContactScreen extends StatefulWidget {
  const ContactScreen({required this.repository, super.key});

  final FamilyRepository repository;

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  late Future<FamilyOverview> _overview;

  @override
  void initState() {
    super.initState();
    _overview = widget.repository.fetchOverview();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<FamilyOverview>(
        future: _overview,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _LoadError(
              message: snapshot.error.toString(),
              onRetry: _reload,
              onJoinFamily: _openJoinFamily,
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _ContactContent(
            overview: snapshot.requireData,
            onJoinFamily: _openJoinFamily,
            onConfigureEmergencyContacts: () =>
                _openEmergencyContactSettings(snapshot.requireData),
          );
        },
      ),
    );
  }

  void _reload() {
    final nextOverview = widget.repository.fetchOverview();
    setState(() {
      _overview = nextOverview;
    });
  }

  Future<void> _openJoinFamily() async {
    final joined = await Navigator.of(context).push<JoinedFamily>(
      MaterialPageRoute(
        builder: (_) => JoinFamilyScreen(repository: widget.repository),
      ),
    );
    if (joined != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('已加入${joined.name}')));
      _reload();
    }
  }

  Future<void> _setEmergencyContact(
    int priority,
    FamilyContact? contact,
  ) async {
    final overview = await _overview;
    final selections = overview.contacts
        .where(
          (candidate) =>
              candidate.emergencyContactPriority != null &&
              candidate.emergencyContactPriority != priority &&
              candidate.internalId != contact?.internalId,
        )
        .map(
          (candidate) => EmergencyContactSelection(
            contactMemberId: candidate.internalId,
            priority: candidate.emergencyContactPriority!,
          ),
        )
        .toList();
    if (contact != null) {
      selections.add(
        EmergencyContactSelection(
          contactMemberId: contact.internalId,
          priority: priority,
        ),
      );
    }
    selections.sort((left, right) => left.priority.compareTo(right.priority));
    try {
      await widget.repository.replaceEmergencyContacts(
        householdId: overview.internalHouseholdId,
        contacts: selections,
      );
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('紧急联系人已更新')));
    } on FamilyRepositoryException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  void _openEmergencyContactSettings(FamilyOverview overview) {
    final familyContacts = overview.contacts
        .where((contact) => !contact.isCurrentUser)
        .toList(growable: false);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '设置紧急联系人',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text('按优先顺序选择需要紧急联系的家人。'),
              const SizedBox(height: 16),
              _EmergencyContactSelector(
                contacts: familyContacts,
                onSelected: (priority, contact) {
                  _setEmergencyContact(priority, contact);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactContent extends StatelessWidget {
  const _ContactContent({
    required this.overview,
    required this.onJoinFamily,
    required this.onConfigureEmergencyContacts,
  });

  final FamilyOverview overview;
  final VoidCallback onJoinFamily;
  final VoidCallback onConfigureEmergencyContacts;

  @override
  Widget build(BuildContext context) {
    final familyContacts = overview.contacts
        .where((contact) => !contact.isCurrentUser)
        .toList(growable: false);

    return CustomScrollView(
      key: const Key('contact-screen'),
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
          sliver: SliverToBoxAdapter(
            child: Text(
              '联系家人',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.list(
            children: [
              _FamilyCodeCard(overview: overview, onJoinFamily: onJoinFamily),
              const SizedBox(height: 14),
              _EmergencyContactButton(onPressed: onConfigureEmergencyContacts),
              const SizedBox(height: 14),
              ...familyContacts.map(
                (contact) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _ContactCard(contact: contact),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmergencyContactButton extends StatelessWidget {
  const _EmergencyContactButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonalIcon(
        key: const Key('configure-emergency-contacts'),
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          shape: const StadiumBorder(),
        ),
        icon: const Icon(Icons.emergency_outlined),
        label: const Text('设置紧急联系人'),
      ),
    );
  }
}

class _EmergencyContactSelector extends StatelessWidget {
  const _EmergencyContactSelector({
    required this.contacts,
    required this.onSelected,
  });

  final List<FamilyContact> contacts;
  final EmergencyContactSelected onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildDropdown(
              priority: 1,
              label: '第一紧急联系人',
              key: const Key('first-emergency-contact-dropdown'),
            ),
            const SizedBox(height: 14),
            _buildDropdown(
              priority: 2,
              label: '第二紧急联系人',
              key: const Key('second-emergency-contact-dropdown'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required int priority,
    required String label,
    required Key key,
  }) {
    final selectedContact = _findContactAtPriority(priority);
    final otherContact = _findContactAtPriority(priority == 1 ? 2 : 1);
    final availableContacts = contacts
        .where((contact) => contact.internalId != otherContact?.internalId)
        .toList(growable: false);
    return DropdownButtonFormField<String>(
      key: key,
      initialValue: selectedContact?.internalId ?? '',
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.emergency_outlined),
        border: const OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(value: '', child: Text('暂不设置')),
        ...availableContacts.map(
          (contact) => DropdownMenuItem(
            value: contact.internalId,
            child: Text(contact.nickname),
          ),
        ),
      ],
      onChanged: contacts.isEmpty
          ? null
          : (contactId) => _selectContact(priority, contactId),
    );
  }

  FamilyContact? _findContactAtPriority(int priority) {
    for (final contact in contacts) {
      if (contact.emergencyContactPriority == priority) return contact;
    }
    return null;
  }

  void _selectContact(int priority, String? contactId) {
    if (contactId == null || contactId.isEmpty) {
      onSelected(priority, null);
      return;
    }
    for (final contact in contacts) {
      if (contact.internalId == contactId) {
        onSelected(priority, contact);
        return;
      }
    }
  }
}

class _FamilyCodeCard extends StatelessWidget {
  const _FamilyCodeCard({required this.overview, required this.onJoinFamily});

  final FamilyOverview overview;
  final VoidCallback onJoinFamily;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.family_restroom_rounded, color: Color(0xFF0876F9)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    overview.householdName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '家庭码 ${overview.familyCode}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            FilledButton.tonal(
              key: const Key('join-family-button'),
              onPressed: onJoinFamily,
              child: const Text('加入家庭'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.contact});

  final FamilyContact contact;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFFEDF4FD),
              foregroundImage: contact.avatarUrl == null
                  ? null
                  : NetworkImage(contact.avatarUrl!),
              child: Text(
                contact.nickname.characters.first,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.nickname,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    contact.phoneMasked,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            if (contact.isEmergencyContact)
              Tooltip(
                message: '紧急联系人',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.emergency_rounded,
                      color: Color(0xFFD63C32),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      contact.emergencyContactPriority == 1 ? '第一' : '第二',
                      style: const TextStyle(color: Color(0xFFD63C32)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({
    required this.message,
    required this.onRetry,
    required this.onJoinFamily,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onJoinFamily;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onJoinFamily, child: const Text('通过家庭码加入')),
            TextButton(onPressed: onRetry, child: const Text('重新加载家人信息')),
          ],
        ),
      ),
    );
  }
}
