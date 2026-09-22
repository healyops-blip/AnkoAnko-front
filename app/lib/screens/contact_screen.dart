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
            onEmergencyContactChanged: _setEmergencyContact,
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
    try {
      await widget.repository.setEmergencyContact(
        householdId: overview.internalHouseholdId,
        contactId: contact.internalId,
        selected: !contact.isEmergencyContact,
      );
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(contact.isEmergencyContact ? '已取消紧急联系人' : '已设为紧急联系人'),
        ),
      );
    } on FamilyRepositoryException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _ContactContent extends StatelessWidget {
  const _ContactContent({
    required this.overview,
    required this.onJoinFamily,
    required this.onEmergencyContactChanged,
  });

  final FamilyOverview overview;
  final VoidCallback onJoinFamily;
  final ValueChanged<FamilyContact> onEmergencyContactChanged;

  @override
  Widget build(BuildContext context) {
    final familyContacts = overview.contacts.where(
      (contact) => !contact.isCurrentUser,
    );

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
              ...familyContacts.map(
                (contact) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _ContactCard(
                    contact: contact,
                    onEmergencyContactChanged: onEmergencyContactChanged,
                  ),
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
  const _ContactCard({
    required this.contact,
    required this.onEmergencyContactChanged,
  });

  final FamilyContact contact;
  final ValueChanged<FamilyContact> onEmergencyContactChanged;

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
            if (!contact.isCurrentUser)
              IconButton.filledTonal(
                key: ValueKey('emergency-contact-${contact.internalId}'),
                tooltip: contact.isEmergencyContact ? '取消紧急联系人' : '设为紧急联系人',
                onPressed: () => onEmergencyContactChanged(contact),
                icon: Icon(
                  contact.isEmergencyContact
                      ? Icons.emergency_rounded
                      : Icons.emergency_outlined,
                  color: contact.isEmergencyContact
                      ? const Color(0xFFD63C32)
                      : null,
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
