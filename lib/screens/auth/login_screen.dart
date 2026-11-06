import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/tv1_glass_widgets.dart';
import '../home/home_screen.dart';
import '../intro/app_intro_screen.dart';
import '../profile/edit_profile_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final identifier = _usernameController.text.trim();
    final password = _passwordController.text;

    // Đăng nhập qua AuthService (hỗ trợ Username, SĐT hoặc Email, đọc SQLite)
    final user = await AuthService().login(identifier, password);
    if (!mounted) return;

    if (user != null) {
      final profile = AuthService().getProfile(user.id);
      if (!profile.isCompleted) {
        if (!AuthService().hasSeenIntro(user.id)) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AppIntroScreen(profile: profile),
            ),
          );
        } else {
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
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      }
    } else {
      setState(() {
        _errorMessage = 'Tên tài khoản hoặc mật khẩu không đúng.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tên tài khoản hoặc mật khẩu không đúng.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegisterScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Tv1GlassScaffold(
      appBar: const Tv1GlassAppBar(
        title: Text(
          'Đăng nhập',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Biểu tượng nhịp tim sức khỏe hiện đại trong khung huy hiệu kính đa lớp
                const Center(
                  child: Tv1LayeredBadge(
                    icon: Icons.monitor_heart_rounded,
                    size: 58,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ứng dụng Quản lý Sức khỏe',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 28),

                // Tấm kính Form Đăng nhập
                Tv1GlassCard(
                  padding: const EdgeInsets.all(22.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Thông báo lỗi nếu có
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.6),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Color(0xFFFF6B6B), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Trường Tên tài khoản
                      TextFormField(
                        controller: _usernameController,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: Tv1GlassTheme.inputDecoration(
                          labelText: 'Tên tài khoản',
                          hintText: 'Nhập tên tài khoản, email hoặc SĐT',
                          helperText: 'Đăng nhập bằng tên tài khoản, email hoặc SĐT',
                          prefixIcon: const Icon(Icons.person, color: Color(0xFF7DD3FC)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Tên tài khoản không được để trống.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Trường Mật khẩu
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: Tv1GlassTheme.inputDecoration(
                          labelText: 'Mật khẩu',
                          hintText: 'Nhập mật khẩu (vd: 123456)',
                          prefixIcon: const Icon(Icons.lock, color: Color(0xFF7DD3FC)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Mật khẩu không được để trống.';
                          }
                          if (value.trim().isEmpty) {
                            return 'Mật khẩu không được chỉ chứa khoảng trắng.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Nút Đăng nhập phong cách Aurora Ocean-Indigo
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _handleLogin,
                          style: Tv1GlassTheme.primaryButtonStyle(),
                          child: const Text(
                            'Đăng nhập',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Dòng Chưa có tài khoản? Đăng ký
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'Chưa có tài khoản?',
                            style: TextStyle(color: Colors.white70),
                          ),
                          TextButton(
                            onPressed: _navigateToRegister,
                            child: const Text(
                              'Đăng ký',
                              style: TextStyle(
                                color: Color(0xFF7DD3FC),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Hộp gợi ý tài khoản mẫu để test prototype
                Tv1GlassCard(
                  padding: const EdgeInsets.all(14),
                  surfaceColor: Colors.white.withValues(alpha: 0.12),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tài khoản mẫu để thử nghiệm prototype:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF7DD3FC),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• Tên tài khoản: user01\n• SĐT: 0901234567 | Email: user01@example.com\n• Mật khẩu: 123456',
                        style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
