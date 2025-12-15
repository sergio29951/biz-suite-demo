import '../../../core/permissions/permissions.dart';
import '../../../core/session/workspace_session.dart';
import '../data/transactions_repository.dart';
import '../models/transaction.dart';

class TransactionsController {
  TransactionsController({
    required TransactionsRepository repository,
    required WorkspaceSession session,
  })  : _repository = repository,
        _session = session;

  final TransactionsRepository _repository;
  final WorkspaceSession _session;

  Stream<List<WorkspaceTransaction>> watch(
    String workspaceId, {
    DateTime? from,
    DateTime? to,
    String? type,
    String? status,
  }) {
    return _repository.watchTransactions(
      workspaceId,
      from: from,
      to: to,
      type: type,
      status: status,
    );
  }

  Future<void> create(String workspaceId, WorkspaceTransaction transaction) {
    _validate(transaction);
    return _repository.addTransaction(workspaceId, transaction);
  }

  Future<void> update(String workspaceId, WorkspaceTransaction transaction) {
    _validate(transaction);
    return _repository.updateTransaction(workspaceId, transaction);
  }

  Future<void> delete(
    String workspaceId,
    String transactionId,
    String workspaceRole,
  ) {
    if (!canDeleteTransactions(workspaceRole)) {
      throw StateError('Not allowed');
    }
    return _repository.deleteTransaction(workspaceId, transactionId);
  }

  void _validate(WorkspaceTransaction transaction) {
    if (transaction.customerId.isEmpty) {
      throw ArgumentError('Cliente richiesto');
    }
    if (transaction.offerId.isEmpty) {
      throw ArgumentError('Offerta richiesta');
    }
  }
}
