import 'package:flutter/material.dart';

/// Logical viewport tiers based on the width reported by `MediaQuery`.
class Breakpoints {
  /// Small phones (iPhone SE, 320-380 logical dp).
  static const double compact = 360.0;

  /// Most phones.
  static const double medium = 480.0;

  /// Tablets, foldables opened, desktop and web windows.
  static const double tablet = 720.0;
}

/// MediaQuery-driven responsive sizing.
///
/// SportX screens are tuned against a 360 logical-dp wide reference canvas.
/// Every value is multiplied by a clamped viewport factor so the UI stays
/// proportionate on any viewport:
///
///  * small phones        -> values tighten slightly
///  * phones (360-480dp)  -> 1:1 with the tuned design
///  * landscape / split   -> fonts widen a touch, vertical rhythm compresses
///  * tablet / desktop    -> fonts widen up to the cap; layouts center content
///
/// Never access this from `initState` — it needs a live `MediaQuery`.
class Responsive {
  Responsive._(this.mq);

  factory Responsive.of(BuildContext context) =>
      Responsive._(MediaQuery.of(context));

  final MediaQueryData mq;

  double get width => mq.size.width;
  double get height => mq.size.height;

  /// Width factor around the 360dp reference, clamped so UI can never become
  /// microscopic on tiny viewports or balloon on tablets / desktop.
  double get _w => (width / 360).clamp(0.90, 1.12);

  /// Compress vertical rhythm when the viewport is short (landscape,
  /// split-screen, short desktop windows) so content fits comfortably.
  bool get _isShort => height < 620;

  /// Scales a horizontal size, font size or radius around the reference.
  double ws(double base) => base * _w;

  /// Scales a vertical gap around the reference.
  double vs(double base) => base * (_isShort ? 0.85 : 1.0);

  /// Symmetric horizontal padding scaled with the viewport.
  EdgeInsets padH(double h) => EdgeInsets.symmetric(horizontal: ws(h));
}

/// Convenience accessors so screens read naturally:
/// `final r = context.resp;` / `padding: EdgeInsets.all(r.ws(16))`.
extension ResponsiveContext on BuildContext {
  Responsive get resp => Responsive.of(this);

  double get vpWidth => MediaQuery.of(this).size.width;
  double get vpHeight => MediaQuery.of(this).size.height;

  bool get isCompactViewport => vpWidth < Breakpoints.compact;
  bool get isMediumViewport =>
      vpWidth >= Breakpoints.compact && vpWidth < Breakpoints.tablet;
  bool get isTabletViewport => vpWidth >= Breakpoints.tablet;
}
