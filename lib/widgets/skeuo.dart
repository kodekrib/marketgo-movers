// Soft-tactile skeuomorphic toolkit shared across the MarketGO Flutter apps.
//
// Flat Material surfaces are turned into physical, tactile ones: raised panels
// with beveled edges and layered shadows, glossy push buttons that visibly
// depress under the finger, and engraved (inset) fields. Everything is
// colour-driven so each app keeps its own brand palette.
import 'package:flutter/material.dart';

class Skeuo {
  Skeuo._();

  static const Color defaultTint = Color(0xFF0E1116);

  /// Blend [c] towards white (t > 0) or black (t < 0).
  static Color shade(Color c, double t) => t >= 0
      ? Color.lerp(c, Colors.white, t)!
      : Color.lerp(c, Colors.black, -t)!;

  /// Layered shadows that lift a raised surface off the page.
  static List<BoxShadow> raisedShadows({
    double depth = 1,
    Color tint = defaultTint,
    Color highlight = Colors.white,
  }) =>
      [
        BoxShadow(
          color: tint.withOpacity(0.20 * depth),
          blurRadius: 26 * depth,
          offset: Offset(0, 14 * depth),
        ),
        BoxShadow(
          color: tint.withOpacity(0.10 * depth),
          blurRadius: 7 * depth,
          offset: Offset(0, 3 * depth),
        ),
        BoxShadow(
          color: highlight.withOpacity(0.85),
          blurRadius: 3,
          offset: const Offset(-1.5, -1.5),
        ),
      ];

  /// Shadows that make a surface look carved into the page.
  static List<BoxShadow> insetShadows({
    double depth = 1,
    Color tint = defaultTint,
    Color highlight = Colors.white,
  }) =>
      [
        BoxShadow(
          color: tint.withOpacity(0.18 * depth),
          blurRadius: 8 * depth,
          offset: Offset(0, 3 * depth),
        ),
        BoxShadow(
          color: highlight.withOpacity(0.90),
          blurRadius: 5,
          offset: const Offset(0, -2.5),
        ),
      ];
}

// ---------------------------------------------------------------------------
// Raised panel
// ---------------------------------------------------------------------------

/// A raised, beveled surface with a subtle top-light gradient — the base
/// building block of the skeuomorphic look.
class SkeuoCard extends StatelessWidget {
  const SkeuoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.radius = 24,
    this.color = const Color(0xFFFBFBFC),
    this.tint = Skeuo.defaultTint,
    this.depth = 1,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color color;
  final Color tint;
  final double depth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    Widget face = Container(
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Skeuo.shade(color, 0.055), Skeuo.shade(color, -0.05)],
        ),
        border: Border.all(color: Skeuo.shade(color, -0.12), width: 1),
        boxShadow: Skeuo.raisedShadows(depth: depth, tint: tint),
      ),
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      face = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: face,
      );
    }
    if (margin != null) {
      face = Padding(padding: margin!, child: face);
    }
    return face;
  }
}

/// An inset (engraved) surface — the counterpart to [SkeuoCard] for areas that
/// should look carved into the page.
class SkeuoInset extends StatelessWidget {
  const SkeuoInset({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 14,
    this.color = const Color(0xFFEFF1F4),
    this.tint = Skeuo.defaultTint,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Skeuo.shade(color, -0.05), Skeuo.shade(color, 0.04)],
        ),
        border: Border.all(color: Skeuo.shade(color, -0.18), width: 1),
        boxShadow: Skeuo.insetShadows(tint: tint),
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Glossy push button
// ---------------------------------------------------------------------------

/// A glossy, beveled button that physically depresses when pressed.
class SkeuoButton extends StatefulWidget {
  const SkeuoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.textColor = Colors.white,
    this.iconColor,
    this.height = 54,
    this.radius = 16,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final Color textColor;
  final Color? iconColor;
  final double height;
  final double radius;
  final bool loading;
  final bool expand;

