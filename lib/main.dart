import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/app_repository.dart';
import 'state/archive_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ArchiveStore(AppRepository())..load(),
      child: const CameraArchiveApp(),
    ),
  );
}
