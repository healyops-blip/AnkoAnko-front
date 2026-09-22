import 'package:flutter/material.dart';

import 'data/auth_repository.dart';
import 'data/configuration_auth_repository.dart';
import 'data/family_repository.dart';
import 'data/smoke_auth_repository.dart';
import 'data/smoke_data_store.dart';
import 'data/smoke_family_repository.dart';
import 'domain/auth_models.dart';
import 'screens/auth_screen.dart';
import 'screens/contact_screen.dart';
import 'screens/guardian_screen.dart';
import 'screens/profile_screen.dart';

typedef FamilyRepositoryFactory = FamilyRepository Function(
  AuthSession session,
);

class AnkoApp extends StatelessWidget {
  factory AnkoApp({
    Key? key,
    AuthRepository? authRepository,
    FamilyRepositoryFactory? familyRepositoryFactory,
    bool? smokeMode,
  }) {
    if (authRepository != null && familyRepositoryFactory != null) {
      return AnkoApp._(
        key: key,
        authRepository: authRepository,
        familyRepositoryFactory: familyRepositoryFactory,
        smokeMode: smokeMode ?? false,
      );
    }
    final store = SmokeDataStore();
    final session = store.findByAnkoAccount('dev_grandma')!.toSession();
    return AnkoApp._(
      key: key,
      authRepository: SmokeAuthRepository(
        store: store,
        initialSession: session,
      ),
      familyRepositoryFactory: (activeSession) =>
          SmokeFamilyRepository(store: store, session: activeSession),
      smokeMode: smokeMode ?? true,
    );
  }

  const AnkoApp._({
    required this.authRepository,
    required this.familyRepositoryFactory,
    required this.smokeMode,
    super.key,
  });

  final AuthRepository authRepository;
  final FamilyRepositoryFactory familyRepositoryFactory;
  final bool smokeMode;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF172130);
    const blue = Color(0xFF0876F9);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Anko',
      builder: (context, child) {
        if (!smokeMode) return child!;
        return Banner(
          key: const Key('smoke-mode-banner'),
          message: 'SMOKE',
          location: BannerLocation.topEnd,
          color: const Color(0xFFE07A19),
          child: child!,
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        colorScheme: ColorScheme.fromSeed(seedColor: blue, primary: blue),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: ink,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: TextStyle(
            color: ink,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: TextStyle(color: ink, height: 1.5),
          bodyMedium: TextStyle(color: Color(0xFF748196), height: 1.5),
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        navigationBarTheme: const NavigationBarThemeData(
          height: 72,
          backgroundColor: Colors.white,
          indicatorColor: Color(0xFFE4ECF8),
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      home: SessionGate(
        authRepository: authRepository,
        familyRepositoryFactory: familyRepositoryFactory,
      ),
    );
  }
}

class SessionGate extends StatefulWidget {
  const SessionGate({
    required this.authRepository,
    required this.familyRepositoryFactory,
    super.key,
  });

  final AuthRepository authRepository;
  final FamilyRepositoryFactory familyRepositoryFactory;

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late Future<AuthSession?> _restoredSession;
  AuthSession? _session;

  @override
  void initState() {
    super.initState();
    _restoredSession = widget.authRepository.restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    if (_session case final session?) {
      return HomeShell(
        familyRepository: widget.familyRepositoryFactory(session),
      );
    }
    return FutureBuilder<AuthSession?>(
      future: _restoredSession,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          return _ConfigurationErrorScreen(
            message: error is AppConfigurationException
                ? error.message
                : '应用初始化失败，请检查运行配置。',
          );
        }
        if (snapshot.data case final session?) {
          return HomeShell(
            familyRepository: widget.familyRepositoryFactory(session),
          );
        }
        return AuthScreen(
          repository: widget.authRepository,
          onAuthenticated: (session) => setState(() => _session = session),
        );
      },
    );
  }
}

class _ConfigurationErrorScreen extends StatelessWidget {
  const _ConfigurationErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('configuration-error-screen'),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.settings_ethernet_rounded,
                  size: 52,
                  color: Color(0xFFE07A19),
                ),
                const SizedBox(height: 16),
                const Text(
                  '运行配置不完整',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({required this.familyRepository, super.key});

  final FamilyRepository familyRepository;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      ContactScreen(repository: widget.familyRepository),
      const GuardianScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) =>
              setState(() => _selectedIndex = index),
          destinations: const [
            NavigationDestination(
              key: Key('contact-tab'),
              icon: Icon(Icons.favorite_border_rounded),
              selectedIcon: Icon(Icons.favorite_rounded),
              label: '家人',
            ),
            NavigationDestination(
              key: Key('guardian-tab'),
              icon: Icon(Icons.pets_outlined),
              selectedIcon: Icon(Icons.pets_rounded),
              label: 'Anko',
            ),
            NavigationDestination(
              key: Key('profile-tab'),
              icon: Icon(Icons.account_circle_outlined),
              selectedIcon: Icon(Icons.account_circle_rounded),
              label: '我的',
            ),
          ],
        ),
      ),
    );
  }
}
