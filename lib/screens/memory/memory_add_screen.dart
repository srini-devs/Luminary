import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../models/memory_entry.dart';
import '../../providers/loss_profile_provider.dart';
import '../../providers/memory_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/luminary_button.dart';
import '../../widgets/luminary_text_field.dart';

const _mauuid = Uuid();

enum _MemoryType { photo, text, voice }

class MemoryAddScreen extends ConsumerStatefulWidget {
  const MemoryAddScreen({super.key});

  @override
  ConsumerState<MemoryAddScreen> createState() => _MemoryAddScreenState();
}

class _MemoryAddScreenState extends ConsumerState<MemoryAddScreen> {
  _MemoryType? _selectedType;
  final _titleController = TextEditingController();
  final _textController = TextEditingController();
  bool _shareWithAI = false;
  bool _isSaving = false;
  String? _localPhotoPath;

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  bool get _canSave {
    if (_selectedType == null || _isSaving) return false;
    if (_selectedType == _MemoryType.text) {
      return _textController.text.trim().isNotEmpty;
    }
    if (_selectedType == _MemoryType.photo) return _localPhotoPath != null;
    return true;
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final profile = ref.read(lossProfileProvider);
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 350));

    final memory = MemoryEntry(
      id: _mauuid.v4(),
      lossProfileId: profile?.id ?? 'mock',
      title: _titleController.text.trim().isEmpty
          ? null
          : _titleController.text.trim(),
      textContent: _selectedType == _MemoryType.text
          ? _textController.text.trim()
          : null,
      localPhotoPath: _selectedType == _MemoryType.photo ? _localPhotoPath : null,
      voiceNoteUrl:
          _selectedType == _MemoryType.voice ? 'mock://voice/new' : null,
      isSharedWithAI: _shareWithAI,
      addedAt: DateTime.now(),
    );

    ref.read(memoryProvider.notifier).addMemory(memory);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGray,
      resizeToAvoidBottomInset: true,
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
                    child: Text('Add memory',
                        style: AppTextStyles.screenTitle,
                        textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type selector tiles
                    Text('MEMORY TYPE',
                        style: AppTextStyles.sectionLabel),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _TypeTile(
                          icon: Icons.image_outlined,
                          label: 'Photo',
                          selected:
                              _selectedType == _MemoryType.photo,
                          onTap: () => setState(
                              () => _selectedType = _MemoryType.photo),
                        ),
                        const SizedBox(width: 10),
                        _TypeTile(
                          icon: Icons.edit_note_outlined,
                          label: 'Written',
                          selected:
                              _selectedType == _MemoryType.text,
                          onTap: () => setState(
                              () => _selectedType = _MemoryType.text),
                        ),
                        const SizedBox(width: 10),
                        _TypeTile(
                          icon: Icons.mic_outlined,
                          label: 'Voice',
                          selected:
                              _selectedType == _MemoryType.voice,
                          onTap: () => setState(
                              () => _selectedType = _MemoryType.voice),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Type-specific input
                    if (_selectedType == _MemoryType.photo) ...[
                      _PhotoInput(
                        localPhotoPath: _localPhotoPath,
                        onPicked: (path) => setState(() {
                          _localPhotoPath = path;
                        }),
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (_selectedType == _MemoryType.text) ...[
                      _WrittenInput(controller: _textController,
                          onChanged: (_) => setState(() {})),
                    ],
                    if (_selectedType == _MemoryType.voice) ...[
                      _VoiceInput(),
                      const SizedBox(height: 4),
                    ],
                    // Title field
                    LuminaryTextField(
                      label: 'MEMORY TITLE',
                      hint: 'Give this memory a name…',
                      controller: _titleController,
                      onChanged: (_) => setState(() {}),
                    ),
                    // Share with AI toggle
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.bgWhite,
                        borderRadius: BorderRadius.circular(
                            AppDimensions.cardRadius),
                        border: Border.all(
                            color: AppColors.cardBorder, width: 2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Share with my AI companion',
                                    style: AppTextStyles.bodyMedium
                                        .copyWith(
                                            fontWeight:
                                                FontWeight.w600),
                                  ),
                                  Text(
                                    'Your companion can reference this memory',
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(
                                    () => _shareWithAI = !_shareWithAI);
                              },
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 200),
                                width: 51,
                                height: 31,
                                decoration: BoxDecoration(
                                  color: _shareWithAI
                                      ? AppColors.sageGreen
                                      : AppColors.divider,
                                  borderRadius:
                                      BorderRadius.circular(100),
                                ),
                                child: AnimatedAlign(
                                  duration: const Duration(
                                      milliseconds: 200),
                                  alignment: _shareWithAI
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    width: 25,
                                    height: 25,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 3),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0x33000000),
                                          blurRadius: 4,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    LuminaryButton(
                      label: 'Save memory',
                      onTap: _canSave ? _save : null,
                      isLoading: _isSaving,
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

class _TypeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TypeTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 88,
          decoration: BoxDecoration(
            color: selected ? AppColors.textPrimary : AppColors.bgWhite,
            borderRadius:
                BorderRadius.circular(AppDimensions.cardRadius),
            border: Border.all(
              color: selected
                  ? AppColors.textPrimary
                  : AppColors.cardBorder,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 28,
                color:
                    selected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoInput extends StatelessWidget {
  final String? localPhotoPath;
  final ValueChanged<String> onPicked;

  const _PhotoInput({required this.localPhotoPath, required this.onPicked});

  Future<void> _pick() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) onPicked(picked.path);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pick,
      child: Container(
        height: 160,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: localPhotoPath != null ? Colors.transparent : AppColors.amberTint,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          border: Border.all(color: AppColors.warmAmber, width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: AppColors.warmAmber,
              offset: AppDimensions.neoShadowOffset,
              blurRadius: AppDimensions.neoShadowBlur,
            ),
          ],
        ),
        child: localPhotoPath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.cardRadius - 2),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(localPhotoPath!), fit: BoxFit.cover),
                    Positioned(
                      bottom: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Text('Change', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_photo_alternate_outlined, size: 36, color: AppColors.amberDark),
                  const SizedBox(height: 8),
                  Text('Tap to choose a photo',
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.amberDark, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}

class _WrittenInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _WrittenInput(
      {required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 160),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius:
            BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(
            color: AppColors.warmAmber, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.warmAmber,
            offset: AppDimensions.neoShadowOffset,
            blurRadius: AppDimensions.neoShadowBlur,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: null,
        autofocus: false,
        style:
            AppTextStyles.bodyMedium.copyWith(height: 1.7),
        decoration: InputDecoration(
          hintText: 'Write your memory…',
          hintStyle: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.textTertiary),
          contentPadding: const EdgeInsets.all(16),
          border: InputBorder.none,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _VoiceInput extends StatelessWidget {
  const _VoiceInput();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius:
            BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(
            color: AppColors.softPurple, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.softPurple,
            offset: AppDimensions.neoShadowOffset,
            blurRadius: AppDimensions.neoShadowBlur,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.softPurple,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic,
                color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text('Tap to record',
              style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.softPurple)),
        ],
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
          border:
              Border.all(color: AppColors.divider, width: 1.5),
        ),
        child: Center(child: child),
      ),
    );
  }
}
