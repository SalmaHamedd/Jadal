import 'package:fpdart/fpdart.dart';
import 'package:jadal_app/core/error/failures.dart';
import 'package:jadal_app/features/complaints/domain/entities/complaint.dart';

abstract class ComplaintRepository {
  Future<Either<Failure, List<Complaint>>> getMyComplaints();

  Future<Either<Failure, Complaint>> fileComplaint({
    required String description,
    required int debateId,
    int? targetUserId,
    String? targetRole,
  });
}
