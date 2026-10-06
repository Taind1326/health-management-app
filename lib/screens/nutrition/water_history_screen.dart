import 'package:flutter/material.dart';

class WaterHistoryScreen extends StatelessWidget {
  const WaterHistoryScreen({super.key});

  final List<Map<String, String>> history = const [
    {
      'time': '08:00',
      'amount': '250 ml',
    },
    {
      'time': '10:30',
      'amount': '250 ml',
    },
    {
      'time': '13:00',
      'amount': '500 ml',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử nước'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: history.length,
        separatorBuilder: (context, index) {
          return const SizedBox(height: 10);
        },
        itemBuilder: (context, index) {
          final item = history[index];

          return Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.water_drop),
              ),
              title: Text(
                item['amount']!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Thời gian: ${item['time']}',
              ),
            ),
          );
        },
      ),
    );
  }
}