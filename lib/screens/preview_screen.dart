import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/resume.dart';
import '../services/resume_service.dart';
import '../templates/pdf_templates.dart';
import '../theme/app_theme.dart';

class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key, required this.resume});

  final Resume resume;

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  static const _swatches = [
    0,
    0xFF6D5CFF,
    0xFF2563EB,
    0xFF0F766E,
    0xFF15803D,
    0xFFB91C1C,
    0xFFC2410C,
    0xFFBE185D,
    0xFF334155,
  ];

  late String _template = templateNames.containsKey(widget.resume.templateId)
      ? widget.resume.templateId
      : 'classic';
  late int _accent = widget.resume.accentColor;
  bool _saving = false;

  Future<void> _saveSelection({String? template, int? accent}) async {
    if (_saving) return;
    final previousTemplate = _template;
    final previousAccent = _accent;

    setState(() {
      _saving = true;
      if (template != null) _template = template;
      if (accent != null) _accent = accent;
    });
    widget.resume
      ..templateId = _template
      ..accentColor = _accent;

    try {
      await ResumeService().saveResume(widget.resume);
    } catch (error) {
      widget.resume
        ..templateId = previousTemplate
        ..accentColor = previousAccent;
      if (mounted) {
        setState(() {
          _template = previousTemplate;
          _accent = previousAccent;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save preview settings: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _swatchRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text('Color'),
          const SizedBox(width: 12),
          for (final color in _swatches)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Tooltip(
                message: color == 0 ? 'Template default' : 'Accent color',
                child: GestureDetector(
                  onTap: _saving ? null : () => _saveSelection(accent: color),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color == 0 ? AppColors.card : Color(color),
                      border: Border.all(
                        color: _accent == color
                            ? Colors.white
                            : AppColors.border,
                        width: _accent == color ? 2.5 : 1,
                      ),
                    ),
                    child: color == 0
                        ? const Icon(Icons.format_color_reset, size: 16)
                        : _accent == color
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeTitle = widget.resume.title
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final fileName = '${safeTitle.isEmpty ? 'resume' : safeTitle}.pdf';

    return Scaffold(
      appBar: AppBar(title: const Text('Preview & Export')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Wrap(
              spacing: 8,
              children: [
                for (final entry in templateNames.entries)
                  ChoiceChip(
                    label: Text(entry.value),
                    selected: _template == entry.key,
                    onSelected: _saving
                        ? null
                        : (_) => _saveSelection(template: entry.key),
                  ),
              ],
            ),
          ),
          _swatchRow(),
          if (_saving) const LinearProgressIndicator(),
          const SizedBox(height: 10),
          Expanded(
            child: PdfPreview(
              key: ValueKey('$_template-$_accent'),
              build: (format) => buildResumePdf(widget.resume, _template),
              pdfFileName: fileName,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
            ),
          ),
        ],
      ),
    );
  }
}
