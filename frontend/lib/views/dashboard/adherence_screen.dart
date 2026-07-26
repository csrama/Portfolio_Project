import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/medication_item.dart';
import '../../i18n/strings.dart';

class _Colors {
  static const Color primaryGreen = Color(0xFF1D9E75);
  static const Color darkGreen = Color(0xFF085041);
  static const Color lightGreenBg = Color(0xFFD9F2E7);
  static const Color textSecondary = Colors.black54;
  static const Color borderGrey = Color(0xFFE0E0E0);
}

class AdherenceScreen extends StatefulWidget {
  final List<MedicationItem> medications;

  const AdherenceScreen({super.key, required this.medications});

  @override
  State<AdherenceScreen> createState() => _AdherenceScreenState();
}

class _AdherenceScreenState extends State<AdherenceScreen> {
  bool _loading = true;
  int _rate = 0;
  int _completed = 0;
  int _total = 0;
  List<Map<String, dynamic>> _records = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.accessToken;

    if (token == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final rateData = await ApiService.getJsonDynamic(
        '/adherence/rate',
        token: token,
      );
      final records = await ApiService.getJsonList('/dose-logs', token: token);

      records.sort((a, b) {
        final aTime =
            DateTime.tryParse((a['scheduled_time'] ?? '').toString()) ??
            DateTime(0);
        final bTime =
            DateTime.tryParse((b['scheduled_time'] ?? '').toString()) ??
            DateTime(0);
        return bTime.compareTo(aTime);
      });

      if (!mounted) return;
      setState(() {
        _rate = (rateData is Map ? rateData['adherence_rate'] as int? : 0) ?? 0;
        _completed = (rateData is Map ? rateData['completed'] as int? : 0) ?? 0;
        _total = (rateData is Map ? rateData['total'] as int? : 0) ?? 0;
        _records = List<Map<String, dynamic>>.from(records);
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading adherence data: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _medicationName(dynamic medicationId) {
    for (final m in widget.medications) {
      if (m.id == medicationId.toString()) return m.name;
    }
    return '';
  }

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/${dt.year} - $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: _Colors.darkGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(Strings.tr(context, 'adherence_tracking')),
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildRateCard(),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              Strings.tr(context, 'adherence_rate'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_records.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Text(
                  'لا توجد سجلات',
                  style: TextStyle(color: _Colors.textSecondary),
                ),
              ),
            )
          else
            ..._records.map((r) => _buildRecordTile(r, theme)),
        ],
      ),
    );
  }

  Widget _buildRateCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: _Colors.lightGreenBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            '$_rate%',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: _Colors.darkGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Strings.tr(context, 'adherence_rate_percent'),
            style: const TextStyle(color: _Colors.textSecondary),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatColumn(
                '$_completed',
                Strings.tr(context, 'doses_taken'),
              ),
              Container(width: 1, height: 32, color: _Colors.borderGrey),
              _buildStatColumn('$_total', Strings.tr(context, 'total_doses')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _Colors.darkGreen,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: _Colors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildRecordTile(Map<String, dynamic> record, ThemeData theme) {
    final status = (record['status'] ?? '').toString();
    final doseTaken = record['dose_taken'] == true;
    final taken = status == 'TAKEN' || doseTaken;

    final scheduledRaw = record['scheduled_time'];
    final scheduled = scheduledRaw != null
        ? DateTime.tryParse(scheduledRaw.toString())
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: taken ? _Colors.lightGreenBg : const Color(0xFFFBEAEA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            taken ? Icons.check_circle : Icons.schedule,
            color: taken ? _Colors.primaryGreen : Colors.redAccent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _medicationName(record['medication_id']),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                if (scheduled != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatDateTime(scheduled),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _Colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            taken
                ? Strings.tr(context, 'medication_taken')
                : Strings.tr(context, 'medication_not_taken'),
            style: TextStyle(
              color: taken ? _Colors.darkGreen : Colors.redAccent,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
