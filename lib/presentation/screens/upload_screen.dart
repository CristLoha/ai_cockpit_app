import 'package:ai_cockpit_app/blocs/analysis/analysis_bloc.dart';
import 'package:ai_cockpit_app/blocs/auth/auth_cubit.dart';
import 'package:ai_cockpit_app/blocs/file_picker/file_picker_cubit.dart';
import 'package:ai_cockpit_app/blocs/history/history_cubit.dart';
import 'package:ai_cockpit_app/presentation/screens/analysis_result_screen.dart';
import 'package:ai_cockpit_app/presentation/widgets/history_drawer.dart';
import 'package:ai_cockpit_app/presentation/widgets/welcome_message.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final isAuthenticated = authState is Authenticated;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          context.read<HistoryCubit>().fetchHistory();
        }
      },
      child: BlocBuilder<AnalysisBloc, AnalysisState>(
        builder: (context, analysisState) {
          return PopScope(
            canPop: analysisState.status != AnalysisStatus.loading,
            onPopInvokedWithResult: (bool didPop, _) {
              if (!didPop && analysisState.status == AnalysisStatus.loading) {
                context.read<AnalysisBloc>().add(AnalysisCancelled());
              }
            },
            child: Scaffold(
              backgroundColor: const Color(0xFF1A1A1A),
              appBar: _buildAppBar(context, authState),
              drawer: HistoryDrawer(
                isAuthenticated: isAuthenticated,
                onNewChat: () => Navigator.pop(context),
              ),
              body: MultiBlocListener(
                listeners: [
                  BlocListener<AnalysisBloc, AnalysisState>(
                    listenWhen: (previous, current) =>
                        previous.status != current.status,
                    listener: (context, state) {
                      if (state.status == AnalysisStatus.success &&
                          state.result != null) {
                        context.read<HistoryCubit>().fetchHistory();

                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (_) => AnalysisResultScreen(
                                  result: state.result!,
                                  chatId: state.result!.chatId,
                                ),
                              ),
                            )
                            .then((_) {
                              if (mounted) {
                                context.read<AnalysisBloc>().add(
                                  AnalysisReset(),
                                );
                              }
                            });
                      } else if (state.status == AnalysisStatus.failure) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              state.errorMessage ??
                                  'Terjadi kesalahan yang tidak diketahui.',
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
                  ),
                ],
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          WelcomeMessage(authState: authState),
                          const SizedBox(height: 40),
                          _buildFileUploadArea(context),
                          const SizedBox(height: 40),
                          _buildAnalyzeButton(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFileUploadArea(BuildContext context) {
    return BlocBuilder<AnalysisBloc, AnalysisState>(
      builder: (context, analysisState) {
        return BlocBuilder<FilePickerCubit, FilePickerState>(
          builder: (context, fileState) {
            final bool hasFiles = fileState.selectedFiles.isNotEmpty;
            final bool isLoading =
                analysisState.status == AnalysisStatus.loading;

            return GestureDetector(
              onTap: isLoading
                  ? null
                  : () => context.read<FilePickerCubit>().pickSingleFile(),
              child: DottedBorder(
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 200),
                  decoration: BoxDecoration(
                    color: const Color(0xFF212121).withAlpha(128),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildFileUploadChild(
                      context,
                      isLoading,
                      hasFiles,
                      analysisState,
                      fileState,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFileUploadChild(
    BuildContext context,
    bool isLoading,
    bool hasFiles,
    AnalysisState analysisState,
    FilePickerState fileState,
  ) {
    if (isLoading) {
      return _buildLoadingView(context, analysisState.uploadProgress);
    } else if (hasFiles) {
      return _buildSelectedFileView(context, fileState.selectedFiles.first);
    } else {
      return _buildEmptyUploadView();
    }
  }

  Widget _buildLoadingView(BuildContext context, double progress) {
    return Center(
      key: const ValueKey('loading'),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: Colors.grey.shade800,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.deepPurple,
                    ),
                  ),
                  Center(
                    child: Text(
                      '${(progress * 100).toInt()}%',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              progress < 1.0 ? 'Mengunggah dokumen...' : 'Menganalisis...',
              style: GoogleFonts.inter(
                color: Colors.grey.shade400,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyUploadView() {
    return Center(
      key: const ValueKey('empty'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            size: 60,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 12),
          Text(
            'Ketuk untuk memilih dokumen\n(PDF/DOCX)',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedFileView(BuildContext context, SelectedFile file) {
    return Center(
      key: const ValueKey('selected'),

      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.insert_drive_file_rounded,
                  color: Colors.deepPurpleAccent,
                ),
                title: Text(
                  file.fileName,
                  style: const TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, color: Colors.redAccent),
                  onPressed: () => context.read<FilePickerCubit>().clearFiles(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton(BuildContext context) {
    return BlocBuilder<AnalysisBloc, AnalysisState>(
      builder: (context, analysisState) {
        return BlocBuilder<FilePickerCubit, FilePickerState>(
          builder: (context, fileState) {
            final bool isLoading =
                analysisState.status == AnalysisStatus.loading;
            final bool hasFile = fileState.selectedFiles.isNotEmpty;
            return SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                icon: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.science_outlined, color: Colors.white),
                label: Text(
                  isLoading ? 'Menganalisis...' : 'Analisis Sekarang',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                onPressed: (isLoading || !hasFile)
                    ? null
                    : () => context.read<AnalysisBloc>().add(
                        AnalysisDocumentRequested(),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  disabledBackgroundColor: Colors.grey.shade800,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AuthState authState) {
    return AppBar(
      backgroundColor: const Color(0xFF2D2D2D),
      elevation: 0,
      title: Text(
        'AI Research Cockpit',
        style: GoogleFonts.spaceGrotesk(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
      centerTitle: true,
      actions: [_buildAuthButton(context), const SizedBox(width: 16)],
    );
  }

  Widget _buildAuthButton(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.white,
              ),
            ),
          );
        }

        if (state is Authenticated) {
          return GestureDetector(
            onTap: () => _showSignOutDialog(context),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Theme.of(context).primaryColor, Colors.deepPurple],
                ),
              ),
              child: CircleAvatar(
                backgroundImage: NetworkImage(state.user.photoURL ?? ''),
                radius: 18,
              ),
            ),
          );
        }
        return ElevatedButton.icon(
          onPressed: () => context.read<AuthCubit>().signInWithGoogle(),
          icon: const Icon(Icons.login, size: 18),
          label: Text(
            'Sign In',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D2D2D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Sign Out',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Apakah Anda yakin ingin keluar?',
            style: GoogleFonts.inter(color: Colors.white70),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Batal',
                style: GoogleFonts.inter(color: Colors.grey),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                context.read<AuthCubit>().signOut();
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                'Keluar',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
