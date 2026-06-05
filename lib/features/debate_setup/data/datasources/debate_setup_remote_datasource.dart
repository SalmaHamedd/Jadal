import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;

import '../../../../core/app_models/motion_model.dart';

abstract class DebateSetupRemoteDatasource {
  Future<List<MotionModel>> getAllMotions();
  Future<List<String>> getAllTopics();
  Future<Unit> addMotion(MotionModel motion);
}

// TODO: real endpoints not wired yet — currently returns hard-coded demo data
class DebateSetupRemoteDatasourceImpl extends DebateSetupRemoteDatasource {
  final http.Client client;

  DebateSetupRemoteDatasourceImpl({required this.client});

  @override
  Future<Unit> addMotion(MotionModel motion) async {
    return Future.value(unit);
  }

  @override
  Future<List<MotionModel>> getAllMotions() async {
    return Future.value(_demoMotions);
  }

  @override
  Future<List<String>> getAllTopics() async {
    return Future.value(_demoTopics);
  }
}

final List<MotionModel> _demoMotions = const [
  MotionModel(
    title: 'This House would ban single-use plastics',
    topics: ['Educational', 'Social', 'Ecological'],
  ),
  MotionModel(
    title: 'This House supports universal basic income',
    topics: ['Social', 'Ecological', 'Educational'],
  ),
  MotionModel(
    title:
        'This House would require companies to disclose their carbon footprint',
    topics: ['Social', 'Educational', 'Ecological'],
  ),
  MotionModel(
    title: 'This House believes cryptocurrencies do more harm than good',
    topics: ['Social', 'Educational', 'Ecological'],
  ),
  MotionModel(
    title: 'This House would lower the voting age to 16',
    topics: ['Educational', 'Economical', 'Social'],
  ),
  MotionModel(
    title: 'This House supports mandatory military service',
    topics: ['Economical', 'Social', 'Ecological'],
  ),
  MotionModel(
    title: 'This House would regulate AI more strictly',
    topics: ['Legal', 'Political', 'Economical'],
  ),
  MotionModel(
    title: 'This House believes that the media is a threat to democracy',
    topics: ['Political', 'Legal', 'Social'],
  ),
  MotionModel(
    title: 'This House supports allowing students to evaluate their teachers',
    topics: ['Educational', 'Economical', 'Political'],
  ),
  MotionModel(
    title: 'This House would criminalize hate speech on social media',
    topics: ['Legal', 'Economical', 'Political'],
  ),
  MotionModel(
    title: 'This House believes global organizations do more harm than good',
    topics: ['Educational', 'Political', 'Economical'],
  ),
];

const List<String> _demoTopics = [
  'Economical',
  'Political',
  'Educational',
  'Ecological',
  'Legal',
  'Social',
];
