import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dependent_provider.dart';
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
      _loadDependents();
    });
  }

 
  Future<void> _loadDependents() async {
    try {
      await context.read<DependentProvider>().fetchDependents();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تحميل التابعين: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  
  void _showAddDependentSheet() {
    final nameController = TextEditingController();
    final relationshipController = TextEditingController();
    final formKey = GlobalKey<FormState>();

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
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'إضافة تابع جديد',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 48), 
                ],
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: nameController,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'الاسم الكامل *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'الرجاء إدخال الاسم الكامل';
                  }
                  if (value.trim().length < 3) {
                    return 'الاسم يجب أن يكون 3 أحرف على الأقل';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              
              TextFormField(
                controller: relationshipController,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'صلة القرابة * (مثلاً: أب، أم، ابن)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.family_restroom),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'الرجاء إدخال صلة القرابة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) {
                          return;
                        }

                        setState(() {});
                        
                        try {
                          final success = await context
                              .read<DependentProvider>()
                              .addDependent(
                                name: nameController.text.trim(),
                                relationship: relationshipController.text.trim(),
                              );

                          if (success && mounted) {
                            Navigator.pop(context);
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(' تم إضافة التابع بنجاح'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(' فشل الإضافة: $e'),
                                backgroundColor: Colors.red,
                              ),
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
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }


  Future<void> _deleteDependent(Dependent dependent) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف تابع'),
        content: Text('هل أنت متأكد من حذف "${dependent.fullName}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await context
          .read<DependentProvider>()
          .deleteDependent(dependent.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(' تم حذف التابع بنجاح'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' فشل الحذف: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  

  void _navigateToDashboard(Dependent dependent) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DependentDashboardScreen(
          dependentId: dependent.id,
          dependentName: dependent.fullName,
        ),
      ),
    );
  }

  void _selectDependent(Dependent dependent) {
    context.read<DependentProvider>().selectDependent(dependent);
    Navigator.pop(context); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التابعين'),
        backgroundColor: const Color(0xFF1D9E75),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDependents,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Consumer<DependentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF1D9E75),
                  ),
                  SizedBox(height: 16),
                  Text('جاري تحميل التابعين...'),
                ],
              ),
            );
          }

          if (provider.dependents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'لا يوجد تابعين',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'أضف تابعاً جديداً بالضغط على زر +',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadDependents,
            color: const Color(0xFF1D9E75),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: provider.dependents.length,
              itemBuilder: (context, index) {
                final dependent = provider.dependents[index];
                final isSelected = provider.selectedDependent?.id == dependent.id;

                return _buildDependentCard(dependent, isSelected);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDependentSheet,
        backgroundColor: const Color(0xFF1D9E75),
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'إضافة تابع جديد',
      ),
    );
  }

  

  Widget _buildDependentCard(Dependent dependent, bool isSelected) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: Color(0xFF1D9E75), width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSelected 
              ? const Color(0xFF1D9E75) 
              : const Color(0xFF085041),
          child: Text(
            dependent.fullName.isNotEmpty 
                ? dependent.fullName[0].toUpperCase() 
                : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          dependent.fullName,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(dependent.relationship),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF1D9E75),
                size: 24,
              ),
            
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'dashboard':
                    _navigateToDashboard(dependent);
                    break;
                  case 'select':
                    _selectDependent(dependent);
                    break;
                  case 'delete':
                    _deleteDependent(dependent);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'select',
                  child: Row(
                    children: [
                      Icon(Icons.check, color: Color(0xFF1D9E75)),
                      SizedBox(width: 8),
                      Text('تحديد كـتابع نشط'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'dashboard',
                  child: Row(
                    children: [
                      Icon(Icons.dashboard, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('لوحة التحكم'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('حذف'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _selectDependent(dependent),
        onLongPress: () => _navigateToDashboard(dependent),
      ),
    );
  }
}
