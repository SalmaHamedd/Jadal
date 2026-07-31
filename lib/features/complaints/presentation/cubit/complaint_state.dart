part of 'complaint_cubit.dart';

abstract class ComplaintState extends Equatable {
  const ComplaintState();
}

class ComplaintInitial extends ComplaintState {
  @override
  List<Object?> get props => [];
}

class ComplaintLoading extends ComplaintState {
  @override
  List<Object?> get props => [];
}

class ComplaintLoaded extends ComplaintState {
  final List<Complaint> complaints;
  const ComplaintLoaded(this.complaints);
  @override
  List<Object?> get props => [complaints];
}

class ComplaintError extends ComplaintState {
  final String message;
  const ComplaintError(this.message);
  @override
  List<Object?> get props => [message];
}
