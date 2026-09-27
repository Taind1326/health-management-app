import 'package:flutter/material.dart';
import '../../models/health_goal.dart';

class HealthGoalScreen extends StatefulWidget {
  const HealthGoalScreen({super.key});

  @override
  State<HealthGoalScreen> createState() => _HealthGoalScreenState();
}

class _HealthGoalScreenState extends State<HealthGoalScreen> {
  final _goalController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Dữ liệu mẫu (Sample data/in-memory) cho prototype
  final List<HealthGoal> _goals = [
    HealthGoal(
      id: 1,
      userId: 1,
      goal: 'Tập thể dục 30 phút mỗi ngày',
    ),
    HealthGoal(
      id: 2,
      userId: 1,
      goal: 'Uống đủ 2 lít nước mỗi ngày',
    ),
  ];

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

    final newGoal = HealthGoal(
      id: DateTime.now().millisecondsSinceEpoch,
      userId: 1,
      goal: newGoalText,
    );

    setState(() {
      _goals.add(newGoal);
    });

    _goalController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã thêm mục tiêu sức khỏe.'),
        backgroundColor: Colors.teal,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mục tiêu sức khỏe'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Khối nhập mục tiêu mới
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _goalController,
                      decoration: const InputDecoration(
                        labelText: 'Nhập mục tiêu sức khỏe',
                        hintText: 'Ví dụ: Đi bộ 10.000 bước mỗi ngày',
                        prefixIcon: Icon(Icons.flag_outlined, color: Colors.teal),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Mục tiêu sức khỏe không được để trống.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _handleAddGoal,
                        icon: const Icon(Icons.add),
                        label: const Text(
                          'Thêm mục tiêu',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tiêu đề danh sách mục tiêu
              Row(
                children: [
                  const Icon(Icons.track_changes, color: Colors.teal),
                  const SizedBox(width: 8),
                  Text(
                    'Danh sách mục tiêu (${_goals.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Danh sách các mục tiêu
              Expanded(
                child: _goals.isEmpty
                    ? const Center(
                        child: Text(
                          'Chưa có mục tiêu sức khỏe nào.\nHãy thêm mục tiêu đầu tiên của bạn!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _goals.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _goals[index];
                          return Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.teal.shade100),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.teal.shade50,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.teal,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                item.goal,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
