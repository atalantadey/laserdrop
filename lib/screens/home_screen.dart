import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
// ignore: unused_import
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'home_screen_content.dart';
import 'result_screen_content.dart';
import 'home_screen_utils.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen();

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String result = '';
  Image? processedImage;
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> recentUploads = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRecentUploads();
  }

  Future<void> _loadRecentUploads() async {
    final uploads = await HomeScreenUtils.loadRecentUploads();
    setState(() {
      recentUploads = uploads;
    });
  }

  Future<void> analyzeImage(ImageSource source) async {
    try {
      print("Starting image analysis process...");
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) {
        print("No image selected.");
        return;
      }
      print("Image picked: ${image.path}");

      final directory = await getApplicationDocumentsDirectory();
      final imagePath =
          '${directory.path}/upload_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(image.path).copy(imagePath);
      print("Original image saved to: $imagePath");

      print("Compressing image...");
      final compressedImagePath =
          await HomeScreenUtils.compressImage(image.path);
      print("Compressed image saved to: $compressedImagePath");

      setState(() {
        _isLoading = true;
      });

      print("Sending image to server for analysis...");
      final data = await ApiService.analyzeImage(compressedImagePath);
      print("Analysis received from server: $data");

      final processedImagePath =
          '${directory.path}/processed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(processedImagePath)
          .writeAsBytes(base64Decode(data['processed_image']));
      print("Processed image saved to: $processedImagePath");

      print("Saving upload data to local storage...");
      await HomeScreenUtils.saveUpload(
        data,
        imagePath,
        processedImagePath,
        (updatedUploads) {
          setState(() {
            recentUploads = updatedUploads;
          });
        },
      );
      print("Upload data saved.");

      setState(() {
        result = 'Bubbles: ${data['bubble_count']}\n'
            'Algae: ${data['algae_count']}\n'
            'Total Impurities: ${data['total_impurities']}\n'
            'PPM: ${data['ppm']}\n'
            'Drinkability: ${data['drinkability']}';
        processedImage = Image.memory(base64Decode(data['processed_image']));
        _isLoading = false;
      });

      await File(compressedImagePath).delete();
      print("Compressed image deleted.");
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      String errorMessage =
          e.toString().replaceFirst('Exception: Failed to analyze image: ', '');
      if (errorMessage.contains('Connection closed while receiving data')) {
        errorMessage =
            'Connection lost while uploading image. Please check your network and try again.';
      }
      print("Error during image analysis: $errorMessage");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: MediaQuery.of(context).size.width * 0.04,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.redAccent.shade200,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  void _showRecentUploadResult(Map<String, dynamic> upload) {
    HomeScreenUtils.showRecentUploadResult(upload, (newResult, newImage) {
      setState(() {
        result = newResult;
        processedImage = newImage;
      });
    });
  }

  void _goBack() {
    setState(() {
      processedImage = null;
      result = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          processedImage != null
              ? ResultScreenContent(
                  result: result,
                  processedImage: processedImage!,
                  onBack: _goBack,
                )
              : HomeScreenContent(
                  recentUploads: recentUploads,
                  onAnalyzeImage: analyzeImage,
                  onShowRecentUploadResult: _showRecentUploadResult,
                ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Text(
                      'Connecting to server...',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: screenWidth * 0.04,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
