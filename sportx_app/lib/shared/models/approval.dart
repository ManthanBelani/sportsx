enum ApprovalStatus { pending, approved, rejected }

extension ApprovalStatusX on ApprovalStatus {
  static ApprovalStatus fromString(String? s) {
    switch (s?.toLowerCase()) {
      case 'approved':
      case 'verified':
      case 'confirmed':
        return ApprovalStatus.approved;
      case 'rejected':
      case 'cancelled':
        return ApprovalStatus.rejected;
      case 'pending':
      default:
        return ApprovalStatus.pending;
    }
  }

  String get label {
    switch (this) {
      case ApprovalStatus.pending:
        return 'Pending Approval';
      case ApprovalStatus.approved:
        return 'Approved';
      case ApprovalStatus.rejected:
        return 'Rejected';
    }
  }
}

enum PlanType { session, monthly, quarterly }

extension PlanTypeX on PlanType {
  static PlanType fromString(String? s) {
    switch (s) {
      case 'monthly':
        return PlanType.monthly;
      case 'quarterly':
        return PlanType.quarterly;
      case 'session':
      default:
        return PlanType.session;
    }
  }
}
