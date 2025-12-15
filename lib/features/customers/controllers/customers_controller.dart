import '../data/customers_repository.dart';
import '../models/customer.dart';

import '../../../core/session/workspace_session.dart';

class CustomersController {
  CustomersController({
    required CustomersRepository repository,
    required WorkspaceSession session,
  })  : _repository = repository,
        _session = session;

  final CustomersRepository _repository;
  final WorkspaceSession _session;

  Stream<List<Customer>> watchList(String workspaceId) {
    return _repository.watchCustomers(workspaceId);
  }

  Future<void> create(String workspaceId, Customer customer) {
    _validate(customer);
    return _repository.addCustomer(workspaceId, customer);
  }

  Future<void> update(String workspaceId, Customer customer) {
    _validate(customer);
    return _repository.updateCustomer(workspaceId, customer);
  }

  Future<void> delete(String workspaceId, String customerId) {
    return _repository.deleteCustomer(workspaceId, customerId);
  }

  void _validate(Customer customer) {
    if (customer.fullName.trim().isEmpty) {
      throw ArgumentError('Nome richiesto');
    }
    if (customer.phone.trim().isEmpty) {
      throw ArgumentError('Telefono richiesto');
    }
  }
}
