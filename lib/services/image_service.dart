import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class ImageService {
  // Replace this with your own ImgBB API key from imgbb.com
  static const String apiKey = '71377728708c202a69ed3d92520edf7c'; // Get free API key from imgbb.com
  static const String apiUrl = 'https://api.imgbb.com/1/upload';
  
  static Future<String> uploadImage(File imageFile) async {
    try {
      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse('$apiUrl?key=$apiKey'));
      
      // Add the image file to the request
      final fileStream = http.ByteStream(imageFile.openRead());
      final fileLength = await imageFile.length();
      
      final multipartFile = http.MultipartFile(
        'image',
        fileStream,
        fileLength,
        filename: '${Uuid().v4()}.jpg',
      );
      
      request.files.add(multipartFile);
      
      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      // Parse the response
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return jsonResponse['data']['url'];
        } else {
          throw Exception('Image upload failed: ${jsonResponse['error']['message']}');
        }
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      throw Exception('Image upload error: $e');
    }
  }
}