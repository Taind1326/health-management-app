class User {
  final int id;
  final String username;
  final String? phone;
  final String? email;
  final String password;
  final String? passwordHash;
  final String? passwordSalt;

  User({
    required this.id,
    required this.username,
    this.phone,
    this.email,
    this.password = '',
    this.passwordHash,
    this.passwordSalt,
  });

  Map<String, dynamic> toMap() {
    assert(
      passwordHash != null && passwordHash!.isNotEmpty,
      'Bảo mật Zero Plaintext: Không thể lưu User vào SQLite khi chưa có password_hash đã băm.',
    );
    assert(
      passwordSalt != null && passwordSalt!.isNotEmpty,
      'Bảo mật Zero Plaintext: Không thể lưu User vào SQLite khi chưa có password_salt.',
    );
    return {
      if (id > 0) 'id': id,
      'username': username,
      'phone': phone,
      'email': email,
      'password_hash': passwordHash ?? '',
      'password_salt': passwordSalt ?? '',
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int,
      username: map['username'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      password: '', // Không lưu plaintext password từ database
      passwordHash: map['password_hash'] as String?,
      passwordSalt: map['password_salt'] as String?,
    );
  }
}
