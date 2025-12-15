bool canManageStaff(String workspaceRole) => workspaceRole == 'admin';

bool canDeleteOffers(String workspaceRole) => workspaceRole == 'admin';

bool canDeleteTransactions(String workspaceRole) => workspaceRole == 'admin';

bool canDeleteCustomers(String workspaceRole) => workspaceRole == 'admin';
