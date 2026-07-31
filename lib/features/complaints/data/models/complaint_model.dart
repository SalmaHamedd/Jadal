import 'package:jadal_app/features/complaints/domain/entities/complaint.dart';

class ComplaintModel extends Complaint {
  const ComplaintModel({
    required super.id,
    required super.debateId,
    super.targetUserId,
    super.targetRole,
    required super.description,
    required super.status,
    super.adminResponse,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) => ComplaintModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        debateId: (json['debate_id'] as num?)?.toInt() ?? 0,
        targetUserId: (json['target_user_id'] as num?)?.toInt(),
        targetRole: json['target_role'] as String?,
        description: json['description'] as String? ?? '',
        status: json['status'] as String? ?? 'open',
        adminResponse: json['admin_response'] as String?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
      );
}
