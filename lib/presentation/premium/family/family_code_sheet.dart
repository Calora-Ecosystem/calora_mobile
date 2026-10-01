import 'dart:async';
import 'dart:math' as math;

import 'package:calora/common/di/injection.dart';
import 'package:calora/common/extensions/bottom_sheet.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/util/share_origin.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/common/widgets/snack_bar/custom_snack_bar.dart';
import 'package:calora/domain/model/premium/family_code.dart';
import 'package:calora/domain/repo/premium/premium_repo.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/premium/family/person_avatar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// App download link appended to the family invite.
const String _appLink = 'https://calora.uz/get-app?utm_source=family_plan';

/// How long a fresh code stays redeemable when the dates don't tell
/// (mirrors the backend's `FamilyService.RedeemWindowDays`).
const int _redeemWindowDays = 30;

/// Family plan: the code the buyer sends to the second person.
///
/// Told as one short story rather than a form: a ticket travels from you to
/// your loved one, the code arrives on a ticket and decodes into place, and
/// a single "send" action follows. Opened right after the family plan is paid
/// for, and from Profile → Subscription so the code is never lost with a
/// closed popup. Honors the system "reduce motion" setting.
class FamilyCodeSheet extends StatefulWidget {
  /// Just paid: the backend issues the code when the payment is accepted,
  /// which can trail the app by a moment — poll briefly before giving up.
  final bool waitForNew;

  const FamilyCodeSheet({super.key, this.waitForNew = false});

  static Future<void> show(BuildContext context, {bool waitForNew = false}) =>
      context.showAppBottomSheet(
        child: FamilyCodeSheet(waitForNew: waitForNew),
      );

  @override
  State<FamilyCodeSheet> createState() => _FamilyCodeSheetState();
}

