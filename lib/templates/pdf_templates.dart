import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/resume.dart';

const templateNames = {
  'cv': 'CV Style',
  'classic': 'Classic',
  'modern': 'Modern',
  'minimal': 'Minimal',
};

PdfColor _tint(PdfColor color) => PdfColor(
  color.red + (1 - color.red) * 0.88,
  color.green + (1 - color.green) * 0.88,
  color.blue + (1 - color.blue) * 0.88,
);

Future<Uint8List> buildResumePdf(Resume resume, String templateId) async {
  final document = pw.Document(title: resume.title, author: resume.fullName);
  final accent = resume.accentColor == 0
      ? null
      : PdfColor.fromInt(resume.accentColor);
  switch (templateId) {
    case 'cv':
      _cv(document, resume, accent);
    case 'modern':
      _modern(document, resume, accent);
    case 'minimal':
      _minimal(document, resume, accent);
    default:
      _classic(document, resume, accent);
  }
  return document.save();
}

String _location(Resume resume) {
  final location = [resume.city, resume.country]
      .where((value) => value.trim().isNotEmpty)
      .join(', ');
  return location.isNotEmpty ? location : resume.address;
}

String _contact(Resume resume) => [
  resume.email,
  resume.phone,
  _location(resume),
].where((value) => value.trim().isNotEmpty).join('  |  ');

String _dates(String start, String end) =>
    [start, end].where((value) => value.trim().isNotEmpty).join(' - ');

pw.Widget _heading(String text, PdfColor color, {bool line = true}) {
  return pw.Container(
    width: double.infinity,
    margin: const pw.EdgeInsets.only(top: 14, bottom: 6),
    padding: const pw.EdgeInsets.only(bottom: 2),
    decoration: line
        ? pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: color, width: 1)),
          )
        : null,
    child: pw.Text(
      text.toUpperCase(),
      style: pw.TextStyle(
        fontSize: 12,
        fontWeight: pw.FontWeight.bold,
        color: color,
      ),
    ),
  );
}

pw.Widget _experienceItem(Experience experience) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Text(
                experience.role,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Text(
              _dates(experience.startDate, experience.endDate),
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
        pw.Text(
          experience.company,
          style: const pw.TextStyle(fontSize: 10.5),
        ),
        pw.SizedBox(height: 2),
        for (final bullet in experience.bullets)
          pw.Bullet(text: bullet, style: const pw.TextStyle(fontSize: 10)),
      ],
    ),
  );
}

String _educationSubtitle(Education education) {
  final parts = <String>[];
  if (education.institution.trim().isNotEmpty) {
    parts.add(education.institution);
  }
  if (education.semester.trim().isNotEmpty) {
    parts.add('Semester: ${education.semester}');
  }
  final end = education.endDate.trim();
  final year = int.tryParse(RegExp(r'\d{4}').firstMatch(end)?.group(0) ?? '');
  if (year != null && year > DateTime.now().year) {
    parts.add('Expected Graduation: $end');
  } else {
    final dates = _dates(education.startDate, education.endDate);
    if (dates.isNotEmpty) parts.add(dates);
  }
  return parts.join(' | ');
}

pw.Widget _educationItem(Education education) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          education.degree,
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          _educationSubtitle(education),
          style: const pw.TextStyle(fontSize: 10),
        ),
      ],
    ),
  );
}

pw.Widget _projectItem(Project project) {
  final points = project.bullets
      .where((bullet) => bullet.trim().isNotEmpty)
      .toList();
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 7),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                text: project.title,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (project.techStack.trim().isNotEmpty)
                pw.TextSpan(
                  text: ' | ${project.techStack}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
            ],
          ),
        ),
        if (points.isNotEmpty)
          ...points.map(
            (bullet) =>
                pw.Bullet(text: bullet, style: const pw.TextStyle(fontSize: 10)),
          )
        else if (project.description.trim().isNotEmpty)
          pw.Text(
            project.description,
            style: const pw.TextStyle(fontSize: 10),
          ),
        if (project.link.trim().isNotEmpty)
          pw.Text(
            project.link,
            style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.blue700),
          ),
      ],
    ),
  );
}

pw.Widget _certificationItem(Certification certification) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 5),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.RichText(
            text: pw.TextSpan(
              children: [
                pw.TextSpan(
                  text: certification.name,
                  style: pw.TextStyle(
                    fontSize: 10.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (certification.issuer.trim().isNotEmpty)
                  pw.TextSpan(
                    text: ' - ${certification.issuer}',
                    style: const pw.TextStyle(fontSize: 10.5),
                  ),
              ],
            ),
          ),
        ),
        if (certification.date.trim().isNotEmpty)
          pw.Text(
            certification.date,
            style: const pw.TextStyle(fontSize: 10),
          ),
      ],
    ),
  );
}

