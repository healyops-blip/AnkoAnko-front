import 'package:flutter/material.dart';

import '../data/family_repository.dart';
import '../domain/family_models.dart';
import 'join_family_screen.dart';

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
            onEmergencyContactSelected: _setEmergencyContact,
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

  Future<void> _setEmergencyContact(FamilyContact contact) async {
    final overview = await _overview;
    final previousContact = _selectedEmergencyContact(overview.contacts);
    if (previousContact?.internalId == contact.internalId) return;
    try {
      if (previousContact != null) {
        await widget.repository.setEmergencyContact(
          householdId: overview.internalHouseholdId,
          contactId: previousContact.internalId,
          selected: false,
        );
      }
      await widget.repository.setEmergencyContact(
        householdId: overview.internalHouseholdId,
        contactId: contact.internalId,
        selected: true,
      );
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已将${contact.nickname}设为紧急联系人')));
    } on FamilyRepositoryException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  FamilyContact? _selectedEmergencyContact(List<FamilyContact> contacts) {
    for (final contact in contacts) {
      if (contact.isEmergencyContact) return contact;
    }
    return null;
  }
}

class _ContactContent extends StatelessWidget {
  const _ContactContent({
    required this.overview,
    required this.onJoinFamily,
    required this.onEmergencyContactSelected,
  });

  final FamilyOverview overview;
  final VoidCallback onJoinFamily;
  final ValueChanged<FamilyContact> onEmergencyContactSelected;

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
              _EmergencyContactSelector(
                contacts: familyContacts,
                onSelected: onEmergencyContactSelected,
              ),
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

class _EmergencyContactSelector extends StatelessWidget {
  const _EmergencyContactSelector({
    required this.contacts,
    required this.onSelected,
  });

  final List<FamilyContact> contacts;
  final ValueChanged<FamilyContact> onSelected;

  @override
  Widget build(BuildContext context) {
    final selectedContact = _findSelectedContact();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: DropdownButtonFormField<String>(
          key: ValueKey(
            'emergency-contact-dropdown-${selectedContact?.internalId}',
          ),
          initialValue: selectedContact?.internalId,
          decoration: const InputDecoration(
            labelText: '紧急联系人',
            prefixIcon: Icon(Icons.emergency_outlined),
            border: OutlineInputBorder(),
          ),
          hint: const Text('请选择紧急联系人'),
          items: contacts
              .map(
                (contact) => DropdownMenuItem(
                  value: contact.internalId,
                  child: Text(contact.nickname),
                ),
              )
              .toList(growable: false),
          onChanged: contacts.isEmpty ? null : _selectContact,
        ),
      ),
    );
  }

  FamilyContact? _findSelectedContact() {
    for (final contact in contacts) {
      if (contact.isEmergencyContact) return contact;
    }
    return null;
  }

  void _selectContact(String? contactId) {
    if (contactId == null) return;
    for (final contact in contacts) {
      if (contact.internalId == contactId) {
        onSelected(contact);
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
              const Tooltip(
                message: '紧急联系人',
                child: Icon(Icons.emergency_rounded, color: Color(0xFFD63C32)),
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
