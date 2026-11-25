class Ticket {
  final String ticketId;
  final String customerName;
  final String customerEmail;
  final String issue;
  final String status;
  final String? attachmentKey;
  final String? createdAt;
  final String? updatedAt;
  final String? uploadUrl;

  Ticket({
    required this.ticketId,
    required this.customerName,
    required this.customerEmail,
    required this.issue,
    required this.status,
    this.attachmentKey,
    this.createdAt,
    this.updatedAt,
    this.uploadUrl,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      ticketId: json['ticketId'] ?? json['ticketId '] ?? '',
      customerName: json['customerName'] ?? 'Anonymous',
      customerEmail: json['customerEmail'] ?? 'Not provided',
      issue: json['issue'] ?? '',
      status: json['status'] ?? 'OPEN',
      attachmentKey: json['attachmentKey'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      uploadUrl: json['uploadUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticketId': ticketId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'issue': issue,
      'status': status,
      if (attachmentKey != null) 'attachmentKey': attachmentKey,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  Ticket copyWith({String? status}) {
    return Ticket(
      ticketId: ticketId,
      customerName: customerName,
      customerEmail: customerEmail,
      issue: issue,
      status: status ?? this.status,
      attachmentKey: attachmentKey,
      createdAt: createdAt,
      updatedAt: updatedAt,
      uploadUrl: uploadUrl,
    );
  }
}
