import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import '../../models/customer.dart';
import '../../models/offering.dart';
import '../../models/transaction.dart';
import '../../services/firestore_service.dart';
import '../auth/workspace_scope.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<WorkspaceSession>(context);
    final service = FirestoreService(FirebaseFirestore.instance);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biz Suite Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _WorkspaceSelector(session: session),
            const SizedBox(height: 16),
            Expanded(
              child: session.workspaceId == null
                  ? const _WorkspacePlaceholder()
                  : _DashboardContent(
                      workspaceId: session.workspaceId!,
                      service: service,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceSelector extends StatefulWidget {
  const _WorkspaceSelector({required this.session});

  final WorkspaceSession session;

  @override
  State<_WorkspaceSelector> createState() => _WorkspaceSelectorState();
}

class _WorkspaceSelectorState extends State<_WorkspaceSelector> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.session.workspaceId ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Workspace ID',
              hintText: 'Obbligatorio per multi-tenant',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: () {
            widget.session.updateWorkspace(_controller.text);
          },
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Imposta'),
        ),
      ],
    );
  }
}

class _WorkspacePlaceholder extends StatelessWidget {
  const _WorkspacePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Imposta un Workspace ID per iniziare'),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.workspaceId, required this.service});

  final String workspaceId;
  final FirestoreService service;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: 2,
          child: _DataColumn(
            title: 'Clienti',
            child: _CustomerPanel(
              workspaceId: workspaceId,
              service: service,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          flex: 2,
          child: _DataColumn(
            title: 'Offerte',
            child: _OfferingPanel(
              workspaceId: workspaceId,
              service: service,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          flex: 3,
          child: _DataColumn(
            title: 'Transazioni',
            child: _TransactionPanel(
              workspaceId: workspaceId,
              service: service,
            ),
          ),
        ),
      ],
    );
  }
}

