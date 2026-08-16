import 'package:excel/excel.dart';

import '../../data/models/activity_stat_model.dart';
import '../../data/models/debater_stats_models.dart';
import '../../data/models/judge_rating_model.dart';
import '../../data/models/team_analysis_models.dart';

/// Builds the "debate sheet" — a styled `.xlsx` export of whatever analysis is
/// on screen, with its current filters. Design (per request): orange header
/// cells with dark-blue text over white data cells, and a red/green accent on
/// the metric cells depending on whether they clear the [_threshold] (50%).
class StatsExcelExporter {
  StatsExcelExporter._();

  static final ExcelColor _orange = ExcelColor.fromHexString('FFEA7C1C');
  static final ExcelColor _darkBlue = ExcelColor.fromHexString('FF1A3868');
  static final ExcelColor _white = ExcelColor.fromHexString('FFFFFFFF');
  static final ExcelColor _green = ExcelColor.fromHexString('FF2E9E5B');
  static final ExcelColor _red = ExcelColor.fromHexString('FFE53935');

  /// Values at/above this (on the 0–100 scale) read green, below read red.
  static const double _threshold = 50;

  static CellStyle get _titleStyle =>
      CellStyle(bold: true, fontSize: 14, fontColorHex: _darkBlue, backgroundColorHex: _white);

  static CellStyle get _labelStyle =>
      CellStyle(bold: true, fontColorHex: _darkBlue, backgroundColorHex: _white);

  static CellStyle get _headerStyle => CellStyle(
        bold: true,
        fontColorHex: _darkBlue,
        backgroundColorHex: _orange,
        horizontalAlign: HorizontalAlign.Center,
      );

  static CellStyle get _cellStyle =>
      CellStyle(fontColorHex: _darkBlue, backgroundColorHex: _white);

  static CellStyle _metricStyle(double value) => CellStyle(
        bold: true,
        fontColorHex: value >= _threshold ? _green : _red,
        backgroundColorHex: _white,
        horizontalAlign: HorizontalAlign.Center,
      );

  /// Returns the `.xlsx` bytes for the current view + filters, or null if the
  /// active stat has no data to write.
  static List<int>? build({
    required StatKind kind,
    required StatsFilter filter,
    required String debaterName,
    RankingMode rankingMode = RankingMode.top,
    BucketedStat? bucketed,
    ScoreRanking? ranking,
    ImprovementStat? improvement,
    ActivityStat? activity,
    JudgeRatingStat? judgeRating,
    TeamCombinationsStat? combinations,
  }) {
    final excel = Excel.createExcel();
    const sheetName = 'Analysis';
    final sheet = excel[sheetName];
    // Excel.createExcel seeds a default 'Sheet1'; drop it so only ours remains.
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != sheetName) {
      excel.delete(defaultSheet);
    }
    excel.setDefaultSheet(sheetName);

    var row = 0;
    _put(sheet, 0, row, TextCellValue('${_kindTitle(kind)} — $debaterName'), _titleStyle);
    row += 2;
    row = _writeFilters(sheet, row, kind, filter, rankingMode);
    row += 1;

    switch (kind) {
      case StatKind.winRate:
      case StatKind.avgScore:
      case StatKind.bestSpeaker:
        if (bucketed == null) return null;
        row = _writeBucketed(sheet, row, kind, bucketed);
      case StatKind.ranking:
        if (ranking == null) return null;
        row = _writeRanking(sheet, row, ranking);
      case StatKind.improvement:
        if (improvement == null) return null;
        row = _writeImprovement(sheet, row, improvement);
      case StatKind.activity:
        if (activity == null) return null;
        row = _writeActivity(sheet, row, activity);
      case StatKind.judgeRating:
        if (judgeRating == null) return null;
        row = _writeJudgeRating(sheet, row, judgeRating);
    }

    sheet.setColumnWidth(0, 24);
    for (var c = 1; c <= 10; c++) {
      sheet.setColumnWidth(c, c == 2 ? 42 : 15);
    }

