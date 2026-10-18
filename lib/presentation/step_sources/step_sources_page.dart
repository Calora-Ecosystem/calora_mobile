import 'package:calora/common/di/injection.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/service/step_counter_service.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/step_sources/step_connect.dart';
import 'package:calora/presentation/step_sources/step_sources_controller.dart';
import 'package:calora/widgets/app_bar/custom_app_bar.dart';
import 'package:calora_steps/calora_steps.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class StepSourcesPage extends StatefulWidget {
  const StepSourcesPage({super.key, this.controller});

  final StepSourcesController? controller;

  @override
  State<StepSourcesPage> createState() => _StepSourcesPageState();
}

class _StepSourcesPageState extends State<StepSourcesPage> {
  late final StepSourcesController _controller =
      widget.controller ?? StepSourcesController(getIt<StepCounterService>());

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) _controller.init();
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final outcome = await _controller.connectHealthConnect();
    if (!mounted || outcome == null) return;
    final message = switch (outcome.result) {
      HealthConnectConnectResult.connected => 'steps_connect_done'.tr(),
      HealthConnectConnectResult.denied => 'steps_connect_denied'.tr(),
      HealthConnectConnectResult.storeOpened => null,
      HealthConnectConnectResult.unsupported =>
        'steps_sources_hc_unsupported'.tr(),
      HealthConnectConnectResult.unavailable => null,
    };
    if (message == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.commonBackground,
      appBar: CustomAppBar(title: 'steps_sources_title'.tr()),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.loading) {
            return Center(
              child: CircularProgressIndicator(color: context.colors.accentSub),
            );
          }
          return RefreshIndicator(
            color: context.colors.accentSub,
            onRefresh: _controller.refreshAll,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _TodayCard(controller: _controller),
                _Section(
                  title: 'steps_sources_phone'.tr(),
                  child: _PhoneCard(controller: _controller),
                ),
                _Section(
                  title: 'Health Connect',
                  child: _HealthConnectCard(
                    controller: _controller,
                    onConnect: _connect,
                  ),
                ),
                if (_controller.status.trackers.isNotEmpty)
                  _Section(
                    title: 'steps_sources_apps_title'.tr(),
                    child: _TrackersCard(controller: _controller),
                  ),
                _Section(
                  title: 'steps_sources_breakdown'.tr(),
                  child: _BreakdownCard(controller: _controller),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

String _formatSteps(BuildContext context, int value) =>
    NumberFormat.decimalPattern(context.locale.toString()).format(value);

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
          child: title.text(14, 18, 600).c(context.colors.textSub),
        ),
        child,
      ],
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child, this.padding = EdgeInsets.zero});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

