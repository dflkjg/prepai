import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../services/supabase_service.dart';
import '../../widgets/app_widgets.dart';

class ResumeUploadScreen extends ConsumerStatefulWidget {
  const ResumeUploadScreen({super.key});
  @override
  ConsumerState<ResumeUploadScreen> createState() =>
      _ResumeUploadScreenState();
}

class _ResumeUploadScreenState extends ConsumerState<ResumeUploadScreen> {
  String? _fileName;
  Uint8List? _fileBytes;
  bool _uploading = false;
  String? _error;
  String _status = '';

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    setState(() {
      _fileName = file.name;
      _fileBytes = file.bytes;
      _error = null;
    });
  }

  Future<void> _uploadAndAnalyze() async {
    if (_fileBytes == null || _fileName == null) return;
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;

    setState(() { _uploading = true; _status = 'Uploading resume...'; _error = null; });

    try {
      setState(() => _status = 'Analyzing with AI... (this may take 15-30s)');

      await ref.read(resumeServiceProvider).uploadAndAnalyze(
            userId: uid,
            fileName: _fileName!,
            bytes: _fileBytes!,
          );

      // Refresh the cached resume
      await ref.read(resumeProvider.notifier).loadLatest(uid);

      if (mounted) {
        context.push('/resume/analysis');
      }
    } catch (e) {
      setState(() => _error = 'Analysis failed: ${e.toString().split('\n').first}');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingResume = ref.watch(resumeProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume'),
        leading: BackButton(onPressed: () => context.go('/home')),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Card ─────────────────────────────
                AppCard(
                  color: AppColors.primary,
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.description_outlined,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Upload Your Resume',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                            SizedBox(height: 4),
                            Text(
                              'AI will analyze your resume and give personalised feedback.',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Existing Resume ──────────────────────────
                if (existingResume != null) ...[
                  const Text('Current Resume',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  AppCard(
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.check_circle_outline,
                              color: AppColors.success, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(existingResume.fileName ?? 'Resume',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              Text(
                                'Score: ${existingResume.analysis?.score ?? 0}/100',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.push('/resume/analysis'),
                          child: const Text('View'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Upload New Resume',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                ],

                // ── Drop Zone ────────────────────────────────
                GestureDetector(
                  onTap: _pickFile,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: BoxDecoration(
                      color: _fileBytes != null
                          ? AppColors.primary.withOpacity(0.05)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _fileBytes != null
                            ? AppColors.primary
                            : AppColors.divider,
                        width: _fileBytes != null ? 2 : 1,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _fileBytes != null
                              ? Icons.description
                              : Icons.cloud_upload_outlined,
                          size: 48,
                          color: _fileBytes != null
                              ? AppColors.primary
                              : AppColors.textHint,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _fileBytes != null
                              ? _fileName!
                              : 'Tap to select PDF resume',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _fileBytes != null
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _fileBytes != null
                              ? '${(_fileBytes!.length / 1024).toStringAsFixed(1)} KB • PDF'
                              : 'Supports PDF files',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textHint),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: _fileBytes != null
                                ? AppColors.primary.withOpacity(0.1)
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _fileBytes != null ? 'Change File' : 'Browse Files',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _fileBytes != null
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(_error!,
                                style: const TextStyle(
                                    color: AppColors.error, fontSize: 13))),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                GradientButton(
                  label: 'Analyze Resume',
                  onPressed: _fileBytes != null ? _uploadAndAnalyze : null,
                  isLoading: _uploading,
                  icon: Icons.auto_awesome,
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          if (_uploading)
            LoadingOverlay(message: _status),
        ],
      ),
    );
  }
}
