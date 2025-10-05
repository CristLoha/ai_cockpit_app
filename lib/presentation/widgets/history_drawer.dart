
import 'package:ai_cockpit_app/blocs/auth/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HistoryDrawer extends StatelessWidget {
  final bool isAuthenticated;
  final VoidCallback onNewChat;

  const HistoryDrawer({
    super.key,
    required this.isAuthenticated,
    required this.onNewChat,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF252525),
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(
                height: 120,
                child: DrawerHeader(
                  child: Text('Riwayat Chat', style: TextStyle(fontSize: 24)),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Chat Baru'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              if (state is Authenticated) ...[
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Terkini'),
                ),
                ListTile(title: const Text('Analisis Jurnal A...')),
                ListTile(title: const Text('Rangkuman Paper B...')),
              ] else ...[
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.history),
                  title: Text('Sign in untuk melihat riwayat'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
