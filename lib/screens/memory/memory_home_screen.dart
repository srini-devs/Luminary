import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/memory_entry.dart';
import '../../providers/loss_profile_provider.dart';
import '../../providers/memory_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/candle_icon.dart';
import '../../widgets/luminary_button.dart';

class MemoryHomeScreen extends ConsumerWidget {
  const MemoryHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memories = ref.watch(memoryProvider);
    final profile = ref.watch(lossProfileProvider);
    final name = profile?.deceasedName ?? 'them';

    return Scaffold(
      backgroundColor: AppColors.bgGray,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                        child: Text("$name's Space",
                            style: AppTextStyles.screenTitle,
                            textAlign: TextAlign.center),
                      ),
                      _CircleBtn(
                        onTap: () {/* TODO: star/fav */},
                        child: const Icon(Icons.star_border_outlined,
                            size: 18,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: memories.isEmpty
                      ? _EmptyState(
                          name: name,
                          onAdd: () =>
                              context.push('/home/memory/add'))
                      : _MemoryGrid(
                          memories: memories,
                          name: name,
                          onTap: (m) => context.push(
                            '/home/memory/view/${m.id}',
                            extra: m,
                          ),
                        ),
                ),
              ],
            ),
            // FAB
            Positioned(
              bottom: 90,
              right: 24,
              child: GestureDetector(
                onTap: () => context.push('/home/memory/add'),
                child: Container(
                  width: AppDimensions.fabSize,
                  height: AppDimensions.fabSize,
                  decoration: BoxDecoration(
                    color: AppColors.warmAmber,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.amberDark, width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.amberDark,
                        offset: Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add,
                      color: Colors.white, size: 26),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoryGrid extends StatelessWidget {
  final List<MemoryEntry> memories;
  final String name;
  final void Function(MemoryEntry) onTap;
  const _MemoryGrid(
      {required this.memories,
      required this.name,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM');

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        Text(
          '${memories.length} ${memories.length == 1 ? 'memory' : 'memories'} of $name',
          style: AppTextStyles.screenTitle.copyWith(fontSize: 20),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.9,
          ),
          itemCount: memories.length,
          itemBuilder: (context, i) {
            final m = memories[i];
            return GestureDetector(
              onTap: () => onTap(m),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bgWhite,
                  borderRadius: BorderRadius.circular(
                      AppDimensions.cardRadius),
                  border: Border.all(
                      color: AppColors.cardBorder, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                      AppDimensions.cardRadius - 1),
                  child: m.voiceNoteUrl != null
                      ? _VoiceCell(
                          m: m, dateFmt: fmt)
                      : m.textContent != null
                          ? _TextCell(m: m, dateFmt: fmt)
                          : _PhotoCell(m: m, dateFmt: fmt),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PhotoCell extends StatelessWidget {
  final MemoryEntry m;
  final DateFormat dateFmt;
  const _PhotoCell({required this.m, required this.dateFmt});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            color: AppColors.amberTint,
            child: const Center(
              child: Text('🌷', style: TextStyle(fontSize: 40)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.title ?? '',
                  style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Text(dateFmt.format(m.addedAt),
                  style: AppTextStyles.caption
                      .copyWith(fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}

class _TextCell extends StatelessWidget {
  final MemoryEntry m;
  final DateFormat dateFmt;
  const _TextCell({required this.m, required this.dateFmt});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              '"${m.textContent}"',
              style: AppTextStyles.caption.copyWith(
                  fontSize: 13, height: 1.6),
              overflow: TextOverflow.fade,
            ),
          ),
          Text(
            '${dateFmt.format(m.addedAt)} · Text',
            style: AppTextStyles.caption.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _VoiceCell extends StatelessWidget {
  final MemoryEntry m;
  final DateFormat dateFmt;
  const _VoiceCell({required this.m, required this.dateFmt});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mic_outlined,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text('Voice note',
                  style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: const LinearGradient(
                colors: [
                  AppColors.warmAmber,
                  AppColors.softPurple,
                  AppColors.warmAmber,
                ],
              ),
            ),
          ),
          const Spacer(),
          Text(dateFmt.format(m.addedAt),
              style: AppTextStyles.caption
                  .copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String name;
  final VoidCallback onAdd;
  const _EmptyState({required this.name, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CandleIcon(size: 40),
            const SizedBox(height: 16),
            Text(
              'Start collecting memories of $name.',
              style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700, fontSize: 17),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            LuminaryButton(
              label: 'Add first memory',
              onTap: onAdd,
            ),
          ],
        ),
      ),
    );
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
          border: Border.all(color: AppColors.divider, width: 1.5),
        ),
        child: Center(child: child),
      ),
    );
  }
}
