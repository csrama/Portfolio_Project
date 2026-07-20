import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dependent_provider.dart';
import 'dependent_dashboard_screen.dart';
import 'add_dependent_screen.dart'; 

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
    final ageController = TextEditingController();
    String? selectedRelationship;

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
        child: StatefulBuilder(
          builder: (context, setState) {
            return Column(
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
                    labelText: 'العمر (اختياري)',
                    border: OutlineInputBorder(),
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: selectedRelationship,
                  decoration: const InputDecoration(
                    labelText: 'صلة القرابة',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'spouse', child: Text('زوج/زوجة')),
                    DropdownMenuItem(value: 'child', child: Text('ابن/ابنة')),
                    DropdownMenuItem(value: 'parent', child: Text('أب/أم')),
                    DropdownMenuItem(value: 'sibling', child: Text('أخ/أخت')),
                    DropdownMenuItem(value: 'other', child: Text('أخرى')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedRelationship = value;
                    });
                  },
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      if (nameController.text.isNotEmpty &&
                          selectedRelationship != null) {
                        final auth = context.read<AuthProvider>();

                        if (auth.accessToken == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Access Token is NULL"),
                            ),
                          );
                          return;
                        }

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
                            'relationship': selectedRelationship,
                            if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
                          },
                        );

                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم إضافة التابع بنجاح'),
                              backgroundColor: Color(0xFF085041),
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('الرجاء إدخال الاسم واختيار العلاقة'),
                          ),
                        );
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
                    backgroundColor: const Color(0xFF085041),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'إضافة',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التابعين'),
        backgroundColor: const Color(0xFF085041),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.mail_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddDependentScreen(),
                ),
              ).then((_) {
                final auth = context.read<AuthProvider>();
                if (auth.accessToken != null) {
                  context.read<DependentProvider>().fetchDependents(auth.accessToken!);
                }
              });
            },
            tooltip: 'إرسال دعوة',
          ),
        ],
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
                    Navigator.pop(context, true);
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
        backgroundColor: const Color(0xFF085041),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}