import 'package:flutter/material.dart';
import '../../models/health_profile.dart';
import '../../services/auth_service.dart';
import '../../widgets/tv1_glass_widgets.dart';
import '../profile/edit_profile_screen.dart';

class AppIntroScreen extends StatefulWidget {
  final HealthProfile? profile;

  const AppIntroScreen({super.key, this.profile});

  @override
  State<AppIntroScreen> createState() => _AppIntroScreenState();
}

class _AppIntroScreenState extends State<AppIntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_IntroSlideData> _slides = const [
    _IntroSlideData(
      icon: Icons.monitor_heart_rounded,
      title: 'Theo dõi chỉ số sức khỏe',
      description:
          'Ghi nhận và phân tích các chỉ số cơ bản như BMI, Huyết áp, Nhịp tim và Cân nặng theo thời gian thực.',
    ),
    _IntroSlideData(
      icon: Icons.local_dining_rounded,
      title: 'Dinh dưỡng & Nước uống',
      description:
          'Tính toán mục tiêu calo (TDEE), chế độ dinh dưỡng khoa học và nhắc nhở uống đủ nước mỗi ngày theo thể trạng.',
    ),
    _IntroSlideData(
      icon: Icons.directions_run_rounded,
      title: 'Mục tiêu & Lối sống lành mạnh',
      description:
          'Thiết lập mục tiêu giảm cân, tăng cân hoặc duy trì sức khỏe. Theo dõi số bước chân và giấc ngủ khoa học.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finishIntro() {
    final authService = AuthService();
    final profile = widget.profile ??
        authService.getProfile(authService.currentUser?.id ?? 1);

    authService.setSeenIntro(profile.userId);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          currentProfile: profile,
          isInitialSetup: true,
        ),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishIntro();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _slides.length - 1;

    return Tv1GlassScaffold(
      appBar: Tv1GlassAppBar(
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _finishIntro,
            child: const Text(
              'Bỏ qua',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7DD3FC),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _slides.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final slide = _slides[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Center(
                    child: Tv1GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 22.0),
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Tv1LayeredBadge(
                              icon: slide.icon,
                              size: 56,
                              iconColor: const Color(0xFFE0F2FE),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              slide.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              slide.description,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.45,
                                color: Colors.white.withValues(alpha: 0.88),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Thanh chỉ số trang (Dots)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _slides.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? const Color(0xFF7DD3FC)
                      : Colors.white.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Nút Tiếp tục / Bắt đầu ngay
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _nextPage,
                style: Tv1GlassTheme.primaryButtonStyle(),
                child: Text(
                  isLastPage ? 'Bắt đầu ngay' : 'Tiếp tục',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroSlideData {
  final IconData icon;
  final String title;
  final String description;

  const _IntroSlideData({
    required this.icon,
    required this.title,
    required this.description,
  });
}
