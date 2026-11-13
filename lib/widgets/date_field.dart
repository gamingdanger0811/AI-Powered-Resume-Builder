import 'package:flutter/material.dart';

class DateField extends StatefulWidget {
  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final bool allowPresent;
  final bool yearOnly;

  const DateField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.allowPresent = false,
    this.yearOnly = false,
  });

  @override
  State<DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<DateField> {
  late final TextEditingController _c =
      TextEditingController(text: widget.initialValue);

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _set(String value) {
    setState(() => _c.text = value);
    widget.onChanged(value);
  }

  Future<void> _pick() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1970),
      lastDate: DateTime(now.year + 10),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked == null) return;
    _set(
      widget.yearOnly
          ? '${picked.year}'
          : '${_months[picked.month - 1]} ${picked.year}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _c,
        readOnly: true,
        onTap: _pick,
        decoration: InputDecoration(
          labelText: widget.label,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.allowPresent)
                TextButton(
                  onPressed: () => _set('Present'),
                  child: const Text('Present'),
                ),
              IconButton(
                icon: const Icon(Icons.calendar_month_outlined),
                onPressed: _pick,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
