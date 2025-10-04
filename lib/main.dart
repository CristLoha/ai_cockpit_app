import 'package:ai_cockpit_app/api/api_service.dart';
import 'package:ai_cockpit_app/blocs/chat/chat_bloc.dart';
import 'package:ai_cockpit_app/blocs/file_picker/file_picker_cubit.dart';
import 'package:ai_cockpit_app/presentation/screens/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => ApiService(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                ChatBloc(apiService: context.read<ApiService>()),
          ),
          BlocProvider(create: (context) => FilePickerCubit()),
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
          home: const ChatScreen(),
        ),
      ),
    );
  }
}
