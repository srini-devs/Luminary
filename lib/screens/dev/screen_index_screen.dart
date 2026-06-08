import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../mock/mock_data.dart';
import '../../providers/dev_index_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/section_header.dart';
import '../../widgets/luminary_card.dart';

// Maps screen ID → display name
const _screenNames = {
  'S-01': 'Splash',
  'S-02': 'Welcome',
  'S-03': 'Loss — Who',
  'S-04': 'Loss — Dates',
  'S-05': 'Loss — Type',
  'S-06': 'Notification Permission',
  'S-07': 'Home Dashboard',
  'S-08': 'AI Companion Chat',
  'S-09': 'Daily Check-In',
  'S-10': 'Journal Home',
  'S-11': 'Journal — Prompted',
  'S-12': 'Journal — Freewrite',
  'S-13': 'Journal — Entry View',
  'S-14': 'Grief Wave',
  'S-15': 'Community Home',
  'S-16': 'Community Post View',
  'S-17': 'Community — Create Post',
  'S-18': 'Memory Home',
  'S-19': 'Memory — Add',
  'S-20': 'Memory — View',
  'S-21': 'Calendar',
  'S-22': 'Hard Date',
  'S-23': 'Paywall',
  'S-24': 'Settings',
  'S-25': 'Profile',
  'S-26': 'Sign Up',
  'S-27': 'Sign In',
  'S-28': 'Password Reset',
  'S-29': 'Offline State',
  'S-30': 'Check-In — Streak',
  'S-31': 'Companion — Opening (Hard Date)',
  'S-32': 'Companion — Opening (High Intensity)',
  'S-33': 'Grief Wave — History',
  'S-34': 'Journal — Filter',
  'S-35': 'Journal — Favourites',
  'S-36': 'Memory — Photo View',
  'S-37': 'Offline — Companion',
  'S-38': 'Community — Filter',
  'S-39': 'Check-In — Confirmation',
  'S-40': 'Calendar — Hard Date Detail',
  'S-41': 'Grief Wave — Entry',
  'S-42': 'Offline — Journal',
  'S-43': 'Community — Search',
  'S-44': 'Memory — Share with AI',
  'S-45': 'Companion — Crisis Panel',
  'S-46': 'Journal — Prompted Complete',
  'S-47': 'Paywall — Annual Plan',
  'S-48': 'Paywall — Trial Expired',
  'S-49': 'Settings — Notifications',
  'S-50': 'Settings — Accessibility',
  'S-51': 'Grief Wave — Trend',
  'S-52': 'Journal — Search',
  'S-53': 'Settings — Account',
  'S-54': 'About',
  'S-55': 'Community — My Posts',
  'S-56': 'Calendar — Upcoming',
  'S-57': 'Hard Date — 48h Banner',
  'S-58': 'Grief Wave — Monthly',
  'S-59': 'Companion — Session Summary',
  'S-60': 'Journal — Intensity Chart',
  'S-61': 'Profile — Edit',
  'S-62': 'Onboarding — Welcome',
  'S-63': 'Companion — Memory Controls',
  'S-64': 'Settings — Privacy',
  'S-65': 'Paywall — Restore',
  'S-66': 'Settings — Appearance',
  'S-67': 'Calendar — Month View',
  'S-68': 'Memory — Voice Note',
  'S-69': 'Check-In — Hard Date',
  'S-70': 'Offline — Sync Pending',
  'S-71': 'Companion — Offline Mode',
  'S-72': 'Hard Date — One Year',
  'S-73': 'Loss Profile — Edit',
  'S-74': 'Community — Resonated',
  'S-75': 'Check-In — Weekly View',
  'S-76': 'Offline — Memory',
  'S-77': 'Notification — Permission Denied',
  'S-78': 'Journal — Prompted List',
  'S-79': 'Check-In — Emotion Detail',
  'S-80': 'Paywall — Grace Period',
  'S-81': 'Grief Wave — Compare',
  'S-82': 'Offline — Checkin',
  'S-83': 'Companion — Welcome Message',
  'S-84': 'Journal — Hard Date Entry',
  'S-85': 'Community — Anonymous',
  'S-86': 'Check-In — Streak 7',
  'S-87': 'Memory — Grid View',
  'S-88': 'Paywall — Trial 3 Days',
  'S-89': 'Companion — Long Message',
  'S-90': 'Offline — Community',
  'S-91': 'Calendar — Add Custom Date',
  'S-92': 'Settings — Data',
  'S-93': 'Companion — Proactive',
  'S-94': 'Loss Profile — Pet',
  'S-95': 'Community — Post Types',
  'S-96': 'Memory — Sort',
  'S-97': 'Onboarding — Long Term',
  'S-98': 'Grief Wave — Spike',
  'S-99': 'Paywall — Cancelled',
  'S-100': 'Offline — Full',
};

