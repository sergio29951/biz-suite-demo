import 'package:flutter/material.dart';

import '../../../core/session/workspace_session.dart';
import '../data/kpi_repository.dart';
import '../models/kpi_snapshot.dart';

enum KpiPeriodType { today, last7Days, last30Days, custom }

class KpiPeriod {
  const KpiPeriod({required this.from, required this.to, required this.type});

  final DateTime from;
  final DateTime to;
  final KpiPeriodType type;

  factory KpiPeriod.today() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return KpiPeriod(
      from: start,
      to: start.add(const Duration(days: 1)),
      type: KpiPeriodType.today,
    );
  }

  factory KpiPeriod.lastDays(int days) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));
    final end = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final type = days == 7
        ? KpiPeriodType.last7Days
        : days == 30
            ? KpiPeriodType.last30Days
            : KpiPeriodType.custom;
    return KpiPeriod(from: start, to: end, type: type);
  }

  factory KpiPeriod.custom(DateTimeRange range) {
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day)
        .add(const Duration(days: 1));
    return KpiPeriod(
      from: start,
      to: end,
      type: KpiPeriodType.custom,
    );
  }
}

class KpiController {
  KpiController({required KpiRepository repository, required WorkspaceSession session})
      : _repository = repository,
        _session = session;

  final KpiRepository _repository;
  final WorkspaceSession _session;

  Stream<KpiSnapshot> watch(KpiPeriod period) {
    final workspaceId = _session.activeWorkspaceId;
    if (workspaceId == null) {
      return Stream.value(KpiSnapshot.fromTransactions(const []));
    }

    return _repository
        .watchTransactions(
          workspaceId,
          from: period.from,
          to: period.to,
        )
        .map(KpiSnapshot.fromTransactions);
  }

  Future<void> refresh(KpiPeriod period) async {
    // The stream reflects live updates; exposing refresh for future enhancements.
    await for (final _ in watch(period).take(1)) {
      return;
    }
  }
}
