import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/permissions/permissions.dart';
import '../../core/session/workspace_session.dart';
import 'controllers/customers_controller.dart';
import 'customer_form_page.dart';
import 'models/customer.dart';

class CustomersPage extends StatelessWidget {
  CustomersPage({super.key})
      : _controller = CustomersController(
          repository: CustomersRepository(),
        );
  final CustomersController _controller;

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<WorkspaceSession>(context, listen: true);
    final activeWorkspaceId = session.activeWorkspaceId;
    final workspaceRole = session.memberRole ?? 'admin';

    if (activeWorkspaceId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Seleziona un workspace per gestire i clienti.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clienti'),
      ),
      body: StreamBuilder<List<Customer>>(
        stream: _controller.watchList(activeWorkspaceId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Errore nel caricamento: ${snapshot.error}'),
            );
          }

          final customers = snapshot.data ?? [];
          if (customers.isEmpty) {
            return const Center(
              child: Text('Nessun cliente ancora. Aggiungine uno.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: customers.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final customer = customers[index];
              return Dismissible(
                key: ValueKey(customer.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) => _confirmDelete(
                  context,
                  activeWorkspaceId,
                  customer,
                  workspaceRole,
                ),
                background: Container(
                  color: Colors.red.withOpacity(0.1),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Icon(Icons.delete, color: Colors.red),
                ),
                child: ListTile(
                  title: Text(customer.fullName),
                  subtitle: Text(customer.phone),
                  trailing: canDeleteCustomers(workspaceRole)
                      ? IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmDelete(
                                context,
                                activeWorkspaceId,
                                customer,
                                workspaceRole,
                              ),
                        )
                      : null,
                  onTap: () => _openForm(
                    context,
                    activeWorkspaceId,
                    customer: customer,
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, activeWorkspaceId),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, String workspaceId,
      {Customer? customer}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerFormPage(
          workspaceId: workspaceId,
          controller: _controller,
          customer: customer,
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    String workspaceId,
    Customer customer,
    String workspaceRole,
  ) async {
    if (!canDeleteCustomers(workspaceRole)) {
      return false;
    }
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare cliente?'),
        content: Text('Vuoi eliminare ${customer.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await _controller.delete(workspaceId, customer.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cliente eliminato')),
          );
        }
        return true;
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore eliminazione: $e')),
          );
        }
        return false;
      }
    }

    return false;
  }
}
