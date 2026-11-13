import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resume_builder/models/resume.dart';

void main() {
  test('resume serializes and restores nested data', () {
    final updatedAt = DateTime(2026, 10, 4);
    final resume = Resume(
      id: 'resume-1',
      title: 'Flutter Developer Resume',
      fullName: 'Ayesha Khan',
      headline: 'Computer Engineering Undergraduate',
      email: 'ayesha@example.com',
      phone: '+1 555 0100',
      address: 'Seattle',
      city: 'Seattle',
      country: 'United States',
      summary: 'Flutter developer',
      experience: [
        Experience(
          company: 'Example Co',
          role: 'Developer',
          startDate: 'Jan 2024',
          endDate: 'Present',
          bullets: ['Built Flutter apps'],
        ),
      ],
      education: [
        Education(
          institution: 'Example University',
          degree: 'BS Computer Science',
          semester: '7th',
          startDate: '2020',
          endDate: '2024',
        ),
      ],
      skills: ['Dart', 'Flutter'],
      projects: [
        Project(
          title: 'Portfolio',
          techStack: 'Flutter, Firebase',
          bullets: ['Built a responsive portfolio'],
          link: 'https://example.com',
        ),
      ],
      languages: [Language(name: 'English', level: 'Native')],
      certifications: [
        Certification(
          name: 'Cloud Practitioner',
          issuer: 'Example Cloud',
          date: 'Sep 2026',
        ),
      ],
      templateId: 'modern',
      accentColor: 0xFF2563EB,
      updatedAt: updatedAt,
    );

    final restored = Resume.fromMap('resume-1', {
      ...resume.toMap(),
      'updatedAt': Timestamp.fromDate(updatedAt),
    });

    expect(restored.id, resume.id);
    expect(restored.title, resume.title);
    expect(restored.fullName, resume.fullName);
    expect(restored.headline, resume.headline);
    expect(restored.email, resume.email);
    expect(restored.phone, resume.phone);
    expect(restored.address, resume.address);
    expect(restored.city, resume.city);
    expect(restored.country, resume.country);
    expect(restored.summary, resume.summary);
    expect(
      restored.experience.single.toMap(),
      resume.experience.single.toMap(),
    );
    expect(restored.education.single.toMap(), resume.education.single.toMap());
    expect(restored.skills, resume.skills);
    expect(restored.projects.single.toMap(), resume.projects.single.toMap());
    expect(restored.languages.single.toMap(), resume.languages.single.toMap());
    expect(
      restored.certifications.single.toMap(),
      resume.certifications.single.toMap(),
    );
    expect(restored.templateId, resume.templateId);
    expect(restored.accentColor, resume.accentColor);
    expect(restored.updatedAt, updatedAt);
  });

  test('resume uses defaults for absent optional fields', () {
    final resume = Resume.fromMap('resume-2', const {});

    expect(resume.id, 'resume-2');
    expect(resume.title, 'Untitled Resume');
    expect(resume.templateId, 'classic');
    expect(resume.accentColor, 0);
    expect(resume.headline, isEmpty);
    expect(resume.experience, isEmpty);
    expect(resume.education, isEmpty);
    expect(resume.skills, isEmpty);
    expect(resume.projects, isEmpty);
    expect(resume.city, isEmpty);
    expect(resume.country, isEmpty);
    expect(resume.languages, isEmpty);
    expect(resume.certifications, isEmpty);
    expect(resume.updatedAt, isNull);
  });

  test('restores education and projects saved before added fields', () {
    final education = Education.fromMap({
      'institution': 'Example University',
      'degree': 'BS Computer Science',
    });
    final project = Project.fromMap({
      'title': 'Legacy project',
      'description': 'Existing project description',
    });

    expect(education.semester, isEmpty);
    expect(project.techStack, isEmpty);
    expect(project.bullets, isEmpty);
    expect(project.description, 'Existing project description');
  });

  test('normalizes imported language proficiency levels', () {
    expect(normalizeLanguageLevel('Native or bilingual proficiency'), 'Native');
    expect(normalizeLanguageLevel('Full professional proficiency'), 'Fluent');
    expect(
      normalizeLanguageLevel('Elementary proficiency'),
      'Professional working',
    );
    expect(normalizeLanguageLevel(''), 'Fluent');
  });
}
