import 'package:flutter/material.dart';

import '../data/family_repository.dart';

class JoinFamilyScreen extends StatefulWidget {
  const JoinFamilyScreen({required this.repository, super.key});

  final FamilyRepository repository;

  @override
  State<JoinFamilyScreen> createState() => _JoinFamilyScreenState();
}

class _JoinFamilyScreenState extends State<JoinFamilyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _familyCodeController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _familyCodeController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('通过家庭码加入')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.family_restroom_rounded,
                  size: 64,
                  color: Color(0xFF0876F9),
                ),
                const SizedBox(height: 16),
                Text(
                  '输入家庭创建者分享的家庭码',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  key: const Key('family-code-field'),
                  controller: _familyCodeController,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    labelText: '家庭码',
                    hintText: '例如 DEVANKO1',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().length < 6
                      ? '请输入有效家庭码'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nicknameController,
                  maxLength: 40,
                  decoration: const InputDecoration(
                    labelText: '我在家庭中的昵称',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? '请输入昵称' : null,
                ),
                if (_error case final error?) ...[
                  const SizedBox(height: 8),
                  Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                FilledButton(
                  key: const Key('submit-family-code'),
                  onPressed: _submitting ? null : _submit,
                  child: Text(_submitting ? '正在加入…' : '加入家庭'),
                ),
                const SizedBox(height: 12),
                const Text(
                  '加入后，你的昵称、头像和权限会由家庭成员共同可见；手机号只显示脱敏信息。',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF7E8997), height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final joined = await widget.repository.joinFamily(
        familyCode: _familyCodeController.text.trim().toUpperCase(),
        memberNickname: _nicknameController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(joined);
    } on FamilyRepositoryException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on Object {
      if (mounted) setState(() => _error = '加入失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
