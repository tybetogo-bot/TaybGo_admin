import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class CloudinaryUploadException implements Exception {
  const CloudinaryUploadException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'CloudinaryUploadException($message)';
}

/// Uploads files with TaybGo's unsigned Cloudinary upload preset.
class CloudinaryService {
  CloudinaryService({
    http.Client? client,
    this.cloudName = const String.fromEnvironment(
      'CLOUDINARY_CLOUD_NAME',
      defaultValue: 'djkufgvvm',
    ),
    this.uploadPreset = const String.fromEnvironment(
      'CLOUDINARY_UPLOAD_PRESET',
      defaultValue: 'typetogo',
    ),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String cloudName;
  final String uploadPreset;

  Future<String> uploadFile(
    Uint8List bytes, {
    required String fileName,
    required String folder,
    String resourceType = 'auto',
  }) async {
    if (bytes.isEmpty) {
      throw const CloudinaryUploadException('The selected file is empty.');
    }
    if (cloudName.trim().isEmpty || uploadPreset.trim().isEmpty) {
      throw const CloudinaryUploadException(
        'Cloudinary upload configuration is unavailable.',
      );
    }

    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse(
              'https://api.cloudinary.com/v1_1/${cloudName.trim()}/'
              '${resourceType.trim()}/upload',
            ),
          )
          ..fields['upload_preset'] = uploadPreset.trim()
          ..fields['folder'] = folder.trim();
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    );

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(response.body);
      body = decoded is Map
          ? decoded.cast<String, dynamic>()
          : const <String, dynamic>{};
    } on FormatException {
      body = const <String, dynamic>{};
    }

    final secureUrl = body['secure_url']?.toString().trim();
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        secureUrl != null &&
        secureUrl.isNotEmpty) {
      return secureUrl;
    }

    final error = body['error'];
    final errorMap = error is Map
        ? error.cast<String, dynamic>()
        : const <String, dynamic>{};
    throw CloudinaryUploadException(
      errorMap['message']?.toString() ?? 'Cloudinary upload failed.',
      statusCode: response.statusCode,
    );
  }

  void close() => _client.close();
}
