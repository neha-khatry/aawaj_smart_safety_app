import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/contact.dart';
import '../widgets/glass_card.dart';
import '../services/contact_service.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationController = TextEditingController();
  @override
  void initState() {
    super.initState();
    // Fetch contacts automatically when screen opens
    Future.microtask(() {
      Provider.of<AppProvider>(context, listen: false)
          .fetchContactsFromBackend();
    });
  }
  Future<void> _addContact() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in name and phone number'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final provider = Provider.of<AppProvider>(context, listen: false);

    final success = await ContactService.saveContact(
      name: _nameController.text,
      phone: _phoneController.text,
      relation: _relationController.text,
    );

    if (success) {
      _nameController.clear();
      _phoneController.clear();
      _relationController.clear();

      await provider.fetchContactsFromBackend();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Contact saved successfully'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to save contact'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }


  /**void _addContact() {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in name and phone number'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final provider = Provider.of<AppProvider>(context, listen: false);
    provider.addContact(EmergencyContact(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      phone: _phoneController.text,
      relation: _relationController.text,
    ));

    _nameController.clear();
    _phoneController.clear();
    _relationController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Contact added successfully'),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }**/

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Trusted Contacts',
                    style:
                    TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Add Emergency Contact',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'Contact Name',
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _relationController,
                        decoration: const InputDecoration(
                          hintText: 'Relationship (e.g., Sister, Friend)',
                          prefixIcon: Icon(Icons.people),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _addContact,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Contact'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your Emergency Contacts',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      if (provider.contacts.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'No contacts added yet',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ),
                        )
                      else
                        ...provider.contacts.map((contact) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFFec4899),
                                        Color(0xFF8b5cf6)
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      contact.name[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        contact.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        contact.phone,
                                        style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 12),
                                      ),
                                      if (contact.relation.isNotEmpty)
                                        Text(
                                          contact.relation,
                                          style: TextStyle(
                                              color: Colors.pink[400],
                                              fontSize: 12),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    await provider.removeContact(contact.id);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Contact deleted'),
                                        backgroundColor: Colors.red[600],
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  icon: Icon(Icons.delete, color: Colors.red[400]),
                                ),
                              ],
                            ),
                          ),
                        )),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
