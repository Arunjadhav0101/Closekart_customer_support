import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ticket.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class SupportAdminScreen extends StatefulWidget {
  const SupportAdminScreen({super.key});

  @override
  State<SupportAdminScreen> createState() => _SupportAdminScreenState();
}

class _SupportAdminScreenState extends State<SupportAdminScreen> {
  final _usernameController = TextEditingController(text: 'admin@closekart.com');
  final _passwordController = TextEditingController(text: 'AdminSupport@1234');
  bool _isLoggingIn = false;
  bool _isLoadingTickets = false;

  List<Ticket> _tickets = [];
  String _filterStatus = 'ALL';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (ApiService.adminToken != null) {
      _loadTickets();
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoggingIn = true);
    try {
      await ApiService.loginAdmin(
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cognito Authentication Successful!'),
          backgroundColor: AppTheme.statusResolved,
        ),
      );
      await _loadTickets();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login Failed: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoadingTickets = true);
    try {
      final list = await ApiService.fetchAdminTickets();
      if (!mounted) return;
      setState(() => _tickets = list);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fetch error: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoadingTickets = false);
    }
  }

  Future<void> _updateTicketStatus(String ticketId, String newStatus) async {
    try {
      await ApiService.updateTicketStatus(ticketId: ticketId, status: newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ticket updated to $newStatus'),
          backgroundColor: AppTheme.statusResolved,
        ),
      );
      await _loadTickets();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  List<Ticket> get _filteredTickets {
    return _tickets.where((t) {
      final matchesStatus = _filterStatus == 'ALL' || t.status.toUpperCase() == _filterStatus;
      final matchesSearch = _searchQuery.isEmpty ||
          t.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.issue.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.ticketId.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesStatus && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (ApiService.adminToken == null) {
      return _buildLoginView();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Team Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Tickets',
            onPressed: _isLoadingTickets ? null : _loadTickets,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ActionChip(
              avatar: const Icon(Icons.logout, size: 16),
              label: Text('Logout (${ApiService.adminEmail ?? 'Admin'})'),
              onPressed: () {
                ApiService.logoutAdmin();
                setState(() {});
              },
            ),
          ),
        ],
      ),
      body: _isLoadingTickets
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTickets,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetricsRow(),
                    const SizedBox(height: 20),
                    _buildFilterBar(),
                    const SizedBox(height: 16),
                    if (_filteredTickets.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(48),
                        alignment: Alignment.center,
                        child: const Column(
                          children: [
                            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                            SizedBox(height: 12),
                            Text(
                              'No tickets found matching the criteria',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._filteredTickets.map((t) => _buildTicketCard(t)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLoginView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shield_outlined, color: AppTheme.primaryColor, size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Support Team Login',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Authenticate with Amazon Cognito User Pool to access customer tickets.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Admin Username / Email',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoggingIn ? null : _handleLogin,
                      child: _isLoggingIn
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Sign In via Cognito'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      icon: const Icon(Icons.auto_fix_high, size: 16),
                      label: const Text('Use Configured Admin Credentials'),
                      onPressed: () {
                        setState(() {
                          _usernameController.text = 'admin@closekart.com';
                          _passwordController.text = 'AdminSupport@1234';
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsRow() {
    final total = _tickets.length;
    final open = _tickets.where((t) => t.status.toUpperCase() == 'OPEN').length;
    final inProgress = _tickets.where((t) => t.status.toUpperCase() == 'IN_PROGRESS').length;
    final resolved = _tickets.where((t) => t.status.toUpperCase() == 'RESOLVED').length;

    return Row(
      children: [
        _buildStatCard('Total Tickets', total.toString(), Icons.folder_outlined, Colors.indigo),
        const SizedBox(width: 12),
        _buildStatCard('Open', open.toString(), Icons.pending_actions, AppTheme.statusOpen),
        const SizedBox(width: 12),
        _buildStatCard('In Progress', inProgress.toString(), Icons.trending_up, AppTheme.statusInProgress),
        const SizedBox(width: 12),
        _buildStatCard('Resolved', resolved.toString(), Icons.task_alt, AppTheme.statusResolved),
      ],
    );
  }

  Widget _buildStatCard(String label, String count, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search by Customer, Issue, or Ticket ID...',
                  prefixIcon: Icon(Icons.search, size: 20),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
            const VerticalDivider(width: 24, thickness: 1),
            DropdownButton<String>(
              value: _filterStatus,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'ALL', child: Text('Filter: All')),
                DropdownMenuItem(value: 'OPEN', child: Text('Filter: Open')),
                DropdownMenuItem(value: 'IN_PROGRESS', child: Text('Filter: In Progress')),
                DropdownMenuItem(value: 'RESOLVED', child: Text('Filter: Resolved')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _filterStatus = val);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(Ticket ticket) {
    Color statusColor;
    switch (ticket.status.toUpperCase()) {
      case 'IN_PROGRESS':
        statusColor = AppTheme.statusInProgress;
        break;
      case 'RESOLVED':
        statusColor = AppTheme.statusResolved;
        break;
      default:
        statusColor = AppTheme.statusOpen;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryLight,
                  child: Text(
                    ticket.customerName.isNotEmpty ? ticket.customerName[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.customerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'ID: ${ticket.ticketId} • Created: ${ticket.createdAt ?? 'N/A'}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    ticket.status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              ticket.issue,
              style: const TextStyle(fontSize: 14, color: AppTheme.secondaryColor),
            ),
            if (ticket.attachmentKey != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.attachment, size: 16, color: Colors.blue),
                  const SizedBox(width: 6),
                  Text(
                    'Attachment: ${ticket.attachmentKey}',
                    style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy ID'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: ticket.ticketId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied ticket ID')),
                    );
                  },
                ),
                const SizedBox(width: 8),
                if (ticket.status.toUpperCase() != 'IN_PROGRESS')
                  OutlinedButton.icon(
                    icon: const Icon(Icons.hourglass_empty, size: 16, color: AppTheme.statusInProgress),
                    label: const Text('Mark In Progress', style: TextStyle(color: AppTheme.statusInProgress)),
                    onPressed: () => _updateTicketStatus(ticket.ticketId, 'IN_PROGRESS'),
                  ),
                const SizedBox(width: 8),
                if (ticket.status.toUpperCase() != 'RESOLVED')
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusResolved),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Resolve Ticket'),
                    onPressed: () => _updateTicketStatus(ticket.ticketId, 'RESOLVED'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
