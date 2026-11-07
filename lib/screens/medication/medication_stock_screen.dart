import 'package:flutter/material.dart';

import '../../models/medication.dart';
import '../../repositories/medication_repository.dart';
import '../../services/medication_rules.dart';
import 'medication_style.dart';

class MedicationStockScreen extends StatefulWidget {
  final Medication medication;
  const MedicationStockScreen({super.key, required this.medication});
  @override
  State<MedicationStockScreen> createState() => _MedicationStockScreenState();
}

class _MedicationStockScreenState extends State<MedicationStockScreen> {
  late final repo = MedicationRepository(widget.medication.userId);
  Medication? med;
  List<Map<String, Object?>> movements = [];
  String summary = '';
  String? error;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await repo.medications();
      final current = all.firstWhere((m) => m.id == widget.medication.id);
      final schedules = (await repo.schedules())
          .where((s) => s.medicationId == current.id)
          .toList();
      final logs = await repo.logs();
      final moves = await repo.movements(current.id);
      final count = MedicationRules.remainingSevenDays(
        schedules,
        logs,
        DateTime.now(),
      );
      final needed = count * double.parse(current.dosage);
      final label = MedicationRules.courseLabel(schedules, DateTime.now());
      final text =
          '$label\nCòn $count lần chưa xác nhận trong 7 ngày lịch từ hôm nay, cần khoảng ${medNumber(needed)} ${current.unit} theo liều hiện tại.';
      if (!mounted) return;
      setState(() {
        med = current;
        movements = moves;
        summary = text;
        error = null;
      });
    } catch (e) {
      if (mounted) setState(() => error = medError(e));
    }
  }

  Future<void> _adjust(bool add) async {
    final result = await showMedicationDialog<({double amount, String reason})>(
      context: context,
      builder: (_) => _StockDialog(add: add, unit: med!.unit),
    );
    if (!mounted || result == null) return;
    setState(() => busy = true);
    try {
      await repo.adjustStock(
        med!.id,
        result.amount,
        add: add,
        reason: result.reason,
      );
      await _load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(medError(e))));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => MedicationScaffold(
    appBar: AppBar(title: const Text('Lượng thuốc và đợt dùng')),
    body: error != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error!),
                TextButton(onPressed: _load, child: const Text('Tải lại')),
              ],
            ),
          )
        : med == null
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TvStockCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med!.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      med!.stockAmount == null
                          ? 'Chưa bật theo dõi lượng thuốc'
                          : 'Còn ${medNumber(med!.stockAmount!)} ${med!.unit}',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 12),
                    Text(summary),
                    const SizedBox(height: 12),
                    const Text(
                      'Ước tính theo lịch đã nhập, không xác định đã hết bệnh hoặc cần uống tiếp. Nếu lượng thuốc không đủ, kiểm tra đơn và liên hệ bác sĩ/dược sĩ.',
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: busy || med!.stockAmount == null
                              ? null
                              : () => _adjust(true),
                          child: const Text('Ghi nhận bổ sung'),
                        ),
                        OutlinedButton(
                          onPressed: busy ? null : () => _adjust(false),
                          child: Text(
                            med!.stockAmount == null
                                ? 'Nhập lượng hiện có'
                                : 'Đối chiếu lượng thực tế',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Lịch sử thay đổi lượng thuốc',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (movements.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Chưa có thay đổi.'),
                ),
              for (final row in movements)
                MedicationGlassCard(
                  child: ListTile(
                    title: Text(row['reason'] as String),
                    subtitle: Text(
                      '${medTime(DateTime.parse(row['recorded_at'] as String))}\nTồn sau: ${medNumber(row['balance_after'] as num)} ${med!.unit}',
                    ),
                    trailing: Text(
                      '${(row['delta'] as num) > 0 ? '+' : ''}${medNumber(row['delta'] as num)}',
                    ),
                    isThreeLine: true,
                  ),
                ),
            ],
          ),
  );
}

class TvStockCard extends StatelessWidget {
  final Widget child;
  const TvStockCard({super.key, required this.child});
  @override
  Widget build(BuildContext context) => MedicationGlassCard(
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );
}

class _StockDialog extends StatefulWidget {
  final bool add;
  final String unit;
  const _StockDialog({required this.add, required this.unit});
  @override
  State<_StockDialog> createState() => _StockDialogState();
}

class _StockDialogState extends State<_StockDialog> {
  final keyForm = GlobalKey<FormState>();
  final amount = TextEditingController();
  final reason = TextEditingController();
  @override
  void dispose() {
    amount.dispose();
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.add ? 'Ghi nhận thuốc bổ sung' : 'Đối chiếu lượng thực tế',
    ),
    content: SingleChildScrollView(
      child: Form(
        key: keyForm,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText:
                    '${widget.add ? 'Lượng bổ sung' : 'Lượng đang có'} (${widget.unit})',
              ),
              validator: (v) {
                final n = double.tryParse(
                  (v ?? '').trim().replaceAll(',', '.'),
                );
                return n == null ||
                        !n.isFinite ||
                        n < 0 ||
                        (widget.add && n == 0)
                    ? 'Nhập lượng hợp lệ.'
                    : null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: reason,
              decoration: const InputDecoration(labelText: 'Lý do / ghi chú'),
              validator: (v) => (v ?? '').trim().isEmpty
                  ? 'Nhập lý do để lưu lịch sử.'
                  : null,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(
        onPressed: () {
          if (keyForm.currentState!.validate())
            Navigator.pop(context, (
              amount: double.parse(amount.text.trim().replaceAll(',', '.')),
              reason: reason.text.trim(),
            ));
        },
        child: const Text('Lưu'),
      ),
    ],
  );
}
