import 'dart:math';

import 'package:bloc/bloc.dart';

import '../../../../core/app_entities/motion_entity.dart';
import '../../../../core/function/error_message.dart';
import '../../domain/usecases/get_all_motions_usecase.dart';
import '../../domain/usecases/get_all_topics_usecase.dart';
import 'debate_setup_states.dart';

class DebateSetupCubit extends Cubit<DebateSetupStates> {
  DebateSetupCubit({
    required this.getAllMotionsUsecase,
    required this.getAllTopicsUsecase,
  }) : super(DebateSetupInitialState());

  List<String> allSides = ['og', 'oo', 'cg', 'co'];
  List<String> currentTeams = ['og', 'oo', 'cg', 'co'];

  void randomizeSides() {
    currentTeams.shuffle();
    emit(DebateSetupChangeTeamAssignmentState());
  }

  List<String> allTopics = [];
  List<String> selectedTopics = [];
  List<String> selectedTopicsCopy = [];

  final GetAllTopicsUsecase getAllTopicsUsecase;
  void getAllTopics() async {
    emit(DebateSetupGetAllTopicsLoadingState());
    final failureOrTopics = await getAllTopicsUsecase();
    failureOrTopics.fold(
      (failure) {
        emit(DebateSetupGetAllTopicsErrorState(
            message: mapFailureToMessage(failure)));
      },
      (topicsList) {
        allTopics = topicsList;
        emit(DebateSetupGetAllTopicsSuccessState());
      },
    );
  }

  List<MotionEntity> allMotions = [];
  List<MotionEntity> filteredMotions = [];
  MotionEntity? selectedMotion;
  final GetAllMotionsUsecase getAllMotionsUsecase;
  void getAllMotions() async {
    emit(DebateSetupGetAllMotionsLoadingState());
    final failureOrMotions = await getAllMotionsUsecase();
    failureOrMotions.fold(
      (failure) {
        emit(DebateSetupGetAllMotionsErrorState(
            message: mapFailureToMessage(failure)));
      },
      (motionsList) {
        allMotions = motionsList;
        filteredMotions = allMotions;
        selectedMotion = allMotions.isNotEmpty ? allMotions[0] : null;
        emit(DebateSetupGetAllMotionsSuccessState());
      },
    );
  }

  void selectMotion(MotionEntity motion) {
    selectedMotion = motion;
    emit(DebateSetupMotionSelectState());
  }

  void randomizeMotion() {
    if (filteredMotions.isEmpty) return;
    final index = Random().nextInt(filteredMotions.length);
    selectMotion(filteredMotions[index]);
  }

  void toggleTopic(String topic) {
    if (selectedTopicsCopy.contains(topic)) {
      selectedTopicsCopy.remove(topic);
    } else {
      selectedTopicsCopy.add(topic);
    }
    emit(DebateSetupChangeTopicState());
  }

  String _searchQuery = '';
  void searchMotions(String query) {
    _searchQuery = query;
    applyFilters();
  }

  void applyFilters() {
    selectedTopics = selectedTopicsCopy.sublist(0);
    filteredMotions = allMotions.where((m) {
      final bool matchesTopic;
      if (selectedTopics.isEmpty) {
        matchesTopic = true;
      } else {
        matchesTopic = m.topics.any((e) => selectedTopics.contains(e));
      }
      final bool matchesSearch = _searchQuery.isEmpty ||
          m.title.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesTopic && matchesSearch;
    }).toList();
    emit(DebateSetupMotionsFilteredState());
  }

  String selectedTopic = 'Economical';

  List<String> newMotionSelectedTopics = [];
  void addTopicToNewMotion(String topic) {
    if (!newMotionSelectedTopics.contains(topic)) {
      newMotionSelectedTopics.add(topic);
      if (newMotionSelectedTopics.length > 2) {
        newMotionSelectedTopics.removeAt(0);
      }
    } else {
      newMotionSelectedTopics.remove(topic);
    }
    emit(DebateSetupAddTopicToNewMotionState());
  }
}