class _DataColumn extends StatelessWidget {
  const _DataColumn({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _CustomerPanel extends StatelessWidget {
  const _CustomerPanel({required this.workspaceId, required this.service});

  final String workspaceId;
  final FirestoreService service;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _CustomerForm(),
        const SizedBox(height: 12),
        Expanded(
          child: StreamBuilder(
            stream: service.watchCustomers(workspaceId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final customers = snapshot.data!;
              if (customers.isEmpty) {
                return const Center(child: Text('Nessun cliente')); 
              }
              return ListView.separated(
                itemCount: customers.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  return ListTile(
                    title: Text(customer.name),
                    subtitle: Text('${customer.email}\n${customer.phone}'),
                    isThreeLine: true,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CustomerForm extends HookWidget {
  const _CustomerForm();

  @override
  Widget build(BuildContext context) {
    final session = WorkspaceSession.of(context);
    final nameController = useTextEditingController();
    final emailController = useTextEditingController();
    final phoneController = useTextEditingController();
    final noteController = useTextEditingController();
    final service = FirestoreService(FirebaseFirestore.instance);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nome',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: phoneController,
          decoration: const InputDecoration(
            labelText: 'Telefono',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: noteController,
          decoration: const InputDecoration(
            labelText: 'Note',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () async {
            final workspaceId = session.workspaceId;
            if (workspaceId == null) return;
            await service.addCustomer(
              workspaceId,
              Customer(
                id: '',
                workspaceId: workspaceId,
                name: nameController.text,
                email: emailController.text,
                phone: phoneController.text,
                notes: noteController.text,
              ),
            );
            nameController.clear();
            emailController.clear();
            phoneController.clear();
            noteController.clear();
          },
          child: const Text('Aggiungi cliente'),
        ),
      ],
    );
  }
}

class _OfferingPanel extends StatelessWidget {
  const _OfferingPanel({required this.workspaceId, required this.service});

  final String workspaceId;
  final FirestoreService service;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _OfferingForm(),
        const SizedBox(height: 12),
        Expanded(
          child: StreamBuilder(
            stream: service.watchOfferings(workspaceId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final offerings = snapshot.data!;
              if (offerings.isEmpty) {
                return const Center(child: Text('Nessuna offerta'));
              }
              return ListView.separated(
                itemCount: offerings.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final offering = offerings[index];
                  return ListTile(
                    title: Text(offering.name),
                    subtitle: Text(offering.description),
                    trailing:
                        Text('${offering.price.toStringAsFixed(2)} ${offering.currency}'),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _OfferingForm extends HookWidget {
  const _OfferingForm();

  @override
  Widget build(BuildContext context) {
    final session = WorkspaceSession.of(context);
    final nameController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final priceController = useTextEditingController();
    final currencyController = useTextEditingController(text: 'EUR');
    final service = FirestoreService(FirebaseFirestore.instance);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nome offerta',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: descriptionController,
          decoration: const InputDecoration(
            labelText: 'Descrizione',
            border: OutlineInputBorder(),
          ),
          minLines: 1,
          maxLines: 3,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Prezzo',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 80,
              child: TextField(
                controller: currencyController,
                decoration: const InputDecoration(
                  labelText: 'Valuta',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () async {
            final workspaceId = session.workspaceId;
            if (workspaceId == null) return;
            final price = double.tryParse(priceController.text) ?? 0;
            await service.addOffering(
              workspaceId,
              Offering(
                id: '',
                workspaceId: workspaceId,
                name: nameController.text,
                description: descriptionController.text,
                price: price,
                currency: currencyController.text,
              ),
            );
            nameController.clear();
            descriptionController.clear();
            priceController.clear();
          },
          child: const Text('Aggiungi offerta'),
        ),
      ],
    );
  }
}

class _TransactionPanel extends StatelessWidget {
  const _TransactionPanel({required this.workspaceId, required this.service});

  final String workspaceId;
  final FirestoreService service;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _TransactionForm(),
        const SizedBox(height: 12),
        Expanded(
          child: StreamBuilder(
            stream: service.watchTransactions(workspaceId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final transactions = snapshot.data!;
              if (transactions.isEmpty) {
                return const Center(child: Text('Nessuna transazione')); 
              }
              return ListView.separated(
                itemCount: transactions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  return ListTile(
                    title: Text('${tx.type.name} - ${tx.amount.toStringAsFixed(2)} ${tx.currency}'),
                    subtitle: Text('Stato: ${tx.status.name}\nCliente: ${tx.customerId}'),
                    isThreeLine: true,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TransactionForm extends HookWidget {
  const _TransactionForm();

  @override
  Widget build(BuildContext context) {
    final session = WorkspaceSession.of(context);
    final service = FirestoreService(FirebaseFirestore.instance);
    final customerController = useTextEditingController();
    final offeringController = useTextEditingController();
    final amountController = useTextEditingController();
    final currencyController = useTextEditingController(text: 'EUR');
    TransactionType selectedType = TransactionType.order;
    TransactionStatus selectedStatus = TransactionStatus.pending;

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: customerController,
                    decoration: const InputDecoration(
                      labelText: 'Cliente ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: offeringController,
                    decoration: const InputDecoration(
                      labelText: 'Offerta ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Importo',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: currencyController,
                    decoration: const InputDecoration(
                      labelText: 'Valuta',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<TransactionType>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(),
                    ),
                    items: TransactionType.values
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedType = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<TransactionStatus>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Stato',
                      border: OutlineInputBorder(),
                    ),
                    items: TransactionStatus.values
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedStatus = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () async {
                final workspaceId = session.workspaceId;
                if (workspaceId == null) return;
                final amount = double.tryParse(amountController.text) ?? 0;
                await service.addTransaction(
                  workspaceId,
                  TransactionRecord(
                    id: '',
                    workspaceId: workspaceId,
                    customerId: customerController.text,
                    offeringId: offeringController.text,
                    amount: amount,
                    currency: currencyController.text,
                    type: selectedType,
                    status: selectedStatus,
                    createdAt: DateTime.now(),
                  ),
                );
                customerController.clear();
                offeringController.clear();
                amountController.clear();
              },
              child: const Text('Registra transazione'),
            ),
          ],
        );
      },
    );
  }
}
