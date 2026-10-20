import 'package:flutter/material.dart';

enum TaskRole {
  academic,
  work,
  personal,
  world;

  String get displayName => switch (this) {
    TaskRole.academic => 'Academic',
    TaskRole.work => 'Work',
    TaskRole.personal => 'Personal',
    TaskRole.world => 'World',
  };

  Color get color => switch (this) {
    TaskRole.academic => const Color(0xFF9B51E0),
    TaskRole.work => const Color(0xFF2F80ED),
    TaskRole.personal => const Color(0xFFF59E0B),
    TaskRole.world => const Color(0xFF10B981),
  };

  IconData get icon => switch (this) {
    TaskRole.academic => Icons.school_outlined,
    TaskRole.work => Icons.business_center_outlined,
    TaskRole.personal => Icons.local_cafe_outlined,
    TaskRole.world => Icons.public_outlined,
  };
}
