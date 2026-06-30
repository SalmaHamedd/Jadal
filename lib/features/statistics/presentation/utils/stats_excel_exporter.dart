import 'package:excel/excel.dart';

import '../../data/models/debater_stats_models.dart';

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
  }) {
    final excel = Excel.createExcel();
    const sheetName = 'Analysis';
    final sheet = excel[sheetName];
    // Excel.createExcel() seeds a default 'Sheet1'; drop it so only ours remains.
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

  // ── sections ──────────────────────────────────────────────────────────────

  static int _writeFilters(
      Sheet s, int row, StatKind kind, StatsFilter f, RankingMode mode) {
    final isBucketed = kind == StatKind.winRate ||
        kind == StatKind.avgScore ||
        kind == StatKind.bestSpeaker;
    final rows = <(String, String)>[
      ('Period', '${f.from ?? '—'}  to  ${f.to ?? '—'}'),
      if (isBucketed) ('Group by', f.groupBy.name),
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

  // ── helpers ───────────────────────────────────────────────────────────────

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
      };
}