class _FamilyCodeSheetState extends State<FamilyCodeSheet>
    with TickerProviderStateMixin {
  static const _retries = 4;
  static const _retryDelay = Duration(seconds: 2);

  /// The hero: the ticket flies from you to your loved one.
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  /// Once the code is in: ticket rises, code decodes, light sweeps across,
  /// the deadline fills, then the action and the steps.
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );

  FamilyCode? _code;
  bool _loading = true;
  bool _copied = false;
  Timer? _copiedTimer;

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion) {
      _intro.value = 1;
    } else if (_intro.isDismissed) {
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _copiedTimer?.cancel();
    _intro.dispose();
    _reveal.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = getIt<PremiumRepo>();
    for (var attempt = 0; ; attempt++) {
      FamilyCode? code;
      try {
        code = _pick(await repo.getFamilyCodes());
      } catch (_) {
        // Shown as "being prepared" below; Profile → Subscription has it later.
      }
      final lastTry = !widget.waitForNew || attempt >= _retries;
      if (code != null || lastTry) {
        if (!mounted) return;
        setState(() {
          _code = code;
          _loading = false;
        });
        if (_reduceMotion) {
          _reveal.value = 1;
        } else {
          _reveal.forward(from: 0);
        }
        return;
      }
      await Future<void>.delayed(_retryDelay);
      if (!mounted) return;
    }
  }

  /// The newest unused code; otherwise (when just looking it up) the newest
  /// one, so a redeemed or expired code still explains itself. Right after
  /// paying only a fresh, unused code counts.
  FamilyCode? _pick(List<FamilyCode> codes) {
    for (final code in codes) {
      if (code.status == FamilyCodeStatus.active) return code;
    }
    return codes.isNotEmpty && !widget.waitForNew ? codes.first : null;
  }

  void _copy() {
    final code = _code;
    if (code == null || code.status != FamilyCodeStatus.active) return;
    Clipboard.setData(ClipboardData(text: code.code));
    HapticFeedback.mediumImpact();
    _copiedTimer?.cancel();
    setState(() => _copied = true);
    _copiedTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _share(BuildContext buttonContext) async {
    final code = _code;
    if (code == null) return;
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: 'family_code_share_text'.tr(
            namedArgs: {
              'code': code.code,
              'months': '${code.months}',
              'link': _appLink,
            },
          ),
          sharePositionOrigin: shareOrigin(buttonContext),
        ),
      );
    } catch (_) {
      if (mounted) CustomSnackBar.show(context, 'something_went_wrong'.tr());
    }
  }

  /// Progress of one beat of [animation], 0 → 1.
  static double _beat(
    Animation<double> animation,
    double from,
    double to, {
    Curve curve = Curves.easeOutCubic,
  }) => Interval(from, to, curve: curve).transform(animation.value);

  static Widget _rise(double t, Widget child, {double dy = 12}) => Opacity(
    opacity: t,
    child: Transform.translate(offset: Offset(0, dy * (1 - t)), child: child),
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedBuilder(
      animation: Listenable.merge([_intro, _reveal]),
      builder: (context, _) {
        final code = _code;
        final status = code?.status;
        final done = status == FamilyCodeStatus.redeemed;
        final active = status == FamilyCodeStatus.active;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GiftJourney(
                appear: _beat(_intro, 0, 0.3),
                travel: done ? 1 : _beat(_intro, 0.18, 0.78),
                arrive: done
                    ? 1
                    : _beat(_intro, 0.72, 1, curve: Curves.easeOutBack),
              ),
              const SizedBox(height: 14),
              if (widget.waitForNew && code != null)
                _rise(
                  _beat(_intro, 0.1, 0.4),
                  const Center(child: _ActiveBadge()),
                ),
              if (widget.waitForNew && code != null) const SizedBox(height: 10),
              _rise(
                _beat(_intro, 0.12, 0.45),
                'family_code_title'
                    .tr()
                    .text(21, 27, 700)
                    .c(colors.textStrong)
                    .copyWith(textAlign: TextAlign.center),
              ),
              const SizedBox(height: 6),
              _rise(
                _beat(_intro, 0.2, 0.55),
                'family_code_subtitle'
                    .tr(namedArgs: {'months': '${code?.months ?? 1}'})
                    .text(14, 20, 400)
                    .c(colors.textSub)
                    .copyWith(textAlign: TextAlign.center),
              ),
              const SizedBox(height: 20),
              if (_loading)
                const _TicketSkeleton()
              else if (code == null)
                _pending(context)
              else ...[
                _rise(
                  _beat(_reveal, 0, 0.32),
                  dy: 22,
                  _CodeTicket(
                    code: code,
                    decode: _beat(_reveal, 0.18, 0.62, curve: Curves.linear),
                    shine: _beat(_reveal, 0.6, 0.9, curve: Curves.easeInOut),
                    copied: _copied,
                    onCopy: _copy,
                  ),
                ),
                const SizedBox(height: 14),
                _rise(
                  _beat(_reveal, 0.42, 0.66),
                  _StatusLine(code: code, fill: _beat(_reveal, 0.5, 0.95)),
                ),
                if (active) ...[
                  const SizedBox(height: 20),
                  _rise(
                    _beat(_reveal, 0.55, 0.8),
                    Builder(
                      builder: (buttonContext) => Button(
                        onPressed: () => _share(buttonContext),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.send_rounded,
                              size: 18,
                              color: colors.white,
                            ),
                            const SizedBox(width: 8),
                            'family_code_send'
                                .tr()
                                .text(16, 24, 500)
                                .c(colors.white),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _Steps(
                    progress: (int i) =>
                        _beat(_reveal, 0.66 + i * 0.1, 0.9 + i * 0.03),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _pending(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.backgroundElevation,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.schedule_rounded, size: 20, color: colors.textSub),
          const SizedBox(width: 10),
          Expanded(
            child: 'family_code_pending'
                .tr()
                .text(14, 20, 500)
                .c(colors.textStrong),
          ),
        ],
      ),
    );
  }
}

/// "Family plan is on" — only right after paying.
class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.lightGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 7,
            width: 7,
            decoration: BoxDecoration(
              color: colors.accentSub,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          'family_code_badge'.tr().text(12, 16, 600).c(colors.accentSub),
        ],
      ),
    );
  }
}

/// You on the left, your loved one on the right, a dashed arc between: a
/// small ticket flies across and, when it lands, your loved one's avatar
/// lights up with a check — the code's whole job, in one glance.
class _GiftJourney extends StatelessWidget {
  final double appear;
  final double travel;
  final double arrive;

  const _GiftJourney({
    required this.appear,
    required this.travel,
    required this.arrive,
  });

  static const double _height = 116;
  static const double _avatar = 52;
  static const double _token = 30;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: _height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          const y = 62.0;
          final left = Offset(w * 0.2, y);
          final right = Offset(w * 0.8, y);
          final control = Offset(w / 2, -4);

          // Point on the arc at t (quadratic Bézier).
          Offset at(double t) {
            final u = 1 - t;
            return left * (u * u) + control * (2 * u * t) + right * (t * t);
          }

