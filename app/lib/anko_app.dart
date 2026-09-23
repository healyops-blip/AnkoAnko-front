import 'package:flutter/material.dart';

import 'data/auth_repository.dart';
import 'data/configuration_auth_repository.dart';
import 'data/family_repository.dart';
import 'data/guardian_map_repository.dart';
import 'data/smoke_auth_repository.dart';
import 'data/smoke_data_store.dart';
import 'data/smoke_family_repository.dart';
import 'data/smoke_guardian_map_repository.dart';
import 'domain/auth_models.dart';
import 'screens/auth_screen.dart';
import 'screens/contact_screen.dart';
import 'screens/guardian_screen.dart';
import 'screens/profile_screen.dart';

typedef FamilyRepositoryFactory = FamilyRepository Function(
  AuthSession session,
);
typedef GuardianMapRepositoryFactory = GuardianMapRepository Function(
  AuthSession session,
);

class AnkoApp extends StatelessWidget {
  factory AnkoApp({
    Key? key,
    AuthRepository? authRepository,
    FamilyRepositoryFactory? familyRepositoryFactory,
    GuardianMapRepositoryFactory? guardianMapRepositoryFactory,
    bool? smokeMode,
  }) {
    if (authRepository != null && familyRepositoryFactory != null) {
      final resolvedSmokeMode = smokeMode ?? false;
      return AnkoApp._(
        key: key,
        authRepository: authRepository,
        familyRepositoryFactory: familyRepositoryFactory,
        guardianMapRepositoryFactory:
            guardianMapRepositoryFactory ??
            (_) => resolvedSmokeMode
                ? const SmokeGuardianMapRepository()
                : const ConfigurationGuardianMapRepository(
                    '正式模式缺少二维地图 Repository。',
                  ),
        smokeMode: resolvedSmokeMode,
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
      guardianMapRepositoryFactory: (_) => const SmokeGuardianMapRepository(),
      smokeMode: smokeMode ?? true,
    );
  }

  const AnkoApp._({
    required this.authRepository,
    required this.familyRepositoryFactory,
    required this.guardianMapRepositoryFactory,
    required this.smokeMode,
    super.key,
  });

  final AuthRepository authRepository;
  final FamilyRepositoryFactory familyRepositoryFactory;
  final GuardianMapRepositoryFactory guardianMapRepositoryFactory;
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
      ),
      home: SessionGate(
        authRepository: authRepository,
        familyRepositoryFactory: familyRepositoryFactory,
        guardianMapRepositoryFactory: guardianMapRepositoryFactory,
      ),
    );
  }
}

class SessionGate extends StatefulWidget {
  const SessionGate({
    required this.authRepository,
    required this.familyRepositoryFactory,
    required this.guardianMapRepositoryFactory,
    super.key,
  });

  final AuthRepository authRepository;
  final FamilyRepositoryFactory familyRepositoryFactory;
  final GuardianMapRepositoryFactory guardianMapRepositoryFactory;

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
        guardianMapRepository: widget.guardianMapRepositoryFactory(session),
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
            guardianMapRepository: widget.guardianMapRepositoryFactory(session),
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
  const HomeShell({
    required this.familyRepository,
    required this.guardianMapRepository,
    super.key,
  });

  final FamilyRepository familyRepository;
  final GuardianMapRepository guardianMapRepository;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      ContactScreen(repository: widget.familyRepository),
      GuardianScreen(repository: widget.guardianMapRepository),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: _BubbleNavigationBar(
        selectedIndex: _selectedIndex,
        onSelected: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}

class _BubbleNavigationBar extends StatelessWidget {
  const _BubbleNavigationBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  static const _destinations = [
    _BubbleDestination(
      key: Key('contact-tab'),
      icon: Icons.favorite_border_rounded,
      selectedIcon: Icons.favorite_rounded,
      label: '家人',
    ),
    _BubbleDestination(
      key: Key('guardian-tab'),
      icon: Icons.pets_outlined,
      selectedIcon: Icons.pets_rounded,
      label: 'Anko',
    ),
    _BubbleDestination(
      key: Key('profile-tab'),
      icon: Icons.account_circle_outlined,
      selectedIcon: Icons.account_circle_rounded,
      label: '我的',
    ),
  ];

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(18, 8, 18, 10),
      child: DecoratedBox(
        key: const Key('bubble-navigation-bar'),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFF4F8FD)],
          ),
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: const Color(0xFFDDE8F4)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x24125B9F),
              blurRadius: 24,
              offset: Offset(0, 9),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              for (var index = 0; index < _destinations.length; index++)
                Expanded(
                  child: _BubbleNavigationItem(
                    destination: _destinations[index],
                    selected: selectedIndex == index,
                    onTap: () => onSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BubbleNavigationItem extends StatelessWidget {
  const _BubbleNavigationItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _BubbleDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 260);
    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: destination.key,
            borderRadius: BorderRadius.circular(27),
            onTap: onTap,
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.easeOutCubic,
              height: 54,
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF55A5FF), Color(0xFF0876F9)],
                      )
                    : null,
                borderRadius: BorderRadius.circular(27),
                boxShadow: selected
                    ? const [
                        BoxShadow(
                          color: Color(0x3D0876F9),
                          blurRadius: 13,
                          offset: Offset(0, 5),
                        ),
                        BoxShadow(
                          color: Color(0x8AFFFFFF),
                          blurRadius: 1,
                          offset: Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    duration: duration,
                    curve: Curves.easeOutBack,
                    scale: selected ? 1.08 : 1,
                    child: Icon(
                      selected ? destination.selectedIcon : destination.icon,
                      color: selected ? Colors.white : const Color(0xFF718399),
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedDefaultTextStyle(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF718399),
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                    child: Text(destination.label),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BubbleDestination {
  const _BubbleDestination({
    required this.key,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final Key key;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