List<pw.Widget> _sections(
  Resume resume,
  PdfColor color, {
  bool lines = true,
  bool skillChips = false,
  bool cv = false,
  PdfColor? chipColor,
}) {
  final experience = resume.experience
      .where(
        (item) => item.company.trim().isNotEmpty || item.role.trim().isNotEmpty,
      )
      .toList();
  final education = resume.education
      .where(
        (item) =>
            item.institution.trim().isNotEmpty || item.degree.trim().isNotEmpty,
      )
      .toList();
  final projects = resume.projects
      .where((item) => item.title.trim().isNotEmpty)
      .toList();
  final certifications = resume.certifications
      .where((certification) => certification.name.trim().isNotEmpty)
      .toList();
  final languages = resume.languages
      .where((language) => language.name.trim().isNotEmpty)
      .toList();
  final experienceBlock = <pw.Widget>[
    if (experience.isNotEmpty) ...[
      _heading('Experience', color, line: lines),
      ...experience.map(_experienceItem),
    ],
  ];
  final educationBlock = <pw.Widget>[
    if (education.isNotEmpty) ...[
      _heading('Education', color, line: lines),
      ...education.map(_educationItem),
    ],
  ];

  pw.Widget skillsBody() {
    if (skillChips) {
      return pw.Wrap(
        spacing: 5,
        runSpacing: 5,
        children: [
          for (final skill in resume.skills)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: pw.BoxDecoration(
                color: chipColor ?? PdfColors.indigo50,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Text(
                skill,
                style: const pw.TextStyle(fontSize: 9.5),
              ),
            ),
        ],
      );
    }
    final grouped = resume.skills.where((skill) => skill.contains(':')).toList();
    final plain = resume.skills.where((skill) => !skill.contains(':')).toList();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (final group in grouped)
          pw.Bullet(
            text: group,
            style: const pw.TextStyle(fontSize: 10.5),
          ),
        if (plain.isNotEmpty)
          grouped.isEmpty
              ? pw.Text(
                  plain.join(', '),
                  style: const pw.TextStyle(fontSize: 10.5),
                )
              : pw.Bullet(
                  text: 'Other: ${plain.join(', ')}',
                  style: const pw.TextStyle(fontSize: 10.5),
                ),
      ],
    );
  }

  return [
    if (resume.summary.trim().isNotEmpty) ...[
      _heading(cv ? 'Career Objective' : 'Summary', color, line: lines),
      pw.Text(resume.summary, style: const pw.TextStyle(fontSize: 10.5)),
    ],
    if (cv) ...educationBlock else ...experienceBlock,
    if (cv) ...experienceBlock else ...educationBlock,
    if (resume.skills.isNotEmpty) ...[
      _heading(cv ? 'Technical Skills' : 'Skills', color, line: lines),
      skillsBody(),
    ],
    if (projects.isNotEmpty) ...[
      _heading('Projects', color, line: lines),
      ...projects.map(_projectItem),
    ],
    if (certifications.isNotEmpty) ...[
      _heading(
        cv ? 'Certifications & Workshops' : 'Certifications',
        color,
        line: lines,
      ),
      if (cv)
        ...certifications.map((certification) {
          final main = [certification.name, certification.issuer]
              .where((value) => value.trim().isNotEmpty)
              .join(' | ');
          final date = certification.date.trim().isEmpty
              ? ''
              : ' (${certification.date})';
          return pw.Bullet(
            text: '$main$date',
            style: const pw.TextStyle(fontSize: 10.5),
          );
        })
      else
        ...certifications.map(_certificationItem),
    ],
    if (languages.isNotEmpty) ...[
      _heading('Languages', color, line: lines),
      pw.Text(
        languages
            .map((language) => '${language.name} (${language.level})')
            .join(cv ? '  •  ' : ', '),
        style: const pw.TextStyle(fontSize: 10.5),
      ),
    ],
  ];
}

void _cv(pw.Document document, Resume resume, PdfColor? accent) {
  final color = accent ?? PdfColors.black;
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
      build: (context) => [
        pw.Center(
          child: pw.Text(
            resume.fullName,
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ),
        if (resume.headline.trim().isNotEmpty)
          pw.Center(
            child: pw.Text(
              resume.headline,
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
        pw.SizedBox(height: 3),
        pw.Center(
          child: pw.Text(
            _contact(resume),
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
        ..._sections(resume, color, cv: true),
      ],
    ),
  );
}

void _classic(pw.Document document, Resume resume, PdfColor? accent) {
  final color = accent ?? PdfColors.black;
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (context) => [
        pw.Center(
          child: pw.Text(
            resume.fullName,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.Text(
            _contact(resume),
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
        ..._sections(resume, color),
      ],
    ),
  );
}

void _modern(pw.Document document, Resume resume, PdfColor? accent) {
  final color = accent ?? PdfColors.indigo700;
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(18),
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                resume.fullName,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                _contact(resume),
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
        ),
        ..._sections(
          resume,
          color,
          skillChips: true,
          chipColor: _tint(color),
        ),
      ],
    ),
  );
}

void _minimal(pw.Document document, Resume resume, PdfColor? accent) {
  final color = accent ?? PdfColors.grey700;
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 44, vertical: 40),
      build: (context) => [
        pw.Text(
          resume.fullName,
          style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          _contact(resume),
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        ..._sections(resume, color, lines: false),
      ],
    ),
  );
}