          final token = at(travel);
          final flying = travel > 0 && travel < 1;
          final landed = arrive.clamp(0.0, 1.0);

          Widget person({
            required Offset center,
            required Color bg,
            required Color fg,
            required String label,
            bool partner = false,
          }) {
            final ring = partner ? arrive : 0.0;
            return Positioned(
              left: center.dx - 45,
              top: center.dy - _avatar / 2,
              width: 90,
              child: Opacity(
                opacity: appear,
                child: Transform.scale(
                  scale: 0.85 + 0.15 * appear,
                  child: Column(
                    children: [
                      SizedBox(
                        height: _avatar,
                        width: _avatar,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            if (partner && ring > 0)
                              Transform.scale(
                                scale: 1 + 0.18 * ring,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colors.accentSub.withValues(
                                        alpha: landed,
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            PersonAvatar(
                              size: _avatar,
                              background: bg,
                              foreground: fg,
                            ),
                            if (partner && ring > 0)
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Transform.scale(
                                  scale: ring,
                                  child: Container(
                                    height: 20,
                                    width: 20,
                                    decoration: BoxDecoration(
                                      color: colors.accentSub,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.check_rounded,
                                      size: 12,
                                      color: colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      label.text(12, 16, 500).c(colors.textSub),
                    ],
                  ),
                ),
              ),
            );
          }

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: appear,
                  child: CustomPaint(
                    painter: _ArcPainter(
                      from: left,
                      control: control,
                      to: right,
                      avatarRadius: _avatar / 2 + 6,
                      color: colors.strokeSub,
                      done: colors.accentSub,
                      progress: travel,
                    ),
                  ),
                ),
              ),
              person(
                center: left,
                bg: colors.accentSub,
                fg: colors.white,
                label: 'tf_person_you'.tr(),
              ),
              person(
                center: right,
                bg: PersonAvatar.partnerBackground,
                fg: PersonAvatar.partnerForeground,
                label: 'tf_person_partner'.tr(),
                partner: true,
              ),
              if (flying)
                Positioned(
                  left: token.dx - _token / 2,
                  top: token.dy - _token / 2,
                  child: Transform.rotate(
                    // Banks into the arc like a paper plane.
                    angle: (travel - 0.5) * 0.5,
                    child: Container(
                      height: _token,
                      width: _token,
                      decoration: BoxDecoration(
                        color: colors.accentSub,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: [
                          BoxShadow(
                            color: colors.accentSub.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.confirmation_number_rounded,
                        size: 17,
                        color: colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Dashed arc between the two avatars; the part the ticket has already
/// flown turns solid green.
class _ArcPainter extends CustomPainter {
  final Offset from;
  final Offset control;
  final Offset to;
  final double avatarRadius;
  final Color color;
  final Color done;
  final double progress;

  const _ArcPainter({
    required this.from,
    required this.control,
    required this.to,
    required this.avatarRadius,
    required this.color,
    required this.done,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(control.dx, control.dy, to.dx, to.dy);
    final metric = path.computeMetrics().first;
    // Keep the line off the avatars themselves.
    final start = avatarRadius;
    final end = metric.length - avatarRadius;
    if (end <= start) return;
    final flown = start + (end - start) * progress.clamp(0.0, 1.0);

    final dashed = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const dash = 5.0, gap = 5.0;
    for (var d = flown; d < end; d += dash + gap) {
      canvas.drawPath(metric.extractPath(d, math.min(d + dash, end)), dashed);
    }
    if (flown > start) {
      canvas.drawPath(
        metric.extractPath(start, flown),
        Paint()
          ..color = done
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress ||
      old.from != from ||
      old.to != to ||
      old.color != color;
}

/// The code on a ticket: a green "Premium · N months" stub, a perforated
/// tear line with side notches, and the code below — it decodes into place
/// letter by letter, then a single highlight sweeps across. Tap anywhere to
/// copy; the chip confirms it in place.
class _CodeTicket extends StatelessWidget {
  final FamilyCode code;
  final double decode;
  final double shine;
  final bool copied;
  final VoidCallback onCopy;

  const _CodeTicket({
    required this.code,
    required this.decode,
    required this.shine,
    required this.copied,
    required this.onCopy,
  });

  static const double _stub = 46;
  static const double _notch = 10;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final active = code.status == FamilyCodeStatus.active;
    final accent = active ? colors.accentSub : colors.iconSoft;

    return GestureDetector(
      onTap: active ? onCopy : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: (active ? colors.accentSub : colors.textSub).withValues(
                alpha: 0.08,
              ),
              blurRadius: 18,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipPath(
          clipper: const _TicketClipper(stub: _stub, notch: _notch),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: _stub,
                    color: accent,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: [
                        Icon(
                          Icons.workspace_premium_rounded,
                          size: 18,
                          color: colors.white,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: 'family_code_ticket_label'
                              .tr(namedArgs: {'months': '${code.months}'})
                              .toUpperCase()
                              .text(12, 16, 700)
                              .c(colors.white)
                              .copyWith(maxLines: 1),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < 2; i++)
                              Padding(
                                padding: EdgeInsets.only(left: i == 0 ? 0 : 2),
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 16,
                                  color: colors.white.withValues(
                                    alpha: i == 0 ? 1 : 0.7,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
                    child: Column(
                      children: [
                        _DecodingCode(
                          code: code.code,
                          progress: decode,
                          active: active,
                          struck: code.status == FamilyCodeStatus.expired,
                        ),
                        if (active) ...[
                          const SizedBox(height: 14),
                          _CopyChip(copied: copied),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              // Perforated tear line between the stub and the code.
              Positioned(
                left: _notch + 6,
                right: _notch + 6,
                top: _stub - 1,
                child: CustomPaint(
                  size: const Size.fromHeight(2),
                  painter: _PerforationPainter(color: colors.strokeSub),
                ),
              ),
              // One highlight sweep once the code has landed.
              if (active && shine > 0 && shine < 1)
                Positioned.fill(
                  child: IgnorePointer(
                    child: FractionalTranslation(
                      translation: Offset(-1 + 2 * shine, 0),
                      child: Transform.rotate(
                        angle: 0.35,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colors.white.withValues(alpha: 0),
                                colors.white.withValues(alpha: 0.45),
                                colors.white.withValues(alpha: 0),
                              ],
                              stops: const [0.35, 0.5, 0.65],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rounded ticket with a half-circle notch on each side at the tear line.
class _TicketClipper extends CustomClipper<Path> {
  final double stub;
  final double notch;

  const _TicketClipper({required this.stub, required this.notch});

  @override
  Path getClip(Size size) {
    final ticket = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)),
      );
    final holes = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, stub), radius: notch))
      ..addOval(
        Rect.fromCircle(center: Offset(size.width, stub), radius: notch),
      );
    return Path.combine(PathOperation.difference, ticket, holes);
  }

  @override
  bool shouldReclip(_TicketClipper old) =>
      old.stub != stub || old.notch != notch;
}

class _PerforationPainter extends CustomPainter {
  final Color color;

  const _PerforationPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    const dash = 4.0, gap = 4.0;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(math.min(x + dash, size.width), size.height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_PerforationPainter old) => old.color != color;
}

/// The code in fixed-width cells: unsettled letters cycle through the code
/// alphabet, then settle left to right — a split-flap board, not a jump.
/// "FAMILY-" is quieter than the part that matters. Screen readers get the
/// code once, as a whole.
class _DecodingCode extends StatelessWidget {
  final String code;
  final double progress;
  final bool active;

  /// An expired code is crossed out; a redeemed one just goes quiet.
  final bool struck;

  const _DecodingCode({
    required this.code,
    required this.progress,
    required this.active,
    this.struck = false,
  });

  static const _alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dash = code.indexOf('-');
    final prefix = code.substring(0, dash + 1);
    final body = code.substring(dash + 1);
    final settled = (progress * body.length).floor();
    // A new set of random letters every few frames, not every frame.
    final tick = (progress * 36).floor();
    final decoration = struck ? TextDecoration.lineThrough : null;

    return Semantics(
      container: true,
      label: code,
      child: ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                prefix,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: active ? colors.textSub : colors.iconSoft,
                ),
              ),
              const SizedBox(width: 4),
              for (var i = 0; i < body.length; i++)
                SizedBox(
                  width: 21,
                  child: Text(
                    i < settled || progress >= 1
                        ? body[i]
                        : _alphabet[math.Random(
                            tick * 31 + i,
                          ).nextInt(_alphabet.length)],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      decoration: decoration,
                      color: !active
                          ? colors.iconSoft
                          : i < settled || progress >= 1
                          ? colors.textStrong
                          : colors.accentSub,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Copy code" that turns into "Copied" right where the finger is.
class _CopyChip extends StatelessWidget {
  final bool copied;

  const _CopyChip({required this.copied});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: copied ? colors.accentSub : colors.lightGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        ),
        child: Row(
          key: ValueKey(copied),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              copied ? Icons.check_rounded : Icons.copy_rounded,
              size: 16,
              color: copied ? colors.white : colors.accentSub,
            ),
            const SizedBox(width: 6),
            (copied ? 'copied' : 'family_code_copy')
                .tr()
                .text(13, 16, 600)
                .c(copied ? colors.white : colors.accentSub),
          ],
        ),
      ),
    );
  }
}

/// Active: days left to activate and a bar of the window that's left.
/// Redeemed: who activated it. Expired: says so.
class _StatusLine extends StatelessWidget {
  final FamilyCode code;
  final double fill;

  const _StatusLine({required this.code, required this.fill});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    switch (code.status) {
      case FamilyCodeStatus.redeemed:
        final name = code.redeemedBy?.trim() ?? '';
        return _iconLine(
          context,
          Icons.verified_rounded,
          name.isNotEmpty
              ? 'family_code_redeemed_by'.tr(namedArgs: {'name': name})
              : 'family_code_redeemed'.tr(),
          colors.accentSub,
        );
      case FamilyCodeStatus.expired:
        return _iconLine(
          context,
          Icons.timer_off_rounded,
          'family_code_expired'.tr(),
          colors.errorBase,
        );
      case FamilyCodeStatus.active:
        final expireAt = code.expireAt;
        if (expireAt == null) return const SizedBox.shrink();
        final now = DateTime.now();
        final daysLeft = math.max(
          0,
          (expireAt.difference(now).inHours / 24).ceil(),
        );
        final totalDays = code.createdAt == null
            ? _redeemWindowDays
            : math.max(1, expireAt.difference(code.createdAt!).inDays);
        final share = (daysLeft / totalDays).clamp(0.0, 1.0);
        return Column(
          children: [
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 15, color: colors.textSub),
                const SizedBox(width: 6),
                Expanded(
                  child: 'family_code_days_left'
                      .tr(namedArgs: {'days': '$daysLeft'})
                      .text(13, 18, 600)
                      .c(colors.textStrong),
                ),
                const SizedBox(width: 8),
                'family_code_until'
                    .tr(namedArgs: {'date': _formatDate(expireAt)})
                    .text(12, 16, 500)
                    .c(colors.textSub),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 4,
                child: Stack(
                  children: [
                    Container(color: colors.strokeSoft),
                    FractionallySizedBox(
                      widthFactor: share * fill,
                      child: Container(color: colors.accentSub),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _iconLine(
    BuildContext context,
    IconData icon,
    String text,
    Color color,
  ) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, size: 15, color: color),
      const SizedBox(width: 6),
      Flexible(
        child: text
            .text(13, 18, 500)
            .c(color)
            .copyWith(textAlign: TextAlign.center),
      ),
    ],
  );

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.${d.year}';
}

/// The three steps the loved one goes through — the same ones the shared
/// message spells out — on a thin timeline, each sliding in after the last.
class _Steps extends StatelessWidget {
  final double Function(int index) progress;

  const _Steps({required this.progress});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const steps = [
      'family_code_how_1',
      'family_code_how_2',
      'family_code_how_3',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Opacity(
          opacity: progress(0),
          child: 'tf_family_how'.tr().text(15, 20, 700).c(colors.textStrong),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < steps.length; i++)
          Opacity(
            opacity: progress(i),
            child: Transform.translate(
              offset: Offset(16 * (1 - progress(i)), 0),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          height: 24,
                          width: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colors.lightGreen,
                            shape: BoxShape.circle,
                          ),
                          child: '${i + 1}'
                              .text(12, 14, 700)
                              .c(colors.accentSub),
                        ),
                        if (i < steps.length - 1)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              color: colors.lightGreen,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: 2,
                          bottom: i < steps.length - 1 ? 14 : 0,
                        ),
                        child: steps[i]
                            .tr()
                            .text(14, 20, 400)
                            .c(colors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Ticket-shaped placeholder while the code loads.
class _TicketSkeleton extends StatelessWidget {
  const _TicketSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipPath(
      clipper: const _TicketClipper(stub: 46, notch: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 46, color: colors.strokeSoft),
          Container(
            height: 112,
            color: colors.backgroundElevation,
            alignment: Alignment.center,
            child: const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ),
        ],
      ),
    );
  }
}
