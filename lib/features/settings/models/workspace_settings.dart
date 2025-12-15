class WorkspaceSettings {
  const WorkspaceSettings({
    required this.nomeAttivita,
    required this.emailContatto,
    required this.telefono,
    required this.indirizzo,
    this.partitaIva,
    this.valuta = 'EUR',
    this.timezone = 'Europe/Rome',
    this.durataSlotMinuti = 30,
    this.createdAt,
    this.updatedAt,
  });

  final String nomeAttivita;
  final String emailContatto;
  final String telefono;
  final String indirizzo;
  final String? partitaIva;
  final String valuta;
  final String timezone;
  final int durataSlotMinuti;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory WorkspaceSettings.defaults() {
    return const WorkspaceSettings(
      nomeAttivita: '',
      emailContatto: '',
      telefono: '',
      indirizzo: '',
      partitaIva: null,
      valuta: 'EUR',
      timezone: 'Europe/Rome',
      durataSlotMinuti: 30,
    );
  }

  factory WorkspaceSettings.fromMap(Map<String, dynamic> map) {
    return WorkspaceSettings(
      nomeAttivita: (map['nomeAttivita'] as String?) ?? '',
      emailContatto: (map['emailContatto'] as String?) ?? '',
      telefono: (map['telefono'] as String?) ?? '',
      indirizzo: (map['indirizzo'] as String?) ?? '',
      partitaIva: map['partitaIVA'] as String?,
      valuta: (map['valuta'] as String?) ?? 'EUR',
      timezone: (map['timezone'] as String?) ?? 'Europe/Rome',
      durataSlotMinuti: (map['durataSlotMinuti'] as int?) ?? 30,
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nomeAttivita': nomeAttivita,
      'emailContatto': emailContatto,
      'telefono': telefono,
      'indirizzo': indirizzo,
      'partitaIVA': partitaIva,
      'valuta': valuta,
      'timezone': timezone,
      'durataSlotMinuti': durataSlotMinuti,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
