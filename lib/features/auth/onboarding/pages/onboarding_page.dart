import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/onboarding_provider.dart';
import '../../../../core/providers/profile_provider.dart';
import '../../../../core/utils/constant/app_colors.dart';
import '../../../user/widgets/navigation.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  final _nicknameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load problem preferences when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OnboardingProvider>().loadPreferences();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nicknameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  // ── Slide 2 → Save profile info then go to slide 3 ──
  Future<void> _onSlide2Next() async {
    final provider = context.read<OnboardingProvider>();

    if (!provider.isSlide2Valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi semua data terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await provider.saveProfileInfo();

    if (mounted) {
      if (success) {
        _nextPage();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Gagal menyimpan profil'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Slide 3 → Save preferences + complete onboarding ──
  Future<void> _onSubmit() async {
    final provider = context.read<OnboardingProvider>();

    if (!provider.isSlide3Valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal satu masalah'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await provider.savePreferencesAndComplete();

    if (mounted) {
      if (success) {
        // Refresh profile so AuthGate knows onboarding is done
        await context.read<ProfileProvider>().fetchProfile();

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const Navigation()),
            (route) => false,
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Gagal menyimpan data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<OnboardingProvider>(
        builder: (context, provider, _) {
          return PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => provider.setCurrentPage(i),
            children: [
              // ── Slide 1: Welcome ──
              _WelcomePage(onStart: _nextPage),

              // ── Slide 2: Profile info ──
              _ProfilePage(
                nicknameController: _nicknameController,
                phoneController: _phoneController,
                gender: provider.gender,
                birthDate: provider.birthDate,
                isSaving: provider.isSaving,
                onNicknameChanged: (v) => provider.setNickname(v),
                onPhoneChanged: (v) => provider.setPhoneNumber(v),
                onGenderChanged: (v) => provider.setGender(v),
                onBirthDateTap: () => _showDatePicker(provider),
                onBack: _prevPage,
                onNext: _onSlide2Next,
              ),

              // ── Slide 3: Problem preferences ──
              _ProblemPage(
                availablePreferences: provider.availablePreferences,
                selectedIds: provider.selectedPreferenceIds,
                isLoadingPrefs: provider.isLoading,
                isSaving: provider.isSaving,
                error: provider.error,
                onToggle: (id) => provider.togglePreference(id),
                onBack: _prevPage,
                onSubmit: _onSubmit,
                onRetry: () => provider.loadPreferences(),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showDatePicker(OnboardingProvider provider) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.birthDate ?? DateTime(now.year - 20),
      firstDate: DateTime(1950),
      lastDate: now,
      helpText: 'Pilih tanggal lahir',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      provider.setBirthDate(picked);
    }
  }
}

// ─────────────────────────────────────────
// Page 1 — Welcome
// ─────────────────────────────────────────
class _WelcomePage extends StatelessWidget {
  final VoidCallback onStart;
  const _WelcomePage({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            const _ProgressPill(filled: 1, total: 3),
            const Spacer(flex: 2),

            // Greeting
            RichText(
              textAlign: TextAlign.center,
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.4,
                ),
                children: [
                  TextSpan(text: 'Hi 🌿\n'),
                  TextSpan(text: 'Senang kamu ada di sini.'),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Mascot
            _MascotImage(variant: _MascotVariant.wave),

            const SizedBox(height: 32),

            // Subtitle
            const Text(
              'Kami akan menemanimu\nmenjaga kesehatan emosional\nsetiap hari 🌿',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
                height: 1.6,
              ),
            ),

            const Spacer(flex: 3),

            _PrimaryButton(label: 'Mulai Perjalanan', onTap: onStart),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Page 2 — Profile (nickname + gender + birth_date)
// ─────────────────────────────────────────
class _ProfilePage extends StatelessWidget {
  final TextEditingController nicknameController;
  final TextEditingController phoneController;
  final String? gender;
  final DateTime? birthDate;
  final bool isSaving;
  final ValueChanged<String> onNicknameChanged;
  final ValueChanged<String> onPhoneChanged;
  final ValueChanged<String?> onGenderChanged;
  final VoidCallback onBirthDateTap;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _ProfilePage({
    required this.nicknameController,
    required this.phoneController,
    required this.gender,
    required this.birthDate,
    required this.isSaving,
    required this.onNicknameChanged,
    required this.onPhoneChanged,
    required this.onGenderChanged,
    required this.onBirthDateTap,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _ProgressPill(filled: 2, total: 3),
            _BackButton(onTap: onBack),
            const Spacer(flex: 1),

            const Text(
              'Ceritakan sedikit\ntentang dirimu 🌱',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 8),

            _MascotImage(variant: _MascotVariant.peace),

            const SizedBox(height: 24),

            // ── Nickname input ──
            TextField(
              controller: nicknameController,
              onChanged: onNicknameChanged,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Nama panggilan',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Phone number input ──
            TextField(
              controller: phoneController,
              onChanged: onPhoneChanged,
              keyboardType: TextInputType.phone,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Nomor telepon',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Gender selector ──
            Row(
              children: [
                Expanded(
                  child: _GenderCard(
                    label: 'Laki-laki',
                    icon: Icons.male_rounded,
                    isSelected: gender == 'Laki-laki',
                    onTap: () => onGenderChanged('Laki-laki'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GenderCard(
                    label: 'Perempuan',
                    icon: Icons.female_rounded,
                    isSelected: gender == 'Perempuan',
                    onTap: () => onGenderChanged('Perempuan'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Birth date picker ──
            GestureDetector(
              onTap: onBirthDateTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: birthDate != null
                        ? AppColors.primary
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: birthDate != null
                          ? AppColors.primary
                          : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      birthDate != null
                          ? DateFormat('dd MMMM yyyy').format(birthDate!)
                          : 'Tanggal lahir',
                      style: TextStyle(
                        fontSize: 15,
                        color: birthDate != null
                            ? Colors.black87
                            : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(flex: 2),

            _PrimaryButton(
              label: isSaving ? '' : 'Lanjutkan',
              onTap: isSaving ? null : onNext,
              child: isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Page 3 — Problem Preferences (multi-select)
// ─────────────────────────────────────────
class _ProblemPage extends StatelessWidget {
  final List availablePreferences;
  final Set<int> selectedIds;
  final bool isLoadingPrefs;
  final bool isSaving;
  final String? error;
  final ValueChanged<int> onToggle;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final VoidCallback onRetry;

  const _ProblemPage({
    required this.availablePreferences,
    required this.selectedIds,
    required this.isLoadingPrefs,
    required this.isSaving,
    this.error,
    required this.onToggle,
    required this.onBack,
    required this.onSubmit,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _ProgressPill(filled: 3, total: 3),
            _BackButton(onTap: onBack),
            const SizedBox(height: 24),

            const Text(
              'Apa yang membuat kamu\nmencoba aplikasi ini?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Pilih satu atau lebih',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),

            const SizedBox(height: 20),

            _MascotImage(variant: _MascotVariant.search),

            const SizedBox(height: 24),

            // ── Dynamic options ──
            if (isLoadingPrefs)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (error != null)
              // ── Error state ──
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade300,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.red.shade400,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: onRetry,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Coba Lagi',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (availablePreferences.isEmpty)
              // ── Empty state ──
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_rounded,
                      color: Colors.grey.shade400,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada data preferences.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: onRetry,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Muat Ulang',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 54,
                  ),
                  itemCount: availablePreferences.length,
                  itemBuilder: (context, index) {
                    final pref = availablePreferences[index];
                    final isSelected = selectedIds.contains(pref.id);
                    return GestureDetector(
                      onTap: () => onToggle(pref.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey.shade300,
                            width: 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                pref.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),

            _PrimaryButton(
              label: isSaving ? '' : 'Mulai Perjalanan',
              onTap: isSaving ? null : onSubmit,
              child: isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Shared Widgets
// ─────────────────────────────────────────

class _GenderCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? Colors.white : Colors.grey.shade500,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressPill extends StatelessWidget {
  final int filled;
  final int total;
  const _ProgressPill({required this.filled, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (i) {
          final active = i < filled;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 28 : 8,
            height: 6,
            decoration: BoxDecoration(
              color: active ? AppColors.primary : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(99),
            ),
          );
        }),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.only(top: 8, bottom: 4),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.chevron_left_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Widget? child;
  const _PrimaryButton({required this.label, this.onTap, this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 54,
        decoration: BoxDecoration(
          color: onTap == null ? Colors.grey.shade300 : AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child:
            child ??
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Mascot Placeholder
// ─────────────────────────────────────────
enum _MascotVariant { wave, peace, search }

class _MascotImage extends StatelessWidget {
  final _MascotVariant variant;
  const _MascotImage({required this.variant});

  String get _assetPath {
    switch (variant) {
      case _MascotVariant.wave:
        return 'assets/images/mascot_wave.png';
      case _MascotVariant.peace:
        return 'assets/images/mascot_peace.png';
      case _MascotVariant.search:
        return 'assets/images/mascot_search.png';
    }
  }

  IconData get _fallbackIcon {
    switch (variant) {
      case _MascotVariant.wave:
        return Icons.waving_hand_rounded;
      case _MascotVariant.peace:
        return Icons.sentiment_satisfied_alt_rounded;
      case _MascotVariant.search:
        return Icons.manage_search_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        _assetPath,
        height: 130,
        errorBuilder: (_, _, _) => Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Icon(_fallbackIcon, size: 48, color: AppColors.primary),
        ),
      ),
    );
  }
}
