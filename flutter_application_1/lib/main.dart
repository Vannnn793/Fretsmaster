import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection_container.dart' as di;
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/chord_detection/presentation/bloc/chord_detection_bloc.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/practice_drill/presentation/bloc/practice_drill_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi Service Locator (Clean Architecture Dependency Injection)
  await di.initServiceLocator();
  
  runApp(const FretMasterApp());
}

class FretMasterApp extends StatelessWidget {
  const FretMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => di.sl<AuthBloc>()..add(const AuthCheckRequested()),
        ),
        BlocProvider<ChordDetectionBloc>(
          create: (_) => di.sl<ChordDetectionBloc>(),
        ),
        BlocProvider<PracticeDrillBloc>(
          create: (_) => di.sl<PracticeDrillBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'FretMaster — AI Chord Gitar',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomePage(),
      ),
    );
  }
}