// Maps screen ID → GoRouter route path — every screen is routable
const _screenRoutes = {
  'S-01': '/splash',
  'S-02': '/onboarding/welcome',
  'S-03': '/onboarding/who',
  'S-04': '/onboarding/dates',
  'S-05': '/onboarding/type',
  'S-06': '/onboarding/notifications',
  'S-07': '/home/dashboard',
  'S-08': '/home/companion',
  'S-09': '/checkin',
  'S-10': '/home/journal',
  'S-11': '/home/journal/prompted',
  'S-12': '/home/journal/freewrite',
  'S-13': '/home/journal?devState=entryview',
  'S-14': '/home/journal/wave',
  'S-15': '/home/community',
  'S-16': '/home/community?devState=postview',
  'S-17': '/home/community/create',
  'S-18': '/home/memory',
  'S-19': '/home/memory/add',
  'S-20': '/home/memory?devState=view',
  'S-21': '/calendar',
  'S-22': '/hard-date',
  'S-23': '/paywall',
  'S-24': '/settings',
  'S-25': '/home/profile',
  'S-26': '/sign-up',
  'S-27': '/sign-in',
  'S-28': '/password-reset',
  'S-29': '/home/dashboard?state=offline',
  'S-30': '/checkin?state=streak',
  'S-31': '/home/companion?state=harddate',
  'S-32': '/home/companion?state=highintensity',
  'S-33': '/home/journal/wave?state=history',
  'S-34': '/home/journal?state=filter',
  'S-35': '/home/journal?state=favourites',
  'S-36': '/home/memory?state=photo',
  'S-37': '/home/companion?state=offline',
  'S-38': '/home/community?state=empty',
  'S-39': '/checkin?state=confirmation',
  'S-40': '/calendar?state=harddate',
  'S-41': '/home/journal/wave?state=entry',
  'S-42': '/home/dashboard?state=hardatewarning',
  'S-43': '/home/community?state=search',
  'S-44': '/home/memory/add?state=voicenote',
  'S-45': '/home/companion?state=crisis',
  'S-46': '/home/journal?state=empty',
  'S-47': '/paywall?state=annual',
  'S-48': '/paywall?state=expired',
  'S-49': '/settings?state=notifications',
  'S-50': '/settings?state=accessibility',
  'S-51': '/home/journal/wave?range=3months',
  'S-52': '/home/journal?state=search',
  'S-53': '/settings?state=account',
  'S-54': '/about',
  'S-55': '/home/community?state=filter',
  'S-56': '/calendar?state=preview',
  'S-57': '/hard-date?state=48h',
  'S-58': '/home/journal/wave?state=annotation',
  'S-59': '/home/companion?state=summary',
  'S-60': '/home/journal?state=monthly',
  'S-61': '/home/profile?state=edit',
  'S-62': '/onboarding/welcome?state=longterm',
  'S-63': '/home/companion?state=offline',
  'S-64': '/settings?state=appearance',
  'S-65': '/home/profile?state=cancel',
  'S-66': '/settings?state=appearance',
  'S-67': '/hard-date?state=passed',
  'S-68': '/home/memory/add?state=voice',
  'S-69': '/checkin?state=harddate',
  'S-70': '/home/dashboard?state=empty',
  'S-71': '/home/companion?state=long',
  'S-72': '/hard-date?state=oneyear',
  'S-73': '/home/profile?state=editloss',
  'S-74': '/home/community/create?state=success',
  'S-75': '/checkin?state=weekly',
  'S-76': '/home/dashboard?state=postharddate',
  'S-77': '/onboarding/notifications?state=denied',
  'S-78': '/home/journal/freewrite?state=inprogress',
  'S-79': '/checkin?state=emotion',
  'S-80': '/home/memory?state=multiprofile',
  'S-81': '/home/journal/wave?range=alltime',
  'S-82': '/home/dashboard?state=return',
  'S-83': '/calendar?state=christmas',
  'S-84': '/home/journal?state=saving',
  'S-85': '/home/community/my-posts',
  'S-86': '/checkin?state=streak7',
  'S-87': '/home/memory?state=grid',
  'S-88': '/paywall?state=error',
  'S-89': '/home/companion?state=new',
  'S-90': '/home/dashboard?state=peaceful',
  'S-91': '/hard-date?state=oneyear',
  'S-92': '/settings/export',
  'S-93': '/home/companion?state=proactive',
  'S-94': '/home/profile?state=pet',
  'S-95': '/home/community?state=oneyear',
  'S-96': '/home/memory?state=oneyear',
  'S-97': '/onboarding/welcome?state=longterm',
  'S-98': '/home/journal/wave?state=empty',
  'S-99': '/home/profile?state=active',
  'S-100': '/home/dashboard?state=peacefulday',
};

