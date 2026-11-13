import 'package:cloud_firestore/cloud_firestore.dart';

class Experience {
  Experience({
    this.company = '',
    this.role = '',
    this.startDate = '',
    this.endDate = '',
    List<String>? bullets,
  }) : bullets = bullets ?? [];

  String company;
  String role;
  String startDate;
  String endDate;
  List<String> bullets;

  Map<String, dynamic> toMap() => {
    'company': company,
    'role': role,
    'startDate': startDate,
    'endDate': endDate,
    'bullets': bullets,
  };

  factory Experience.fromMap(Map<String, dynamic> map) => Experience(
    company: map['company'] as String? ?? '',
    role: map['role'] as String? ?? '',
    startDate: map['startDate'] as String? ?? '',
    endDate: map['endDate'] as String? ?? '',
    bullets: List<String>.from(map['bullets'] as List? ?? const []),
  );
}

class Education {
  Education({
    this.institution = '',
    this.degree = '',
    this.semester = '',
    this.startDate = '',
    this.endDate = '',
  });

  String institution;
  String degree;
  String semester;
  String startDate;
  String endDate;

  Map<String, dynamic> toMap() => {
    'institution': institution,
    'degree': degree,
    'semester': semester,
    'startDate': startDate,
    'endDate': endDate,
  };

  factory Education.fromMap(Map<String, dynamic> map) => Education(
    institution: map['institution'] as String? ?? '',
    degree: map['degree'] as String? ?? '',
    semester: map['semester'] as String? ?? '',
    startDate: map['startDate'] as String? ?? '',
    endDate: map['endDate'] as String? ?? '',
  );
}

class Project {
  Project({
    this.title = '',
    this.techStack = '',
    this.description = '',
    List<String>? bullets,
    this.link = '',
  }) : bullets = bullets ?? [];

  String title;
  String techStack;
  String description;
  List<String> bullets;
  String link;

  Map<String, dynamic> toMap() => {
    'title': title,
    'techStack': techStack,
    'description': description,
    'bullets': bullets,
    'link': link,
  };

  factory Project.fromMap(Map<String, dynamic> map) => Project(
    title: map['title'] as String? ?? '',
    techStack: map['techStack'] as String? ?? '',
    description: map['description'] as String? ?? '',
    bullets: List<String>.from(map['bullets'] as List? ?? const []),
    link: map['link'] as String? ?? '',
  );
}

const languageLevels = ['Native', 'Fluent', 'Professional working'];

String normalizeLanguageLevel(String raw) {
  final level = raw.toLowerCase();
  if (level.trim().isEmpty) return 'Fluent';
  if (level.contains('native') ||
      level.contains('bilingual') ||
      level.contains('mother')) {
    return 'Native';
  }
  if (level.contains('fluent') ||
      level.contains('full professional') ||
      level.contains('advanced')) {
    return 'Fluent';
  }
  return 'Professional working';
}

class Language {
  Language({this.name = '', this.level = 'Fluent'});

  String name;
  String level;

  Map<String, dynamic> toMap() => {'name': name, 'level': level};

  factory Language.fromMap(Map<String, dynamic> map) => Language(
    name: map['name'] as String? ?? '',
    level: normalizeLanguageLevel(map['level'] as String? ?? ''),
  );
}

class Certification {
  Certification({this.name = '', this.issuer = '', this.date = ''});

  String name;
  String issuer;
  String date;

  Map<String, dynamic> toMap() => {
    'name': name,
    'issuer': issuer,
    'date': date,
  };

  factory Certification.fromMap(Map<String, dynamic> map) => Certification(
    name: map['name'] as String? ?? '',
    issuer: map['issuer'] as String? ?? '',
    date: map['date'] as String? ?? '',
  );
}

class Resume {
  Resume({
    this.id = '',
    this.title = 'Untitled Resume',
    this.fullName = '',
    this.headline = '',
    this.email = '',
    this.phone = '',
    this.address = '',
    this.city = '',
    this.country = '',
    this.summary = '',
    List<Experience>? experience,
    List<Education>? education,
    List<String>? skills,
    List<Project>? projects,
    List<Language>? languages,
    List<Certification>? certifications,
    this.templateId = 'cv',
    this.accentColor = 0,
    this.updatedAt,
  }) : experience = experience ?? [],
       education = education ?? [],
       skills = skills ?? [],
       projects = projects ?? [],
       languages = languages ?? [],
       certifications = certifications ?? [];

  String id;
  String title;
  String fullName;
  String headline;
  String email;
  String phone;
  String address;
  String city;
  String country;
  String summary;
  List<Experience> experience;
  List<Education> education;
  List<String> skills;
  List<Project> projects;
  List<Language> languages;
  List<Certification> certifications;
  String templateId;
  int accentColor;
  DateTime? updatedAt;

  Map<String, dynamic> toMap() => {
    'title': title,
    'fullName': fullName,
    'headline': headline,
    'email': email,
    'phone': phone,
    'address': address,
    'city': city,
    'country': country,
    'summary': summary,
    'experience': experience.map((item) => item.toMap()).toList(),
    'education': education.map((item) => item.toMap()).toList(),
    'skills': skills,
    'projects': projects.map((item) => item.toMap()).toList(),
    'languages': languages.map((language) => language.toMap()).toList(),
    'certifications': certifications
        .map((certification) => certification.toMap())
        .toList(),
    'templateId': templateId,
    'accentColor': accentColor,
  };

  factory Resume.fromMap(String id, Map<String, dynamic> map) => Resume(
    id: id,
    title: map['title'] as String? ?? 'Untitled Resume',
    fullName: map['fullName'] as String? ?? '',
    headline: map['headline'] as String? ?? '',
    email: map['email'] as String? ?? '',
    phone: map['phone'] as String? ?? '',
    address: map['address'] as String? ?? '',
    city: map['city'] as String? ?? '',
    country: map['country'] as String? ?? '',
    summary: map['summary'] as String? ?? '',
    experience: (map['experience'] as List? ?? const [])
        .map(
          (item) => Experience.fromMap(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
    education: (map['education'] as List? ?? const [])
        .map(
          (item) => Education.fromMap(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
    skills: List<String>.from(map['skills'] as List? ?? const []),
    projects: (map['projects'] as List? ?? const [])
        .map((item) => Project.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList(),
    languages: (map['languages'] as List? ?? const [])
        .map((item) => Language.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList(),
    certifications: (map['certifications'] as List? ?? const [])
        .map(
          (item) =>
              Certification.fromMap(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
    templateId: map['templateId'] as String? ?? 'classic',
    accentColor: (map['accentColor'] as num?)?.toInt() ?? 0,
    updatedAt: switch (map['updatedAt']) {
      Timestamp timestamp => timestamp.toDate(),
      DateTime dateTime => dateTime,
      _ => null,
    },
  );
}
