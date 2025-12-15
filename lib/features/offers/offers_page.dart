import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/session/workspace_session.dart';
import '../workspace/permissions.dart';
import 'data/offers_repository.dart';
import 'models/offer.dart';
import 'offer_form_page.dart';

class OffersPage extends StatelessWidget {
  OffersPage({super.key})
      : _repository = OffersRepository(FirebaseFirestore.instance);

  final OffersRepository _repository;

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<WorkspaceSession>(context, listen: true);
    final activeWorkspaceId = session.activeWorkspaceId;
    final role = session.memberRole;

    if (activeWorkspaceId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Seleziona un workspace per gestire le offerte.'),
        ),
      );
    }

    final canDelete = canDeleteOffers(role);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offerte'),
      ),
      body: StreamBuilder<List<Offer>>(
        stream: _repository.watchOffers(activeWorkspaceId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Errore nel caricamento: ${snapshot.error}'),
            );
          }

          final offers = snapshot.data ?? [];
          if (offers.isEmpty) {
            return const Center(
              child: Text('Nessuna offerta ancora. Aggiungine una.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: offers.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final offer = offers[index];
              return ListTile(
                leading: Icon(
                  offer.type == 'service'
                      ? Icons.design_services_outlined
                      : Icons.shopping_bag_outlined,
                ),
                title: Text(offer.name),
                subtitle: Text(
                  '${offer.type == 'service' ? 'Servizio' : 'Prodotto'} • € ${offer.price.toStringAsFixed(2)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: offer.isActive,
                      onChanged: (value) => _toggleActive(
                        context,
                        activeWorkspaceId,
                        offer.copyWith(isActive: value),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _openForm(
                        context,
                        activeWorkspaceId,
                        offer: offer,
                      ),
                    ),
                    if (canDelete)
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            _confirmDelete(context, activeWorkspaceId, offer),
                      ),
                  ],
                ),
                onTap: () => _openForm(
                  context,
                  activeWorkspaceId,
                  offer: offer,
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
      {Offer? offer}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OfferFormPage(
          workspaceId: workspaceId,
          repository: _repository,
          offer: offer,
        ),
      ),
    );
  }

  Future<void> _toggleActive(
    BuildContext context,
    String workspaceId,
    Offer offer,
  ) async {
    try {
      await _repository.updateOffer(workspaceId, offer);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore aggiornamento: $e')),
        );
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String workspaceId,
    Offer offer,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare offerta?'),
        content: Text('Vuoi eliminare ${offer.name}?'),
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
        await _repository.deleteOffer(workspaceId, offer.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Offerta eliminata')),
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
