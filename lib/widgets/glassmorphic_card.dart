import 'dart:ui';
import 'package:flutter/material.dart';

class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final double blur;
  final double opacity;
  final Color borderColor;
  final double borderWidth;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.height,
    this.borderRadius = 20.0,
    this.padding = const EdgeInsets.all(16.0),
    this.backgroundColor,
    this.blur = 10.0,
    this.opacity = 0.05,
    this.borderColor = Colors.white,
    this.borderWidth = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardBgColor = backgroundColor ?? theme.cardColor;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              color: cardBgColor.withOpacity(opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor.withOpacity(0.1),
                width: borderWidth,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cardBgColor.withOpacity(0.2),
                  cardBgColor.withOpacity(0.05),
                ],
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

// Animovaná verze karty pro efektní animace
class AnimatedGlassmorphicCard extends StatefulWidget {
  final Widget child;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final double blur;
  final double opacity;
  final Color borderColor;
  final double borderWidth;
  final Duration duration;
  final bool isVisible;

  const AnimatedGlassmorphicCard({
    super.key,
    required this.child,
    this.height,
    this.borderRadius = 20.0,
    this.padding = const EdgeInsets.all(16.0),
    this.backgroundColor,
    this.blur = 10.0,
    this.opacity = 0.05,
    this.borderColor = Colors.white,
    this.borderWidth = 1.5,
    this.duration = const Duration(milliseconds: 500),
    this.isVisible = true,
  });

  @override
  State<AnimatedGlassmorphicCard> createState() => _AnimatedGlassmorphicCardState();
}

class _AnimatedGlassmorphicCardState extends State<AnimatedGlassmorphicCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _translateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _translateAnimation = Tween<double>(
      begin: 20.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedGlassmorphicCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _translateAnimation.value),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: GlassmorphicCard(
                child: widget.child,
                height: widget.height,
                borderRadius: widget.borderRadius,
                padding: widget.padding,
                backgroundColor: widget.backgroundColor,
                blur: widget.blur,
                opacity: widget.opacity,
                borderColor: widget.borderColor,
                borderWidth: widget.borderWidth,
              ),
            ),
          ),
        );
      },
    );
  }
}


