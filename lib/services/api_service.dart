import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/ticket.dart';

class ApiService {
  static const String baseUrl = 'https://kpdyiiyyya.execute-api.ap-south-1.amazonaws.com';
  static const String cognitoIdpUrl = 'https://cognito-idp.ap-south-1.amazonaws.com/';
  static const String clientId = '24ib8mo6mb35b6i6nets0ck59';

  static String? adminToken;
  static String? adminEmail;

  // 1. Check API Health
  static Future<Map<String, dynamic>> checkHealth() async {
    try {
      final res = await http.get(Uri.parse(baseUrl));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return {'status': 'Error', 'code': res.statusCode};
    } catch (e) {
      return {'status': 'Offline', 'error': e.toString()};
    }
  }

  // 2. Customer: Create Ticket and Upload Attachment to S3
  static Future<Ticket> createTicket({
    required String customerName,
    required String customerEmail,
    required String issue,
    String? fileName,
    Uint8List? fileBytes,
  }) async {
    final payload = {
      'customerName': customerName,
      'customerEmail': customerEmail,
      'issue': issue,
      if (fileName != null && fileName.isNotEmpty) 'fileName': fileName,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/tickets'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      final errorJson = jsonDecode(response.body);
      throw Exception(errorJson['message'] ?? 'Failed to create ticket (${response.statusCode})');
    }

    final data = jsonDecode(response.body);
    final ticketJson = data['ticket'] as Map<String, dynamic>;
    final uploadUrl = data['uploadUrl'] as String?;

    // If attachment uploadUrl is provided and fileBytes exist, upload directly to S3
    if (uploadUrl != null && fileBytes != null && fileBytes.isNotEmpty) {
      await uploadToS3(uploadUrl: uploadUrl, fileBytes: fileBytes);
    }

    return Ticket.fromJson(ticketJson);
  }

  // S3 Direct Upload via Presigned URL
  static Future<void> uploadToS3({
    required String uploadUrl,
    required Uint8List fileBytes,
  }) async {
    final s3Res = await http.put(
      Uri.parse(uploadUrl),
      body: fileBytes,
    );

    if (s3Res.statusCode != 200) {
      throw Exception('Failed to upload file to S3 (${s3Res.statusCode})');
    }
  }

  // 3. Support Admin: Login via Cognito
  static Future<bool> loginAdmin({
    required String username,
    required String password,
  }) async {
    final authBody = {
      'AuthFlow': 'USER_PASSWORD_AUTH',
      'ClientId': clientId,
      'AuthParameters': {
        'USERNAME': username,
        'PASSWORD': password,
      },
    };

    final res = await http.post(
      Uri.parse(cognitoIdpUrl),
      headers: {
        'X-Amz-Target': 'AWSCognitoIdentityProviderService.InitiateAuth',
        'Content-Type': 'application/x-amz-json-1.1',
      },
      body: jsonEncode(authBody),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode != 200) {
      throw Exception(data['message'] ?? 'Authentication failed');
    }

    if (data['AuthenticationResult'] != null) {
      adminToken = data['AuthenticationResult']['IdToken'];
      adminEmail = username;
      return true;
    } else if (data['ChallengeName'] == 'NEW_PASSWORD_REQUIRED') {
      throw Exception('User password reset required. Please set permanent password.');
    }

    return false;
  }

  static void logoutAdmin() {
    adminToken = null;
    adminEmail = null;
  }

  // 4. Support Admin: Fetch All Tickets
  static Future<List<Ticket>> fetchAdminTickets() async {
    if (adminToken == null) {
      throw Exception('Unauthorized: Please log in as Admin');
    }

    final res = await http.get(
      Uri.parse('$baseUrl/admin/tickets'),
      headers: {
        'Authorization': 'Bearer $adminToken',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to fetch tickets (${res.statusCode})');
    }

    final data = jsonDecode(res.body);
    final List items = data['tickets'] ?? [];
    return items.map((t) => Ticket.fromJson(t)).toList();
  }

  // 5. Support Admin: Update Ticket Status
  static Future<void> updateTicketStatus({
    required String ticketId,
    required String status,
  }) async {
    if (adminToken == null) {
      throw Exception('Unauthorized: Please log in as Admin');
    }

    final res = await http.patch(
      Uri.parse('$baseUrl/admin/tickets/$ticketId'),
      headers: {
        'Authorization': 'Bearer $adminToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'status': status}),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to update ticket status (${res.statusCode})');
    }
  }
}
