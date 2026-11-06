import 'package:flutter/material.dart';
import '../../models/health_goal.dart';
import '../../services/auth_service.dart';
import '../../widgets/tv1_glass_widgets.dart';

class HealthGoalScreen extends StatefulWidget {
  const HealthGoalScreen({super.key});

  @override
  State<HealthGoalScreen> createState() => _HealthGoalScreenState();
}

class _HealthGoalScreenState extends State<HealthGoalScreen> {
  final _goalController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late List<HealthGoal> _goals;
  late int _userId;

  @override
  void initState() {
    super.initState();
    final authService = AuthService();
    _userId = authService.currentUser?.id ?? 1;
    _goals = List.from(authService.getGoals(_userId));
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  void _handleAddGoal() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final newGoalText = _goalController.text.trim();

    // Thêm mục tiêu vào AuthService in-memory & SQLite
    final newGoal = AuthService().addGoal(_userId, newGoalText);

    setState(() {
      _goals.add(newGoal);
    });

    _goalController.clear();

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã thêm mục tiêu sức khỏe.'),
        backgroundColor: Color(0xFF0284C7),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleDeleteGoal(HealthGoal item, {bool showSnackBar = true}) {
    AuthService().deleteGoal(_userId, item.id);

    setState(() {
      _goals.removeWhere((g) => g.id == item.id);
    });

    if (showSnackBar) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa mục tiêu sức khỏe.'),
          backgroundColor: Color(0xFF0284C7),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tv1GlassScaffold(
      appBar: const Tv1GlassAppBar(
        title: Text(
          'Mục tiêu sức khỏe',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Khối nhập mục tiêu mới (Tấm kính Aurora Borealis)
            Tv1GlassCard(
              padding: const EdgeInsets.all(18.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _goalController,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: Tv1GlassTheme.inputDecoration(
                        labelText: 'Nhập mục tiêu sức khỏe',
                        hintText: 'Ví dụ: Đi bộ 10.000 bước mỗi ngày',
                        prefixIcon: const Icon(Icons.flag_outlined, color: Color(0xFF7DD3FC)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Mục tiêu sức khỏe không được để trống.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _handleAddGoal,
                        icon: const Icon(Icons.add),
                        label: const Text(
                          'Thêm mục tiêu',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: Tv1GlassTheme.primaryButtonStyle(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tiêu đề danh sách mục tiêu
            Row(
              children: [
                const Icon(Icons.track_changes, color: Color(0xFF7DD3FC)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Danh sách mục tiêu (${_goals.length})',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Danh sách các mục tiêu (hỗ trợ vuốt để xóa và nút thùng rác)
            if (_goals.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Center(
                  child: Text(
                    'Chưa có mục tiêu sức khỏe nào.\nHãy thêm mục tiêu đầu tiên của bạn!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _goals.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = _goals[index];
                  return Dismissible(
                    key: Key('goal_${item.id}_${item.goal}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(Icons.delete_outline, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Xóa',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    onDismissed: (_) {
                      _handleDeleteGoal(item, showSnackBar: true);
                    },
                    child: Tv1GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.35),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Color(0xFFE0F2FE),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          item.goal,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFFF6B6B),
                          ),
                          tooltip: 'Xóa mục tiêu',
                          onPressed: () => _handleDeleteGoal(item, showSnackBar: true),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
