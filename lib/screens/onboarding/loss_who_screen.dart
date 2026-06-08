import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../models/loss_profile.dart';
import '../../providers/loss_profile_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/luminary_button.dart';
import '../../widgets/luminary_chip.dart';
import '../../widgets/luminary_text_field.dart';
import '../../widgets/section_header.dart';

const _uuid = Uuid();

class LossWhoScreen extends ConsumerStatefulWidget {
  const LossWhoScreen({super.key});

  @override
  ConsumerState<LossWhoScreen> createState() => _LossWhoScreenState();
}

class _LossWhoScreenState extends ConsumerState<LossWhoScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  RelationshipType? _selectedRelationship;
  String? _nameError;
  String? _relationshipError;

  static const _relationships = [
    (RelationshipType.spouse, 'Spouse / Partner'),
    (RelationshipType.parent, 'Parent'),
    (RelationshipType.child, 'Child'),
    (RelationshipType.sibling, 'Sibling'),
    (RelationshipType.friend, 'Friend'),
    (RelationshipType.pet, 'Pet'),
    (RelationshipType.other, 'Other'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _continue() {
    setState(() {
      _nameError = null;
      _relationshipError = null;
    });

    bool valid = true;
    if (_nameController.text.trim().isEmpty) {
      setState(() => _nameError = 'Please enter their name');
      valid = false;
    }
    if (_selectedRelationship == null) {
      setState(() => _relationshipError = 'Please select your relationship');
      valid = false;
    }
    if (!valid) return;

    final existing = ref.read(lossProfileProvider);
    final isPet = _selectedRelationship == RelationshipType.pet;
    final profile = LossProfile(
      id: existing?.id ?? _uuid.v4(),
      deceasedName: _nameController.text.trim(),
      relationship: _selectedRelationship!,
      isPet: isPet,
      personalDescription: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      dateOfDeath: existing?.dateOfDeath ?? DateTime.now().subtract(const Duration(days: 30)),
      lossType: existing?.lossType ?? LossType.sudden,
      trackedHolidays: existing?.trackedHolidays ?? [],
    );
    ref.read(lossProfileProvider.notifier).saveLossProfile(profile);
    // Fire-and-forget: persist step in background, navigate immediately
    ref.read(lossProfileProvider.notifier).saveOnboardingStep('3');
    _saveWhoKeys(
      name: _nameController.text.trim(),
      relationship: _selectedRelationship!,
      description: _descriptionController.text.trim(),
    );
    context.go('/onboarding/dates');
  }

  Future<void> _saveWhoKeys({
    required String name,
    required RelationshipType relationship,
    required String description,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('deceased_name', name);
    await prefs.setString('relationship', relationship.name);
    if (description.isNotEmpty) {
      await prefs.setString('personal_description', description);
    } else {
      await prefs.remove('personal_description');
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _nameController.text.trim();
    final displayName = name.isEmpty ? '[name]' : name;

    return Scaffold(
      backgroundColor: AppColors.bgGray,
      body: SafeArea(
        child: Column(
          children: [
            // Non-scrollable header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/onboarding/welcome'),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.bgWhite,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.divider, width: 1.5),
                          ),
                          child: const Center(
                            child: Text('‹',
                                style: TextStyle(
                                    fontSize: 22,
                                    color: AppColors.textSecondary)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _ProgressDots(activeIndex: 0),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Tell me about\nwho you lost.',
                    style: AppTextStyles.displayH1,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This helps Luminary remember who matters most to you.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
              ),
            ),
            // Scrollable body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LuminaryTextField(
                      label: 'THEIR NAME',
                      hint: 'Name...',
                      controller: _nameController,
                      isActive: true,
                      errorText: _nameError,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SectionHeader('YOUR RELATIONSHIP'),
                    if (_relationshipError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          _relationshipError!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.dustyRose,
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _relationships.map((r) {
                        return LuminaryChip(
                          label: r.$2,
                          isSelected: _selectedRelationship == r.$1,
                          onTap: () => setState(() {
                            _selectedRelationship = r.$1;
                            _relationshipError = null;
                          }),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 22),
                    LuminaryTextField(
                      label: 'A FEW WORDS ABOUT $displayName — OPTIONAL',
                      hint: 'She was my anchor…',
                      controller: _descriptionController,
                      maxLines: 3,
                    ),
                    LuminaryButton(
                      label: 'Continue',
                      onTap: _continue,
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

class _ProgressDots extends StatelessWidget {
  final int activeIndex;
  const _ProgressDots({required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final isActive = i == activeIndex;
        return Container(
          width: isActive ? 24 : 6,
          height: 6,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: isActive ? AppColors.warmAmber : AppColors.divider,
            borderRadius: BorderRadius.circular(100),
          ),
        );
      }),
    );
  }
}
