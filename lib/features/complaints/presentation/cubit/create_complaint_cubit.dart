import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:jadal_app/features/complaints/domain/entities/complaint.dart';
import 'package:jadal_app/features/complaints/domain/repositories/complaint_repository.dart';

part 'create_complaint_state.dart';

class CreateComplaintCubit extends Cubit<CreateComplaintState> {
  final ComplaintRepository repository;

  CreateComplaintCubit(this.repository) : super(CreateComplaintInitial());

  Future<void> submit({
    required String description,
    required int debateId,
    int? targetUserId,
    String? targetRole,
  }) async {
    emit(CreateComplaintSubmitting());
    final result = await repository.fileComplaint(
      description: description,
      debateId: debateId,
      targetUserId: targetUserId,
      targetRole: targetRole,
    );
    result.fold(
      (failure) => emit(CreateComplaintError(failure.message)),
      (complaint) => emit(CreateComplaintSuccess(complaint)),
    );
  }
}
