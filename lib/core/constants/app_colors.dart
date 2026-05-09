import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary Palette ──────────────────────────────
  static const primary       = Color(0xFF6366F1); // Indigo
  static const primaryDark   = Color(0xFF4F46E5);
  static const secondary     = Color(0xFF8B5CF6); // Violet
  static const accent        = Color(0xFF06B6D4); // Cyan

  // ── Gradient ─────────────────────────────────────
  static const gradientStart = Color(0xFF6366F1);
  static const gradientEnd   = Color(0xFF8B5CF6);

  static const primaryGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Background & Surface ─────────────────────────
  static const background    = Color(0xFFF1F5F9);
  static const surface       = Color(0xFFFFFFFF);
  static const surfaceVariant= Color(0xFFEEF2FF);

  // ── Text ─────────────────────────────────────────
  static const textPrimary   = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textHint      = Color(0xFF94A3B8);

  // ── Status ───────────────────────────────────────
  static const success       = Color(0xFF10B981);
  static const warning       = Color(0xFFF59E0B);
  static const error         = Color(0xFFEF4444);
  static const info          = Color(0xFF3B82F6);

  // ── Misc ─────────────────────────────────────────
  static const divider       = Color(0xFFE2E8F0);
  static const cardShadow    = Color(0x1A6366F1);
  static const white         = Color(0xFFFFFFFF);
  static const black         = Color(0xFF000000);

  // ── Score Colors ─────────────────────────────────
  static Color scoreColor(double score) {
    if (score >= 7.5) return success;
    if (score >= 5.0) return warning;
    return error;
  }
}
