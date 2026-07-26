/// Filter params for `GET /debates/search` (sprinkles §8). All lists are
/// optional/combinable — AND across dimensions, OR within one (e.g. two
/// `formatIds` means format A OR format B). "Motion tag" was dropped per
/// backend's confirmation that it isn't real data — motion "tags" are just
/// framework names mirrored flat, so framework covers it.
class DebateSearchFilter {
  final String? q;
  final List<String> status;
  final List<int> formatIds;
  final List<String> debateTags;
  final List<int> frameworkIds;
  final List<int> judgeIds;
  final List<int> teamIds;
  final List<int> userIds;
  final String? dateFrom;
  final String? dateTo;

  const DebateSearchFilter({
    this.q,
    this.status = const [],
    this.formatIds = const [],
    this.debateTags = const [],
    this.frameworkIds = const [],
    this.judgeIds = const [],
    this.teamIds = const [],
    this.userIds = const [],
    this.dateFrom,
    this.dateTo,
  });

  bool get isEmpty =>
      (q == null || q!.isEmpty) &&
      status.isEmpty &&
      formatIds.isEmpty &&
      debateTags.isEmpty &&
      frameworkIds.isEmpty &&
      judgeIds.isEmpty &&
      teamIds.isEmpty &&
      userIds.isEmpty &&
      dateFrom == null &&
      dateTo == null;

  DebateSearchFilter copyWith({
    String? q,
    List<String>? status,
    List<int>? formatIds,
    List<String>? debateTags,
    List<int>? frameworkIds,
    List<int>? judgeIds,
    List<int>? teamIds,
    List<int>? userIds,
    String? dateFrom,
    String? dateTo,
  }) =>
      DebateSearchFilter(
        q: q ?? this.q,
        status: status ?? this.status,
        formatIds: formatIds ?? this.formatIds,
        debateTags: debateTags ?? this.debateTags,
        frameworkIds: frameworkIds ?? this.frameworkIds,
        judgeIds: judgeIds ?? this.judgeIds,
        teamIds: teamIds ?? this.teamIds,
        userIds: userIds ?? this.userIds,
        dateFrom: dateFrom ?? this.dateFrom,
        dateTo: dateTo ?? this.dateTo,
      );

  Map<String, dynamic> toQueryParameters({int page = 1, int perPage = 15}) => {
        'q': ?q,
        'date_from': ?dateFrom,
        'date_to': ?dateTo,
        'page': '$page',
        'per_page': '$perPage',
        if (status.isNotEmpty) 'status[]': status,
        if (formatIds.isNotEmpty) 'format_id[]': formatIds.map((e) => '$e').toList(),
        if (debateTags.isNotEmpty) 'debate_tag[]': debateTags,
        if (frameworkIds.isNotEmpty) 'framework_id[]': frameworkIds.map((e) => '$e').toList(),
        if (judgeIds.isNotEmpty) 'judge_id[]': judgeIds.map((e) => '$e').toList(),
        if (teamIds.isNotEmpty) 'team_id[]': teamIds.map((e) => '$e').toList(),
        if (userIds.isNotEmpty) 'user_id[]': userIds.map((e) => '$e').toList(),
      };
}
