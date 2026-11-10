import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/services/church_auth_service.dart';
import '../../../core/theme/app_colors.dart';

/// "Tuma Tukio / Omba Poster".
///
/// Leaders, ushers, choir and jumuiya workers log structured event details
/// straight into Cloud Firestore `events`. The leadership portal's Poster Desk
/// (Studio ya Poster & Matukio) picks them up live, and the Super Admin turns
/// one into an HD poster. This is the member-app half of the same workflow —
/// the portal and the app write to the exact same collection.
class EventRequestScreen extends StatefulWidget {
  const EventRequestScreen({super.key});

  @override
  State<EventRequestScreen> createState() => _EventRequestScreenState();
}

class _EventRequestScreenState extends State<EventRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _venueController = TextEditingController();
  final _verseController = TextEditingController();

  String _category = 'Ibada';
  bool _needsPoster = true;
  bool _saving = false;
  bool _lastSucceeded = false;
  String? _feedback;

  static const List<String> _categories = [
    'Ibada',
    'Mkesha',
    'Semina',
    'Kwaya',
    'Jumuiya',
    'Taarifa Kuu',
    'Ujenzi',
    'Msiba',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _venueController.dispose();
    _verseController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = ChurchAuthService();
    if (auth.uid == null) {
      setState(() {
        _lastSucceeded = false;
        _feedback =
            'Ingia kwanza kwa akaunti halisi ya kanisa ili kutuma tukio kwenye wingu.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _feedback = null;
    });

    try {
      await FirebaseFirestore.instance.collection('events').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _category,
        'eventDate': _dateController.text.trim(),
        'eventTime': _timeController.text.trim(),
        'venue': _venueController.text.trim(),
        'themeVerse': _verseController.text.trim(),
        'branch': 'Mbagala Kwa Matope (HQ)',
        'needsPoster': _needsPoster,
        'posterStatus': _needsPoster ? 'requested' : 'none',
        'requestedBy': auth.name,
        'requestedByRole': auth.roleTitle,
        'requestedByEmail': auth.email,
        'createdBy': auth.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _titleController.clear();
      _descriptionController.clear();
      _dateController.clear();
      _timeController.clear();
      _venueController.clear();
      _verseController.clear();
      setState(() {
        _saving = false;
        _lastSucceeded = true;
        _feedback =
            '✓ Tukio limehifadhiwa kwenye Cloud Firestore. Super Admin atakiona mara moja kwenye Studio ya Poster & Matukio, hata akiwa kwenye kompyuta nyingine.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _lastSucceeded = false;
        _feedback = 'Imeshindikana kutuma tukio: $e';
      });
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    bool required = false,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (value) => (value == null || value.trim().isEmpty)
                ? 'Sehemu hii inahitajika'
                : null
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tuma Tukio / Omba Poster'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Viongozi, wakaribishaji (ushers), kwaya na jumuiya: andika maelezo ya tukio hapa. Yanaenda moja kwa moja kwenye mfumo wa kanisa; Super Admin atatengeneza poster na kuituma.',
                style: TextStyle(fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 16),
              _field(_titleController, 'Kichwa cha Tukio *',
                  required: true, hint: 'mf. Mkesha wa Maombi ya Ijumaa'),
              _field(_descriptionController, 'Maelezo / Ujumbe wa Poster *',
                  required: true, maxLines: 4),
              _field(_dateController, 'Tarehe', hint: 'Jumapili, 15 Novemba 2026'),
              _field(_timeController, 'Saa', hint: '08:30 – 13:00'),
              _field(_venueController, 'Mahali', hint: 'Hekalu Kuu, Mbagala'),
              _field(_verseController, 'Mstari wa Biblia', hint: 'Zaburi 122:1'),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(
                    labelText: 'Kategoria',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _category = value ?? 'Ibada'),
                ),
              ),
              SwitchListTile(
                value: _needsPoster,
                onChanged: (value) => setState(() => _needsPoster = value),
                title: const Text('Omba poster ya tukio hili'),
                subtitle: const Text(
                    'Itaonekana kwenye folio ya Super Admin kama "Inasubiri Poster".'),
                contentPadding: EdgeInsets.zero,
              ),
              if (_feedback != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _lastSucceeded
                        ? AppColors.success.withOpacity(0.12)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _lastSucceeded ? AppColors.success : Colors.red,
                    ),
                  ),
                  child: Text(
                    _feedback!,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: _lastSucceeded ? AppColors.success : Colors.red,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(_saving ? 'Inatuma...' : 'Tuma Tukio kwenye Mfumo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
