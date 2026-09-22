import 'package:flutter/material.dart';

import '../data/auth_repository.dart';
import '../domain/auth_models.dart';
import '../widgets/anko_image.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    required this.repository,
    required this.onAuthenticated,
    super.key,
  });

  final AuthRepository repository;
  final ValueChanged<AuthSession> onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _accountController = TextEditingController();
  final _nicknameController = TextEditingController();
  String? _challengeId;
  String? _error;
  bool _registering = false;
  bool _busy = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _accountController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('auth-screen'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: AnkoImage(size: 120)),
                const SizedBox(height: 8),
                Text(
                  '欢迎回家',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                const Text(
                  '使用手机号和短信验证码登录 Anko',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF748196)),
                ),
                const SizedBox(height: 24),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('登录')),
                    ButtonSegment(value: true, label: Text('注册')),
                  ],
                  selected: {_registering},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _registering = selection.first;
                      _error = null;
                    });
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  key: const Key('auth-phone-field'),
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: '手机号',
                    prefixText: '+86 ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null ||
                          value.replaceAll(RegExp(r'\D'), '').length < 8
                      ? '请输入有效手机号'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('auth-code-field'),
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: '短信验证码',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value?.length == 6 ? null : '请输入6位验证码',
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.tonal(
                      key: const Key('request-auth-code'),
                      onPressed: _busy ? null : _requestCode,
                      child: const Text('获取验证码'),
                    ),
                  ],
                ),
                if (_registering) ...[
                  const SizedBox(height: 4),
                  TextFormField(
                    key: const Key('auth-account-field'),
                    controller: _accountController,
                    decoration: const InputDecoration(
                      labelText: 'Anko账号',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.trim().length < 4
                        ? 'Anko账号至少4位'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('auth-nickname-field'),
                    controller: _nicknameController,
                    decoration: const InputDecoration(
                      labelText: '昵称',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? '请输入昵称' : null,
                  ),
                ],
                if (_error case final error?) ...[
                  const SizedBox(height: 12),
                  Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                FilledButton(
                  key: const Key('submit-auth'),
                  onPressed: _busy ? null : _submit,
                  child: Text(
                    _busy
                        ? '请稍候…'
                        : _registering
                        ? '注册并登录'
                        : '登录',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '手机号仅用于登录验证、账号找回和紧急联系；服务端不保存明文手机号。',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF8A96A6), height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _requestCode() async {
    if (!_validPhone()) return;
    await _run(() async {
      final challenge = await widget.repository.requestCode(
        countryCode: '+86',
        phoneNumber: _phoneController.text,
      );
      _challengeId = challenge.id;
      if (challenge.devCode != null) {
        _codeController.text = challenge.devCode!;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_challengeId == null) {
      setState(() => _error = '请先获取验证码');
      return;
    }
    await _run(() async {
      final session = await widget.repository.verifyCode(
        challengeId: _challengeId!,
        code: _codeController.text,
        ankoAccount: _registering ? _accountController.text.trim() : null,
        nickname: _registering ? _nicknameController.text.trim() : null,
      );
      widget.onAuthenticated(session);
    });
  }

  bool _validPhone() {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 8) return true;
    setState(() => _error = '请输入有效手机号');
    return false;
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on AuthRepositoryException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on Object {
      if (mounted) setState(() => _error = '网络异常，请稍后重试');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
