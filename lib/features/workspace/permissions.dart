bool canManageStaff(String? role) {
  if (role == null) return false;
  return role == 'admin' || role == 'owner';
}

bool canDeleteOffers(String? role) {
  if (role == null) return false;
  return role == 'admin' || role == 'owner';
}
