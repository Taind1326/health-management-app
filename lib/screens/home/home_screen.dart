import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

/// Mô tả một mục chức năng hiển thị trên Trang chủ và trong Drawer.
class _Feature {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;

  const _Feature({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });
}

const List<_Feature> _features = [
  _Feature(
    title: 'Chỉ số sức khỏe',
    subtitle: 'Cân nặng, huyết áp, nhịp tim',
    icon: Icons.monitor_heart_outlined,
    route: AppRoutes.healthMetrics,
  ),
  _Feature(
    title: 'Thuốc & Nhắc nhở',
    subtitle: 'Lịch uống thuốc hằng ngày',
    icon: Icons.medication_outlined,
    route: AppRoutes.medication,
  ),
  _Feature(
    title: 'Dinh dưỡng & Nước',
    subtitle: 'Bữa ăn và lượng nước uống',
    icon: Icons.restaurant_outlined,
    route: AppRoutes.nutrition,
  ),
  _Feature(
    title: 'Vận động',
    subtitle: 'Bước chân và hoạt động',
    icon: Icons.directions_run,
    route: AppRoutes.activity,
  ),
  _Feature(
    title: 'Giấc ngủ',
    subtitle: 'Theo dõi giờ ngủ',
    icon: Icons.bedtime_outlined,
    route: AppRoutes.sleep,
  ),
  _Feature(
    title: 'Hồ sơ cá nhân',
    subtitle: 'Thông tin và mục tiêu',
    icon: Icons.person_outline,
    route: AppRoutes.profile,
  ),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _logout(BuildContext context) {
    AuthService().logout();
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final currentUser = AuthService().currentUser;
    final username = currentUser?.username ?? 'user01';

    return Scaffold(
      appBar: AppBar(title: const Text('Trang chủ')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: scheme.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: scheme.onPrimary,
                    child: Icon(Icons.person, size: 40, color: scheme.primary),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Quản lý Sức khỏe',
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Tài khoản: $username',
                    style: TextStyle(
                      color: scheme.onPrimary.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text(
                'Trang chủ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              selected: true,
              onTap: () => Navigator.pop(context),
            ),
            for (final f in _features)
              ListTile(
                leading: Icon(f.icon),
                title: Text(f.title),
                onTap: () {
                  Navigator.pop(context); // Đóng Drawer
                  Navigator.pushNamed(context, f.route);
                },
              ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: scheme.error),
              title: Text('Đăng xuất', style: TextStyle(color: scheme.error)),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: AppTheme.pagePadding,
          children: [
            Card(
              color: scheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.waving_hand,
                        size: 32, color: scheme.onPrimaryContainer),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xin chào, $username!',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Hôm nay bạn cảm thấy thế nào?',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Chức năng', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                // Chiều cao cố định, đủ chứa icon + tiêu đề 2 dòng + mô tả 2 dòng
                mainAxisExtent: 190,
              ),
              children: [
                for (final f in _features) _FeatureCard(feature: f),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final _Feature feature;

  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, feature.route),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: scheme.primaryContainer,
                child: Icon(feature.icon, color: scheme.onPrimaryContainer),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.title,
                    style: theme.textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    feature.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}