    return excel.save(fileName: 'debate-analysis.xlsx');
  }

  /// A suggested file name (no path) for the export.
  static String fileName(StatKind kind) =>
      'jadal-${kind.name}-${DateTime.now().toIso8601String().substring(0, 10)}.xlsx';

  static String teamFileName(String metric) =>
      'jadal-team-$metric-${DateTime.now().toIso8601String().substring(0, 10)}.xlsx';

  /// The coach's per-team analysis. Same sheet style as [build];
  /// separate entry point because a team export is scoped by team + metric
  /// rather than by [StatKind] + debater, and because the line-up analysis has
  /// no debater-side equivalent.
  static List<int>? buildTeam({
    required String teamName,
    required String metric,
    required StatsFilter filter,
    BucketedStat? bucketed,
    ImprovementStat? improvement,
    ActivityStat? activity,
    int membersCounted = 0,
    TeamCombinationsStat? combinations,
  }) {
    final excel = Excel.createExcel();
    const sheetName = 'Analysis';
    final sheet = excel[sheetName];
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != sheetName) {
      excel.delete(defaultSheet);
    }
    excel.setDefaultSheet(sheetName);

    var row = 0;
    _put(
      sheet,
      0,
      row,
      TextCellValue('$metric — $teamName'),
      _titleStyle,
    );
    row += 2;
    row = _writeFilters(sheet, row, StatKind.winRate, filter, RankingMode.top);
    row += 1;

    if (combinations != null) {
      row = _writeCombinations(sheet, row, combinations);
    } else if (improvement != null) {
      row = _writeImprovement(sheet, row, improvement);
    } else if (activity != null) {
      if (membersCounted > 0) {
        _put(sheet, 0, row, TextCellValue('Members counted'), _labelStyle);
        _put(sheet, 1, row, IntCellValue(membersCounted), _cellStyle);
        row += 2;
      }
      row = _writeActivity(sheet, row, activity);
    } else if (bucketed != null) {
      row = _writeBucketed(
        sheet,
        row,
        metric == 'win-rate' ? StatKind.winRate : StatKind.avgScore,
        bucketed,
      );
    } else {
      return null;
    }

    sheet.setColumnWidth(0, 30);
    for (var c = 1; c <= 10; c++) {
      sheet.setColumnWidth(c, 16);
    }
    return excel.save();
  }

  // ── sections ──────────────────────────────────────────────────────────────

  static int _writeFilters(
      Sheet s, int row, StatKind kind, StatsFilter f, RankingMode mode) {
    final isBucketed = kind == StatKind.winRate ||
        kind == StatKind.avgScore ||
        kind == StatKind.bestSpeaker;
    final rows = <(String, String)>[
      ('Period', '${f.from ?? '—'}  to  ${f.to ?? '—'}'),
      if (isBucketed || kind == StatKind.activity) ('Group by', f.groupBy.name),
      if (isBucketed)
        ('Compare', f.series == StatsSeries.none ? 'Combined' : 'By ${f.series.name}'),
      if (kind == StatKind.ranking) ('Order', mode.name),
      ('Positions', f.positions.isEmpty ? 'All' : f.positions.join(', ')),
      if (f.frameworks.isNotEmpty) ('Frameworks', f.frameworks.join(', ')),
      if (f.teams.isNotEmpty) ('Teams', f.teams.join(', ')),
    ];
    for (final r in rows) {
      _put(s, 0, row, TextCellValue(r.$1), _labelStyle);
      _put(s, 1, row, TextCellValue(r.$2), _cellStyle);
      row++;
    }
    return row;
  }

  static int _writeBucketed(Sheet s, int row, StatKind kind, BucketedStat data) {
    if (data.buckets.isEmpty) {
      _put(s, 0, row, TextCellValue('No data for these filters.'), _cellStyle);
      return row + 1;
    }
    final keys = data.seriesKeys;

    // Header: corner + one column per bucket.
    _put(s, 0, row, TextCellValue('Series / Position'), _headerStyle);
    for (var c = 0; c < data.buckets.length; c++) {
      _put(s, c + 1, row, TextCellValue(data.buckets[c].label), _headerStyle);
    }
    row++;

    // One row per series; cell = the plotted 0–100 metric, red/green by threshold.
    for (final k in keys) {
      _put(s, 0, row, TextCellValue(k.label), _labelStyle);
      for (var c = 0; c < data.buckets.length; c++) {
        final byKey = {for (final e in data.buckets[c].series) e.key: e};
        final entry = byKey[k.key];
        if (entry == null) {
          _put(s, c + 1, row, TextCellValue('—'), _cellStyle);
        } else {
          final v = entry.plotted(kind);
          _put(s, c + 1, row, DoubleCellValue(_round1(v)), _metricStyle(v));
        }
      }
      row++;
    }

    row += 1;
    _put(s, 0, row, TextCellValue('Total debates'), _labelStyle);
    _put(s, 1, row, IntCellValue(data.totalNDebates), _cellStyle);
    return row + 1;
  }

  static int _writeRanking(Sheet s, int row, ScoreRanking data) {
    const headers = [
      '#', 'Date', 'Motion', 'Framework', 'Side', 'Positions', 'Score', 'Main', 'Reply', 'Won'
    ];
    for (var c = 0; c < headers.length; c++) {
      _put(s, c, row, TextCellValue(headers[c]), _headerStyle);
    }
    row++;

    for (var i = 0; i < data.entries.length; i++) {
      final e = data.entries[i];
      _put(s, 0, row, IntCellValue(i + 1), _cellStyle);
      _put(s, 1, row, TextCellValue(e.debateDate), _cellStyle);
      _put(s, 2, row, TextCellValue(e.motionText), _cellStyle);
      _put(s, 3, row, TextCellValue(e.frameworkLabel ?? '—'), _cellStyle);
      _put(s, 4, row, TextCellValue(e.side), _cellStyle);
      _put(s, 5, row, TextCellValue(e.positionsHeld.join(', ')), _cellStyle);
      _put(s, 6, row, DoubleCellValue(_round1(e.normalizedScore)), _metricStyle(e.normalizedScore));
      _put(s, 7, row,
          e.rawMainScore != null ? IntCellValue(e.rawMainScore!) : TextCellValue('—'), _cellStyle);
      _put(s, 8, row,
          e.rawReplyScore != null ? IntCellValue(e.rawReplyScore!) : TextCellValue('—'), _cellStyle);
      _put(
        s,
        9,
        row,
        TextCellValue(e.debateWon ? 'Won' : 'Lost'),
        CellStyle(
          bold: true,
          fontColorHex: e.debateWon ? _green : _red,
          backgroundColorHex: _white,
          horizontalAlign: HorizontalAlign.Center,
        ),
      );
      row++;
    }

    row += 1;
    _put(s, 0, row, TextCellValue('Qualifying debates'), _labelStyle);
    _put(s, 1, row, IntCellValue(data.totalQualifyingDebates), _cellStyle);
    return row + 1;
  }

  static int _writeImprovement(Sheet s, int row, ImprovementStat data) {
    _put(s, 0, row, TextCellValue('Index'), _labelStyle);
    if (data.index != null) {
      _put(
        s,
        1,
        row,
        DoubleCellValue(_round2(data.index!)),
        CellStyle(
          bold: true,
          fontColorHex: data.index! >= 0 ? _green : _red,
          backgroundColorHex: _white,
        ),
      );
    } else {
      _put(s, 1, row, TextCellValue('Insufficient history'), _cellStyle);
    }
    row++;
    _put(s, 0, row, TextCellValue('Band'), _labelStyle);
    _put(s, 1, row, TextCellValue(data.band ?? '—'), _cellStyle);
    row++;

    if (data.components != null) {
      final c = data.components!;
      final comps = <(String, double)>[
        ('Score trend', c.slopeScore),
        ('Win-rate trend', c.slopeWinrate),
        ('Consistency', c.consistency),
      ];
      for (final cm in comps) {
        _put(s, 0, row, TextCellValue(cm.$1), _labelStyle);
        _put(s, 1, row, DoubleCellValue(_round2(cm.$2)), _cellStyle);
        row++;
      }
    }

    row += 1;
    const headers = ['Period', 'Avg score', 'Win rate %', 'n_debates'];
    for (var c = 0; c < headers.length; c++) {
      _put(s, c, row, TextCellValue(headers[c]), _headerStyle);
    }
    row++;
    for (final b in data.buckets) {
      _put(s, 0, row, TextCellValue(b.label), _cellStyle);
      _put(s, 1, row, DoubleCellValue(_round1(b.avgScore)), _metricStyle(b.avgScore));
      final wr = b.winRate * 100;
      _put(s, 2, row, DoubleCellValue(_round1(wr)), _metricStyle(wr));
      _put(s, 3, row, IntCellValue(b.nDebates), _cellStyle);
      row++;
    }
    return row;
  }

  static int _writeActivity(Sheet s, int row, ActivityStat data) {
    _put(s, 0, row, TextCellValue('Total activity points'), _labelStyle);
    _put(
      s,
      1,
      row,
      DoubleCellValue(_round1(data.totalValue)),
      CellStyle(
        bold: true,
        fontColorHex: data.totalValue >= 0 ? _green : _red,
        backgroundColorHex: _white,
      ),
    );
    row += 2;

    // Totals breakdown — the "what made this number" block.
    final totals = <(String, ActivitySignal)>[
      ('Registrations', data.totalBreakdown.registration),
      ('Attendance', data.totalBreakdown.attendance),
      ('Watched debates', data.totalBreakdown.viewing),
      ('Missed debates', data.totalBreakdown.penalty),
    ];
    for (final t in totals) {
      _put(s, 0, row, TextCellValue(t.$1), _labelStyle);
      _put(
        s,
        1,
        row,
        DoubleCellValue(_round1(t.$2.points)),
        CellStyle(
          bold: true,
          fontColorHex: t.$2.points >= 0 ? _green : _red,
          backgroundColorHex: _white,
        ),
      );
      _put(s, 2, row, IntCellValue(t.$2.count), _cellStyle);
      row++;
    }

    row += 1;
    const headers = [
      'Period',
      'Points',
      'Registration',
      'Attendance',
      'Viewing',
      'Penalty',
    ];
    for (var c = 0; c < headers.length; c++) {
      _put(s, c, row, TextCellValue(headers[c]), _headerStyle);
    }
    row++;
    for (final b in data.buckets) {
      _put(s, 0, row, TextCellValue(b.label), _cellStyle);
      _put(
        s,
        1,
        row,
        DoubleCellValue(_round1(b.value)),
        CellStyle(
          bold: true,
          fontColorHex: b.value >= 0 ? _green : _red,
          backgroundColorHex: _white,
          horizontalAlign: HorizontalAlign.Center,
        ),
      );
      _put(s, 2, row, DoubleCellValue(_round1(b.breakdown.registration.points)), _cellStyle);
      _put(s, 3, row, DoubleCellValue(_round1(b.breakdown.attendance.points)), _cellStyle);
      _put(s, 4, row, DoubleCellValue(_round1(b.breakdown.viewing.points)), _cellStyle);
      _put(s, 5, row, DoubleCellValue(_round1(b.breakdown.penalty.points)), _cellStyle);
      row++;
    }
    return row;
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  /// The coach's team-summary card (four averages). Small on purpose — the
  /// backend ships scalars here, not series.
  static List<int>? buildTeamSummary({
    required String scopeLabel,
    required int teamsCounted,
    required double improvement,
    required double winRate,
    required double avgScore,
    required double memberActivity,
  }) {
    final excel = Excel.createExcel();
    const sheetName = 'Analysis';
    final sheet = excel[sheetName];
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != sheetName) {
      excel.delete(defaultSheet);
    }
    excel.setDefaultSheet(sheetName);

    var row = 0;
    _put(sheet, 0, row, TextCellValue('Team analysis — $scopeLabel'), _titleStyle);
    row += 2;
    _put(sheet, 0, row, TextCellValue('Teams counted'), _labelStyle);
    _put(sheet, 1, row, IntCellValue(teamsCounted), _cellStyle);
    row += 2;

    _put(sheet, 0, row, TextCellValue('Metric'), _headerStyle);
    _put(sheet, 1, row, TextCellValue('Value'), _headerStyle);
    row++;
    for (final e in <(String, double, bool)>[
      ('Average improvement', improvement, false),
      ('Average win rate', winRate * 100, true),
      ('Average score', avgScore, true),
      ('Average member activity', memberActivity, false),
    ]) {
      _put(sheet, 0, row, TextCellValue(e.$1), _cellStyle);
      _put(
        sheet,
        1,
        row,
        DoubleCellValue(_round1(e.$2)),
        // Improvement/activity are signed indices, not 0–100 scores, so the
        // 50% red/green threshold would be meaningless on them.
        e.$3 ? _metricStyle(e.$2) : _cellStyle,
      );
      row++;
    }

    sheet.setColumnWidth(0, 30);
    sheet.setColumnWidth(1, 16);
    return excel.save();
  }

  /// The judge's received ratings: headline average, coverage, the
  /// full distribution, and the per-period trend.
  static int _writeJudgeRating(Sheet s, int row, JudgeRatingStat d) {
    _put(s, 0, row, TextCellValue('Average rating'), _labelStyle);
    _put(
      s,
      1,
      row,
      d.avgRating == null
          ? TextCellValue('—')
          : DoubleCellValue(_round2(d.avgRating!)),
      _cellStyle,
    );
    _put(
      s,
      2,
      row,
      TextCellValue('out of ${d.scaleMax}'),
      _cellStyle,
    );
    row++;

    for (final e in <(String, CellValue)>[
      ('Ratings received', IntCellValue(d.ratingsCount)),
      ('Debates rated', IntCellValue(d.debatesRated)),
      ('Debates judged', IntCellValue(d.debatesJudged)),
      (
        'Coverage',
        d.coverage == null
            ? TextCellValue('—')
            : TextCellValue('${(d.coverage! * 100).round()}%'),
      ),
      (
        'Other judges average',
        d.peerAverage == null
            ? TextCellValue('—')
            : DoubleCellValue(_round2(d.peerAverage!)),
      ),
    ]) {
      _put(s, 0, row, TextCellValue(e.$1), _labelStyle);
      _put(s, 1, row, e.$2, _cellStyle);
      row++;
    }
    row++;

    _put(s, 0, row, TextCellValue('Rating'), _headerStyle);
    _put(s, 1, row, TextCellValue('Count'), _headerStyle);
    row++;
    for (var v = d.scaleMax; v >= d.scaleMin; v--) {
      _put(s, 0, row, IntCellValue(v), _cellStyle);
      _put(s, 1, row, IntCellValue(d.distribution[v] ?? 0), _cellStyle);
      row++;
    }

    if (d.buckets.isNotEmpty) {
      row++;
      _put(s, 0, row, TextCellValue('Period'), _headerStyle);
      _put(s, 1, row, TextCellValue('Average'), _headerStyle);
      _put(s, 2, row, TextCellValue('Ratings'), _headerStyle);
      _put(s, 3, row, TextCellValue('Debates rated'), _headerStyle);
      row++;
      for (final b in d.buckets) {
        _put(s, 0, row, TextCellValue(b.label), _cellStyle);
        _put(
          s,
          1,
          row,
          // A quiet period is null, not zero — keep that distinction in the
          // sheet rather than writing a misleading 0.
          b.avgRating == null
              ? TextCellValue('—')
              : DoubleCellValue(_round2(b.avgRating!)),
          _cellStyle,
        );
        _put(s, 2, row, IntCellValue(b.ratingsCount), _cellStyle);
        _put(s, 3, row, IntCellValue(b.debatesRated), _cellStyle);
        row++;
      }
    }
    return row;
  }

  /// The team's line-ups, ranked, with the team baseline so each
  /// row can be read as a delta rather than a bare figure.
  static int _writeCombinations(Sheet s, int row, TeamCombinationsStat d) {
    for (final e in <(String, CellValue)>[
      ('Team', TextCellValue(d.teamName)),
      ('Ranked by', TextCellValue(d.metric.wire)),
      ('Debates considered', IntCellValue(d.totalDebatesConsidered)),
      ('Distinct line-ups', IntCellValue(d.distinctCombinations)),
      ('Minimum appearances', IntCellValue(d.minDebates)),
      (
        'Team win rate',
        d.baseline.winRate == null
            ? TextCellValue('—')
            : TextCellValue('${(d.baseline.winRate! * 100).round()}%'),
      ),
      (
        'Team average score',
        d.baseline.avgScore == null
            ? TextCellValue('—')
            : DoubleCellValue(_round1(d.baseline.avgScore!)),
      ),
    ]) {
      _put(s, 0, row, TextCellValue(e.$1), _labelStyle);
      _put(s, 1, row, e.$2, _cellStyle);
      row++;
    }
    row++;

    _put(s, 0, row, TextCellValue('Line-up'), _headerStyle);
    _put(s, 1, row, TextCellValue('Size'), _headerStyle);
    _put(s, 2, row, TextCellValue('Debates'), _headerStyle);
    _put(s, 3, row, TextCellValue('Wins'), _headerStyle);
    _put(s, 4, row, TextCellValue('Win rate'), _headerStyle);
    _put(s, 5, row, TextCellValue('Avg score'), _headerStyle);
    _put(s, 6, row, TextCellValue('Last played'), _headerStyle);
    row++;

    for (final c in d.combinations) {
      // Departed members are marked so a historical line-up isn't mistaken for
      // one the coach can still field.
      final names = c.members
          .map((m) => m.isCurrentMember ? m.name : '${m.name} (left)')
          .join(', ');
      _put(s, 0, row, TextCellValue(names), _cellStyle);
      _put(s, 1, row, IntCellValue(c.size), _cellStyle);
      _put(s, 2, row, IntCellValue(c.nDebates), _cellStyle);
      _put(s, 3, row, IntCellValue(c.wins), _cellStyle);
      final winPct = (c.winRate ?? 0) * 100;
      _put(
        s,
        4,
        row,
        c.winRate == null
            ? TextCellValue('—')
            : DoubleCellValue(_round1(winPct)),
        c.winRate == null ? _cellStyle : _metricStyle(winPct),
      );
      _put(
        s,
        5,
        row,
        c.avgScore == null
            ? TextCellValue('—')
            : DoubleCellValue(_round1(c.avgScore!)),
        c.avgScore == null ? _cellStyle : _metricStyle(c.avgScore!),
      );
      _put(
        s,
        6,
        row,
        TextCellValue(
          c.lastDebateAt?.toIso8601String().substring(0, 10) ?? '—',
        ),
        _cellStyle,
      );
      row++;
    }
    return row;
  }

  static void _put(Sheet s, int col, int row, CellValue value, CellStyle style) {
    final cell = s.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = value;
    cell.cellStyle = style;
  }

  static double _round1(double v) => double.parse(v.toStringAsFixed(1));
  static double _round2(double v) => double.parse(v.toStringAsFixed(2));

  static String _kindTitle(StatKind k) => switch (k) {
        StatKind.winRate => 'Win rate',
        StatKind.avgScore => 'Average score',
        StatKind.bestSpeaker => 'Best-speaker rate',
        StatKind.ranking => 'Score ranking',
        StatKind.improvement => 'Improvement',
        StatKind.activity => 'Activity',
        StatKind.judgeRating => 'Judge rating',
      };
}
