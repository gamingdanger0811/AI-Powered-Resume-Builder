import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';

class AiService {
  AiService({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  Future<String> _chat(String system, String user) async {
    final response = await _functions
        .httpsCallable('generateContent')
        .call<Map<String, dynamic>>({'system': system, 'user': user});
    final text = response.data['text'];
    if (text is! String || text.trim().isEmpty) {
      throw StateError('AI returned an empty response.');
    }
    return text.trim();
  }

  Future<String> generateSummary({
    required String fullName,
    required String targetRole,
    required List<String> skills,
    required List<String> experience,
  }) {
    return _chat(
      'You are an expert resume writer. Write in first-person-implied style '
          '(no "I"), 3-4 concise sentences, ATS-friendly, no clichés, '
          'no placeholders. Return only the summary text.',
      'Name: $fullName\n'
          'Target role: $targetRole\n'
          'Skills: ${skills.join(', ')}\n'
          'Experience: ${experience.join('; ')}\n'
          'Write a professional resume summary.',
    );
  }

  Future<List<String>> improveBullets(List<String> bullets, String role) async {
    final text = await _chat(
      'You are an expert resume writer. Rewrite each bullet to start with a '
          'strong action verb and highlight impact. Keep each under 25 words. '
          'Do not invent numbers or facts. Return one bullet per line, '
          'no numbering, no dashes.',
      'Role: $role\nBullets:\n${bullets.join('\n')}',
    );
    return text
        .split('\n')
        .map((line) => line.replaceFirst(RegExp(r'^[-•*\d.\s]+'), '').trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  Future<List<String>> suggestSkills(String role) async {
    final text = await _chat(
      'You are a career advisor. Return 10 relevant resume skills/keywords '
          'for the given job role as a single comma-separated line. '
          'Nothing else.',
      'Job role: $role',
    );
    return text
        .split(',')
        .map((skill) => skill.trim())
        .where((skill) => skill.isNotEmpty)
        .toList();
  }

  Future<Map<String, dynamic>> parseProfile({
    String? text,
    Uint8List? pdfBytes,
  }) async {
    if (pdfBytes != null && pdfBytes.length > 4 * 1024 * 1024) {
      throw ArgumentError('PDF is too large (max 4 MB).');
    }
    final profileText = text?.trim() ?? '';
    if (pdfBytes == null && profileText.isEmpty) {
      throw ArgumentError('Provide profile text or a PDF to import.');
    }

    const system =
        'You extract resume data from a LinkedIn profile or CV. '
        'Return ONLY valid JSON with exactly these keys: '
        'fullName, headline (the short tagline under the name, or empty), '
        'email, phone, city, country, summary, '
        'experience (list of {company, role, startDate, endDate, bullets (list of strings)}), '
        'education (list of {institution, degree, semester, startDate, endDate}) '
        'where semester is e.g. "7th" or empty, and endDate is the graduation year, '
        'skills (list of strings; if the source groups skills by category, return '
        'each group as ONE string like "Programming Languages: C++, Python, SQL"), '
        'projects (list of {title, techStack, bullets (list of strings), link}), '
        'certifications (list of {name, issuer, date}), '
        'languages (list of {name, level}) where level is exactly one of: '
        'Native, Fluent, Professional working. '
        'Use an empty string or empty list when something is missing. '
        'Never invent information. Dates as short text like "Jan 2023" or "Present".';

    final response = await _functions
        .httpsCallable('generateContent')
        .call<Map<String, dynamic>>({
          'system': system,
          'user': profileText.isNotEmpty
              ? 'Profile text:\n$profileText'
              : 'Extract the resume data from the attached profile PDF.',
          'profileImport': true,
          if (pdfBytes != null) 'pdfBase64': base64Encode(pdfBytes),
        });
    final responseText = response.data['text'];
    if (responseText is! String || responseText.trim().isEmpty) {
      throw StateError('AI returned an empty response.');
    }
    var raw = responseText.trim();
    raw = raw
        .replaceAll(RegExp(r'^```(?:json)?\s*|\s*```$', multiLine: true), '')
        .trim();
    if (raw.isEmpty) {
      throw StateError('AI returned an empty response.');
    }

    final decoded = _normalize(jsonDecode(raw));
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Could not read the profile data.');
    }
    return decoded;
  }

  dynamic _normalize(dynamic value) {
    if (value is Map) {
      final normalized = <String, dynamic>{};
      value.forEach((key, item) {
        if (item != null) normalized[key.toString()] = _normalize(item);
      });
      return normalized;
    }
    if (value is List) {
      return value.where((item) => item != null).map(_normalize).toList();
    }
    if (value is num) return value.toString();
    return value;
  }
}
