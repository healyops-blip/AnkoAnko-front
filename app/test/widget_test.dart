import 'package:anko_anko/anko_app.dart';
import 'package:anko_anko/data/configuration_auth_repository.dart';
import 'package:anko_anko/data/api_guardian_map_repository.dart';
import 'package:anko_anko/data/runtime_services.dart';
import 'package:anko_anko/data/smoke_auth_repository.dart';
import 'package:anko_anko/data/smoke_data_store.dart';
import 'package:anko_anko/data/smoke_family_repository.dart';
import 'package:anko_anko/data/smoke_guardian_map_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('starts on the Anko guardian screen', (tester) async {
    await tester.pumpWidget(AnkoApp());
    await tester.pumpAndSettle();

    expect(find.text('Anko守护界面'), findsOneWidget);
    expect(find.byKey(const Key('smoke-mode-banner')), findsOneWidget);
    expect(find.byKey(const Key('guardian-screen')), findsOneWidget);
    expect(find.text('空间完整度 75% · 4 个房间'), findsOneWidget);
    expect(find.text('4 个房间 · 与家保持连接'), findsNothing);
    expect(find.text('2台在线 · 1处无监测'), findsOneWidget);
  });

  testWidgets('switches between primary destinations', (tester) async {
    await tester.pumpWidget(AnkoApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('contact-tab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('contact-screen')), findsOneWidget);
    expect(find.text('联系家人'), findsOneWidget);
    expect(find.text('妈妈'), findsOneWidget);
    expect(find.text('奶奶'), findsNothing);
    expect(find.text('+86 **** 1002'), findsNothing);
    expect(find.text('+86 **** 1001'), findsOneWidget);
    expect(find.text('奶奶 · 奶奶'), findsNothing);
    expect(find.textContaining('smoke-member'), findsNothing);

    await tester.tap(find.byKey(const Key('profile-tab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-screen')), findsOneWidget);
    expect(find.text('设备与监测覆盖'), findsOneWidget);
  });

  testWidgets('toggles the guardian coverage overlay', (tester) async {
    await tester.pumpWidget(AnkoApp());
    await tester.pumpAndSettle();

    expect(find.text('覆盖图层'), findsOneWidget);
    await tester.ensureVisible(find.text('覆盖图层'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('覆盖图层'));
    await tester.pump();
    expect(find.text('关闭覆盖'), findsOneWidget);
  });

  testWidgets('opens natural language chat by long pressing Anko', (
    tester,
  ) async {
    await tester.pumpWidget(AnkoApp());
    await tester.pumpAndSettle();
    final anko = find.byKey(const Key('map-anko'));
    await tester.ensureVisible(anko);
    await tester.pumpAndSettle();

    await tester.longPress(anko);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('anko-conversation-screen')), findsOneWidget);
    expect(find.text('自然语言对话'), findsOneWidget);
    expect(find.byKey(const Key('conversation-text-field')), findsOneWidget);
  });

  testWidgets('pulls down into natural language chat and sends a message', (
    tester,
  ) async {
    await tester.pumpWidget(AnkoApp());
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const Key('message-card-drag-region')),
      const Offset(0, 180),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('anko-conversation-screen')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('conversation-text-field')),
      '家里现在安全吗？',
    );
    await tester.tap(find.byKey(const Key('send-conversation-message')));
    await tester.pump();
    expect(find.text('家里现在安全吗？'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.textContaining('家庭消息和守护事件'), findsOneWidget);
  });

  testWidgets('an elder selects first and second emergency contacts', (
    tester,
  ) async {
    await tester.pumpWidget(AnkoApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('contact-tab')));
    await tester.pumpAndSettle();

    final firstDropdown = find.byKey(
      const Key('first-emergency-contact-dropdown'),
    );
    final secondDropdown = find.byKey(
      const Key('second-emergency-contact-dropdown'),
    );
    expect(firstDropdown, findsOneWidget);
    expect(secondDropdown, findsOneWidget);

    await tester.tap(firstDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('妈妈').last);
    await tester.pumpAndSettle();

    await tester.tap(secondDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('孩子').last);
    await tester.pumpAndSettle();

    expect(find.text('紧急联系人已更新'), findsOneWidget);
    expect(find.byIcon(Icons.emergency_rounded), findsNWidgets(2));
    expect(find.text('第一'), findsOneWidget);
    expect(find.text('第二'), findsOneWidget);
  });

  testWidgets('joins a household with a family code', (tester) async {
    await tester.pumpWidget(AnkoApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('contact-tab')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('join-family-button')));
    await tester.pumpAndSettle();
    expect(find.text('通过家庭码加入'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('family-code-field')),
      'DEVANKO1',
    );
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), '爸爸');
    await tester.tap(find.byKey(const Key('submit-family-code')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('contact-screen')), findsOneWidget);
    expect(find.text('已加入Anko开发家庭'), findsOneWidget);
  });

  testWidgets('registers with a phone verification code', (tester) async {
    final store = SmokeDataStore();
    await tester.pumpWidget(
      AnkoApp(
        authRepository: SmokeAuthRepository(store: store),
        familyRepositoryFactory: (session) =>
            SmokeFamilyRepository(store: store, session: session),
        smokeMode: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('auth-screen')), findsOneWidget);
    expect(find.textContaining('SMOKE 开发账号'), findsNothing);
    expect(find.textContaining('13800001001'), findsNothing);

    await tester.tap(find.text('注册'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('auth-phone-field')),
      '13812345678',
    );
    await tester.tap(find.byKey(const Key('request-auth-code')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('auth-account-field')),
      'anko_test',
    );
    await tester.enterText(
      find.byKey(const Key('auth-nickname-field')),
      '测试用户',
    );
    await tester.ensureVisible(find.byKey(const Key('submit-auth')));
    await tester.tap(find.byKey(const Key('submit-auth')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('guardian-screen')), findsOneWidget);
  });

  test('smoke accounts use the same permission fields as the API', () {
    final store = SmokeDataStore();
    final mom = store.findByAnkoAccount('dev_mom')!;
    final child = store.findByAnkoAccount('dev_child')!;

    expect(mom.permissions['manageHousehold'], isTrue);
    expect(child.permissions['manageHousehold'], isFalse);
    expect(child.permissions['viewEventEvidence'], isFalse);
  });

  test('all three smoke accounts can sign in with the smoke code', () async {
    final store = SmokeDataStore();
    final expectedAccounts = {
      '13800001001': 'dev_mom',
      '13800001002': 'dev_grandma',
      '13800001003': 'dev_child',
    };

    for (final entry in expectedAccounts.entries) {
      final repository = SmokeAuthRepository(store: store);
      final challenge = await repository.requestCode(
        countryCode: '+86',
        phoneNumber: entry.key,
      );
      final session = await repository.verifyCode(
        challengeId: challenge.id,
        code: '123456',
      );
      expect(session.ankoAccount, entry.value);
      expect(session.householdId, smokeFamilyId);
    }
  });

  test('runtime services select smoke only when requested', () {
    final smoke = createRuntimeServices(
      smokeModeOverride: true,
      apiBaseUrlOverride: '',
    );
    final missingApi = createRuntimeServices(
      smokeModeOverride: false,
      apiBaseUrlOverride: '',
    );

    expect(smoke.authRepository, isA<SmokeAuthRepository>());
    expect(
      smoke.guardianMapRepositoryFactory(
        SmokeDataStore().findByAnkoAccount('dev_mom')!.toSession(),
      ),
      isA<SmokeGuardianMapRepository>(),
    );
    expect(missingApi.authRepository, isA<ConfigurationAuthRepository>());
  });

  test('formal mode wires the 2D guardian map API repository', () {
    final services = createRuntimeServices(
      smokeModeOverride: false,
      apiBaseUrlOverride: 'https://api.example.test',
    );
    final session = SmokeDataStore().findByAnkoAccount('dev_mom')!.toSession();

    expect(
      services.guardianMapRepositoryFactory(session),
      isA<ApiGuardianMapRepository>(),
    );
  });

  testWidgets('formal mode never silently falls back to smoke', (tester) async {
    final services = createRuntimeServices(
      smokeModeOverride: false,
      apiBaseUrlOverride: '',
    );
    await tester.pumpWidget(
      AnkoApp(
        authRepository: services.authRepository,
        familyRepositoryFactory: services.familyRepositoryFactory,
        smokeMode: services.smokeMode,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('configuration-error-screen')), findsOneWidget);
    expect(find.byKey(const Key('smoke-mode-banner')), findsNothing);
  });
}
