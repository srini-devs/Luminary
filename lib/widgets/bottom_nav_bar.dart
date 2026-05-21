import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_dimensions.dart';

enum NavTab { home, companion, journal, community, profile }

class BottomNavBar extends StatelessWidget {
  final NavTab activeTab;
  final ValueChanged<NavTab> onTabSelected;

  const BottomNavBar({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 24,
      right: 24,
      child: Container(
        height: AppDimensions.navBarHeight,
        decoration: BoxDecoration(
          color: AppColors.bgWhite,
          borderRadius: BorderRadius.circular(AppDimensions.navBarRadius),
          border: Border.all(color: AppColors.divider, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: NavTab.values.map((tab) {
              final isActive = tab == activeTab;
              return isActive
                  ? _ActiveTab(tab: tab, onTap: () => onTabSelected(tab))
                  : _InactiveTab(tab: tab, onTap: () => onTabSelected(tab));
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _ActiveTab extends StatelessWidget {
  final NavTab tab;
  final VoidCallback onTap;

  const _ActiveTab({required this.tab, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: true,
      label: _label(tab),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: AppColors.textPrimary,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_icon(tab), size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                _label(tab),
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InactiveTab extends StatelessWidget {
  final NavTab tab;
  final VoidCallback onTap;

  const _InactiveTab({required this.tab, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: false,
        label: _label(tab),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: SizedBox(
            height: 50,
            child: Center(
              child: Icon(
                _icon(tab),
                size: 16,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

IconData _icon(NavTab tab) {
  return switch (tab) {
    NavTab.home => Icons.home_outlined,
    NavTab.companion => Icons.chat_bubble_outline,
    NavTab.journal => Icons.article_outlined,
    NavTab.community => Icons.group_outlined,
    NavTab.profile => Icons.person_outline,
  };
}

String _label(NavTab tab) {
  return switch (tab) {
    NavTab.home => 'Home',
    NavTab.companion => 'Companion',
    NavTab.journal => 'Journal',
    NavTab.community => 'Community',
    NavTab.profile => 'Profile',
  };
}
