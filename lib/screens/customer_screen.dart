import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ticket.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _issueController = TextEditingController();

  String _selectedCategory = 'Order Issue';
  String? _attachedFileName;
  Uint8List? _attachedFileBytes;
  bool _isSubmitting = false;

  Ticket? _lastCreatedTicket;
  final List<Ticket> _sessionTickets = [];

  final List<String> _categories = [
    'Order Issue',
    'Item Missing',
    'Damaged Product',
    'Refund / Payment',
    'Delivery Delay',
    'Other'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _issueController.dispose();
    super.dispose();
  }

  void _simulateFileAttachment() {
    setState(() {
      _attachedFileName = 'receipt_${DateTime.now().millisecondsSinceEpoch % 10000}.png';
      // Create a dummy 1KB byte array for S3 upload demonstration
      _attachedFileBytes = Uint8List.fromList(List.generate(1024, (i) => i % 256));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Attached file: $_attachedFileName'),
        backgroundColor: AppTheme.statusResolved,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final combinedIssue = '[${_selectedCategory.toUpperCase()}] ${_issueController.text.trim()}';

      final ticket = await ApiService.createTicket(
        customerName: _nameController.text.trim(),
        customerEmail: _emailController.text.trim(),
        issue: combinedIssue,
        fileName: _attachedFileName,
        fileBytes: _attachedFileBytes,
      );

      setState(() {
        _lastCreatedTicket = ticket;
        _sessionTickets.insert(0, ticket);
        _issueController.clear();
        _attachedFileName = null;
        _attachedFileBytes = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Ticket created successfully! Uploaded to S3 & DynamoDB.'),
            backgroundColor: AppTheme.statusResolved,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Banner
                _buildHeader(),
                const SizedBox(height: 24),

                // Success Confirmation Card (if ticket just created)
                if (_lastCreatedTicket != null) ...[
                  _buildSuccessCard(_lastCreatedTicket!),
                  const SizedBox(height: 24),
                ],

                // Ticket Creation Form Card
                _buildFormCard(),
                const SizedBox(height: 32),

                // Recent Session Tickets
                if (_sessionTickets.isNotEmpty) ...[
                  const Text(
                    'My Recent Tickets in this Session',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._sessionTickets.map((t) => _buildRecentTicketTile(t)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withAlpha(50)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.support_agent, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Closekart Customer Support',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Submit your issue and upload attachments directly to secure AWS storage.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard(Ticket ticket) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.statusResolved),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppTheme.statusResolved, size: 24),
              const SizedBox(width: 10),
              const Text(
                'Ticket Submitted Successfully!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF166534),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: Color(0xFF166534)),
                onPressed: () => setState(() => _lastCreatedTicket = null),
              )
            ],
          ),
          const Divider(height: 20, color: Color(0xFFBBF7D0)),
          Row(
            children: [
              const Text(
                'Ticket ID: ',
                style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF166534)),
              ),
              Expanded(
                child: Text(
                  ticket.ticketId,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Color(0xFF15803D)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18, color: Color(0xFF15803D)),
                tooltip: 'Copy Ticket ID',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: ticket.ticketId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ticket ID copied to clipboard!')),
                  );
                },
              ),
            ],
          ),
          if (ticket.attachmentKey != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.cloud_done, size: 16, color: Color(0xFF15803D)),
                const SizedBox(width: 6),
                Text(
                  'S3 Upload: ${ticket.attachmentKey}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF166534)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New Support Ticket',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryColor,
                ),
              ),
              const SizedBox(height: 16),

              // Customer Name & Email
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Your Name *',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Please enter your name' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address *',
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                      ),
                      validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Category Selection
              const Text(
                'Issue Category',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedCategory = cat);
                    },
                    selectedColor: AppTheme.primaryLight,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primaryColor : const Color(0xFF475569),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Issue Description
              TextFormField(
                controller: _issueController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Describe your issue *',
                  alignLabelWithHint: true,
                  hintText: 'Please provide details like Order ID, missing items, or delivery status...',
                ),
                validator: (v) => v == null || v.trim().length < 5 ? 'Please describe your issue (min 5 chars)' : null,
              ),
              const SizedBox(height: 20),

              // Attachment Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.attach_file, color: Colors.blue),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _attachedFileName ?? 'No attachment added',
                            style: TextStyle(
                              fontWeight: _attachedFileName != null ? FontWeight.bold : FontWeight.normal,
                              color: _attachedFileName != null ? AppTheme.secondaryColor : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Attach screenshot or receipt (Uploaded to S3 via Lambda pre-signed URL)',
                            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      icon: Icon(_attachedFileName == null ? Icons.upload_file : Icons.refresh, size: 18),
                      label: Text(_attachedFileName == null ? 'Attach File' : 'Change'),
                      onPressed: _simulateFileAttachment,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_isSubmitting ? 'Creating Ticket...' : 'Submit Support Ticket'),
                  onPressed: _isSubmitting ? null : _submitTicket,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTicketTile(Ticket ticket) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryLight,
          child: const Icon(Icons.confirmation_number_outlined, color: AppTheme.primaryColor),
        ),
        title: Text(ticket.issue, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('ID: ${ticket.ticketId.substring(0, 8)}... • Created: ${ticket.createdAt ?? 'Just now'}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.statusOpen.withAlpha(25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.statusOpen),
          ),
          child: Text(
            ticket.status,
            style: const TextStyle(color: AppTheme.statusOpen, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
