import '../../transactions/models/transaction.dart';

class KpiTimeseriesPoint {
  const KpiTimeseriesPoint({
    required this.date,
    required this.transactionCount,
    required this.revenue,
  });

  final DateTime date;
  final int transactionCount;
  final double revenue;
}

class KpiLeaderboardEntry {
  const KpiLeaderboardEntry({
    required this.id,
    required this.label,
    required this.transactionCount,
    required this.totalRevenue,
  });

  final String id;
  final String label;
  final int transactionCount;
  final double totalRevenue;
}

class KpiSnapshot {
  const KpiSnapshot({
    required this.totalTransactions,
    required this.totalRevenue,
    required this.averageTicket,
    required this.activeCustomers,
    required this.timeseries,
    required this.topCustomers,
    required this.topOffers,
  });

  final int totalTransactions;
  final double totalRevenue;
  final double averageTicket;
  final int activeCustomers;
  final List<KpiTimeseriesPoint> timeseries;
  final List<KpiLeaderboardEntry> topCustomers;
  final List<KpiLeaderboardEntry> topOffers;

  factory KpiSnapshot.fromTransactions(List<WorkspaceTransaction> items) {
    if (items.isEmpty) {
      return const KpiSnapshot(
        totalTransactions: 0,
        totalRevenue: 0,
        averageTicket: 0,
        activeCustomers: 0,
        timeseries: [],
        topCustomers: [],
        topOffers: [],
      );
    }

    final filtered = items.where((tx) => tx.status != 'cancelled').toList();
    final totalRevenue = filtered.fold<double>(0, (sum, tx) {
      final lineTotal = tx.priceSnapshot * tx.quantity;
      return sum + lineTotal;
    });

    final totalTransactions = filtered.length;
    final averageTicket =
        totalTransactions == 0 ? 0 : totalRevenue / totalTransactions;

    final customerTotals = <String, _AggregateEntry>{};
    final offerTotals = <String, _AggregateEntry>{};
    final timeseriesMap = <DateTime, _TimeseriesAggregate>{};

    for (final tx in filtered) {
      final lineTotal = tx.priceSnapshot * tx.quantity;
      final dateKey = _dateOnly(tx.scheduledAt ?? tx.createdAt ?? DateTime.now());

      final customerEntry = customerTotals.putIfAbsent(
        tx.customerId,
        () => _AggregateEntry(label: tx.customerNameSnapshot),
      );
      customerEntry.count += 1;
      customerEntry.total += lineTotal;

      final offerEntry = offerTotals.putIfAbsent(
        tx.offerId,
        () => _AggregateEntry(label: tx.offerNameSnapshot),
      );
      offerEntry.count += 1;
      offerEntry.total += lineTotal;

      final tsEntry = timeseriesMap.putIfAbsent(dateKey, () => _TimeseriesAggregate());
      tsEntry.count += 1;
      tsEntry.revenue += lineTotal;
    }

    final timeseries = timeseriesMap.entries
        .map(
          (e) => KpiTimeseriesPoint(
            date: e.key,
            transactionCount: e.value.count,
            revenue: e.value.revenue,
          ),
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final topCustomers = _toLeaderboard(customerTotals);
    final topOffers = _toLeaderboard(offerTotals);

    return KpiSnapshot(
      totalTransactions: totalTransactions,
      totalRevenue: totalRevenue,
      averageTicket: averageTicket,
      activeCustomers: customerTotals.length,
      timeseries: timeseries,
      topCustomers: topCustomers,
      topOffers: topOffers,
    );
  }

  static List<KpiLeaderboardEntry> _toLeaderboard(
    Map<String, _AggregateEntry> map,
  ) {
    final entries = map.entries
        .map(
          (e) => KpiLeaderboardEntry(
            id: e.key,
            label: e.value.label,
            transactionCount: e.value.count,
            totalRevenue: e.value.total,
          ),
        )
        .toList();

    entries.sort((a, b) {
      final revenueCompare = b.totalRevenue.compareTo(a.totalRevenue);
      if (revenueCompare != 0) return revenueCompare;
      return b.transactionCount.compareTo(a.transactionCount);
    });
    return entries;
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}

class _AggregateEntry {
  _AggregateEntry({required this.label});

  final String label;
  int count = 0;
  double total = 0;
}

class _TimeseriesAggregate {
  int count = 0;
  double revenue = 0;
}
