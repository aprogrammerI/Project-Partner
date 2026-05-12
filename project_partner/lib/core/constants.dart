import 'package:flutter/material.dart';

/// The 5 partner categories users can be looking for.
/// Keys are stable IDs (stored in DB later), values are display labels.
const Map<String, String> lookingForOptions = {
  'study_buddy': 'Study buddy',
  'project_partner': 'Партнер за факултетски проект',
  'co_founder': 'Co-founder за стартап',
  'collaborator': 'Соработник за развој на идеја',
  'freelancer': 'Freelancer',
};

/// Icon + color per category, used on swipe cards as a badge.
const Map<String, IconData> lookingForIcons = {
  'study_buddy': Icons.school_outlined,
  'project_partner': Icons.assignment_outlined,
  'co_founder': Icons.rocket_launch_outlined,
  'collaborator': Icons.lightbulb_outline,
  'freelancer': Icons.work_outline,
};

const Map<String, Color> lookingForColors = {
  'study_buddy': Color(0xFF4C9AFF),
  'project_partner': Color(0xFF7C5CFF),
  'co_founder': Color(0xFFFF6B6B),
  'collaborator': Color(0xFFFFB020),
  'freelancer': Color(0xFF22C55E),
};

/// Faculties shown in profile setup dropdown.
const List<String> faculties = [
  'FINKI',
  'FEIT',
  'Economics',
  'Architecture',
  'Medicine',
  'Law',
  'Philology',
  'Mechanical Engineering',
  'Other',
];
