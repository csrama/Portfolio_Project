import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dependent_provider.dart';
import '../../services/dependent_service.dart';
import '../../models/dependent.dart';
import 'dependent_dashboard_screen.dart';

class DependentsScreen extends StatefulWidget {
  const DependentsScreen({super.key});

  @override
  State<DependentsScreen> createState() => _DependentsScreenState();
}

class _DependentsScreenState extends State<DependentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.accessToken != null) {
        context.read<DependentProvider>().fetchDependents(auth.accessToken!);
      }
    });
  }

  void _showAddDependentSheet() {
    final nameController = TextEditingController();
    final relationshipController = TextEditingController();
    final ageController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'إضافة تابع جديد',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'الاسم الكامل',
                border: OutlineInputBorder(),
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'العمر',
                border: OutlineInputBorder(),
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: relationshipController,
              decoration: const InputDecoration(
                labelText: 'صلة القرابة (مثلاً: أب، أم، ابن)',
                border: OutlineInputBorder(),
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
  onPressed: () async {
    try {
      if (nameController.text.isNotEmpty &&
          relationshipController.text.isNotEmpty) {

        final auth = context.read<AuthProvider>();

        print("TOKEN = ${auth.accessToken}");

        if (auth.accessToken == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Access Token is NULL"),
            ),
          );
          return;
        }

        // نحول العمر لتاريخ ميلاد تقريبي (نفس اليوم/الشهر، السنة بس تفرق)
        // لأن الباك إند يخزن date_of_birth مو رقم عمر مباشر
        String? dateOfBirth;
        final age = int.tryParse(ageController.text.trim());
        if (age != null && age > 0) {
          final now = DateTime.now();
          dateOfBirth = DateTime(now.year - age, now.month, now.day)
              .toIso8601String();
        }

        await context.read<DependentProvider>().addDependent(
          auth.accessToken!,
          {
            'full_name': nameController.text,
            'relationship': relationshipController.text,
            if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
          },
        );
        print("DEPENDENT ADDED SUCCESS");

        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print("ADD DEPENDENT ERROR: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF1D9E75),
    padding: const EdgeInsets.symmetric(vertical: 15),
  ),
  child: const Text(
    'حفظ',
    style: TextStyle(color: Colors.white),
  ),
),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التابعين'),
        backgroundColor: const Color(0xFF1D9E75),
        foregroundColor: Colors.white,
      ),
      body: Consumer<DependentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.dependents.isEmpty) {
            return const Center(
              child: Text('لم تقم بإضافة أي تابعين بعد'),
            );
          }

          return ListView.builder(
            itemCount: provider.dependents.length,
            itemBuilder: (context, index) {
              final dependent = provider.dependents[index];
              final isSelected = provider.selectedDependent?.id == dependent.id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF085041),
                    child: Text(
                      dependent.fullName[0],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(dependent.fullName),
                  subtitle: Text(dependent.relationship),
                  trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Color(0xFF1D9E75))
                    : null,
                  onTap: () async {

                    provider.selectDependent(dependent);

                    Navigator.pop(
                      context,
                      true,
                    );

                  },
                  onLongPress: () async {
                    final changed = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DependentDashboardScreen(
                          dependent: dependent,
                        ),
                      ),
                    );

                    if (changed == true && mounted) {
                      final auth = context.read<AuthProvider>();

                      if (auth.accessToken != null) {
                        context.read<DependentProvider>().fetchDependents(
                          auth.accessToken!,
                        );
                      }
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDependentSheet,
        backgroundColor: const Color(0xFF1D9E75),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}