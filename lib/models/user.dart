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
    required this.password,
    this.passwordHash,
    this.passwordSalt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id > 0) 'id': id,
      'username': username,
      'phone': phone,
      'email': email,
      'password_hash': passwordHash ?? password,
      'password_salt': passwordSalt ?? 'default_salt',
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
