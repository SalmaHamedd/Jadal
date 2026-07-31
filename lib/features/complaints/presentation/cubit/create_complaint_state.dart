part of 'create_complaint_cubit.dart';

abstract class CreateComplaintState extends Equatable {
  const CreateComplaintState();
}

class CreateComplaintInitial extends CreateComplaintState {
  @override
  List<Object?> get props => [];
}

class CreateComplaintSubmitting extends CreateComplaintState {
  @override
  List<Object?> get props => [];
}

class CreateComplaintSuccess extends CreateComplaintState {
  final Complaint complaint;
  const CreateComplaintSuccess(this.complaint);
  @override
  List<Object?> get props => [complaint];
}

class CreateComplaintError extends CreateComplaintState {
  final String message;
  const CreateComplaintError(this.message);
  @override
  List<Object?> get props => [message];
}
