import 'package:flutter/material.dart';

import 'nutrition_store.dart';
import 'water_history_screen.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  final NutritionStore store = NutritionStore.instance;

  void _addWater(int amount) {
    store.addWater(amount);
    setState(() {});
  }

  Future<void> _editGoal() async {
    final newGoal = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return const _WaterGoalDialog();
      },
    );

    if (!mounted) return;

    if (newGoal != null) {
      store.updateWaterGoal(newGoal);
      setState(() {});
    }
  }

  Future<void> _openHistory() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const WaterHistoryScreen(),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentWater = store.todayWaterTotalMl;
    final waterGoal = store.waterGoalMl;

    final progress = waterGoal > 0
        ? (currentWater / waterGoal).clamp(0.0, 1.0).toDouble()
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theo dõi nước'),
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
  const _WaterGoalDialog();

  @override
  State<_WaterGoalDialog> createState() => _WaterGoalDialogState();
}

class _WaterGoalDialogState extends State<_WaterGoalDialog> {
  final TextEditingController _controller = TextEditingController(
    text: NutritionStore.instance.waterGoalMl.toString(),
  );

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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