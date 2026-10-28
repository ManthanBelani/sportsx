import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Globally consistent UI across every viewport — phone, tablet, web.
///
/// All screens use hard-coded dp values tuned for a *small* (~360x640 logical
/// dp) phone. Rewriting every screen to be fluid is not feasible, so this
/// widget does the equivalent work centrally:
///
///   * the app is laid out on a design canvas of [designWidth] x
///     [designHeight] — the reference the screens were built for,
///   * the canvas is scaled uniformly with the exact factor needed to fill
///     the real screen (the *limiting* dimension drives the factor).
///
/// Result:
///   * portrait phones  — every element occupies the same fraction of the
///     screen on a 5" phone and a 6.7" phone: identical proportions.
///   * landscape / split-screen / short windows — height drives the factor,
///     so content still fits instead of fonts ballooning.
///   * tablet / desktop / web (>= [edgeToEdgeMaxLogicalWidth]) — 1:1 density;
///     only the OS font-size setting is clamped so oversized text can never
///     blow out of its containers on any screen.
///
/// `MediaQuery` is re-provided to the scaled subtree (size, safe-area
/// padding, keyboard insets, text scaling and devicePixelRatio are all
/// converted into design-canvas units) so existing code reading
/// `MediaQuery.of(context)` keeps working unchanged.
///
/// Tuning: change [designWidth]/[designHeight] to the canvas the screens were
/// designed on; [maxTextScaleFactor] to loosen/tighten the font-size cap.
class ResponsiveScaler extends StatelessWidget {
  const ResponsiveScaler({super.key, required this.child});

  final Widget? child;

  /// Reference canvas width — the small-phone width the current UI is tuned for.
  static const double designWidth = 360.0;

  /// Reference canvas height — short portrait phones we tune for.
  static const double designHeight = 640.0;

  /// Scale bounds. Beyond these the density is kept 1:1 and the canvas just
  /// grows (wider layout), instead of scaling an element absurdly.
  ///
  /// Reduced from 1.45 to 1.15 so 6.2"+ phones don't render oversized UI.
  /// At 1.15 cap, even a 400dp wide phone grows only ~11% (fits more content).
  static const double minScale = 0.85;
  static const double maxScale = 1.15;

  /// Large form factors (tablet / desktop / web) have their own adaptive
  /// layouts — never density-scale those.
  static const double edgeToEdgeMaxLogicalWidth = 720.0;

  /// Cap applied to the OS font-size setting. Above this, text blows out of
  /// its containers (the "large text issue") — clamped for consistent,
  /// overflowing-proof UI on every screen.
  static const double maxTextScaleFactor = 1.2;

  @override
  Widget build(BuildContext context) {
    final Widget? child = this.child;
    if (child == null) return const SizedBox.shrink();

    final MediaQueryData mq = MediaQuery.of(context);
    final Size real = mq.size;
    if (real.width == 0 || real.height == 0) {
      return _withTextClamp(mq, child);
    }

    // Tablet / desktop / web — 1:1 density, but keep OS font scaling capped
    // so no screen can render oversized text.
    if (real.width >= edgeToEdgeMaxLogicalWidth) {
      return _withTextClamp(mq, child);
    }

    // Phone-like viewports (any orientation): layout happens on a 360x640
    // design canvas scaled by the *limiting* dimension, so UI stays
    // proportionate in portrait and fits inside short landscape /
    // split-screen viewports instead of looking oversized.
    final double wScale =
        (real.width / designWidth).clamp(minScale, maxScale).toDouble();
    final double hScale =
        (real.height / designHeight).clamp(minScale, maxScale).toDouble();
    final double scale = math.min(wScale, hScale);
    final Size canvas = Size(real.width / scale, real.height / scale);

    final MediaQueryData scaledMq = mq.copyWith(
      size: canvas,
      devicePixelRatio: mq.devicePixelRatio * scale,
      padding: _divideEdgeInsets(mq.padding, scale),
      viewPadding: _divideEdgeInsets(mq.viewPadding, scale),
      viewInsets: _divideEdgeInsets(mq.viewInsets, scale),
      systemGestureInsets: _divideEdgeInsets(mq.systemGestureInsets, scale),
      // OS text scaling on top of the *design* canvas — the FittedBox itself
      // upscales the whole canvas by `scale`, so here we divide it back out.
      //
      // Correct math: visual font size = canvasScaler * FittedBox(scale),
      // and we want the visual result to be fontSize * OS-factor. Therefore
      // the canvas-level scaler must return OS-factor * fontSize / scale.
      //
      // The previous version *multiplied* by scale here, causing fonts to
      // render at fontSize * scale² — roughly 2x the intended growth — which
      // made text look oversized on larger phones.
      textScaler: _ScaledTextScaler(
        mq.textScaler.clamp(
          minScaleFactor: 0.8,
          maxScaleFactor: maxTextScaleFactor,
        ),
        scale,
      ),
    );

    return FittedBox(
      fit: BoxFit.fill,
      child: SizedBox(
        width: canvas.width,
        height: canvas.height,
        child: MediaQuery(data: scaledMq, child: child),
      ),
    );
  }

  /// Desktop/tablet path: no density scaling, only the text clamp.
  static Widget _withTextClamp(MediaQueryData mq, Widget child) {
    final double osTextScale = mq.textScaler.scale(1.0);
    if (osTextScale <= maxTextScaleFactor ||
        osTextScale == 0 ||
        osTextScale.isInfinite) {
      return child;
    }
    return MediaQuery(
      data: mq.copyWith(
        textScaler: mq.textScaler.clamp(minScaleFactor: 0.8, maxScaleFactor: maxTextScaleFactor),
      ),
      child: child,
    );
  }

  static EdgeInsets _divideEdgeInsets(EdgeInsets insets, double scale) {
    if (insets == EdgeInsets.zero) return insets;
    return insets / scale;
  }
}

/// Applies the canvas scale *inverse* on top of the OS-level font scaling
/// while preserving the (possibly non-linear) accessibility curve.
///
/// The surrounding FittedBox upscales the whole canvas by `scale`.
/// To keep text at its intended logical size (fontSize * OS-factor),
/// we must divide by `scale` here so the FittedBox upscale restores it.
class _ScaledTextScaler implements TextScaler {
  const _ScaledTextScaler(this._inner, this._scale);

  final TextScaler _inner;
  final double _scale;

  @override
  double get textScaleFactor => _inner.scale(1.0) / _scale;

  @override
  TextScaler clamp({
    double minScaleFactor = 0,
    double maxScaleFactor = double.infinity,
  }) {
    return _ScaledTextScaler(
      _inner.clamp(
        minScaleFactor: minScaleFactor * _scale,
        maxScaleFactor: maxScaleFactor * _scale,
      ),
      _scale,
    );
  }

  @override
  double scale(double fontSize) => _inner.scale(fontSize) / _scale;
}
