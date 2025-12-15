import 'package:flutter/material.dart';

import 'data/offers_repository.dart';
import 'models/offer.dart';

class OfferFormPage extends StatefulWidget {
  const OfferFormPage({
    super.key,
    required this.workspaceId,
    required this.repository,
    this.offer,
  });

  final String workspaceId;
  final OffersRepository repository;
  final Offer? offer;

  @override
  State<OfferFormPage> createState() => _OfferFormPageState();
}

class _OfferFormPageState extends State<OfferFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  String _type = 'service';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.offer?.name ?? '');
    _priceController = TextEditingController(
      text: widget.offer != null ? widget.offer!.price.toString() : '',
    );
    _descriptionController =
        TextEditingController(text: widget.offer?.description ?? '');
    _type = widget.offer?.type ?? 'service';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final offer = Offer(
        id: widget.offer?.id ?? '',
        name: _nameController.text.trim(),
        type: _type,
        price: double.parse(_priceController.text.trim()),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        isActive: widget.offer?.isActive ?? true,
      );

      if (widget.offer == null) {
        await widget.repository.addOffer(widget.workspaceId, offer);
      } else {
        await widget.repository.updateOffer(widget.workspaceId, offer);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nel salvataggio: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.offer != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifica offerta' : 'Nuova offerta'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Inserisci un nome';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _type,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'service',
                        child: Text('Servizio'),
                      ),
                      DropdownMenuItem(
                        value: 'product',
                        child: Text('Prodotto'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _type = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Prezzo',
                      prefixText: '€ ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Inserisci un prezzo';
                      }
                      final parsed = double.tryParse(value.trim());
                      if (parsed == null) {
                        return 'Prezzo non valido';
                      }
                      if (parsed < 0) {
                        return 'Il prezzo deve essere positivo';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descrizione (opzionale)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEditing ? 'Salva modifiche' : 'Crea offerta'),
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
