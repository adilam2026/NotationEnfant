import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'navigation.dart';
import 'providers/auth_provider.dart';
import 'providers/child_mode_provider.dart';
import 'providers/family_provider.dart';
import 'screens/root/auth_gate.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    // ignore: deprecated_member_use
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const MesEtoilesApp());
}

class MesEtoilesApp extends StatelessWidget {
  const MesEtoilesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FamilyProvider()),
        ChangeNotifierProvider(create: (_) => ChildModeProvider()),
      ],
      child: MaterialApp(
        title: 'Mes Étoiles',
        debugShowCheckedModeBanner: false,
        navigatorKey: rootNavigatorKey,
        theme: AppTheme.light(),
        home: const AuthGate(),
      ),
    );
  }
}
