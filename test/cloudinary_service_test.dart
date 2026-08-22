import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taybgoadmin/core/services/cloudinary_service.dart';

class _RecordingClient extends http.BaseClient {
  http.MultipartRequest? request;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    this.request = request as http.MultipartRequest;
    return http.StreamedResponse(
      Stream.value(
        utf8.encode(
          jsonEncode({
            'secure_url': 'https://res.cloudinary.com/djkufgvvm/file.pdf',
          }),
        ),
      ),
      200,
    );
  }
}

void main() {
  test('uploads bytes with TaybGo Cloudinary configuration', () async {
    final client = _RecordingClient();
    final service = CloudinaryService(
      cloudName: 'djkufgvvm',
      uploadPreset: 'typetogo',
      client: client,
    );

    final url = await service.uploadFile(
      Uint8List.fromList([1, 2, 3]),
      fileName: 'license.pdf',
      folder: 'driver_licenses',
    );

    final captured = client.request!;
    expect(captured.url.path, '/v1_1/djkufgvvm/auto/upload');
    expect(captured.fields['upload_preset'], 'typetogo');
    expect(captured.fields.containsKey('api_key'), isFalse);
    expect(captured.fields['folder'], 'driver_licenses');
    expect(captured.files.single.filename, 'license.pdf');
    expect(url, 'https://res.cloudinary.com/djkufgvvm/file.pdf');
  });

  test('Cloudinary failures are exposed as typed exceptions', () async {
    final service = CloudinaryService(
      cloudName: 'djkufgvvm',
      uploadPreset: 'typetogo',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {'message': 'Upload preset not found'},
          }),
          400,
        ),
      ),
    );

    expect(
      () => service.uploadFile(
        Uint8List.fromList([1]),
        fileName: 'file.pdf',
        folder: 'documents',
      ),
      throwsA(
        isA<CloudinaryUploadException>()
            .having((error) => error.statusCode, 'status code', 400)
            .having(
              (error) => error.message,
              'message',
              'Upload preset not found',
            ),
      ),
    );
  });
}
