import 'package:flutter/material.dart';
import '../../models/health_profile.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'health_goal_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Dữ liệu mẫu (Sample data/in-memory) cho prototype
  late HealthProfile _profile;
  final String _phoneNumber = '0901234567';

  @override
  void initState() {
    super.initState();
    _initSampleData();
  }

  void _initSampleData() {
    const double height = 170.0; // cm
    const double weight = 65.0; // kg
    final double heightInM = height / 100.0;
    final double calculatedBmi = weight / (heightInM * heightInM);

    _profile = HealthProfile(
      id: 1,
      userId: 1,
      fullName: 'Nguyễn Văn A',
      age: 20,
      gender: 'Nam',
      height: height,
      weight: weight,
      bmi: double.parse(calculatedBmi.toStringAsFixed(2)),
    );
  }

  Future<void> _navigateToEditProfile() async {
    final updatedProfile = await Navigator.push<HealthProfile>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(currentProfile: _profile),
      ),
    );

    if (updatedProfile != null && mounted) {
      setState(() {
        _profile = updatedProfile;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật hồ sơ sức khỏe thành công!'),
          backgroundColor: Colors.teal,
        ),
      );
    }
  }

  void _navigateToHealthGoal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HealthGoalScreen(),
      ),
    );
  }

  void _handleLogout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Khối Header thông tin người dùng
              Center(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.teal,
                      child: Icon(
                        Icons.person,
                        size: 54,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _profile.fullName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _phoneNumber,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. Khối hiển thị nổi bật BMI
              Card(
                elevation: 2,
                color: Colors.teal.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.teal.shade200, width: 1.2),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.monitor_weight_outlined, color: Colors.teal),
                          SizedBox(width: 8),
                          Text(
                            'Chỉ số BMI',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _profile.bmi.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Chiều cao: ${_profile.height.toInt()} cm  •  Cân nặng: ${_profile.weight.toInt()} kg',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.teal.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Khối danh sách thông tin chi tiết
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.badge_outlined, color: Colors.teal),
                      title: const Text('Họ và tên'),
                      trailing: Text(
                        _profile.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.phone_outlined, color: Colors.teal),
                      title: const Text('Số điện thoại'),
                      trailing: Text(
                        _phoneNumber,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.calendar_today_outlined, color: Colors.teal),
                      title: const Text('Tuổi'),
                      trailing: Text(
                        '${_profile.age}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.wc, color: Colors.teal),
                      title: const Text('Giới tính'),
                      trailing: Text(
                        _profile.gender,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.height, color: Colors.teal),
                      title: const Text('Chiều cao'),
                      trailing: Text(
                        '${_profile.height.toInt()} cm',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.scale_outlined, color: Colors.teal),
                      title: const Text('Cân nặng'),
                      trailing: Text(
                        '${_profile.weight.toInt()} kg',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. Các nút thao tác
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _navigateToEditProfile,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text(
                    'Chỉnh sửa hồ sơ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _navigateToHealthGoal,
                  icon: const Icon(Icons.flag_outlined, color: Colors.teal),
                  label: const Text(
                    'Mục tiêu sức khỏe',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.teal, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
