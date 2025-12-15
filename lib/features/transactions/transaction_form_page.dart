import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../customers/controllers/customers_controller.dart';
import '../customers/models/customer.dart';
import '../offers/controllers/offers_controller.dart';
import '../offers/models/offer.dart';
import 'data/transactions_repository.dart';
import 'models/transaction.dart';

class TransactionFormPage extends StatefulWidget {
  const TransactionFormPage({
    super.key,
    required this.workspaceId,
    required this.repository,
    required this.customersController,
    required this.offersController,
    this.transaction,
  });

  final String workspaceId;
  final TransactionsRepository repository;
  final CustomersController customersController;
  final OffersController offersController;
  final WorkspaceTransaction? transaction;

  @override
  State<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends State<TransactionFormPage> {
  final _formKey = GlobalKey<FormState>();
  late String _type;
  late String _status;
  DateTime? _scheduledAt;
  String? _selectedCustomerId;
  String? _selectedOfferId;
  late int _quantity;
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _scheduledController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _type = tx?.type ?? 'booking';
    _status = tx?.status ?? 'new';
    _scheduledAt = tx?.scheduledAt ?? DateTime.now();
    _selectedCustomerId = tx?.customerId;
    _selectedOfferId = tx?.offerId;
    _quantity = tx?.quantity ?? 1;
    _priceController.text = tx?.priceSnapshot.toStringAsFixed(2) ?? '0.00';
    _notesController.text = tx?.notes ?? '';
    _scheduledController.text = _formatDateTime(_scheduledAt);
  }

  @override
  void dispose() {
    _priceController.dispose();
    _notesController.dispose();
    _scheduledController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null
            ? 'Nuova transazione'
            : 'Modifica transazione'),
      ),
      body: StreamBuilder<List<Customer>>(
        stream: widget.customersController.watchList(widget.workspaceId),
        builder: (context, customerSnapshot) {
          if (customerSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final customers = customerSnapshot.data ?? [];
          return StreamBuilder<List<Offer>>(
            stream: widget.offersController.watchList(widget.workspaceId),
            builder: (context, offersSnapshot) {
              if (offersSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final offers = offersSnapshot.data ?? [];
              if (customers.isEmpty || offers.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      customers.isEmpty
                          ? 'Aggiungi almeno un cliente per creare una transazione.'
                          : 'Aggiungi un\'offerta per creare una transazione.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return _buildForm(context, customers, offers);
            },
          );
        },
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    List<Customer> customers,
    List<Offer> offers,
  ) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(labelText: 'Tipo'),
            items: const [
              DropdownMenuItem(value: 'booking', child: Text('Prenotazione')),
              DropdownMenuItem(value: 'order', child: Text('Ordine')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _type = value);
              }
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: const InputDecoration(labelText: 'Stato'),
            items: const [
              DropdownMenuItem(value: 'new', child: Text('Nuovo')),
              DropdownMenuItem(value: 'confirmed', child: Text('Confermato')),
              DropdownMenuItem(
                  value: 'in_progress', child: Text('In lavorazione')),
              DropdownMenuItem(value: 'done', child: Text('Completato')),
              DropdownMenuItem(value: 'cancelled', child: Text('Annullato')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _status = value);
              }
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedCustomerId,
            decoration: const InputDecoration(labelText: 'Cliente'),
            items: customers
                .map(
                  (c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.fullName),
                  ),
                )
                .toList(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Seleziona un cliente';
              }
              return null;
            },
            onChanged: (value) => setState(() => _selectedCustomerId = value),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedOfferId,
            decoration: const InputDecoration(labelText: 'Offerta'),
            items: offers
                .map(
                  (o) => DropdownMenuItem(
                    value: o.id,
                    child: Text(o.name),
                  ),
                )
                .toList(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Seleziona un\'offerta';
              }
              return null;
            },
            onChanged: (value) {
              setState(() {
                _selectedOfferId = value;
                final selectedOffer = offers.firstWhere(
                  (o) => o.id == value,
                  orElse: () => offers.first,
                );
                _priceController.text = selectedOffer.price.toStringAsFixed(2);
              });
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Data/ora'),
            readOnly: true,
            controller: _scheduledController,
            onTap: _pickDateTime,
            validator: (value) {
              if (_type == 'booking' && _scheduledAt == null) {
                return 'Data/ora obbligatoria per le prenotazioni';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          if (_type == 'order')
            TextFormField(
              decoration: const InputDecoration(labelText: 'Quantità'),
              initialValue: _quantity.toString(),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final parsed = int.tryParse(value);
                if (parsed != null && parsed > 0) {
                  _quantity = parsed;
                }
              },
            ),
          if (_type == 'order') const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Prezzo'),
            controller: _priceController,
            keyboardType: TextInputType.number,
            validator: (value) {
              final parsed = double.tryParse(value ?? '');
              if (parsed == null) return 'Inserisci un prezzo valido';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Note'),
            controller: _notesController,
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving
                ? null
                : () => _save(context, customers, offers),
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Salva'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      initialDate: _scheduledAt ?? now,
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt ?? now),
    );
    if (time == null) return;

    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _scheduledController.text = _formatDateTime(_scheduledAt);
    });
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return '';
    return date.toLocal().toString().substring(0, 16);
  }

  Future<void> _save(
    BuildContext context,
    List<Customer> customers,
    List<Offer> offers,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    final selectedCustomer =
        customers.firstWhere((c) => c.id == _selectedCustomerId);
    final selectedOffer = offers.firstWhere((o) => o.id == _selectedOfferId);
    final price = double.tryParse(_priceController.text) ?? 0;
    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    final tx = WorkspaceTransaction(
      id: widget.transaction?.id ?? '',
      type: _type,
      status: _status,
      scheduledAt: _scheduledAt ?? DateTime.now(),
      customerId: selectedCustomer.id,
      customerNameSnapshot: selectedCustomer.fullName,
      offerId: selectedOffer.id,
      offerNameSnapshot: selectedOffer.name,
      priceSnapshot: price,
      quantity: _quantity,
      notes: notes,
      createdByUid: FirebaseAuth.instance.currentUser?.uid,
    );

    setState(() => _saving = true);
    try {
      if (widget.transaction == null) {
        await widget.repository.addTransaction(widget.workspaceId, tx);
      } else {
        await widget.repository
            .updateTransaction(widget.workspaceId, tx.copyWith(id: tx.id));
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore salvataggio: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
