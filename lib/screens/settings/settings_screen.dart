import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/section_header.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifs = ref.watch(notificationProvider);
    final user = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.bgGray,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  _CircleBtn(
                    onTap: () => context.pop(),
                    child: const Text('‹',
                        style: TextStyle(
                            fontSize: 22,
                            color: AppColors.textSecondary)),
                  ),
                  Expanded(
                    child: Text('Settings',
                        style: AppTextStyles.screenTitle,
                        textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                children: [
                  // ── Notifications ────────────────────────────────────
                  SectionHeader('NOTIFICATIONS',
                      padding: const EdgeInsets.fromLTRB(
                          2, 0, 2, 10)),
                  _SettingsCard(children: [
                    _ToggleRow(
                      label: 'Hard date reminders',
                      value: notifs.hardDateRemindersEnabled,
                      onChanged: (_) => ref
                          .read(notificationProvider.notifier)
                          .toggleHardDateReminders(),
                    ),
                    _Divider(),
                    _ToggleRow(
                      label: 'Daily check-in reminder',
                      value: notifs.checkinRemindersEnabled,
                      onChanged: (_) => ref
                          .read(notificationProvider.notifier)
                          .toggleCheckinReminders(),
                    ),
                    _Divider(),
                    _NavRow(
                      label: 'Notification settings',
                      onTap: () => _showNotifDetail(context, ref),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ── Appearance ───────────────────────────────────────
                  SectionHeader('APPEARANCE',
                      padding: const EdgeInsets.fromLTRB(
                          2, 0, 2, 10)),
                  _SettingsCard(children: [
                    _ToggleRow(
                      label: 'Larger text',
                      subtitle: 'Increases body font size',
                      value: user?.largerText ?? false,
                      onChanged: (_) => ref
                          .read(userProfileProvider.notifier)
                          .toggleLargerText(),
                    ),
                    _Divider(),
                    _ToggleRow(
                      label: 'Reduce motion',
                      subtitle:
                          'Disables animations across the app',
                      value: user?.reducedMotion ?? false,
                      onChanged: (_) => ref
                          .read(userProfileProvider.notifier)
                          .toggleReducedMotion(),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ── Account ──────────────────────────────────────────
                  SectionHeader('ACCOUNT',
                      padding: const EdgeInsets.fromLTRB(
                          2, 0, 2, 10)),
                  _SettingsCard(children: [
                    _NavRow(
                      label: 'Manage subscription',
                      onTap: () => context.push('/home/profile'),
                    ),
                    _Divider(),
                    _NavRow(
                      label: 'Download my data',
                      onTap: () => context.push('/settings/export'),
                    ),
                    _Divider(),
                    _NavRow(
                      label: 'About Luminary',
                      onTap: () => context.push('/about'),
                    ),
                    _Divider(),
                    _NavRow(
                      label: 'Sign out',
                      onTap: () => _confirmSignOut(context, ref),
                      leadingIcon: Icons.person_off_outlined,
                      color: AppColors.dustyRose,
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ── Danger Zone ──────────────────────────────────────
                  SectionHeader('DANGER ZONE',
                      padding: const EdgeInsets.fromLTRB(
                          2, 0, 2, 10)),
                  _SettingsCard(children: [
                    _DangerRow(
                      label: 'Delete my account',
                      onTap: () =>
                          _confirmDelete(context, ref),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotifDetail(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgWhite,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Consumer(builder: (ctx, ref, _) {
          final n = ref.watch(notificationProvider);
          return Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).padding.bottom + 80),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notification settings',
                    style: AppTextStyles.screenTitle
                        .copyWith(fontSize: 18)),
                const SizedBox(height: 16),
                _SettingsCard(children: [
                  _ToggleRow(
                    label: 'Hard date reminders',
                    value: n.hardDateRemindersEnabled,
                    onChanged: (_) => ref
                        .read(notificationProvider.notifier)
                        .toggleHardDateReminders(),
                  ),
                  _Divider(),
                  _ToggleRow(
                    label: 'Daily check-in reminder',
                    value: n.checkinRemindersEnabled,
                    onChanged: (_) => ref
                        .read(notificationProvider.notifier)
                        .toggleCheckinReminders(),
                  ),
                ]),
              ],
            ),
          );
      }),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Sign out?',
          style: AppTextStyles.screenTitle.copyWith(fontSize: 18),
        ),
        content: Text(
          'Your data stays saved and will be here when you return.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel',
                style: AppTextStyles.buttonLabel
                    .copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(appStateProvider.notifier).setSessionActive(false);
            },
            child: Text('Sign out',
                style: AppTextStyles.buttonLabel
                    .copyWith(color: AppColors.dustyRose)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Delete your account?',
          style: AppTextStyles.screenTitle
              .copyWith(fontSize: 18),
        ),
        content: Text(
          'All your journal entries, memories, and companion conversations will be permanently deleted. This cannot be undone.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel',
                style: AppTextStyles.buttonLabel.copyWith(
                    color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // TODO(backend): Delete all user data from Supabase
              ref.read(userProfileProvider.notifier).signOut();
              context.go('/splash');
            },
            child: Text('Delete everything',
                style: AppTextStyles.buttonLabel
                    .copyWith(color: AppColors.dustyRose)),
          ),
        ],
      ),
    );
  }
}

// ── Shared components ─────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius:
            BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(
            color: AppColors.cardBorder, width: 2),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label, ${value ? 'enabled' : 'disabled'}, toggle',
      button: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.bodyMedium
                          .copyWith(
                              fontWeight: FontWeight.w600)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: AppTextStyles.caption),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                onChanged(v);
              },
              activeThumbColor: AppColors.sageGreen,
              activeTrackColor:
                  AppColors.sageGreen.withAlpha(80),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? leadingIcon;
  final Color? color;

  const _NavRow({
    required this.label,
    required this.onTap,
    this.leadingIcon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 16),
          child: Row(
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: 18, color: c),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(label,
                    style: AppTextStyles.bodyMedium
                        .copyWith(
                          fontWeight: FontWeight.w600,
                          color: c,
                        )),
              ),
              Icon(Icons.chevron_right,
                  size: 18,
                  color: color ?? AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _DangerRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DangerRow(
      {required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.heavyImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(label,
                    style: AppTextStyles.bodyMedium
                        .copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.dustyRose,
                    )),
              ),
              const Icon(Icons.chevron_right,
                  size: 18,
                  color: AppColors.dustyRose),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
        height: 1, thickness: 1, color: Color(0xFFF0F0F0));
  }
}

class _CircleBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _CircleBtn({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.bgGray,
          shape: BoxShape.circle,
          border:
              Border.all(color: AppColors.divider, width: 1.5),
        ),
        child: Center(child: child),
      ),
    );
  }
}
