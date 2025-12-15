import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/session/workspace_session.dart';
import '../workspace/permissions.dart';

class StaffPage extends StatelessWidget {
  StaffPage({super.key}) : _firestore = FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<WorkspaceSession>(context, listen: true);
    final workspaceId = session.activeWorkspaceId;
    final role = session.memberRole;

    if (!canManageStaff(role)) {
      return const Scaffold(
        body: Center(child: Text('Accesso limitato allo staff admin.')),
      );
    }

    if (workspaceId == null) {
      return const Scaffold(
        body: Center(child: Text('Seleziona un workspace per gestire lo staff.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff / Dipendenti'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('workspaces')
            .doc(workspaceId)
            .collection('members')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Errore nel caricamento: ${snapshot.error}'),
            );
          }

          final members = snapshot.data?.docs ?? [];
          if (members.isEmpty) {
            return const Center(
              child: Text('Nessun membro ancora. Invita un dipendente.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: members.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final memberDoc = members[index];
              final memberRole = memberDoc.data()['role'] as String? ?? 'staff';
              return ListTile(
                title: _MemberEmail(uid: memberDoc.id, firestore: _firestore),
                subtitle: Text('Ruolo: $memberRole'),
                trailing: canManageStaff(role)
                    ? IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmRemove(
                          context,
                          workspaceId,
                          memberDoc.id,
                        ),
                      )
                    : null,
              );
            },
          );
        },
      ),
      floatingActionButton: canManageStaff(role)
          ? FloatingActionButton.extended(
              onPressed: () => _promptInvite(context, workspaceId),
              label: const Text('Invita dipendente'),
              icon: const Icon(Icons.person_add_alt_1),
            )
          : null,
    );
  }

  Future<void> _promptInvite(BuildContext context, String workspaceId) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invita dipendente'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Email dipendente',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Invita'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _inviteByEmail(context, workspaceId, controller.text.trim());
    }
  }

  Future<void> _inviteByEmail(
    BuildContext context,
    String workspaceId,
    String email,
  ) async {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci una email valida.')),
      );
      return;
    }

    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Utente non registrato.')),
          );
        }
        return;
      }

      final userDoc = query.docs.first;
      final uid = userDoc.id;
      final userRole = userDoc.data()['role'] as String?;
      if (userRole != 'business') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('L\'utente non è un account business valido.')),
          );
        }
        return;
      }

      final timestamp = FieldValue.serverTimestamp();
      final batch = _firestore.batch();

      final memberRef = _firestore
          .collection('workspaces')
          .doc(workspaceId)
          .collection('members')
          .doc(uid);
      batch.set(memberRef, {
        'role': 'staff',
        'joinedAt': timestamp,
      }, SetOptions(merge: true));

      final membershipRef =
          _firestore.collection('memberships').doc('${uid}_$workspaceId');
      batch.set(membershipRef, {
        'uid': uid,
        'workspaceId': workspaceId,
        'role': 'staff',
        'joinedAt': timestamp,
      }, SetOptions(merge: true));

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invitato $email come staff.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore invito: $e')),
        );
      }
    }
  }

  Future<void> _confirmRemove(
    BuildContext context,
    String workspaceId,
    String uid,
  ) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rimuovere membro?'),
        content: Text('Vuoi rimuovere $uid dallo workspace?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Rimuovi'),
          ),
        ],
      ),
    );

    if (shouldRemove == true) {
      try {
        await _firestore
            .collection('workspaces')
            .doc(workspaceId)
            .collection('members')
            .doc(uid)
            .delete();
        await _firestore.collection('memberships').doc('${uid}_$workspaceId').delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Membro rimosso.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore nella rimozione: $e')),
          );
        }
      }
    }
  }
}

class _MemberEmail extends StatelessWidget {
  const _MemberEmail({required this.uid, required this.firestore});

  final String uid;
  final FirebaseFirestore firestore;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: firestore.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Text(uid);
        }

        final email = snapshot.data!.data()?['email'] as String?;
        return Text(email ?? uid);
      },
    );
  }
}
