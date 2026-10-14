import 'package:flutter/material.dart';

import 'nutrition_store.dart';

class WaterHistoryScreen extends StatelessWidget {
  const WaterHistoryScreen({super.key});

  String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();

    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final store = NutritionStore.instance;
    final history = store.waterHistory;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử nước'),
      ),
      body: history.isEmpty
          ? const Center(
              child: Text(
                'Chưa có bản ghi uống nước.',
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              separatorBuilder: (context, index) {
                return const SizedBox(height: 10);
              },
              itemBuilder: (context, index) {
                final record = history[index];

                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.water_drop),
                    ),
                    title: Text(
                      '${record.amountMl} ml',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      _formatDateTime(record.recordedAt),
                    ),
                  ),
                );
              },
            ),
    );
  }
}