import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ArchitectureScreen extends StatefulWidget {
  const ArchitectureScreen({super.key});

  @override
  State<ArchitectureScreen> createState() => _ArchitectureScreenState();
}

class _ArchitectureScreenState extends State<ArchitectureScreen> {
  Map<String, dynamic>? _healthStatus;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkHealth();
  }

  Future<void> _checkHealth() async {
    setState(() => _isChecking = true);
    final status = await ApiService.checkHealth();
    setState(() {
      _healthStatus = status;
      _isChecking = false;
    });
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
                _buildHeader(),
                const SizedBox(height: 24),
                _buildHealthCard(),
                const SizedBox(height: 24),
                _buildComponentsCard(),
                const SizedBox(height: 24),
                _buildSecurityCard(),
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
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_sync, color: AppTheme.primaryColor, size: 32),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AWS Serverless Architecture Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
                ),
                SizedBox(height: 4),
                Text(
                  'Connected to live Amazon API Gateway, AWS Lambda, DynamoDB, and Cognito.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthCard() {
    final isHealthy = _healthStatus?['status'] == 'Healthy';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isHealthy ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: isHealthy ? AppTheme.statusResolved : Colors.amber,
                ),
                const SizedBox(width: 10),
                Text(
                  isHealthy ? 'Live API Gateway Health: Connected' : 'Checking API Status...',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: _isChecking
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh),
                  onPressed: _isChecking ? null : _checkHealth,
                ),
              ],
            ),
            const Divider(height: 20),
            Text(
              'Base Endpoint: ${ApiService.baseUrl}',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: AppTheme.secondaryColor),
            ),
            const SizedBox(height: 6),
            Text(
              'Cognito IDP: ${ApiService.cognitoIdpUrl}',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComponentsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configured AWS Services',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
            ),
            const SizedBox(height: 16),
            _buildServiceItem(
              icon: Icons.alt_route,
              color: Colors.purple,
              title: 'Amazon API Gateway (HTTP API)',
              subtitle: 'Routes POST /tickets (Public) and GET/PATCH /admin/tickets (Cognito Protected)',
            ),
            _buildServiceItem(
              icon: Icons.code,
              color: Colors.orange,
              title: 'AWS Lambda (Node.js 20.x)',
              subtitle: 'Executes request routing, S3 Presigner, and DynamoDB document client operations',
            ),
            _buildServiceItem(
              icon: Icons.storage,
              color: Colors.blue,
              title: 'Amazon DynamoDB (SupportTickets)',
              subtitle: 'NoSQL item store with ticketId (Partition Key) and createdAt (Sort Key)',
            ),
            _buildServiceItem(
              icon: Icons.folder,
              color: Colors.green,
              title: 'Amazon S3 (closekart-support-uploads)',
              subtitle: 'Private bucket receiving direct file attachments via time-limited signed URLs',
            ),
            _buildServiceItem(
              icon: Icons.lock,
              color: Colors.teal,
              title: 'Amazon Cognito User Pool',
              subtitle: 'Admin group role-based access control protecting support team endpoints',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    final features = [
      'HTTPS TLS 1.3 Communication across all endpoints',
      'Cognito Admin Group RBAC for Support Team',
      'IAM Least Privilege Lambda Execution Role',
      'S3 Access via Lambda-generated Presigned URLs Only',
      'DynamoDB Server-Side Encryption at Rest',
      'CloudWatch Automated Execution & Error Logging',
    ];

    return Card(
      color: const Color(0xFFF0FDF4),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.verified_user, color: AppTheme.statusResolved),
                SizedBox(width: 10),
                Text(
                  'Verified Security Features',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.check, size: 16, color: AppTheme.statusResolved),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF15803D)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
