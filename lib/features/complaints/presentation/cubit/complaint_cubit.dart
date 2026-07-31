import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:jadal_app/features/complaints/domain/entities/complaint.dart';
import 'package:jadal_app/features/complaints/domain/repositories/complaint_repository.dart';

part 'complaint_state.dart';

class ComplaintCubit extends Cubit<ComplaintState> {
  final ComplaintRepository repository;

  ComplaintCubit(this.repository) : super(ComplaintInitial());

  Future<void> loadMyComplaints() async {
    emit(ComplaintLoading());
    final result = await repository.getMyComplaints();
    result.fold(
      (failure) => emit(ComplaintError(failure.message)),
      (complaints) => emit(ComplaintLoaded(complaints)),
    );
  }
}