  @override
  State<SkeuoButton> createState() => _SkeuoButtonState();
}

class _SkeuoButtonState extends State<SkeuoButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    final face = enabled
        ? (widget.color ?? Theme.of(context).colorScheme.primary)
        : Skeuo.shade(
            (widget.color ?? Theme.of(context).colorScheme.primary), 0.34);
    final r = BorderRadius.circular(widget.radius);

    Widget content = widget.loading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              color: widget.textColor,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon,
                    size: 19, color: widget.iconColor ?? widget.textColor),
                const SizedBox(width: 9),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: widget.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          );

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTap: enabled ? widget.onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        height: widget.height,
        width: widget.expand ? double.infinity : null,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: r,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Skeuo.shade(face, 0.20), Skeuo.shade(face, -0.16)],
          ),
          border: Border.all(color: Skeuo.shade(face, -0.30), width: 1),
          boxShadow: _down || !enabled
              ? [
                  BoxShadow(
                    color: face.withOpacity(0.45),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: face.withOpacity(0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Skeuo.shade(face, -0.35).withOpacity(0.45),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Stack(
          children: [
            // Top gloss highlight.
            Positioned(
              top: 1.5,
              left: 8,
              right: 8,
              height: widget.height * 0.42,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: r,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(_down ? 0.12 : 0.38),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Center(child: content),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Glossy icon button
// ---------------------------------------------------------------------------

/// A round, glossy icon button that depresses on press.
class SkeuoIconButton extends StatefulWidget {
  const SkeuoIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
    this.iconColor = const Color(0xFF111418),
    this.size = 46,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Color iconColor;
  final double size;
  final String? tooltip;

  @override
  State<SkeuoIconButton> createState() => _SkeuoIconButtonState();
}

class _SkeuoIconButtonState extends State<SkeuoIconButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(widget.size);
    Widget button = GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          borderRadius: r,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Skeuo.shade(widget.color, 0.14),
              Skeuo.shade(widget.color, -0.10),
            ],
          ),
          border: Border.all(color: Skeuo.shade(widget.color, -0.22), width: 1),
          boxShadow: _down
              ? [
                  BoxShadow(
                    color: Skeuo.defaultTint.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : Skeuo.raisedShadows(depth: 0.7),
        ),
        child: Icon(widget.icon,
            color: widget.iconColor, size: widget.size * 0.46),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}

// ---------------------------------------------------------------------------
// Glossy pill / badge
// ---------------------------------------------------------------------------

/// A small glossy pill, e.g. a status chip or a tag.
class SkeuoPill extends StatelessWidget {
  const SkeuoPill({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Skeuo.shade(color, 0.16), Skeuo.shade(color, -0.08)],
        ),
        border: Border.all(color: Skeuo.shade(color, -0.16), width: 1),
        boxShadow: Skeuo.raisedShadows(depth: 0.5),
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Engraved text field
// ---------------------------------------------------------------------------

/// A text field recessed into the surface, with a focus-aware accent ring.
class SkeuoField extends StatefulWidget {
  const SkeuoField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.accent,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Color? accent;

  @override
  State<SkeuoField> createState() => _SkeuoFieldState();
}

class _SkeuoFieldState extends State<SkeuoField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEBEDF1), Color(0xFFF4F5F7)],
        ),
        border: Border.all(
          color: _focused
              ? (widget.accent ?? Theme.of(context).colorScheme.primary)
              : const Color(0xFFD9DDE3),
          width: _focused ? 1.8 : 1.2,
        ),
        boxShadow: Skeuo.insetShadows(),
      ),
      child: Focus(
        onFocusChange: (f) {
          if (mounted) setState(() => _focused = f);
        },
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onSubmitted: widget.onSubmitted,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111418),
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            filled: false,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
            labelText: widget.label,
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.suffixIcon,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF5B616A),
            ),
            hintStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Color(0xFF9AA1AA),
            ),
          ),
        ),
      ),
    );
  }
}
