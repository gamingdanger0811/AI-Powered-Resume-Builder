import 'package:flutter_test/flutter_test.dart';
import 'package:resume_builder/models/resume.dart';
import 'package:resume_builder/templates/pdf_templates.dart';

void main() {
  test('all templates generate PDF documents', () async {
    final resume = Resume(
      title: 'Sample Resume',
      fullName: 'Taylor Example',
      accentColor: 0xFF0F766E,
      headline: 'Computer Engineering Undergraduate',
      email: 'taylor@example.com',
      phone: '555-0100',
      address: 'Seattle',
      summary: 'Experienced Flutter developer.',
      experience: [
        Experience(
          company: 'Example Co',
          role: 'Developer',
          startDate: '2022',
          endDate: 'Present',
          bullets: ['Built a mobile application.'],
        ),
      ],
      education: [
        Education(
          institution: 'Example University',
          degree: 'BS Computer Science',
          semester: '7th',
          startDate: '2018',
          endDate: '2022',
        ),
      ],
      skills: ['Dart', 'Flutter'],
      projects: [
        Project(
          title: 'Portfolio',
          techStack: 'Flutter, Firebase',
          bullets: ['Built a responsive portfolio site.'],
          link: 'https://example.com',
        ),
      ],
      languages: [Language(name: 'English', level: 'Fluent')],
      certifications: [
        Certification(name: 'Cloud Practitioner', issuer: 'Example Cloud'),
      ],
    );

    for (final templateId in templateNames.keys) {
      final bytes = await buildResumePdf(resume, templateId);

      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    }
  });

  test('unknown template falls back to classic', () async {
    final bytes = await buildResumePdf(
      Resume(fullName: 'Taylor Example'),
      'old',
    );

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
