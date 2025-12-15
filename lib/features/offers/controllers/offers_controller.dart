import '../../../core/permissions/permissions.dart';
import '../data/offers_repository.dart';
import '../models/offer.dart';

class OffersController {
  OffersController({required OffersRepository repository})
      : _repository = repository;

  final OffersRepository _repository;

  Stream<List<Offer>> watchList(String workspaceId) {
    return _repository.watchOffers(workspaceId);
  }

  Future<void> create(String workspaceId, Offer offer) {
    _validate(offer);
    return _repository.addOffer(workspaceId, offer);
  }

  Future<void> update(String workspaceId, Offer offer) {
    _validate(offer);
    return _repository.updateOffer(workspaceId, offer);
  }

  Future<void> delete(String workspaceId, String offerId, String workspaceRole) {
    if (!canDeleteOffers(workspaceRole)) {
      throw StateError('Not allowed');
    }
    return _repository.deleteOffer(workspaceId, offerId);
  }

  Future<void> toggleActive(String workspaceId, Offer offer) {
    return _repository.updateOffer(workspaceId, offer.copyWith(isActive: !offer.isActive));
  }

  void _validate(Offer offer) {
    if (offer.name.trim().isEmpty) {
      throw ArgumentError('Nome richiesto');
    }
    if (offer.type.trim().isEmpty) {
      throw ArgumentError('Tipo richiesto');
    }
  }
}
