import 'package:flutter/material.dart';

import '../models/resume.dart';
import '../services/auth_service.dart';
import '../services/resume_service.dart';
import 'import_screen.dart';
import 'preview_screen.dart';
import 'resume_editor_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, Resume resume) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete resume?'),
        content: Text('"${resume.title}" will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;

    try {
      await ResumeService().deleteResume(resume.id);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete resume: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ResumeService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Resumes'),
        actions: [
          IconButton(
            tooltip: 'Import from LinkedIn',
            icon: const Icon(Icons.upload_file),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ImportScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ResumeEditorScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New resume'),
      ),
      body: StreamBuilder<List<Resume>>(
        stream: service.watchResumes(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final resumes = snapshot.data!;
          if (resumes.isEmpty) {
            return const Center(
              child: Text(
                'No resumes yet.\nTap "New resume" to create one.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: resumes.length,
            itemBuilder: (context, index) {
              final resume = resumes[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(resume.title),
                  subtitle: Text(
                    resume.fullName.isEmpty ? 'No name yet' : resume.fullName,
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'pdf') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PreviewScreen(resume: resume),
                          ),
                        );
                      } else if (value == 'copy') {
                        try {
                          await service.duplicateResume(resume);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Resume duplicated'),
                              ),
                            );
                          }
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Could not duplicate resume: $error'),
                              ),
                            );
                          }
                        }
                      } else if (value == 'delete') {
                        _confirmDelete(context, resume);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'pdf',
                        child: Text('Preview & export PDF'),
                      ),
                      PopupMenuItem(value: 'copy', child: Text('Duplicate')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ResumeEditorScreen(resume: resume),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
