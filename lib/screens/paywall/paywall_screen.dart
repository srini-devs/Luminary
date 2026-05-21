import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/dev_index_provider.dart';
import '../../providers/grief_calendar_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/revenue_cat_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/candle_icon.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  /// When true the user may dismiss the paywall.
  final bool dismissible;

  const PaywallScreen({super.key, this.dismissible = false});

  @override
  ConsumerState<PaywallScreen> createState() =>
      _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _loadingMonthly = false;
  bool _loadingAnnual = false;
  bool _loadingRestore = false;
  bool _success = false;
  String? _errorMessage;

  Future<void> _purchaseMonthly() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _loadingMonthly = true;
      _errorMessage = null;
    });
    try {
      final ok = await ref
          .read(revenueCatServiceProvider)
          .purchaseMonthly();
      if (ok && mounted) _onSuccess();
    } catch (_) {
      if (mounted) {
        setState(() =>
            _errorMessage = 'Purchase failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loadingMonthly = false);
    }
  }

  Future<void> _purchaseAnnual() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _loadingAnnual = true;
      _errorMessage = null;
    });
    try {
      final ok = await ref
          .read(revenueCatServiceProvider)
          .purchaseAnnual();
      if (ok && mounted) _onSuccess();
    } catch (_) {
      if (mounted) {
        setState(() =>
            _errorMessage = 'Purchase failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loadingAnnual = false);
    }
  }

  Future<void> _restore() async {
    HapticFeedback.mediumImpact();
    setState(() => _loadingRestore = true);
    try {
      await ref.read(revenueCatServiceProvider).restorePurchases();
    } finally {
      if (mounted) setState(() => _loadingRestore = false);
    }
  }

  void _extendTrial() {
    ref.read(userProfileProvider.notifier).extendTrial();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Trial extended by 3 days.')),
    );
    if (context.canPop()) context.pop();
  }

  void _onSuccess() {
    setState(() => _success = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && context.canPop()) context.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final next3 = ref.watch(next3HardDatesProvider);
    final dateFmt = DateFormat('d MMM yyyy');
    final devState = ref.watch(devStateProvider);
    final isLoading = _loadingMonthly || _loadingAnnual ||
        devState == 'loading' || devState == 'annual';
    final canExtend =
        ref.read(userProfileProvider.notifier).canExtendTrial;

    if (_success || devState == 'success') return _SuccessView();
    if (devState == 'error') {
      // Fall through with error message pre-set
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _errorMessage == null) {
          setState(() => _errorMessage = 'Purchase failed. Please try again.');
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            if (widget.dismissible)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      0, 12, 20, 0),
                  child: Semantics(
                    label: 'Close paywall',
                    button: true,
                    child: GestureDetector(
                      onTap: () {
                        if (context.canPop()) context.pop();
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.bgGray,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 18,
                            color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    28, 8, 28, 40),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // Personalized dates card
                    if (next3.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.amberTint,
                          borderRadius:
                              BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.warmAmber,
                              width: 2),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Semantics(
                                  label:
                                      'Luminary candle',
                                  excludeSemantics: true,
                                  child:
                                      CandleIcon(size: 20),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Luminary will be with you for all of these.',
                                    style: AppTextStyles
                                        .bodyMedium
                                        .copyWith(
                                            fontWeight:
                                                FontWeight
                                                    .w600,
                                            fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...next3.map((e) => Padding(
                                  padding: const EdgeInsets
                                      .only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Semantics(
                                        excludeSemantics:
                                            true,
                                        child: CandleIcon(
                                            size: 14),
                                      ),
                                      const SizedBox(
                                          width: 8),
                                      Expanded(
                                        child: Text(
                                          e.label,
                                          style: AppTextStyles
                                              .bodyMedium
                                              .copyWith(
                                                  fontSize:
                                                      14),
                                        ),
                                      ),
                                      Text(
                                        dateFmt
                                            .format(e.date),
                                        style: AppTextStyles
                                            .caption.copyWith(
                                                fontWeight:
                                                    FontWeight
                                                        .w600),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Headline
                    Text(
                      'Keep the light on.',
                      style: AppTextStyles.displayH1
                          .copyWith(fontSize: 30),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your AI companion, grief journal, community, and memory space — always with you.',
                      style: AppTextStyles.bodyMedium
                          .copyWith(
                              color:
                                  AppColors.textSecondary,
                              height: 1.6),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    // Annual plan (dominant)
                    Semantics(
                      label:
                          'Annual plan, \$69.99 per year, save 42 percent, best value',
                      button: true,
                      child: GestureDetector(
                        onTap:
                            isLoading ? null : _purchaseAnnual,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(
                                  20),
                              decoration: BoxDecoration(
                                color: AppColors.bgWhite,
                                borderRadius:
                                    BorderRadius.circular(
                                        AppDimensions
                                            .cardRadius),
                                border: Border.all(
                                    color: AppColors
                                        .softPurple,
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
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    '\$69.99 / year',
                                    style: AppTextStyles
                                        .displayH1
                                        .copyWith(
                                            fontSize: 24),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        'Save 42%',
                                        style: AppTextStyles
                                            .caption
                                            .copyWith(
                                          color: AppColors
                                              .sageGreen,
                                          fontWeight:
                                              FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(
                                          width: 6),
                                      Text(
                                        'billed annually',
                                        style: AppTextStyles
                                            .caption,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  _loadingAnnual
                                      ? const Center(
                                          child:
                                              CircularProgressIndicator(
                                            color: AppColors
                                                .softPurple,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Container(
                                          height: 44,
                                          alignment:
                                              Alignment.center,
                                          decoration:
                                              BoxDecoration(
                                            color: AppColors
                                                .softPurple,
                                            borderRadius:
                                                BorderRadius
                                                    .circular(
                                                        10),
                                          ),
                                          child: Text(
                                            'Start with annual',
                                            style: AppTextStyles
                                                .buttonLabel
                                                .copyWith(
                                                    color: Colors
                                                        .white),
                                          ),
                                        ),
                                ],
                              ),
                            ),
                            // BEST VALUE badge
                            Positioned(
                              top: -10,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets
                                    .symmetric(
                                    horizontal: 10,
                                    vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.softPurple,
                                  borderRadius:
                                      BorderRadius.circular(
                                          100),
                                ),
                                child: Text(
                                  'BEST VALUE',
                                  style: AppTextStyles
                                      .caption
                                      .copyWith(
                                    color: Colors.white,
                                    fontWeight:
                                        FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Monthly plan
                    Semantics(
                      label:
                          'Monthly plan, \$9.99 per month',
                      button: true,
                      child: GestureDetector(
                        onTap:
                            isLoading ? null : _purchaseMonthly,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.bgWhite,
                            borderRadius:
                                BorderRadius.circular(
                                    AppDimensions.cardRadius),
                            border: Border.all(
                                color: AppColors.divider,
                                width: 2),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                '\$9.99 / month',
                                style: AppTextStyles
                                    .screenTitle,
                              ),
                              const SizedBox(height: 4),
                              Text('billed monthly',
                                  style: AppTextStyles
                                      .caption),
                              const SizedBox(height: 14),
                              _loadingMonthly
                                  ? const Center(
                                      child:
                                          CircularProgressIndicator(
                                        color: AppColors
                                            .warmAmber,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Container(
                                      height: 44,
                                      alignment:
                                          Alignment.center,
                                      decoration: BoxDecoration(
                                        color: AppColors.bgGray,
                                        borderRadius:
                                            BorderRadius
                                                .circular(10),
                                        border: Border.all(
                                            color: AppColors
                                                .divider,
                                            width: 1.5),
                                      ),
                                      child: Text(
                                        'Start monthly',
                                        style: AppTextStyles
                                            .buttonLabel
                                            .copyWith(
                                          color: AppColors
                                              .textSecondary,
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Error state
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              AppColors.dustyRose.withAlpha(20),
                          borderRadius:
                              BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.dustyRose,
                              width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                size: 18,
                                color: AppColors.dustyRose),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: AppTextStyles.caption
                                    .copyWith(
                                        color: AppColors
                                            .dustyRose),
                              ),
                            ),
                            GestureDetector(
                              onTap: _purchaseAnnual,
                              child: Text('Retry',
                                  style:
                                      AppTextStyles.caption
                                          .copyWith(
                                    color: AppColors.dustyRose,
                                    fontWeight: FontWeight.w700,
                                  )),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Ghost links
                    if (canExtend) ...[
                      Center(
                        child: Semantics(
                          label:
                              'Extend my trial by 3 days',
                          button: true,
                          child: GestureDetector(
                            onTap: _extendTrial,
                            child: Text(
                              'Extend my trial 3 days',
                              style: AppTextStyles.caption
                                  .copyWith(
                                color: AppColors.warmAmber,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Center(
                      child: Semantics(
                        label: 'Restore purchases',
                        button: true,
                        child: GestureDetector(
                          onTap:
                              _loadingRestore ? null : _restore,
                          child: _loadingRestore
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color:
                                        AppColors.textTertiary,
                                  ),
                                )
                              : Text(
                                  'Restore purchases',
                                  style: AppTextStyles.caption
                                      .copyWith(
                                    color:
                                        AppColors.textTertiary,
                                    decoration:
                                        TextDecoration
                                            .underline,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CandleIcon(size: 64),
            const SizedBox(height: 24),
            Text(
              'Welcome to Luminary.',
              style: AppTextStyles.displayH1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "You're not alone anymore.",
              style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
