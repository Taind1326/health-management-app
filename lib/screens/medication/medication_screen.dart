import 'package:flutter/material.dart';

import '../../models/medication.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  // Dữ liệu mẫu phục vụ prototype đợt 1.
  final List<Medication> _medications = [
    const Medication(
      id: 'medication-001',
      userId: 'demo-user',
      name: 'Thuốc mẫu A',
      dosage: '1',
      unit: 'viên',
      note: 'Dữ liệu minh họa cho giao diện.',
    ),
    const Medication(
      id: 'medication-002',
      userId: 'demo-user',
      name: 'Thuốc mẫu B',
      dosage: '5',
      unit: 'ml',
    ),
  ];

  void _showUpcomingFeature(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature sẽ được bổ sung ở bước tiếp theo.')),
    );
  }

  Future<void> _deleteMedication(Medication medication) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xóa thuốc'),
          content: Text('Bạn muốn xóa "${medication.name}" khỏi danh sách?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    setState(() {
      _medications.removeWhere((item) => item.id == medication.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa thuốc khỏi danh sách.')),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.medication_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Bạn chưa thêm thuốc nào',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Thêm thuốc khi bạn cần theo dõi lịch uống.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _showUpcomingFeature('Thêm thuốc'),
              icon: const Icon(Icons.add),
              label: const Text('Thêm thuốc'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationCard(Medication medication) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medication_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    medication.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Tùy chọn thuốc',
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showUpcomingFeature('Sửa thuốc');
                    } else if (value == 'delete') {
                      _deleteMedication(medication);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Sửa thuốc')),
                    PopupMenuItem(value: 'delete', child: Text('Xóa thuốc')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Liều mỗi lần: ${medication.dosage} ${medication.unit}'),
            if (medication.note.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Ghi chú: ${medication.note}'),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _showUpcomingFeature('Lịch uống thuốc'),
              icon: const Icon(Icons.schedule),
              label: const Text('Lịch uống'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thuốc & Nhắc nhở'),
        actions: [
          IconButton(
            tooltip: 'Lịch sử uống thuốc',
            onPressed: () => _showUpcomingFeature('Lịch sử uống thuốc'),
            icon: const Icon(Icons.history),
          ),
          IconButton(
            tooltip: 'Quản lý nhắc nhở',
            onPressed: () => _showUpcomingFeature('Quản lý nhắc nhở'),
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: _medications.isEmpty
          ? _buildEmptyState()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                Text(
                  'Danh sách thuốc (${_medications.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text('Dữ liệu mẫu để minh họa giao diện.'),
                const SizedBox(height: 16),
                ..._medications.map(_buildMedicationCard),
              ],
            ),
      floatingActionButton: _medications.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showUpcomingFeature('Thêm thuốc'),
              icon: const Icon(Icons.add),
              label: const Text('Thêm thuốc'),
            ),
    );
  }
}
