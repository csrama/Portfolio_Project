import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dependent.dart';
import '../../providers/auth_provider.dart';
import '../../services/dependent_service.dart';

class DependentDashboardScreen extends StatefulWidget {
  final Dependent dependent;

  const DependentDashboardScreen({super.key, required this.dependent});

  @override
  State<DependentDashboardScreen> createState() => _DependentDashboardScreenState();
}

class _DependentDashboardScreenState extends State<DependentDashboardScreen> {
  late Future<List<dynamic>> _medicationsFuture;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final depService = context.read<DependentService>();
    _medicationsFuture = depService.getDependentMedications(auth.accessToken!, widget.dependent.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ملف: ${widget.dependent.fullName}'),
        backgroundColor: const Color(0xFF1D9E75),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dependent Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: const Color(0xFF085041),
                            child: Text(
                              widget.dependent.fullName[0],
                              style: const TextStyle(color: Colors.white, fontSize: 32),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.dependent.fullName,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'صلة القرابة: ${widget.dependent.relationship}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                if (widget.dependent.dateOfBirth != null)
                                  Text(
                                    'تاريخ الميلاد: ${widget.dependent.dateOfBirth!.toString().split(' ')[0]}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (widget.dependent.medicalConditions.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'الحالات الطبية:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: widget.dependent.medicalConditions
                              .map((condition) => Chip(label: Text(condition)))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Medications Section
              const Text(
                'الأدوية',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<dynamic>>(
                future: _medicationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('خطأ: ${snapshot.error}'));
                  }

                  final medications = snapshot.data ?? [];

                  if (medications.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('لم يتم إضافة أي أدوية لهذا التابع بعد'),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: medications.length,
                    itemBuilder: (context, index) {
                      final med = medications[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFD9F2E7),
                            child: const Icon(Icons.medication, color: Color(0xFF1D9E75)),
                          ),
                          title: Text(med['name'] ?? 'دواء'),
                          subtitle: Text(med['dosage'] ?? ''),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
