import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/statistics_models.dart';
import '../../domain/repositories/debate_repositories.dart';

enum StatisticsTab { general, personal }

class StatisticsState extends Equatable {
  final bool isLoading;
  final StatisticsTab tab;
  final GeneralStatistics? general;
  final PersonalStatistics? personal;

  const StatisticsState({
    this.isLoading = true,
    this.tab = StatisticsTab.general,
    this.general,
    this.personal,
  });

  StatisticsState copyWith({
    bool? isLoading,
    StatisticsTab? tab,
    GeneralStatistics? general,
    PersonalStatistics? personal,
  }) =>
      StatisticsState(
        isLoading: isLoading ?? this.isLoading,
        tab: tab ?? this.tab,
        general: general ?? this.general,
        personal: personal ?? this.personal,
      );

  @override
  List<Object?> get props => [isLoading, tab, general, personal];
}

class StatisticsCubit extends Cubit<StatisticsState> {
  final StatisticsRepository _repo;

  StatisticsCubit(this._repo) : super(const StatisticsState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    final general = await _repo.fetchGeneral();
    final personal = await _repo.fetchPersonal();
    emit(state.copyWith(
      isLoading: false,
      general: general,
      personal: personal,
    ));
  }

  void setTab(StatisticsTab tab) => emit(state.copyWith(tab: tab));
}
