import 'package:flutter/material.dart';
import 'water_history_screen.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  int currentWater = 1000;
  final int waterGoal = 2000;

  void addWater(int amount) {
    setState(() {
      currentWater += amount;

      if (currentWater > waterGoal) {
        currentWater = waterGoal;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double progress = currentWater / waterGoal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theo dõi nước'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.water_drop,
                    size: 60,
                    color: Colors.blue,
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
                  Text(
                    'Mục tiêu mẫu: $waterGoal ml',
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
                    onPressed: () {
                      addWater(250);
                    },
                    child: const Text('+250 ml'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      addWater(500);
                    },
                    child: const Text('+500 ml'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WaterHistoryScreen(),
                    ),
                  );
                },
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