// Sections: section name → list of screen IDs
const _sections = [
  ('AUTH & ONBOARDING', ['S-01', 'S-02', 'S-03', 'S-04', 'S-05', 'S-06', 'S-26', 'S-27', 'S-28']),
  ('HOME & DASHBOARD', ['S-07']),
  ('AI COMPANION', ['S-08', 'S-31', 'S-32', 'S-45', 'S-63', 'S-71', 'S-89']),
  ('DAILY CHECK-IN', ['S-09', 'S-30', 'S-39', 'S-69', 'S-75', 'S-79', 'S-86']),
  ('JOURNAL', ['S-10', 'S-11', 'S-12', 'S-13', 'S-34', 'S-35', 'S-46', 'S-52', 'S-60', 'S-78', 'S-84', 'S-87']),
  ('GRIEF WAVE', ['S-14', 'S-33', 'S-41', 'S-51', 'S-58', 'S-81', 'S-98']),
  ('COMMUNITY', ['S-15', 'S-16', 'S-17', 'S-38', 'S-43', 'S-55', 'S-74', 'S-85', 'S-95']),
  ('MEMORY SPACE', ['S-18', 'S-19', 'S-20', 'S-36', 'S-44', 'S-68', 'S-87', 'S-96']),
  ('CALENDAR & HARD DATE', ['S-21', 'S-22', 'S-40', 'S-56', 'S-67', 'S-91']),
  ('PAYWALL & SUBSCRIPTION', ['S-23', 'S-47', 'S-48', 'S-65', 'S-88', 'S-99']),
  ('SETTINGS & PROFILE', ['S-24', 'S-25', 'S-49', 'S-50', 'S-53', 'S-54', 'S-64', 'S-66', 'S-92']),
  ('EDGE & OFFLINE STATES', ['S-29', 'S-37', 'S-42', 'S-70', 'S-76', 'S-82', 'S-90', 'S-100']),
];

class ScreenIndexScreen extends ConsumerStatefulWidget {
  const ScreenIndexScreen({super.key});

  @override
  ConsumerState<ScreenIndexScreen> createState() => _ScreenIndexScreenState();
}

class _ScreenIndexScreenState extends ConsumerState<ScreenIndexScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  int _mockUserIndex = 0;
  static const _mockUserNames = ['Sarah (6mo)', 'James (45d)', 'Priya (Pet/Expired)'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset the dev overlay when this screen becomes the top route again (e.g., after natural pop)
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(devFromIndexProvider.notifier).state = false;
          ref.read(devStateProvider.notifier).state = null;
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigate(String screenId) {
    final route = _screenRoutes[screenId]!;
    HapticFeedback.lightImpact();
    final uri = Uri.parse(route);
    final stateVal = uri.queryParameters['state'] ??
        uri.queryParameters['range'] ??
        uri.queryParameters['devState'];
    ref.read(devStateProvider.notifier).state = stateVal;
    ref.read(devFromIndexProvider.notifier).state = true;
    context.push(route);
  }

  bool _matches(String id) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    final name = _screenNames[id]?.toLowerCase() ?? '';
    return id.toLowerCase().contains(q) || name.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    // Build flat list of all sections + filtered items
    final List<Widget> items = [];

    for (final section in _sections) {
      final name = section.$1;
      final ids = section.$2;
      final filtered = ids.where(_matches).toList();
      if (filtered.isEmpty) continue;

      items.add(SectionHeader(name));
      for (final id in filtered) {
        final screenName = _screenNames[id] ?? id;
        final route = _screenRoutes[id]!;
        final uri = Uri.parse(route);
        final stateTag = uri.queryParameters['state'] ??
            uri.queryParameters['range'] ??
            uri.queryParameters['devState'];
        items.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: LuminaryCard(
              onTap: () => _navigate(id),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warmAmber,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        id,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            screenName,
                            style: AppTextStyles.bodyMedium.copyWith(fontSize: 15),
                          ),
                          if (stateTag != null)
                            Text(
                              stateTag,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.softPurple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: AppColors.bgGray,
      appBar: AppBar(
        backgroundColor: AppColors.bgGray,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            context.pop();
          },
          child: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary),
        ),
        title: Text(
          'All Screens (${_screenNames.length})',
          style: AppTextStyles.screenTitle,
        ),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.pop();
            },
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.bgWhite,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider, width: 1.5),
              ),
              child: const Icon(Icons.close, size: 16, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // User switcher
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader('SIMULATE USER'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: List.generate(3, (i) {
                    return GestureDetector(
                      onTap: () async {
                        HapticFeedback.selectionClick();
                        setState(() => _mockUserIndex = i);
                        final messenger = ScaffoldMessenger.of(context);
                        final name = _mockUserNames[i];
                        await MockDataService.loadUser(i, ref);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Simulating $name'),
                            backgroundColor: AppColors.sageGreen,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _mockUserIndex == i ? AppColors.softPurple : AppColors.bgWhite,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: _mockUserIndex == i ? AppColors.softPurple : AppColors.divider,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          _mockUserNames[i],
                          style: TextStyle(
                            color: _mockUserIndex == i ? Colors.white : AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                // Search bar
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.bgWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider, width: 1.5),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    style: AppTextStyles.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Search by name or S-number…',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                      prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textTertiary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          // Screen list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: items,
            ),
          ),
        ],
      ),
    );
  }
}
