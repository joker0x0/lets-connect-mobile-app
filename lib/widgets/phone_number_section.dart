import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/services/firebase_service.dart';

class OfficialPhoneNumbersSection extends StatelessWidget {
  final bool isAdmin;
  final FirebaseService _firebaseService = FirebaseService();

  OfficialPhoneNumbersSection({super.key, this.isAdmin = false});

  void _copyToClipboard(BuildContext context, String number) {
    Clipboard.setData(ClipboardData(text: number));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Phone number copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green[600],
      ),
    );
  }

  void _showEditOptions(BuildContext context, Map<String, dynamic> phoneData) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            runSpacing: 10,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddOrEditDialog(context,
                      id: phoneData['id'],
                      number: phoneData['number'],
                      description: phoneData['description']);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete'),
                onTap: () async {
                  Navigator.pop(context);
                  await _firebaseService.deletePhoneNumber(phoneData['id']);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddOrEditDialog(BuildContext context,
      {String? id, String? number, String? description}) {
    final numberController = TextEditingController(text: number ?? '');
    final descriptionController = TextEditingController(text: description ?? '');

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(id == null ? 'Add Phone Number' : 'Edit Phone Number'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: numberController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            ElevatedButton(
              child: Text(id == null ? 'Add' : 'Update'),
              onPressed: () async {
                final desc = descriptionController.text.trim();
                final num = numberController.text.trim();

                if (desc.isEmpty || num.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill out all fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (id == null) {
                  await _firebaseService.addPhoneNumber(desc, num);
                } else {
                  await _firebaseService.updatePhoneNumber(id, desc, num);
                }

                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _firebaseService.getOfficialPhoneNumbersStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text("Error loading phone numbers."));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final phoneList = snapshot.data!;

            return Column(
              children: [
                if (isAdmin)  
                ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: phoneList.map((phoneData) {
                    final description = phoneData['description'];
                    final number = phoneData['number'];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(description,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(number,
                            style: TextStyle(color: Colors.grey[700])),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon:
                                  const Icon(Icons.copy, color: Colors.blueAccent),
                              onPressed: () => _copyToClipboard(context, number),
                            ),
                            if (isAdmin)
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.orange),
                                onPressed: () =>
                                    _showEditOptions(context, phoneData),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: FloatingActionButton.extended(
                      onPressed: () => _showAddOrEditDialog(context),
                      icon: const Icon(Icons.add, size: 20, color: Colors.white),
                      label: const Text('Add', style: TextStyle(fontSize: 16, color: Colors.white)),
                      backgroundColor: Colors.green[700],
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
