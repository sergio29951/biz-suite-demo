import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateWorkspacePage extends StatefulWidget {
  const CreateWorkspacePage({super.key, required this.user, required this.onWorkspaceCreated});

  final User user;
  final ValueChanged<String> onWorkspaceCreated;

  @override
  State<CreateWorkspacePage> createState() => _CreateWorkspacePageState();
}

class _CreateWorkspacePageState extends State<CreateWorkspacePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final timestamp = FieldValue.serverTimestamp();
      final workspaces = firestore.collection('workspaces');
      final workspaceDoc = await workspaces.add({
        'name': _nameController.text.trim(),
        'createdAt': timestamp,
        'createdByUid': widget.user.uid,
      });

      await workspaceDoc.collection('members').doc(widget.user.uid).set({
        'role': 'admin',
        'joinedAt': timestamp,
      });

      await firestore.collection('memberships').doc('${widget.user.uid}_${workspaceDoc.id}').set({
        'uid': widget.user.uid,
        'workspaceId': workspaceDoc.id,
        'role': 'admin',
        'joinedAt': timestamp,
      });

      widget.onWorkspaceCreated(workspaceDoc.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nella creazione del workspace: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crea workspace')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome attività',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Inserisci un nome';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Crea workspace'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
