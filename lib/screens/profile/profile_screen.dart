import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_profile.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/loss_profile_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/luminary_button.dart';
import '../../widgets/section_header.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email') ?? 'No email found';
    if (mounted) setState(() => _email = email);
  }

  Future<void> _signOut(BuildContext context) async {
    await ref.read(appStateProvider.notifier).setSessionActive(false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('first_dashboard_visit');
    await prefs.remove('last_app_open');
  }

  void _showSignOutDialog(BuildContext context) {
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
            onPressed: () {
              Navigator.of(context).pop();
              _signOut(context);
            },
            child: Text('Sign out',
                style: AppTextStyles.buttonLabel
                    .copyWith(color: AppColors.dustyRose)),
          ),
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Cancel subscription?',
            style: AppTextStyles.screenTitle
                .copyWith(fontSize: 18)),
        content: Text(
          'You\'ll keep access until the end of your billing period.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            child: Text('Keep subscription',
                style: AppTextStyles.buttonLabel
                    .copyWith(
                        color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.heavyImpact();
              Navigator.of(context).pop();
              // TODO(backend): Call RevenueCat cancellation API
            },
            child: Text('Cancel subscription',
                style: AppTextStyles.buttonLabel
                    .copyWith(color: AppColors.dustyRose)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);
    final profile = ref.watch(lossProfileProvider);
    final dateFmt = DateFormat('d MMMM yyyy');

    final subLabel = switch (user?.subscriptionStatus) {
      SubscriptionStatus.trial => 'Free trial',
      SubscriptionStatus.active => 'Active',
      SubscriptionStatus.cancelled => 'Cancelled',
      SubscriptionStatus.expired => 'Expired',
      SubscriptionStatus.gracePeriod => 'Grace period',
      null => 'Unknown',
    };

    final renewalDate = user?.trialEndDate;
    final isMonthly =
        user?.subscriptionStatus == SubscriptionStatus.active;
    final isActive = user?.subscriptionStatus ==
            SubscriptionStatus.active ||
        user?.subscriptionStatus == SubscriptionStatus.trial;

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
                  if (context.canPop())
                    _CircleBtn(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.pop();
                      },
                      child: const Text('‹',
                          style: TextStyle(
                              fontSize: 22,
                              color: AppColors.textSecondary)),
                    )
                  else
                    const SizedBox(width: 40),
                  Expanded(
                    child: Text('My Profile',
                        style: AppTextStyles.screenTitle,
                        textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    20, 20, 20, 40),
                children: [
                  // ── Account ───────────────────────────────────────
                  SectionHeader('YOUR ACCOUNT',
                      padding: const EdgeInsets.fromLTRB(
                          2, 0, 2, 10)),
                  _InfoCard(children: [
                    _InfoRow(
                        label: 'Email',
                        value: _email.isNotEmpty ? _email : '—'),
                    _Divider(),
                    _InfoRow(
                      label: 'Plan',
                      value: subLabel,
                      valueColor: isActive
                          ? AppColors.sageGreen
                          : AppColors.dustyRose,
                      valueSuffix: isActive
                          ? const _ActiveBadge()
                          : null,
                    ),
                    if (renewalDate != null) ...[
                      _Divider(),
                      _InfoRow(
                        label: user?.subscriptionStatus ==
                                SubscriptionStatus.trial
                            ? 'Trial ends'
                            : 'Renews',
                        value: dateFmt.format(renewalDate),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 16),

                  // Subscription status card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.amberTint
                          : AppColors.purpleTint,
                      borderRadius: BorderRadius.circular(
                          AppDimensions.cardRadius),
                      border: Border.all(
                          color: isActive
                              ? AppColors.warmAmber
                              : AppColors.softPurple,
                          width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          isActive
                              ? 'Your Luminary access is active.'
                              : 'Your access has ended.',
                          style:
                              AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (renewalDate != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            user?.subscriptionStatus ==
                                    SubscriptionStatus.trial
                                ? 'Trial expires ${dateFmt.format(renewalDate)}'
                                : 'Next billing date: ${dateFmt.format(renewalDate)}',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Upgrade or cancel actions
                  if (isMonthly) ...[
                    Semantics(
                      label:
                          'Upgrade to annual plan and save 42 percent',
                      button: true,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.push('/paywall');
                        },
                        child: Container(
                          height:
                              AppDimensions.buttonHeight,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.bgWhite,
                            borderRadius:
                                BorderRadius.circular(
                                    AppDimensions
                                        .buttonRadius),
                            border: Border.all(
                                color: AppColors.softPurple,
                                width: 2.5),
                            boxShadow: const [
                              BoxShadow(
                                color:
                                    AppColors.softPurple,
                                offset: Offset(3, 3),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Text(
                            'Upgrade to annual — save 42%',
                            style: AppTextStyles.buttonLabel,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Semantics(
                        label: 'Cancel subscription',
                        button: true,
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.heavyImpact();
                            _confirmCancel(context);
                          },
                          child: Text(
                            'Cancel subscription',
                            style: AppTextStyles.caption
                                .copyWith(
                              color: AppColors.dustyRose,
                              decoration:
                                  TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Loss Profiles ─────────────────────────────────
                  SectionHeader('YOUR LOSS PROFILES',
                      padding: const EdgeInsets.fromLTRB(
                          2, 0, 2, 10)),
                  if (profile != null)
                    _LossProfileCard(
                      name: profile.deceasedName,
                      relationship:
                          profile.relationship.name,
                      dateOfDeath: profile.dateOfDeath,
                      dateFmt: dateFmt,
                      onEdit: () {
                        HapticFeedback.lightImpact();
                        // TODO(navigation): Navigate to onboarding screens in edit mode
                        // Pre-fill all fields from existing LossProfile
                        context.push('/onboarding/who');
                      },
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8),
                      child: Text(
                        'No loss profile set up yet.',
                        style: AppTextStyles.caption,
                      ),
                    ),
                  const SizedBox(height: 10),
                  // Add another person
                  Semantics(
                    label: 'Add another person',
                    button: true,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        // TODO(navigation): Navigate to onboarding in add-profile mode (S-53)
                        context.push('/onboarding/who');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.bgWhite,
                          borderRadius:
                              BorderRadius.circular(
                                  AppDimensions.cardRadius),
                          border: Border.all(
                              color: AppColors.cardBorder,
                              width: 2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.add_circle_outline,
                                size: 20,
                                color: AppColors.textSecondary),
                            const SizedBox(width: 12),
                            Text('Add another person',
                                style: AppTextStyles.bodyMedium
                                    .copyWith(
                                        color: AppColors
                                            .textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 32),
                  LuminaryButton(
                    label: 'Sign out',
                    style: LuminaryButtonStyle.ghost,
                    onTap: () => _showSignOutDialog(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

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
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? valueSuffix;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueSuffix,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary)),
          Row(
            children: [
              Text(value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  )),
              ?valueSuffix,
            ],
          ),
        ],
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(
          horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.sageGreen,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text('Active',
          style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 10)),
    );
  }
}

class _LossProfileCard extends StatelessWidget {
  final String name;
  final String relationship;
  final DateTime dateOfDeath;
  final DateFormat dateFmt;
  final VoidCallback onEdit;

  const _LossProfileCard({
    required this.name,
    required this.relationship,
    required this.dateOfDeath,
    required this.dateFmt,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = now.difference(dateOfDeath);
    final weeks = (diff.inDays / 7).floor();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius:
            BorderRadius.circular(AppDimensions.cardRadius),
        border:
            Border.all(color: AppColors.cardBorder, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTextStyles.bodyMedium
                        .copyWith(
                            fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  '$relationship · $weeks weeks ago',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 2),
                Text(
                  dateFmt.format(dateOfDeath),
                  style: AppTextStyles.caption
                      .copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          Semantics(
            label: 'Edit $name profile',
            button: true,
            child: GestureDetector(
              onTap: onEdit,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.bgGray,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.divider,
                      width: 1.5),
                ),
                child: const Icon(Icons.edit_outlined,
                    size: 16,
                    color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
        height: 1,
        thickness: 1,
        color: Color(0xFFF0F0F0));
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
          border: Border.all(
              color: AppColors.divider, width: 1.5),
        ),
        child: Center(child: child),
      ),
    );
  }
}
