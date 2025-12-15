import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/kpi_controller.dart';
import 'models/kpi_snapshot.dart';

class KpiPage extends StatefulWidget {
  const KpiPage({super.key});

  @override
  State<KpiPage> createState() => _KpiPageState();
}

class _KpiPageState extends State<KpiPage> {
  KpiPeriodType _selected = KpiPeriodType.today;
  DateTimeRange? _customRange;

  KpiPeriod _periodFromSelection() {
    switch (_selected) {
      case KpiPeriodType.today:
        return KpiPeriod.today();
      case KpiPeriodType.last7Days:
        return KpiPeriod.lastDays(7);
      case KpiPeriodType.last30Days:
        return KpiPeriod.lastDays(30);
      case KpiPeriodType.custom:
        final range = _customRange;
        return range == null
            ? KpiPeriod.today()
            : KpiPeriod.custom(range);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<KpiController>();
    final period = _periodFromSelection();

    return Scaffold(
      appBar: AppBar(
        title: const Text('KPI'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Periodo:'),
                const SizedBox(width: 8),
                DropdownButton<KpiPeriodType>(
                  value: _selected,
                  items: const [
                    DropdownMenuItem(
                      value: KpiPeriodType.today,
                      child: Text('Oggi'),
                    ),
                    DropdownMenuItem(
                      value: KpiPeriodType.last7Days,
                      child: Text('Ultimi 7 giorni'),
                    ),
                    DropdownMenuItem(
                      value: KpiPeriodType.last30Days,
                      child: Text('Ultimi 30 giorni'),
                    ),
                    DropdownMenuItem(
                      value: KpiPeriodType.custom,
                      child: Text('Personalizzato'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selected = value);
                    }
                  },
                ),
                if (_selected == KpiPeriodType.custom) ...[
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () async {
                      final now = DateTime.now();
                      final range = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(now.year - 1),
                        lastDate: DateTime(now.year + 1),
                        initialDateRange: _customRange ??
                            DateTimeRange(
                              start: DateTime(now.year, now.month, now.day - 6),
                              end: DateTime(now.year, now.month, now.day),
                            ),
                      );
                      if (range != null) {
                        setState(() => _customRange = range);
                      }
                    },
                    child: Text(
                      _customRange == null
                          ? 'Seleziona intervallo'
                          : '${_customRange!.start.toLocal().toIso8601String().split('T').first} - ${_customRange!.end.toLocal().toIso8601String().split('T').first}',
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<KpiSnapshot>(
                stream: controller.watch(period),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final data = snapshot.data ??
                      const KpiSnapshot(
                        totalTransactions: 0,
                        totalRevenue: 0,
                        averageTicket: 0,
                        activeCustomers: 0,
                        timeseries: [],
                        topCustomers: [],
                        topOffers: [],
                      );

                  return ListView(
                    children: [
                      Text('Transazioni totali: ${data.totalTransactions}'),
                      Text('Fatturato totale: ${data.totalRevenue.toStringAsFixed(2)}'),
                      Text('Ticket medio: ${data.averageTicket.toStringAsFixed(2)}'),
                      Text('Clienti attivi: ${data.activeCustomers}'),
                      const SizedBox(height: 16),
                      Text('Andamento temporale (${data.timeseries.length} giorni):'),
                      ...data.timeseries.map(
                        (point) => Text(
                          '${point.date.toIso8601String().split('T').first}: '
                          '€${point.revenue.toStringAsFixed(2)} / ${point.transactionCount} transazioni',
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Top clienti:'),
                      ...data.topCustomers.map(
                        (entry) => Text(
                          '${entry.label} – €${entry.totalRevenue.toStringAsFixed(2)} (${entry.transactionCount})',
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Top offerte:'),
                      ...data.topOffers.map(
                        (entry) => Text(
                          '${entry.label} – €${entry.totalRevenue.toStringAsFixed(2)} (${entry.transactionCount})',
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
