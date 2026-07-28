import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dependent_provider.dart';
import '../../models/dependent.dart';
import 'dependent_dashboard_screen.dart';
import 'add_dependent_screen.dart';
import '../../i18n/strings.dart';

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
    bool isProcessing = false;
    String? resultMessage;
    bool showInviteLink = false;
    String? generatedLink;
    bool linkCopied = false;
    bool inviteMode = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  Strings.tr(context, 'add_dependent_title'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() {
                            inviteMode = true;
                            resultMessage = null;
                            showInviteLink = false;
                            generatedLink = null;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: inviteMode
                                  ? const Color(0xFF085041)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              Strings.tr(context, 'send_invite'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: inviteMode
                                    ? Colors.white
                                    : Colors.black54,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() {
                            inviteMode = false;
                            resultMessage = null;
                            showInviteLink = false;
                            generatedLink = null;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !inviteMode
                                  ? const Color(0xFF085041)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              Strings.tr(context, 'add_directly'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: !inviteMode
                                    ? Colors.white
                                    : Colors.black54,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: inviteMode
                        ? const Color(0xFFD9F2E7)
                        : const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        inviteMode
                            ? Icons.mail_outline
                            : Icons.person_add_alt_1,
                        size: 18,
                        color: inviteMode
                            ? const Color(0xFF085041)
                            : const Color(0xFF856404),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          inviteMode
                              ? Strings.tr(context, 'will_send_invite')
                              : Strings.tr(context, 'will_add_directly'),
                          style: TextStyle(
                            fontSize: 12,
                            color: inviteMode
                                ? const Color(0xFF085041)
                                : const Color(0xFF856404),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (resultMessage == null && !showInviteLink) ...[
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: Strings.tr(context, 'full_name'),
                      border: const OutlineInputBorder(),
                    ),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: ageController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: Strings.tr(context, 'age_optional'),
                      border: const OutlineInputBorder(),
                    ),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRelationship,
                    decoration: InputDecoration(
                      labelText: Strings.tr(context, 'relationship_label'),
                      border: const OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'spouse',
                        child: Text('زوج/زوجة'),
                      ),
                      DropdownMenuItem(value: 'child', child: Text('ابن/ابنة')),
                      DropdownMenuItem(value: 'parent', child: Text('أب/أم')),
                      DropdownMenuItem(value: 'sibling', child: Text('أخ/أخت')),
                      DropdownMenuItem(value: 'other', child: Text('أخرى')),
                    ],
                    onChanged: (value) {
                      setSheetState(() {
                        selectedRelationship = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isProcessing
                        ? null
                        : () async {
                            try {
                              if (nameController.text.isNotEmpty &&
                                  selectedRelationship != null) {
                                final auth = context.read<AuthProvider>();

                                if (auth.accessToken == null) {
                                  ScaffoldMessenger.of(
                                    sheetContext,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        Strings.tr(
                                          context,
                                          'please_login_first',
                                        ),
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                String? dateOfBirth;
                                final age = int.tryParse(
                                  ageController.text.trim(),
                                );
                                if (age != null && age > 0) {
                                  final now = DateTime.now();
                                  dateOfBirth = DateTime(
                                    now.year - age,
                                    now.month,
                                    now.day,
                                  ).toIso8601String();
                                }

                                setSheetState(() => isProcessing = true);

                                Map<String, dynamic> response;
                                if (inviteMode) {
                                  response = await context
                                      .read<DependentProvider>()
                                      .addDependent(auth.accessToken!, {
                                        'full_name': nameController.text,
                                        'relationship': selectedRelationship,
                                        if (dateOfBirth != null)
                                          'date_of_birth': dateOfBirth,
                                      });
                                } else {
                                  response = await context
                                      .read<DependentProvider>()
                                      .addDependentDirect(auth.accessToken!, {
                                        'full_name': nameController.text,
                                        'relationship': selectedRelationship,
                                        if (dateOfBirth != null)
                                          'date_of_birth': dateOfBirth,
                                      });
                                }

                                if (response['success'] == true) {
                                  if (inviteMode) {
                                    final data =
                                        response['data']
                                            as Map<String, dynamic>? ??
                                        {};
                                    final inviteLink =
                                        data['invite_link'] as String? ?? '';
                                    setSheetState(() {
                                      isProcessing = false;
                                      generatedLink = inviteLink;
                                      showInviteLink = true;
                                      linkCopied = false;
                                    });
                                  } else {
                                    setSheetState(() {
                                      isProcessing = false;
                                      resultMessage = Strings.tr(
                                        context,
                                        'dependent_added_success',
                                      );
                                    });
                                  }
                                } else {
                                  setSheetState(() {
                                    isProcessing = false;
                                    resultMessage =
                                        response['error'] ??
                                        Strings.tr(context, 'operation_failed');
                                  });
                                }
                              } else {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      Strings.tr(context, 'missing_data'),
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              print("ADD DEPENDENT ERROR: $e");
                              setSheetState(() => isProcessing = false);
                              if (mounted) {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
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
                    child: isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            inviteMode
                                ? Strings.tr(context, 'generate_invite_link')
                                : Strings.tr(context, 'add_dependent'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ] else if (showInviteLink && generatedLink != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FFF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: linkCopied
                            ? const Color(0xFF1D9E75)
                            : const Color(0xFF085041),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              linkCopied ? Icons.check_circle : Icons.link,
                              color: linkCopied
                                  ? const Color(0xFF1D9E75)
                                  : const Color(0xFF085041),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              linkCopied
                                  ? Strings.tr(context, 'link_copied')
                                  : Strings.tr(context, 'invite_link_label'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: linkCopied
                                    ? const Color(0xFF1D9E75)
                                    : const Color(0xFF085041),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SelectableText(
                          generatedLink!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF085041),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: generatedLink!),
                              );
                              setSheetState(() => linkCopied = true);
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    Strings.tr(context, 'link_copied_message'),
                                  ),
                                  backgroundColor: const Color(0xFF085041),
                                ),
                              );
                            },
                            icon: Icon(
                              linkCopied ? Icons.check : Icons.copy,
                              size: 18,
                            ),
                            label: Text(
                              linkCopied
                                  ? Strings.tr(context, 'link_copied')
                                  : Strings.tr(context, 'copy_link'),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF085041),
                              side: const BorderSide(color: Color(0xFF085041)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else if (resultMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: resultMessage!.contains('نجاح')
                          ? const Color(0xFFF0FFF4)
                          : const Color(0xFFFFF0F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          resultMessage!.contains('نجاح')
                              ? Icons.check_circle
                              : Icons.error,
                          size: 48,
                          color: resultMessage!.contains('نجاح')
                              ? const Color(0xFF1D9E75)
                              : Colors.red,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          resultMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: resultMessage!.contains('نجاح')
                                ? const Color(0xFF085041)
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (resultMessage != null || showInviteLink)
                  ElevatedButton(
                    onPressed: () {
                      final auth = context.read<AuthProvider>();
                      if (auth.accessToken != null) {
                        context.read<DependentProvider>().fetchDependents(
                          auth.accessToken!,
                        );
                      }
                      Navigator.pop(sheetContext, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF085041),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      Strings.tr(context, 'save_and_return'),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
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

  String _getFirstLetter(String? name) {
    if (name == null || name.isEmpty) return '?';
    return name[0];
  }

  String _getSafeName(String? name) {
    if (name == null || name.isEmpty) return 'مستخدم';
    return name;
  }

  static const Map<String, String> _relationshipLabels = {
    'spouse': 'زوج/زوجة',
    'child': 'ابن/ابنة',
    'parent': 'أب/أم',
    'sibling': 'أخ/أخت',
    'other': 'أخرى',
  };

  String _getSafeRelationship(String? relationship) {
    if (relationship == null || relationship.isEmpty) return 'لا يوجد';
    return _relationshipLabels[relationship] ?? relationship;
  }

  void _showEditDialog(Dependent dependent) {
    final nameController = TextEditingController(text: dependent.fullName);
    String? selectedRelationship = dependent.relationship;

    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(Strings.tr(context, 'edit_dependent_title')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  labelText: Strings.tr(context, 'full_name'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedRelationship,
                decoration: InputDecoration(
                  labelText: Strings.tr(context, 'relationship_label'),
                  border: const OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'spouse', child: Text('زوج/زوجة')),
                  DropdownMenuItem(value: 'child', child: Text('ابن/ابنة')),
                  DropdownMenuItem(value: 'parent', child: Text('أب/أم')),
                  DropdownMenuItem(value: 'sibling', child: Text('أخ/أخت')),
                  DropdownMenuItem(value: 'other', child: Text('أخرى')),
                ],
                onChanged: (value) => selectedRelationship = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(Strings.tr(context, 'cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                final auth = context.read<AuthProvider>();
                if (auth.accessToken == null) return;
                final success = await context
                    .read<DependentProvider>()
                    .updateDependent(
                      auth.accessToken!,
                      dependent.id.toString(),
                      {
                        'full_name': nameController.text.trim(),
                        'relationship':
                            selectedRelationship ?? dependent.relationship,
                      },
                    );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? Strings.tr(context, 'data_updated_success')
                            : Strings.tr(context, 'update_failed'),
                      ),
                      backgroundColor: success
                          ? const Color(0xFF1D9E75)
                          : Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF085041),
              ),
              child: Text(
                Strings.tr(context, 'save'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Dependent dependent) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(Strings.tr(context, 'delete_dependent_title')),
          content: Text(
            '${Strings.tr(context, 'delete_dependent_confirm')} "${dependent.fullName}"؟ ${Strings.tr(context, 'delete_dependent_cant_undo')}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(Strings.tr(context, 'cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(
                Strings.tr(context, 'delete'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      final auth = context.read<AuthProvider>();
      if (auth.accessToken == null) return;
      final success = await context.read<DependentProvider>().deleteDependent(
        auth.accessToken!,
        dependent.id.toString(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? Strings.tr(context, 'dependent_deleted_success')
                  : Strings.tr(context, 'delete_failed'),
            ),
            backgroundColor: success ? const Color(0xFF1D9E75) : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Strings.tr(context, 'dependents_list')),
        backgroundColor: const Color(0xFF085041),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.mail_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddDependentScreen()),
              ).then((_) {
                final auth = context.read<AuthProvider>();
                if (auth.accessToken != null) {
                  context.read<DependentProvider>().fetchDependents(
                    auth.accessToken!,
                  );
                }
              });
            },
            tooltip: Strings.tr(context, 'send_invite'),
          ),
        ],
      ),
      body: Consumer<DependentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.dependents.isEmpty) {
            return Center(
              child: Text(Strings.tr(context, 'no_dependents_yet')),
            );
          }

          return ListView.builder(
            itemCount: provider.dependents.length,
            itemBuilder: (context, index) {
              final dependent = provider.dependents[index];
              final isSelected = provider.selectedDependent?.id == dependent.id;

              final String displayName = _getSafeName(dependent.fullName);
              final String firstLetter = _getFirstLetter(dependent.fullName);
              final String displayRelationship = _getSafeRelationship(
                dependent.relationship,
              );

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF085041),
                    child: Text(
                      firstLetter,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(displayName),
                  subtitle: Text(displayRelationship),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Color(0xFF085041),
                          size: 20,
                        ),
                        onPressed: () => _showEditDialog(dependent),
                        tooltip: Strings.tr(context, 'edit'),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: () => _confirmDelete(dependent),
                        tooltip: Strings.tr(context, 'delete'),
                      ),
                      if (isSelected)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.check_circle,
                            color: Color(0xFF1D9E75),
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                  onTap: () async {
                    provider.selectDependent(dependent);
                    Navigator.pop(context, true);
                  },
                  onLongPress: () async {
                    final changed = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            DependentDashboardScreen(dependent: dependent),
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
