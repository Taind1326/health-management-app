import 'package:flutter/material.dart';
import '../../models/health_profile.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../widgets/tv1_glass_widgets.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'health_goal_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late HealthProfile _profile;
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    final authService = AuthService();
    _user = authService.currentUser;
    final userId = _user?.id ?? 1;
    _profile = authService.getProfile(userId);
  }

  String _formatNumber(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  Future<void> _navigateToEditProfile() async {
    final updatedProfile = await Navigator.push<HealthProfile>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(currentProfile: _profile),
      ),
    );

    if (updatedProfile != null && mounted) {
      AuthService().updateProfile(updatedProfile);
      setState(() {
        _profile = updatedProfile;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật hồ sơ sức khỏe thành công!'),
          backgroundColor: Color(0xFF0284C7),
        ),
      );
    }
  }

  Future<void> _navigateToHealthGoal() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HealthGoalScreen(),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  void _handleLogout() {
    AuthService().logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF7DD3FC), size: 22),
          const SizedBox(width: 14),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userPhone = _user?.phone ?? 'Chưa cập nhật SĐT';
    final userEmail = _user?.email;

    final recommendedWater = AuthService.calculateRecommendedWater(_profile.weight);
    final bmr = (_profile.height > 0 && _profile.weight > 0 && _profile.age > 0)
        ? AuthService.calculateBmr(
            weightKg: _profile.weight,
            heightCm: _profile.height,
            age: _profile.age,
            gender: _profile.gender,
          )
        : 0.0;
    final tdee = bmr > 0 ? AuthService.calculateTdee(bmr: bmr) : 0;

    final goals = AuthService().getGoals(_profile.userId);

    return Tv1GlassScaffold(
      appBar: Tv1GlassAppBar(
        title: const Text(
          'Hồ sơ cá nhân',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Đăng xuất',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Khối Header thông tin người dùng
            Tv1GlassCard(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF7DD3FC),
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.45),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const CircleAvatar(
                        radius: 42,
                        backgroundColor: Color(0xFF312E81),
                        child: Icon(
                          Icons.person,
                          size: 52,
                          color: Color(0xFFE0F2FE),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _profile.fullName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userPhone.isNotEmpty ? userPhone : (userEmail ?? ''),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    if (userEmail != null && userEmail.isNotEmpty && userPhone != userEmail) ...[
                      const SizedBox(height: 2),
                      Text(
                        userEmail,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.70),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Khối hiển thị nổi bật BMI
            Tv1GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.monitor_weight_outlined, color: Color(0xFF7DD3FC)),
                      SizedBox(width: 8),
                      Text(
                        'Chỉ số BMI',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7DD3FC),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _profile.isCompleted ? _profile.bmi.toStringAsFixed(2) : '--',
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _profile.isCompleted
                        ? 'Chiều cao: ${_formatNumber(_profile.height)} cm  •  Cân nặng: ${_formatNumber(_profile.weight)} kg'
                        : 'Chưa thiết lập chỉ số sức khỏe',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Khối mục tiêu & khuyến nghị thông minh (TV1 liên kết TV2/TV4)
            if (_profile.isCompleted) ...[
              Tv1GlassCard(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.auto_awesome, color: Color(0xFF7DD3FC), size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Định hướng sức khỏe & Dinh dưỡng',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nước khuyến nghị',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.75),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$recommendedWater ml/ngày',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF7DD3FC),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TDEE năng lượng',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.75),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tdee > 0 ? '~$tdee kcal' : '-- kcal',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF7DD3FC),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      goals.isNotEmpty
                          ? 'Mục tiêu hiện tại: ${goals.last.goal}'
                          : 'Mục tiêu hiện tại: Chưa thiết lập mục tiêu cá nhân',
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 4. Khối danh sách thông tin chi tiết
            Tv1GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Icons.badge_outlined,
                    label: 'Họ và tên',
                    value: _profile.fullName,
                  ),
                  Divider(height: 1, color: Colors.white.withValues(alpha: 0.15)),
                  _buildInfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Số điện thoại',
                    value: userPhone,
                  ),
                  if (userEmail != null && userEmail.isNotEmpty) ...[
                    Divider(height: 1, color: Colors.white.withValues(alpha: 0.15)),
                    _buildInfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: userEmail,
                    ),
                  ],
                  Divider(height: 1, color: Colors.white.withValues(alpha: 0.15)),
                  _buildInfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Tuổi',
                    value: _profile.age > 0 ? '${_profile.age}' : 'Chưa cập nhật',
                  ),
                  Divider(height: 1, color: Colors.white.withValues(alpha: 0.15)),
                  _buildInfoRow(
                    icon: Icons.wc,
                    label: 'Giới tính',
                    value: _profile.gender,
                  ),
                  Divider(height: 1, color: Colors.white.withValues(alpha: 0.15)),
                  _buildInfoRow(
                    icon: Icons.height,
                    label: 'Chiều cao',
                    value: _profile.height > 0 ? '${_formatNumber(_profile.height)} cm' : 'Chưa cập nhật',
                  ),
                  Divider(height: 1, color: Colors.white.withValues(alpha: 0.15)),
                  _buildInfoRow(
                    icon: Icons.scale_outlined,
                    label: 'Cân nặng',
                    value: _profile.weight > 0 ? '${_formatNumber(_profile.weight)} kg' : 'Chưa cập nhật',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 5. Các nút thao tác
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _navigateToEditProfile,
                icon: const Icon(Icons.edit_outlined),
                label: const Text(
                  'Chỉnh sửa hồ sơ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: Tv1GlassTheme.primaryButtonStyle(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _navigateToHealthGoal,
                icon: const Icon(Icons.flag_outlined, color: Color(0xFF7DD3FC)),
                label: const Text(
                  'Mục tiêu sức khỏe',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7DD3FC),
                  ),
                ),
                style: Tv1GlassTheme.secondaryButtonStyle(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