class _RowsCard extends StatelessWidget {
  const _RowsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: 68,
                endIndent: 16,
                color: context.colors.strokeSoft,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.tint});

  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 22, color: tint),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.text,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(child: text.text(13, 20, 500).c(context.colors.textStrong)),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.controller});

  final StepSourcesController controller;

  @override
  Widget build(BuildContext context) {
    final ok = controller.counting;
    return _Surface(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.colors.accentGreenWhite,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Assets.icons.stepsHuman.svg(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    'steps_sources_today'
                        .tr()
                        .text(14, 18, 500)
                        .c(context.colors.textSub),
                    const SizedBox(height: 2),
                    _formatSteps(
                      context,
                      controller.snapshot.steps,
                    ).text(32, 38, 700).c(context.colors.textStrong),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Banner(
            icon: ok ? Icons.check_circle_rounded : Icons.error_rounded,
            text:
                (ok
                        ? 'steps_sources_counting_ok'
                        : 'steps_sources_counting_problem')
                    .tr(),
            color: ok ? context.colors.accentSub : context.colors.errorBase,
            background: ok
                ? context.colors.accentGreenWhite
                : context.colors.errorLighter,
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.ok,
    this.action,
    this.onAction,
    this.busy = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool? ok;
  final String? action;
  final VoidCallback? onAction;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final tint = switch (ok) {
      true => context.colors.accentSub,
      false => context.colors.warningBase,
      null => context.colors.iconSub,
    };
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconTile(icon: icon, tint: tint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: title
                          .text(15, 20, 600)
                          .c(context.colors.textStrong),
                    ),
                    if (ok == true)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 20,
                          color: context.colors.accentSub,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                subtitle.text(13, 18, 400).c(context.colors.textSub),
                if (action != null) ...[
                  const SizedBox(height: 12),
                  Button(
                    text: action,
                    height: 40,
                    radius: 10,
                    type: ok == false
                        ? ButtonType.primary
                        : ButtonType.secondary,
                    enabled: !busy,
                    onPressed: onAction,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneCard extends StatelessWidget {
  const _PhoneCard({required this.controller});

  final StepSourcesController controller;

  @override
  Widget build(BuildContext context) {
    final status = controller.status;
    final busy = controller.busy;
    final brand = status.manufacturer.isEmpty
        ? ''
        : status.manufacturer[0].toUpperCase() +
              status.manufacturer.substring(1);
    return _RowsCard(
      children: [
        _StatusRow(
          icon: Icons.directions_walk_rounded,
          title: 'steps_sources_activity'.tr(),
          subtitle:
              (status.activityRecognition
                      ? 'steps_sources_activity_on'
                      : 'steps_sources_activity_off')
                  .tr(),
          ok: status.activityRecognition,
          action: status.activityRecognition ? null : 'steps_action_allow'.tr(),
          onAction: controller.requestActivity,
          busy: busy,
        ),
        if (!status.sensorAvailable)
          _StatusRow(
            icon: Icons.sensors_off_rounded,
            title: 'steps_source_sensor'.tr(),
            subtitle: 'steps_sources_no_sensor'.tr(),
            ok: false,
          ),
        _StatusRow(
          icon: Icons.battery_charging_full_rounded,
          title: 'steps_sources_background'.tr(),
          subtitle:
              (status.batteryUnrestricted
                      ? 'steps_sources_background_on'
                      : 'steps_sources_background_off')
                  .tr(),
          ok: status.batteryUnrestricted,
          action: status.batteryUnrestricted ? null : 'steps_action_allow'.tr(),
          onAction: controller.requestBattery,
          busy: busy,
        ),
        if (status.autoStartScreen)
          _StatusRow(
            icon: Icons.rocket_launch_rounded,
            title: 'steps_sources_autostart'.tr(),
            subtitle: 'steps_sources_autostart_hint'.tr(
              namedArgs: {'brand': brand},
            ),
            ok: null,
            action: 'steps_action_open'.tr(),
            onAction: controller.openAutoStart,
            busy: busy,
          ),
        _StatusRow(
          icon: Icons.notifications_active_rounded,
          title: 'steps_sources_notification'.tr(),
          subtitle:
              (status.notifications
                      ? 'steps_sources_notification_on'
                      : 'steps_sources_notification_off')
                  .tr(),
          ok: status.notifications,
          action: status.notifications ? null : 'steps_action_allow'.tr(),
          onAction: controller.requestNotifications,
          busy: busy,
        ),
      ],
    );
  }
}

class _HealthConnectCard extends StatelessWidget {
  const _HealthConnectCard({required this.controller, required this.onConnect});

  final StepSourcesController controller;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final status = controller.status;
    final connected = status.healthConnectConnected;
    final availability = status.healthConnect;
    final (stateText, stateColor) = switch (availability) {
      _ when connected => (
        'steps_sources_hc_connected'.tr(),
        context.colors.accentSub,
      ),
      HealthConnectAvailability.available => (
        'steps_sources_hc_not_connected'.tr(),
        context.colors.warningBase,
      ),
      HealthConnectAvailability.notInstalled => (
        'steps_sources_hc_not_installed'.tr(),
        context.colors.warningBase,
      ),
      HealthConnectAvailability.updateRequired => (
        'steps_sources_hc_update'.tr(),
        context.colors.warningBase,
      ),
      HealthConnectAvailability.unsupported => (
        'steps_sources_hc_unsupported'.tr(),
        context.colors.textSub,
      ),
    };
    final needsBackground =
        connected &&
        status.healthConnectBackgroundAvailable &&
        !status.healthConnectBackgroundGranted;
    final String? primaryAction = switch (availability) {
      _ when needsBackground => 'steps_action_allow'.tr(),
      _ when connected => null,
      HealthConnectAvailability.available => 'steps_action_connect'.tr(),
      HealthConnectAvailability.notInstalled => 'steps_action_install'.tr(),
      HealthConnectAvailability.updateRequired => 'steps_action_update'.tr(),
      HealthConnectAvailability.unsupported => null,
    };
    final showSettings = availability == HealthConnectAvailability.available;
    final hcSteps = controller.snapshot.healthConnectSteps;

    return _Surface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HealthConnectLogo(size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    'Health Connect'
                        .text(16, 20, 600)
                        .c(context.colors.textStrong),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: stateColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: stateText.text(13, 18, 500).c(stateColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          'steps_sources_hc_desc'
              .tr()
              .text(13, 18, 400)
              .c(context.colors.textSub),
          if (connected && hcSteps != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: context.colors.backgroundElevation,
                borderRadius: BorderRadius.circular(12),
              ),
              child: 'steps_sources_hc_today'
                  .tr(namedArgs: {'steps': _formatSteps(context, hcSteps)})
                  .text(13, 18, 600)
                  .c(context.colors.textStrong),
            ),
          ],
          if (needsBackground) ...[
            const SizedBox(height: 12),
            _Banner(
              icon: Icons.warning_rounded,
              text: 'steps_sources_hc_background_off'.tr(),
              color: context.colors.warningBase,
              background: context.colors.warningLighter,
            ),
          ],
          if (primaryAction != null || showSettings) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (primaryAction != null)
                  Expanded(
                    child: Button(
                      text: primaryAction,
                      height: 44,
                      loading: controller.busy,
                      onPressed: onConnect,
                    ),
                  ),
                if (primaryAction != null && showSettings)
                  const SizedBox(width: 10),
                if (showSettings)
                  Expanded(
                    child: Button(
                      text: 'steps_action_settings'.tr(),
                      height: 44,
                      type: ButtonType.secondary,
                      enabled: !controller.busy,
                      onPressed: controller.openHealthConnect,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TrackersCard extends StatelessWidget {
  const _TrackersCard({required this.controller});

  final StepSourcesController controller;

  @override
  Widget build(BuildContext context) {
    final connected = controller.status.healthConnectConnected;
    return _RowsCard(
      children: [
        for (final tracker in controller.status.trackers)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TrackerLogo(id: tracker.id),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          tracker.name
                              .text(15, 20, 600)
                              .c(context.colors.textStrong),
                          const SizedBox(height: 2),
                          _trackerStatus(context, tracker, connected),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Button(
                      text: 'steps_action_open'.tr(),
                      width: 96,
                      height: 36,
                      radius: 10,
                      type: ButtonType.secondary,
                      enabled: !controller.busy,
                      onPressed: () => controller.openTracker(tracker),
                    ),
                  ],
                ),
                if (connected && !tracker.syncing) ...[
                  const SizedBox(height: 12),
                  _Banner(
                    icon: Icons.lightbulb_rounded,
                    text: trackerSetupHint(tracker),
                    color: context.colors.warningBase,
                    background: context.colors.warningLighter,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _trackerStatus(
    BuildContext context,
    TrackerAppStatus tracker,
    bool connected,
  ) {
    final (text, color) = switch ((connected, tracker.syncing)) {
      (true, true) => (
        'steps_sources_app_syncing'.tr(),
        context.colors.accentSub,
      ),
      (true, false) => (
        'steps_sources_app_not_syncing'.tr(),
        context.colors.warningBase,
      ),
      _ => ('steps_sources_app_needs_hc'.tr(), context.colors.textSub),
    };
    return text.text(13, 18, 500).c(color);
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.controller});

  final StepSourcesController controller;

  @override
  Widget build(BuildContext context) {
    final status = controller.status;
    final snapshot = controller.snapshot;
    String value(int? steps, bool available) =>
        available && steps != null ? _formatSteps(context, steps) : '—';
    final rows = [
      (
        Icons.smartphone_rounded,
        'steps_source_sensor'.tr(),
        value(snapshot.sensorSteps, status.canCountOnPhone),
      ),
      (
        Icons.favorite_rounded,
        'steps_source_hc'.tr(),
        value(snapshot.healthConnectSteps, status.healthConnectConnected),
      ),
      (
        Icons.history_rounded,
        'steps_source_recording'.tr(),
        value(snapshot.recordingSteps, status.recordingAvailable),
      ),
    ];
    return _Surface(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (final (icon, label, amount) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: context.colors.iconSoft),
                  const SizedBox(width: 10),
                  Expanded(
                    child: label.text(14, 18, 400).c(context.colors.textSub),
                  ),
                  amount.text(14, 18, 600).c(context.colors.textStrong),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: context.colors.accentGreenWhite,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: 'steps_source_calora'
                      .tr()
                      .text(15, 20, 600)
                      .c(context.colors.textStrong),
                ),
                _formatSteps(
                  context,
                  snapshot.steps,
                ).text(16, 20, 700).c(context.colors.accentSub),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: context.colors.iconSoft,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: 'steps_sources_merge_hint'
                    .tr()
                    .text(12, 17, 400)
                    .c(context.colors.textSub),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
