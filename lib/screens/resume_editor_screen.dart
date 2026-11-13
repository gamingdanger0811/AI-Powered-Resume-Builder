import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/resume.dart';
import '../services/ai_service.dart';
import '../services/resume_service.dart';
import '../widgets/date_field.dart';

class ResumeEditorScreen extends StatefulWidget {
  const ResumeEditorScreen({super.key, this.resume});

  final Resume? resume;

  @override
  State<ResumeEditorScreen> createState() => _ResumeEditorScreenState();
}

class _ResumeEditorScreenState extends State<ResumeEditorScreen> {
  static const _commonLanguages = [
    'English',
    'Urdu',
    'Pashto',
    'Hindko',
    'Punjabi',
    'Hindi',
    'Arabic',
    'Persian',
    'Sindhi',
    'Balochi',
    'Turkish',
    'French',
    'German',
    'Spanish',
    'Chinese',
    'Japanese',
  ];

  late final Resume _resume;
  late final TextEditingController _title;
  late final TextEditingController _name;
  late final TextEditingController _headline;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _country;
  late final TextEditingController _summary;
  late final TextEditingController _skills;
  final TextEditingController _targetRole = TextEditingController();

  int _step = 0;
  bool _saving = false;
  bool _aiBusy = false;
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _resume =
        widget.resume ??
        Resume(fullName: user?.displayName ?? '', email: user?.email ?? '');
    _title = TextEditingController(text: _resume.title);
    _name = TextEditingController(text: _resume.fullName);
    _headline = TextEditingController(text: _resume.headline);
    _email = TextEditingController(text: _resume.email);
    _phone = TextEditingController(text: _resume.phone);
    _address = TextEditingController(text: _resume.address);
    _city = TextEditingController(text: _resume.city);
    _country = TextEditingController(text: _resume.country);
    _summary = TextEditingController(text: _resume.summary);
    _skills = TextEditingController(text: _resume.skills.join('\n'));
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _name,
      _headline,
      _email,
      _phone,
      _address,
      _city,
      _country,
      _summary,
      _skills,
    ]) {
      controller.dispose();
    }
    _targetRole.dispose();
    super.dispose();
  }

  Future<void> _addCustomLanguage() async {
    final controller = TextEditingController();
    String? name;
    try {
      name = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Add language'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Language name'),
            onSubmitted: (value) => Navigator.pop(dialogContext, value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: const Text('Add'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }

    final normalizedName = name?.trim() ?? '';
    if (!mounted || normalizedName.isEmpty) return;
    final exists = _resume.languages.any(
      (language) =>
          language.name.trim().toLowerCase() == normalizedName.toLowerCase(),
    );
    if (exists) return;
    setState(() => _resume.languages.add(Language(name: normalizedName)));
  }

  List<String> _skillList() => _skills.text
      .split('\n')
      .map((skill) => skill.trim())
      .where((skill) => skill.isNotEmpty)
      .toList();

  Future<void> _runAi(Future<void> Function() task) async {
    if (_aiBusy) return;
    setState(() => _aiBusy = true);
    try {
      await task();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('AI error: $error')));
      }
    } finally {
      if (mounted) setState(() => _aiBusy = false);
    }
  }

  Widget _aiButton(String label, VoidCallback onPressed) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FilledButton.tonalIcon(
        onPressed: _aiBusy ? null : onPressed,
        icon: _aiBusy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.auto_awesome),
        label: Text(label),
      ),
    );
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _step = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name')),
      );
      return;
    }
    if (_saving) return;
    _resume
      ..title = _title.text.trim().isEmpty
          ? 'Untitled Resume'
          : _title.text.trim()
      ..fullName = _name.text.trim()
      ..headline = _headline.text.trim()
      ..email = _email.text.trim()
      ..phone = _phone.text.trim()
      ..address = _address.text.trim()
      ..city = _city.text.trim()
      ..country = _country.text.trim()
      ..summary = _summary.text.trim()
      ..skills = _skillList();
    _resume.certifications.removeWhere(
      (certification) => certification.name.trim().isEmpty,
    );
    _resume.languages.removeWhere((language) => language.name.trim().isEmpty);

    setState(() => _saving = true);
    try {
      await ResumeService().saveResume(_resume);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Resume saved')));
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not save: $error')));
    }
  }

  Widget _field(
    String label, {
    TextEditingController? controller,
    String? initialValue,
    ValueChanged<String>? onChanged,
    int maxLines = 1,
    String? hint,
    TextInputType? keyboardType,
    Key? fieldKey,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        key: fieldKey,
        controller: controller,
        initialValue: controller == null ? initialValue : null,
        onChanged: onChanged,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _personalStep() => Column(
    children: [
      _field(
        'Resume title',
        controller: _title,
        hint: 'e.g. Flutter Developer Resume',
      ),
      _field('Full name', controller: _name),
      _field(
        'Headline (optional)',
        controller: _headline,
        hint: 'e.g. Computer Engineering Undergraduate | Seeking Internships',
      ),
      _field(
        'Email',
        controller: _email,
        keyboardType: TextInputType.emailAddress,
      ),
      _field('Phone', controller: _phone, keyboardType: TextInputType.phone),
      Row(
        children: [
          Expanded(child: _field('City', controller: _city)),
          const SizedBox(width: 8),
          Expanded(child: _field('Country', controller: _country)),
        ],
      ),
    ],
  );

  Widget _summaryStep() => Column(
    children: [
      _field(
        'Target job role',
        controller: _targetRole,
        hint: 'e.g. Flutter Developer',
      ),
      _field(
        'Professional summary',
        controller: _summary,
        maxLines: 5,
        hint: 'Write your own or generate with AI',
      ),
      _aiButton('Generate with AI', () {
        if (_targetRole.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enter a target job role first')),
          );
          return;
        }
        _runAi(() async {
          final text = await AiService().generateSummary(
            fullName: _name.text,
            targetRole: _targetRole.text.trim(),
            skills: _skillList(),
            experience: _resume.experience
                .where((entry) => entry.role.trim().isNotEmpty)
                .map((entry) => '${entry.role} at ${entry.company}')
                .toList(),
          );
          if (mounted) {
            setState(() {
              _summary.text = text;
              _resume.summary = text;
            });
          }
        });
      }),
    ],
  );

  Widget _experienceStep() => Column(
    children: [
      for (final experience in _resume.experience)
        Card(
          key: ObjectKey(experience),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _field(
                  'Company',
                  initialValue: experience.company,
                  onChanged: (value) => experience.company = value,
                ),
                _field(
                  'Role',
                  initialValue: experience.role,
                  onChanged: (value) => experience.role = value,
                ),
                Row(
                  children: [
                    Expanded(
                      child: DateField(
                        label: 'Start date',
                        initialValue: experience.startDate,
                        onChanged: (value) => experience.startDate = value,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DateField(
                        label: 'End date',
                        initialValue: experience.endDate,
                        allowPresent: true,
                        onChanged: (value) => experience.endDate = value,
                      ),
                    ),
                  ],
                ),
                _field(
                  'Achievements (one per line)',
                  fieldKey: ValueKey(
                    'bullets-${experience.hashCode}-$_revision',
                  ),
                  initialValue: experience.bullets.join('\n'),
                  maxLines: 4,
                  onChanged: (value) => experience.bullets = value
                      .split('\n')
                      .where((line) => line.trim().isNotEmpty)
                      .toList(),
                ),
                _aiButton('Improve with AI', () {
                  if (experience.bullets.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Write at least one achievement first'),
                      ),
                    );
                    return;
                  }
                  _runAi(() async {
                    final improved = await AiService().improveBullets(
                      experience.bullets,
                      experience.role,
                    );
                    if (mounted) {
                      setState(() {
                        experience.bullets = improved;
                        _revision++;
                      });
                    }
                  });
                }),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () =>
                        setState(() => _resume.experience.remove(experience)),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove'),
                  ),
                ),
              ],
            ),
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: () => setState(() => _resume.experience.add(Experience())),
          icon: const Icon(Icons.add),
          label: const Text('Add experience'),
        ),
      ),
    ],
  );

  Widget _educationStep() => Column(
    children: [
      for (final education in _resume.education)
        Card(
          key: ObjectKey(education),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _field(
                  'Degree',
                  initialValue: education.degree,
                  hint: 'e.g. BS Computer Engineering',
                  onChanged: (value) => education.degree = value,
                ),
                _field(
                  'Institution',
                  initialValue: education.institution,
                  onChanged: (value) => education.institution = value,
                ),
                _field(
                  'Current semester (optional)',
                  initialValue: education.semester,
                  hint: 'e.g. 7th',
                  onChanged: (value) => education.semester = value,
                ),
                Row(
                  children: [
                    Expanded(
                      child: DateField(
                        label: 'Start year',
                        initialValue: education.startDate,
                        yearOnly: true,
                        onChanged: (value) => education.startDate = value,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DateField(
                        label: 'End / expected year',
                        initialValue: education.endDate,
                        yearOnly: true,
                        onChanged: (value) => education.endDate = value,
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () =>
                        setState(() => _resume.education.remove(education)),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove'),
                  ),
                ),
              ],
            ),
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: () => setState(() => _resume.education.add(Education())),
          icon: const Icon(Icons.add),
          label: const Text('Add education'),
        ),
      ),
    ],
  );

  Widget _skillsStep() => Column(
    children: [
      _field(
        'Skills',
        controller: _skills,
        maxLines: 6,
        hint: 'One per line. You can group them:\n'
            'Programming Languages: C++, Python, SQL\n'
            'Tools: Git, GitHub, VS Code',
      ),
      _aiButton('Suggest skills for target role', () {
        final role = _targetRole.text.trim();
        if (role.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Enter a target job role in the Summary step'),
            ),
          );
          return;
        }
        _runAi(() async {
          final suggested = await AiService().suggestSkills(role);
          final current = _skillList();
          final lower = current.map((skill) => skill.toLowerCase()).toList();
          for (final skill in suggested) {
            if (!lower.contains(skill.toLowerCase())) current.add(skill);
          }
          if (mounted) setState(() => _skills.text = current.join('\n'));
        });
      }),
    ],
  );

  Widget _projectsStep() => Column(
    children: [
      for (final project in _resume.projects)
        Card(
          key: ObjectKey(project),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _field(
                  'Project title',
                  initialValue: project.title,
                  onChanged: (value) => project.title = value,
                ),
                _field(
                  'Tech stack',
                  initialValue: project.techStack,
                  hint: 'e.g. Python, OpenCV, ML, Web',
                  onChanged: (value) => project.techStack = value,
                ),
                _field(
                  'Key points (one per line)',
                  initialValue: project.bullets.isNotEmpty
                      ? project.bullets.join('\n')
                      : project.description,
                  maxLines: 4,
                  onChanged: (value) {
                    project.bullets = value
                        .split('\n')
                        .where((line) => line.trim().isNotEmpty)
                        .toList();
                    project.description = '';
                  },
                ),
                _field(
                  'Link (optional)',
                  initialValue: project.link,
                  onChanged: (value) => project.link = value,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () =>
                        setState(() => _resume.projects.remove(project)),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove'),
                  ),
                ),
              ],
            ),
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: () => setState(() => _resume.projects.add(Project())),
          icon: const Icon(Icons.add),
          label: const Text('Add project'),
        ),
      ),
    ],
  );

  Widget _certificationsStep() => Column(
    children: [
      const Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Optional. Skip this step if you have no certifications.',
          ),
        ),
      ),
      for (final certification in _resume.certifications)
        Card(
          key: ObjectKey(certification),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _field(
                  'Certification name',
                  initialValue: certification.name,
                  onChanged: (value) => certification.name = value,
                ),
                _field(
                  'Issuing organization',
                  initialValue: certification.issuer,
                  onChanged: (value) => certification.issuer = value,
                ),
                DateField(
                  label: 'Date issued',
                  initialValue: certification.date,
                  onChanged: (value) => certification.date = value,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(
                      () => _resume.certifications.remove(certification),
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove'),
                  ),
                ),
              ],
            ),
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: () =>
              setState(() => _resume.certifications.add(Certification())),
          icon: const Icon(Icons.add),
          label: const Text('Add certification'),
        ),
      ),
    ],
  );

  Widget _languagesStep() {
    final added = _resume.languages
        .map((language) => language.name.trim().toLowerCase())
        .toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Tap the languages you know, then choose your level for each.',
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final name in _commonLanguages)
              FilterChip(
                label: Text(name),
                selected: added.contains(name.toLowerCase()),
                onSelected: (selected) => setState(() {
                  if (selected) {
                    _resume.languages.add(Language(name: name));
                  } else {
                    _resume.languages.removeWhere(
                      (language) =>
                          language.name.trim().toLowerCase() ==
                          name.toLowerCase(),
                    );
                  }
                }),
              ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: const Text('Other'),
              onPressed: _addCustomLanguage,
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (final language in _resume.languages)
          Card(
            key: ObjectKey(language),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        language.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Remove',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            setState(() => _resume.languages.remove(language)),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final level in languageLevels)
                        ChoiceChip(
                          label: Text(level),
                          selected: language.level == level,
                          onSelected: (_) =>
                              setState(() => language.level = level),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      'Personal Info',
      'Summary',
      'Experience',
      'Education',
      'Skills',
      'Projects',
      'Certifications (optional)',
      'Languages',
    ];
    final contents = [
      _personalStep(),
      _summaryStep(),
      _experienceStep(),
      _educationStep(),
      _skillsStep(),
      _projectsStep(),
      _certificationsStep(),
      _languagesStep(),
    ];
    final lastStep = titles.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.resume == null ? 'New Resume' : 'Edit Resume'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Stepper(
        currentStep: _step,
        onStepTapped: (step) => setState(() => _step = step),
        onStepContinue: () {
          if (_step < lastStep) {
            setState(() => _step++);
          } else {
            _save();
          }
        },
        onStepCancel: () {
          if (_step > 0) setState(() => _step--);
        },
        controlsBuilder: (context, details) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              ElevatedButton(
                onPressed: _saving ? null : details.onStepContinue,
                child: Text(_step == lastStep ? 'Save resume' : 'Next'),
              ),
              const SizedBox(width: 8),
              if (_step > 0)
                TextButton(
                  onPressed: details.onStepCancel,
                  child: const Text('Back'),
                ),
            ],
          ),
        ),
        steps: [
          for (var index = 0; index < titles.length; index++)
            Step(
              title: Text(titles[index]),
              isActive: _step >= index,
              state: _step > index ? StepState.complete : StepState.indexed,
              content: contents[index],
            ),
        ],
      ),
    );
  }
}
