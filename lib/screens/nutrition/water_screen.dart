
import 'package:flutter/material.dart';

import '../../controllers/water_controller.dart';
import '../../services/auth_service.dart';
import 'water_history_screen.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  final WaterController controller = WaterController.instance;

  bool _isInitializing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onControllerChanged);
    _initialize();
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initialize() async {
    final userId = AuthService().currentUser?.id;

    if (userId == null) {
      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _error =
            'Không tìm thấy tài khoản đăng nhập. '
            'Vui lòng đăng nhập lại.';
      });

      return;
    }

    // Sử dụng dữ liệu hiện tại nếu Controller đã tải đúng tài khoản.
    if (controller.currentUserId == userId &&
        !controller.isLoading &&
        controller.error == null) {
      _isInitializing = false;
      _error = null;
      return;
    }

    try {
      await controller.initialize(userId);

      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _addWater(int amount) async {
    try {
      await controller.addWater(amount);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã ghi nhận $amount ml nước.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể ghi nhận nước: $e'),
        ),
      );
    }
  }

  Future<void> _editGoal() async {
    final newGoal = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return _WaterGoalDialog(
          initialGoal: controller.waterGoalMl,
        );
      },
    );

    if (!mounted || newGoal == null) return;

    try {
      await controller.updateWaterGoal(newGoal);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể cập nhật mục tiêu: $e'),
        ),
      );
    }
  }

  Future<void> _openHistory() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const WaterHistoryScreen(),
      ),
    );

    if (!mounted) return;

    try {
      await controller.refresh();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tải lịch sử nước: $e'),
        ),
      );
    }
  }

  Widget _buildError() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theo dõi nước'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Không thể tải dữ liệu nước.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isInitializing = true;
                    _error = null;
                  });

                  _initialize();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Theo dõi nước'),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return _buildError();
    }

    final currentWater = controller.todayWaterTotalMl;
    final waterGoal = controller.waterGoalMl;

    final progress = waterGoal > 0
        ? (currentWater / waterGoal).clamp(0.0, 1.0).toDouble()
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theo dõi nước'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.water_drop,
                    size: 60,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$currentWater ml',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Mục tiêu: $waterGoal ml'),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _editGoal,
                    icon: const Icon(Icons.edit),
                    label: const Text('Chỉnh mục tiêu'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              borderRadius: BorderRadius.circular(10),
            ),

            const SizedBox(height: 10),

            Text(
              '${(progress * 100).toInt()}% tiến độ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Thêm nước',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _addWater(250),
                    child: const Text('+250 ml'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _addWater(500),
                    child: const Text('+500 ml'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _openHistory,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Xem lịch sử nước'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaterGoalDialog extends StatefulWidget {
  final int initialGoal;

  const _WaterGoalDialog({
    required this.initialGoal,
  });

  @override
  State<_WaterGoalDialog> createState() => _WaterGoalDialogState();
}

class _WaterGoalDialogState extends State<_WaterGoalDialog> {
  late final TextEditingController _controller;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.initialGoal.toString(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chỉnh mục tiêu nước'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Mục tiêu nước (ml)',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            final goal = int.tryParse(value?.trim() ?? '');

            if (goal == null || goal <= 0) {
              return 'Nhập số nguyên dương.';
            }

            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(
                context,
                int.parse(_controller.text.trim()),
              );
            }
          },
          child: const Text('Lưu mục tiêu'),
        ),
      ],
    );
  }
}
