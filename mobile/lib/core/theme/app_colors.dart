import 'package:flutter/material.dart';

/// Centralized color palette for the SwapBazar marketplace app.
abstract final class AppColors {
  // ── Brand Colors ──────────────────────────────────────────
  static const Color brand = Color(0xFFFF6B35);
  static const Color brandLight = Color(0xFFFF8F5E);
  static const Color brandDark = Color(0xFFE55A2B);

  // ── Accent Colors ─────────────────────────────────────────
  static const Color accent = Color(0xFF00C9A7);
  static const Color accentLight = Color(0xFF5DFFD4);
  static const Color accentDark = Color(0xFF009879);

  // ── Neutral Colors (Dark Theme) ───────────────────────────
  static const Color darkBg = Color(0xFF0F1115);
  static const Color darkSurface = Color(0xFF1A1D23);
  static const Color darkSurfaceVariant = Color(0xFF252830);
  static const Color darkCard = Color(0xFF1E2128);
  static const Color darkDivider = Color(0xFF2E3240);

  // ── Neutral Colors (Light Theme) ──────────────────────────
  static const Color lightBg = Color(0xFFF8F9FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF0F2F5);
  static const Color lightCard = Color(0xFFFFFFFF);

  // ── Text Colors ───────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF0F0F5);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  // ── Status Colors ─────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ── Gradients ─────────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF3D71)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF00C9A7), Color(0xFF00B4D8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1E2128), Color(0xFF252830)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [Color(0xFF252830), Color(0xFF2E3240), Color(0xFF252830)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment(-1.5, 0),
    end: Alignment(1.5, 0),
  );

  // ── Swap specific colors ──────────────────────────────────
  static const Color swapOrange = Color(0xFFFF9F43);
  static const Color swapTeal = Color(0xFF00D2D3);
}
