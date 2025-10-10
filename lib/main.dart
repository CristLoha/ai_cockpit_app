import 'dart:async';

import 'package:ai_cockpit_app/api/api_service.dart';
import 'package:ai_cockpit_app/blocs/analysis/analysis_bloc.dart';
import 'package:ai_cockpit_app/blocs/chat/chat_bloc.dart';
import 'package:ai_cockpit_app/blocs/file_picker/file_picker_cubit.dart';
import 'package:ai_cockpit_app/blocs/history/history_cubit.dart';
import 'package:ai_cockpit_app/data/repositories/chat_repository.dart';
import 'package:ai_cockpit_app/data/repositories/device_repository.dart';
import 'package:ai_cockpit_app/firebase_options.dart';
import 'package:ai_cockpit_app/presentation/screens/upload_screen.dart';
import 'package:ai_cockpit_app/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/auth/auth_cubit.dart';

final NotificationService notificationService = NotificationService();

void main() {
  // GANTI FUNGSI main() LAMA-MU DENGAN INI
  runZonedGuarded(
    () async {
      // Tambahkan async di sini
      // Semua kode inisialisasi aslimu aman di dalam sini
      WidgetsFlutterBinding.ensureInitialized();

      ErrorWidget.builder = (FlutterErrorDetails details) {
        // Kode ErrorWidget-mu tetap sama
        bool inDebug = false;
        assert(inDebug = true, '');
        if (!inDebug) {
          return const Material(
            child: Center(
              child: Text(
                'Terjadi kesalahan.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }
        return Material(
          child: SingleChildScrollView(
            child: Container(
              color: Colors.redAccent.withOpacity(0.1),
              padding: const EdgeInsets.all(16),
              child: Text(
                details.toString(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        );
      };

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await notificationService.init();

      runApp(const MyApp());
    },
    (error, stackTrace) {
      // Jaring ini akan menangkap SEMUA error yang tidak tertangani
      print("==============================================");
      print("          ERROR TERTANGKAP DI LEVEL ATAS      ");
      print("==============================================");
      print("PESAN ERROR: $error");
      print("----------------------------------------------");
      print("LOKASI FILE (STACK TRACE):");
      print(stackTrace);
      print("==============================================");
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => DeviceRepository()),
        RepositoryProvider(
          create: (context) =>
              ApiService(deviceRepository: context.read<DeviceRepository>()),
        ),
        RepositoryProvider(
          create: (context) =>
              ChatRepository(apiService: context.read<ApiService>()),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => FilePickerCubit()),
          BlocProvider(create: (context) => AuthCubit()),
          BlocProvider(
            create: (context) => ChatBloc(
              chatRepository: context.read<ChatRepository>(),
              notificationService: notificationService,
            ),
          ),
          BlocProvider(
            create: (context) =>
                HistoryCubit(apiService: context.read<ApiService>()),
          ),
          BlocProvider(
            create: (context) => AnalysisBloc(
              chatRepository: context.read<ChatRepository>(),
              filePickerCubit: context.read<FilePickerCubit>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'AI Cockpit',
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF1E1E1E),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF252525),
              elevation: 1,
              centerTitle: true,
            ),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF3D5AFE),
              secondary: Color(0xFF424242),
            ),
          ),
          debugShowCheckedModeBanner: false,
          home: UploadScreen(),
        ),
      ),
    );
  }
}
