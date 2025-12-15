import '../../../core/permissions/permissions.dart';
import '../data/transactions_repository.dart';
import '../models/transaction.dart';

class TransactionsController {
  TransactionsController({required TransactionsRepository repository})
      : _repository = repository;

  final TransactionsRepository _repository;

  Stream<List<TransactionModel>> watch(
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

  Future<void> create(String workspaceId, TransactionModel transaction) {
    _validate(transaction);
    return _repository.addTransaction(workspaceId, transaction);
  }

  Future<void> update(String workspaceId, TransactionModel transaction) {
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

  void _validate(TransactionModel transaction) {
    if (transaction.customerId.isEmpty) {
      throw ArgumentError('Cliente richiesto');
    }
    if (transaction.offerId.isEmpty) {
      throw ArgumentError('Offerta richiesta');
    }
  }
}
