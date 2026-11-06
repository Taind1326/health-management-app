import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Hệ thống Reusable Widgets chuẩn Glassmorphism Bảng màu "Aurora Borealis" (Cực Quang Hiện Đại) dành cho TV1
/// Đặc tả:
/// - Nền Gradient tràn viền 100% diện tích (từ Status Bar mép trên cùng tới mép dưới cùng)
/// - Bảng màu Aurora Borealis 4 tầng: Deep Cosmic Indigo, Royal Indigo-Violet, Luminous Cyan-Teal, Aurora Emerald
/// - 3 Quầng sáng cực quang (Glowing Orbs): Soft Violet Glow, Electric Sky Cyan, Mint Aurora
/// - Tấm kính sáng trong với BackdropFilter blur(16px), fill rgba(255,255,255,0.18)
/// - Viền kính 1px bán trong suốt rgba(255,255,255,0.38), bóng đổ Indigo Navy sâu thẳm
/// - Không còn dải đen ở đỉnh màn hình (AppBar và Status Bar trong suốt hoàn toàn)
/// - Controls rõ nét, Focus state phát sáng viền Sky Cyan (#7DD3FC), Nút bấm gradient Ocean-Indigo (#0284C7)
class Tv1GlassScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? floatingActionButton;
  final bool extendBodyBehindAppBar;

  const Tv1GlassScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.drawer,
    this.floatingActionButton,
    this.extendBodyBehindAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    final isReduced = media?.disableAnimations == true ||
        media?.accessibleNavigation == true ||
        media?.highContrast == true;

    // Lớp nền Gradient Aurora Borealis (Cực quang) bao phủ 100% toàn bộ màn hình
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF312E81), // Deep Cosmic Indigo
            Color(0xFF4338CA), // Royal Indigo-Violet
            Color(0xFF0891B2), // Luminous Cyan-Teal
            Color(0xFF0D9488), // Aurora Emerald
          ],
          stops: [0.0, 0.35, 0.70, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Các khối cầu phát sáng mềm mại (Glowing Orbs) tạo độ xuyên thấu màu sắc
          if (!isReduced) ...[
            // Quầng sáng 1: Góc trên bên phải (Soft Violet Glow)
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFC084FC).withValues(alpha: 0.50),
                      const Color(0xFFA855F7).withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Quầng sáng 2: Giữa bên trái (Electric Sky Cyan)
            Positioned(
              top: 240,
              left: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF38BDF8).withValues(alpha: 0.45),
                      const Color(0xFF7DD3FC).withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Quầng sáng 3: Góc dưới bên phải (Mint Aurora)
            Positioned(
              bottom: -50,
              right: -40,
              child: Container(
                width: 290,
                height: 290,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF34D399).withValues(alpha: 0.45),
                      const Color(0xFF6EE7B7).withValues(alpha: 0.20),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],

          // Scaffold với nền trong suốt hoàn toàn, xóa bỏ dải màu đen ở đỉnh
          Scaffold(
            backgroundColor: Colors.transparent,
            extendBodyBehindAppBar: extendBodyBehindAppBar,
            appBar: appBar,
            drawer: drawer,
            floatingActionButton: floatingActionButton,
            body: SafeArea(
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}

/// AppBar chuẩn Glassmorphism trong suốt 100%, không đổ bóng đen hay phủ màu khi cuộn
class Tv1GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final bool centerTitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  const Tv1GlassAppBar({
    super.key,
    this.title,
    this.centerTitle = true,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      centerTitle: centerTitle,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0, // Tắt hiệu ứng đổ màu khi cuộn
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      actions: actions,
      iconTheme: const IconThemeData(color: Colors.white),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Tấm Panel / Thẻ Card kính mờ chuẩn Glassmorphism Aurora Borealis
class Tv1GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? surfaceColor;
  final Color? borderColor;
  final double borderWidth;
  final double blur;
  final List<BoxShadow>? customShadow;

  const Tv1GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.borderRadius,
    this.surfaceColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.blur = 16.0,
    this.customShadow,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    final isReduced = media?.disableAnimations == true ||
        media?.accessibleNavigation == true ||
        media?.highContrast == true;

    final effectiveRadius = borderRadius ?? BorderRadius.circular(16.0);
    final effectiveBorderColor = borderColor ??
        Colors.white.withValues(alpha: isReduced ? 0.50 : 0.38);
    final effectiveSurfaceColor = surfaceColor ??
        (isReduced
            ? const Color(0xFF1E1B4B).withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.18));

    // Fallback cho chế độ giảm chuyển động / độ tương phản cao
    if (isReduced) {
      return Container(
        margin: margin,
        decoration: BoxDecoration(
          color: effectiveSurfaceColor,
          borderRadius: effectiveRadius,
          border: Border.all(color: effectiveBorderColor, width: borderWidth + 0.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E1B4B).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: padding,
        child: child,
      );
    }

    // Chế độ Glassmorphism: Blur 16px + White 18% + Border 1px White 38% + Deep Indigo Shadow
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        boxShadow: customShadow ??
            [
              BoxShadow(
                color: const Color(0xFF1E1B4B).withValues(alpha: 0.25),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              color: effectiveSurfaceColor,
              borderRadius: effectiveRadius,
              border: Border.all(
                color: effectiveBorderColor,
                width: borderWidth,
              ),
            ),
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Huy hiệu kính đa lớp (Layered Glass Badge) phong cách Aurora Borealis
class Tv1LayeredBadge extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? iconColor;

  const Tv1LayeredBadge({
    super.key,
    required this.icon,
    this.size = 56,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.38),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.18),
        ),
        child: Icon(
          icon,
          size: size,
          color: iconColor ?? const Color(0xFFE0F2FE),
        ),
      ),
    );
  }
}

/// Helper định hình Theme và Controls hiển thị sắc nét trên nền Aurora Borealis
class Tv1GlassTheme {
  Tv1GlassTheme._();

  /// InputDecoration có bề mặt sáng nhẹ, viền rõ ràng và Focus sáng viền Sky Cyan
  static InputDecoration inputDecoration({
    required String labelText,
    String? hintText,
    String? helperText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? suffixText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      suffixText: suffixText,
      suffixStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.15), // Sáng nhẹ bề mặt ô nhập liệu
      labelStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.65),
        fontSize: 13,
      ),
      helperStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.85),
        fontSize: 12,
      ),
      errorStyle: const TextStyle(
        color: Color(0xFFFF6B6B),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.35), // Viền sáng sắc nét
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF7DD3FC), // Sáng viền Sky Cyan nổi bật khi Focus
          width: 1.8,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFFF6B6B),
          width: 1.2,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFFF6B6B),
          width: 1.8,
        ),
      ),
    );
  }

  /// Nút bấm chính phong cách Aurora Ocean-Indigo
  static ButtonStyle primaryButtonStyle({Color? backgroundColor}) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? const Color(0xFF0284C7), // Sắc Ocean-Indigo tràn đầy năng lượng
      foregroundColor: Colors.white,
      elevation: 4,
      shadowColor: const Color(0xFF0284C7).withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  /// Nút bấm viền kính sáng Sky Cyan
  static ButtonStyle secondaryButtonStyle() {
    return OutlinedButton.styleFrom(
      side: const BorderSide(color: Color(0xFF7DD3FC), width: 1.3),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
