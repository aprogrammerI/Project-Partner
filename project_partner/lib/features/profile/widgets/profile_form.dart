import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/universities_api_service.dart';
import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../models/user_model.dart';
import '../../../services/providers.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/user_avatar.dart';

/// Shared form used by both ProfileSetupScreen and ProfileEditScreen.
///
/// Calls [DataService.updateProfile] on submit. The caller decides what
/// happens after success via [onSaved] (typically a Navigator.pop or a no-op
/// — the auth state listener at the app root handles the global transition
/// out of setup mode automatically).
class ProfileForm extends ConsumerStatefulWidget {
  const ProfileForm({
    super.key,
    required this.initial,
    required this.submitLabel,
    this.onSaved,
  });

  final User initial;
  final String submitLabel;
  final VoidCallback? onSaved;

  @override
  ConsumerState<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _bio;
  late final TextEditingController _skillInput;
  late String _faculty;
  late String _lookingFor;
  late List<String> _skills;
  late String _photoUrl;
  bool _saving = false;
  List<String> _faculties = faculties; // fallback

  @override
  void initState() {
    super.initState();
    final u = widget.initial;
    _name = TextEditingController(text: u.name);
    _age = TextEditingController(text: u.age == 0 ? '' : u.age.toString());
    _bio = TextEditingController(text: u.bio);
    _skillInput = TextEditingController();
    _faculty = _faculties.contains(u.faculty) ? u.faculty : _faculties.first;
    _lookingFor = lookingForOptions.keys.contains(u.lookingFor)
        ? u.lookingFor
        : lookingForOptions.keys.first;
    _skills = List<String>.from(u.skills);
    _photoUrl = u.photoUrl;
    UniversityService().fetchFaculties().then((list) {
      if (mounted) setState(() {
        _faculties = list;
        _faculty = list.contains(widget.initial.faculty)
            ? widget.initial.faculty
            : list.first;
      });
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _bio.dispose();
    _skillInput.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;
    if (!mounted) return;
    final svc = ref.read(dataServiceProvider);
    final url = kIsWeb
        ? picked.path
        : await svc.uploadProfilePhoto(File(picked.path));
    if (!mounted) return;
    setState(() => _photoUrl = url);
  }

  void _addSkill() {
    final raw = _skillInput.text.trim();
    if (raw.isEmpty) return;
    if (_skills.length >= 8) return;
    if (_skills.any((s) => s.toLowerCase() == raw.toLowerCase())) {
      _skillInput.clear();
      return;
    }
    setState(() {
      _skills.add(raw);
      _skillInput.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_skills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one skill.')),
      );
      return;
    }
    setState(() => _saving = true);
    final svc = ref.read(dataServiceProvider);
    final updated = widget.initial.copyWith(
      name: _name.text.trim(),
      age: int.tryParse(_age.text) ?? 0,
      photoUrl: _photoUrl,
      bio: _bio.text.trim(),
      faculty: _faculty,
      skills: _skills,
      lookingFor: _lookingFor,
    );
    try {
      await svc.updateProfile(updated);
      if (!mounted) return;
      widget.onSaved?.call();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          Center(
            child: Stack(
              children: [
                UserAvatar(
                  photoUrl: _photoUrl,
                  name: _name.text.isEmpty ? '?' : _name.text,
                  size: 120,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: AppColors.primary,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _pickPhoto,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _age,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Age',
              prefixIcon: Icon(Icons.cake_outlined),
            ),
            validator: (v) {
              final n = int.tryParse(v ?? '');
              if (n == null) return 'Age is required';
              if (n < 15 || n > 80) return 'Enter a realistic age';
              return null;
            },
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _faculty,
            decoration: const InputDecoration(
              labelText: 'Faculty',
              prefixIcon: Icon(Icons.school_outlined),
            ),
            items: [
              for (final f in _faculties)
                DropdownMenuItem(value: f, child: Text(f)),
            ],
            onChanged: (v) => setState(() => _faculty = v ?? _faculty),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _bio,
            minLines: 3,
            maxLines: 5,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: 'Bio',
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 60),
                child: Icon(Icons.short_text_rounded),
              ),
              helperText: 'What are you working on or hoping to find?',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Bio is required';
              return null;
            },
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _lookingFor,
            decoration: const InputDecoration(
              labelText: 'Looking for',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            items: [
              for (final entry in lookingForOptions.entries)
                DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setState(() => _lookingFor = v ?? _lookingFor),
          ),
          const SizedBox(height: 20),
          _SkillsSection(
            skills: _skills,
            controller: _skillInput,
            onAdd: _addSkill,
            onRemove: (s) => setState(() => _skills.remove(s)),
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            label: widget.submitLabel,
            onPressed: _submit,
            isLoading: _saving,
          ),
        ],
      ),
    );
  }
}

class _SkillsSection extends StatelessWidget {
  const _SkillsSection({
    required this.skills,
    required this.controller,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> skills;
  final TextEditingController controller;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Skills',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'e.g. Flutter, Figma…',
                  prefixIcon: Icon(Icons.star_outline_rounded),
                ),
                onSubmitted: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
        if (skills.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in skills)
                Chip(
                  label: Text(s),
                  onDeleted: () => onRemove(s),
                  deleteIconColor: AppColors.textSecondary,
                ),
            ],
          ),
        ],
      ],
    );
  }
}
