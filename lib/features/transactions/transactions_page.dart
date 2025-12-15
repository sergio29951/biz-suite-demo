import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/session/workspace_session.dart';
import '../workspace/permissions.dart';
import '../customers/controllers/customers_controller.dart';
import '../offers/controllers/offers_controller.dart';
import 'data/transactions_repository.dart';
import 'models/transaction.dart';
import 'transaction_form_page.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String _typeFilter = 'all';
  String _statusFilter = 'all';
  _DateRangeFilter _range = _DateRangeFilter.today;

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<WorkspaceSession>(context, listen: true);
    final workspaceId = session.activeWorkspaceId;
    final role = session.memberRole;
    final transactionsRepository =
        Provider.of<TransactionsRepository>(context, listen: false);
    final customersController =
        Provider.of<CustomersController>(context, listen: false);
    final offersController =
        Provider.of<OffersController>(context, listen: false);

    if (workspaceId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Seleziona un workspace per vedere le attività.'),
        ),
      );
    }

    final canDelete = canDeleteOffers(role);
    final dateWindow = _range.toWindow();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attività'),
      ),
      body: Column(
        children: [
          _Filters(
            range: _range,
            type: _typeFilter,
            status: _statusFilter,
            onRangeChanged: (value) => setState(() => _range = value),
            onTypeChanged: (value) => setState(() => _typeFilter = value),
            onStatusChanged: (value) => setState(() => _statusFilter = value),
          ),
          Expanded(
            child: StreamBuilder<List<WorkspaceTransaction>>(
              stream: transactionsRepository.watchTransactions(
                workspaceId,
                from: dateWindow.from,
                to: dateWindow.to,
                type: _typeFilter,
                status: _statusFilter,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Errore: ${snapshot.error}'),
                  );
                }

                final transactions = snapshot.data ?? [];
                if (transactions.isEmpty) {
                  return const Center(
                    child: Text('Nessuna attività per il periodo selezionato.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    return ListTile(
                      leading: Icon(
                        tx.type == 'booking'
                            ? Icons.event_available_outlined
                            : Icons.shopping_cart_outlined,
                      ),
                      title: Text(tx.customerNameSnapshot),
                      subtitle: Text(
                          '${tx.offerNameSnapshot} • ${tx.scheduledAt?.toLocal().toString().substring(0, 16) ?? '-'}'),
                      trailing: Wrap(
                        spacing: 6,
                        children: [
                          Chip(
                            label: Text(tx.status),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _openForm(
                              context,
                              workspaceId,
                              customersController,
                              offersController,
                              transactionsRepository,
                              transaction: tx,
                            ),
                          ),
                          if (canDelete)
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _confirmDelete(
                                context,
                                workspaceId,
                                tx,
                              ),
                            ),
                        ],
                      ),
                      onTap: () => _openForm(
                        context,
                        workspaceId,
                        customersController,
                        offersController,
                        transactionsRepository,
                        transaction: tx,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(
          context,
          workspaceId,
          customersController,
          offersController,
          transactionsRepository,
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    String workspaceId,
    CustomersController customersController,
    OffersController offersController,
    TransactionsRepository transactionsRepository, {
    WorkspaceTransaction? transaction,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionFormPage(
          workspaceId: workspaceId,
          repository: transactionsRepository,
          customersController: customersController,
          offersController: offersController,
          transaction: transaction,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String workspaceId,
    WorkspaceTransaction transaction,
  ) async {
    final transactionsRepository =
        Provider.of<TransactionsRepository>(context, listen: false);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare attività?'),
        content: Text('Vuoi eliminare la transazione per ${transaction.customerNameSnapshot}?'),
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
        await transactionsRepository.deleteTransaction(workspaceId, transaction.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Attività eliminata')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore eliminazione: $e')),
          );
        }
      }
    }
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.range,
    required this.type,
    required this.status,
    required this.onRangeChanged,
    required this.onTypeChanged,
    required this.onStatusChanged,
  });

  final _DateRangeFilter range;
  final String type;
  final String status;
  final ValueChanged<_DateRangeFilter> onRangeChanged;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Wrap(
            spacing: 8,
            children: _DateRangeFilter.values
                .map(
                  (value) => ChoiceChip(
                    label: Text(value.label),
                    selected: range == value,
                    onSelected: (_) => onRangeChanged(value),
                  ),
                )
                .toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Tutti')),
                    DropdownMenuItem(value: 'booking', child: Text('Prenotazioni')),
                    DropdownMenuItem(value: 'order', child: Text('Ordini')),
                  ],
                  onChanged: (value) {
                    if (value != null) onTypeChanged(value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Stato'),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Tutti')),
                    DropdownMenuItem(value: 'new', child: Text('Nuovo')),
                    DropdownMenuItem(value: 'confirmed', child: Text('Confermato')),
                    DropdownMenuItem(value: 'in_progress', child: Text('In lavorazione')),
                    DropdownMenuItem(value: 'done', child: Text('Completato')),
                    DropdownMenuItem(value: 'cancelled', child: Text('Annullato')),
                  ],
                  onChanged: (value) {
                    if (value != null) onStatusChanged(value);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DateWindow {
  const _DateWindow({required this.from, required this.to});

  final DateTime from;
  final DateTime to;
}

enum _DateRangeFilter { today, week, month }

extension on _DateRangeFilter {
  _DateWindow toWindow() {
    final now = DateTime.now();
    switch (this) {
      case _DateRangeFilter.today:
        final start = DateTime(now.year, now.month, now.day);
        return _DateWindow(from: start, to: start.add(const Duration(days: 1)));
      case _DateRangeFilter.week:
        final start = now.subtract(Duration(days: now.weekday - 1));
        final normalized = DateTime(start.year, start.month, start.day);
        return _DateWindow(
          from: normalized,
          to: normalized.add(const Duration(days: 7)),
        );
      case _DateRangeFilter.month:
        final start = DateTime(now.year, now.month, 1);
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        return _DateWindow(from: start, to: nextMonth);
    }
  }

  String get label {
    switch (this) {
      case _DateRangeFilter.today:
        return 'Oggi';
      case _DateRangeFilter.week:
        return 'Settimana';
      case _DateRangeFilter.month:
        return 'Mese';
    }
  }
}
