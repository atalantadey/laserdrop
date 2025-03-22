import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;


class HomeScreenUtils {
  static Future<List<Map<String, dynamic>>> loadRecentUploads() async {
    final prefs = await SharedPreferences.getInstance();
    final uploads = prefs.getStringList('recent_uploads') ?? [];
    return uploads.map((upload) {
      final data = jsonDecode(upload);
      return {
        'imagePath': data['imagePath'],
        'result': 'Bubbles: ${data['bubble_count']}\n'
            'Algae: ${data['algae_count']}\n'
            'Total Impurities: ${data['total_impurities']}\n'
            'PPM: ${data['ppm']}\n'
            'Drinkability: ${data['drinkability']}',
        'processedImagePath': data['processedImagePath'],
      };
    }).toList();
  }

  static Future<void> saveUpload(
    Map<String, dynamic> analysisData,
    String imagePath,
    String processedImagePath,
    Function(List<Map<String, dynamic>>) onRecentUploadsUpdated,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final uploadData = {
      'imagePath': imagePath,
      'bubble_count': analysisData['bubble_count'],
      'algae_count': analysisData['algae_count'],
      'total_impurities': analysisData['total_impurities'],
      'ppm': analysisData['ppm'],
      'drinkability': analysisData['drinkability'],
      'processedImagePath': processedImagePath,
    };

    final uploads = prefs.getStringList('recent_uploads') ?? [];
    uploads.insert(0, jsonEncode(uploadData));

    if (uploads.length > 9) {
      final oldUpload = jsonDecode(uploads.last);
      await File(oldUpload['imagePath']).delete();
      await File(oldUpload['processedImagePath']).delete();
      uploads.removeLast();
    }

    await prefs.setStringList('recent_uploads', uploads);
    final updatedUploads = await loadRecentUploads();
    onRecentUploadsUpdated(updatedUploads);
  }

  static Future<String> compressImage(String imagePath) async {
    final imageFile = File(imagePath);
    final imageBytes = await imageFile.readAsBytes();
    final decodedImage = img.decodeImage(imageBytes);

    if (decodedImage == null) {
      throw Exception('Failed to decode image for compression.');
    }

    final resizedImage = img.copyResize(decodedImage, width: 800);
    final compressedImage = img.encodeJpg(resizedImage, quality: 80);

    final directory = await getApplicationDocumentsDirectory();
    final compressedPath =
        '${directory.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(compressedPath).writeAsBytes(compressedImage);

    return compressedPath;
  }

  static void showRecentUploadResult(
    Map<String, dynamic> upload,
    Function(String, Image) onUpdateResult,
  ) {
    final result = upload['result'];
    final processedImage = Image.file(File(upload['processedImagePath']));
    onUpdateResult(result, processedImage);
  }
}
