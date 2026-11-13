import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/resume.dart';
import '../services/ai_service.dart';
import 'resume_editor_screen.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final _text = TextEditingController();
  Uint8List? _pdf;
  String? _pdfName;
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result.isEmpty || !mounted) return;
    final file = result.first;
    final fileSize = await file.length();
    if (!mounted) return;
    if (fileSize != null && fileSize > 4 * 1024 * 1024) {
      _snack('PDF is too large (max 4 MB).');
      return;
    }
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    if (bytes.isEmpty) {
      _snack('Could not read the file. Try again.');
      return;
    }
    if (bytes.length > 4 * 1024 * 1024) {
      _snack('PDF is too large (max 4 MB).');
      return;
    }
    setState(() {
      _pdf = bytes;
      _pdfName = file.name;
    });
  }

  Future<void> _import() async {
    if (_pdf == null && _text.text.trim().isEmpty) {
      _snack('Upload a PDF or paste your profile text first.');
      return;
    }
    setState(() => _busy = true);
    try {
      final map = await AiService().parseProfile(
        text: _text.text,
        pdfBytes: _pdf,
      );
      final resume = Resume.fromMap('', map)..title = 'Imported Resume';
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ResumeEditorScreen(resume: resume)),
      );
    } catch (error) {
      if (!mounted) return;
      _snack('Import failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import from LinkedIn')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'On LinkedIn open your profile, tap More > Save to PDF, '
              'then upload that PDF here. Or paste your profile text below.',
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _busy ? null : _pickPdf,
              icon: const Icon(Icons.upload_file),
              label: Text(_pdfName ?? 'Upload LinkedIn PDF'),
            ),
            const SizedBox(height: 16),
            const Center(child: Text('or')),
            const SizedBox(height: 16),
            TextField(
              controller: _text,
              maxLines: 10,
              enabled: !_busy,
              decoration: const InputDecoration(
                labelText: 'Paste profile text',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _busy ? null : _import,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_busy ? 'Importing...' : 'Import with AI'),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your profile text is sent to Google Gemini for processing. '
              'Review everything before saving.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
