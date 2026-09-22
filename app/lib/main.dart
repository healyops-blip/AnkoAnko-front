import 'package:flutter/material.dart';

import 'anko_app.dart';
import 'data/runtime_services.dart';

void main() {
  final services = createRuntimeServices();
  runApp(
    AnkoApp(
      authRepository: services.authRepository,
      familyRepositoryFactory: services.familyRepositoryFactory,
      smokeMode: services.smokeMode,
    ),
  );
}
