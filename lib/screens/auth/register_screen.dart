import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/tv1_glass_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _contactType = 'phone'; // 'phone' hoặc 'email'
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final fullName = _fullNameController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    final isPhone = _contactType == 'phone';
    final phone = isPhone ? _phoneController.text.trim() : null;
    final email = !isPhone ? _emailController.text.trim() : null;

    final authService = AuthService();

    if (authService.isUsernameTaken(username)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tên tài khoản "$username" đã tồn tại. Vui lòng chọn tên khác.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (isPhone && authService.isPhoneTaken(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Số điện thoại "$phone" đã được đăng ký.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!isPhone && authService.isEmailTaken(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email "$email" đã được đăng ký.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Đăng ký lưu vào bộ nhớ dùng chung & cơ sở dữ liệu
    final newUser = authService.register(
      fullName: fullName,
      phone: phone,
      email: email,
      username: username,
      password: password,
    );

    // Thông báo đăng ký thành công
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đăng ký thành công cho tài khoản "${newUser.username}"!'),
        backgroundColor: Colors.green,
      ),
    );

    // Chuyển về màn hình đăng nhập
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Tv1GlassScaffold(
      appBar: const Tv1GlassAppBar(
        title: Text(
          'Đăng ký',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Biểu tượng đăng ký thành viên hiện đại trong khung huy hiệu kính đa lớp
                const Center(
                  child: Tv1LayeredBadge(
                    icon: Icons.how_to_reg_rounded,
                    size: 54,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Tạo tài khoản mới',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                // Tấm kính chứa Form đăng ký
                Tv1GlassCard(
                  padding: const EdgeInsets.all(22.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Thanh chuyển đổi SĐT / Email
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'phone',
                            label: Text('Số điện thoại'),
                            icon: Icon(Icons.phone_outlined),
                          ),
                          ButtonSegment(
                            value: 'email',
                            label: Text('Email'),
                            icon: Icon(Icons.email_outlined),
                          ),
                        ],
                        selected: {_contactType},
                        onSelectionChanged: (newSelection) {
                          setState(() {
                            _contactType = newSelection.first;
                          });
                        },
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return const Color(0xFF0284C7); // Aurora Ocean-Indigo
                            }
                            return Colors.white.withValues(alpha: 0.12);
                          }),
                          foregroundColor: WidgetStateProperty.all(Colors.white),
                          side: WidgetStateProperty.all(
                            BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 1. Họ và tên
                      TextFormField(
                        controller: _fullNameController,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: Tv1GlassTheme.inputDecoration(
                          labelText: 'Họ và tên',
                          hintText: 'Nhập họ và tên',
                          prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF7DD3FC)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Họ và tên không được để trống.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 2. Số điện thoại HOẶC Email tùy tab
                      if (_contactType == 'phone')
                        TextFormField(
                          key: const ValueKey('phoneField'),
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                          decoration: Tv1GlassTheme.inputDecoration(
                            labelText: 'Số điện thoại',
                            hintText: 'Nhập số điện thoại (chỉ chứa chữ số)',
                            prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF7DD3FC)),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Số điện thoại không được để trống.';
                            }
                            final phoneRegex = RegExp(r'^0[0-9]{9}$');
                            if (!phoneRegex.hasMatch(value.trim())) {
                              return 'Số điện thoại phải gồm 10 chữ số và bắt đầu bằng số 0.';
                            }
                            return null;
                          },
                        )
                      else
                        TextFormField(
                          key: const ValueKey('emailField'),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                          decoration: Tv1GlassTheme.inputDecoration(
                            labelText: 'Email',
                            hintText: 'Nhập địa chỉ email (vd: name@example.com)',
                            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF7DD3FC)),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email không được để trống.';
                            }
                            final emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');
                            if (!emailRegex.hasMatch(value.trim())) {
                              return 'Email không hợp lệ.';
                            }
                            return null;
                          },
                        ),
                      const SizedBox(height: 16),

                      // 3. Tên tài khoản
                      TextFormField(
                        controller: _usernameController,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: Tv1GlassTheme.inputDecoration(
                          labelText: 'Tên tài khoản',
                          hintText: 'Nhập tên tài khoản',
                          prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF7DD3FC)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Tên tài khoản không được để trống.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 4. Mật khẩu
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: Tv1GlassTheme.inputDecoration(
                          labelText: 'Mật khẩu',
                          hintText: 'Nhập mật khẩu',
                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF7DD3FC)),
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
                          if (value.length < 6) {
                            return 'Mật khẩu phải có ít nhất 6 ký tự.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 5. Xác nhận mật khẩu
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: Tv1GlassTheme.inputDecoration(
                          labelText: 'Xác nhận mật khẩu',
                          hintText: 'Nhập lại mật khẩu',
                          prefixIcon: const Icon(Icons.lock_reset, color: Color(0xFF7DD3FC)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Xác nhận mật khẩu không được để trống.';
                          }
                          if (value != _passwordController.text) {
                            return 'Xác nhận mật khẩu không khớp với mật khẩu.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Nút Đăng ký Aurora Ocean-Indigo
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _handleRegister,
                          style: Tv1GlassTheme.primaryButtonStyle(),
                          child: const Text(
                            'Đăng ký',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Dòng Đã có tài khoản? Đăng nhập
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Đã có tài khoản?',
                            style: TextStyle(color: Colors.white70),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Đăng nhập',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
