import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:chat_toeic_app/core/api/dio_client.dart';
import 'package:http_parser/http_parser.dart';

class UploadService {
  static Future<Map<String, dynamic>?> uploadImage(Uint8List fileBytes, String fileName) async {
    try {
      FormData formData = FormData.fromMap({
        "file": MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
          contentType: MediaType("image", fileName.split('.').last),
        ),
      });

      final response = await DioClient.dio.post("/v1/uploads/images", data: formData);

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return response.data['data'];
      }
    } catch (e) {
      print("Error uploading image: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>?> uploadAudio(Uint8List fileBytes, String fileName) async {
    try {
      FormData formData = FormData.fromMap({
        "file": MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
          contentType: MediaType("audio", fileName.split('.').last),
        ),
      });

      final response = await DioClient.dio.post("/v1/uploads/audio", data: formData);

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return response.data['data'];
      }
    } catch (e) {
      print("Error uploading audio: $e");
    }
    return null;
  }
}
