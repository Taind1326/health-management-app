import 'package:flutter/material.dart';

class FoodDetailScreen extends StatelessWidget {
  final Map<String, dynamic> food;

  const FoodDetailScreen({
    super.key,
    required this.food,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết món ăn'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.restaurant,
                size: 80,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              food['name'],
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _InfoRow(
              title: 'Calo',
              value: '${food['calories']} kcal',
            ),
            _InfoRow(
              title: 'Protein',
              value: '${food['protein']} g',
            ),
            _InfoRow(
              title: 'Carb',
              value: '${food['carb']} g',
            ),
            _InfoRow(
              title: 'Fat',
              value: '${food['fat']} g',
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String value;

  const _InfoRow({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}