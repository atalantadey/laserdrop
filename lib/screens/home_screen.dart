import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import '../services/api_service.dart';

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
  bool _isLoading = false; // Track loading state

  @override
  void initState() {
    super.initState();
    _loadRecentUploads();
  }

  // Load recent uploads from SharedPreferences
  Future<void> _loadRecentUploads() async {
    final prefs = await SharedPreferences.getInstance();
    final uploads = prefs.getStringList('recent_uploads') ?? [];
    setState(() {
      recentUploads = uploads.map((upload) {
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
    });
  }

  // Save an upload to local storage
  Future<void> _saveUpload(Map<String, dynamic> analysisData, String imagePath,
      String processedImagePath) async {
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
      // Limit to 9 for 3x3 grid
      final oldUpload = jsonDecode(uploads.last);
      await File(oldUpload['imagePath']).delete();
      await File(oldUpload['processedImagePath']).delete();
      uploads.removeLast();
    }

    await prefs.setStringList('recent_uploads', uploads);
    await _loadRecentUploads();
  }

  // Compress the image before uploading
  Future<String> _compressImage(String imagePath) async {
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

  // Analyze the image (from camera or gallery)
  Future<void> analyzeImage(ImageSource source) async {
    try {
      print("Starting image analysis process...");
      // Pick an image
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) {
        print("No image selected.");
        return;
      }
      print("Image picked: ${image.path}");

      // Save the original image to local storage
      final directory = await getApplicationDocumentsDirectory();
      final imagePath =
          '${directory.path}/upload_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(image.path).copy(imagePath);
      print("Original image saved to: $imagePath");

      // Compress the image
      print("Compressing image...");
      final compressedImagePath = await _compressImage(image.path);
      print("Compressed image saved to: $compressedImagePath");

      // Show loading indicator
      setState(() {
        _isLoading = true;
      });

      // Analyze the compressed image
      print("Sending image to server for analysis...");
      final data = await ApiService.analyzeImage(compressedImagePath);
      print("Analysis received from server: $data");

      // Save the processed image to local storage
      final processedImagePath =
          '${directory.path}/processed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(processedImagePath)
          .writeAsBytes(base64Decode(data['processed_image']));
      print("Processed image saved to: $processedImagePath");

      // Save the upload data
      print("Saving upload data to local storage...");
      await _saveUpload(data, imagePath, processedImagePath);
      print("Upload data saved.");

      setState(() {
        result = 'Bubbles: ${data['bubble_count']}\n'
            'Algae: ${data['algae_count']}\n'
            'Total Impurities: ${data['total_impurities']}\n'
            'PPM: ${data['ppm']}\n'
            'Drinkability: ${data['drinkability']}';
        processedImage = Image.memory(base64Decode(data['processed_image']));
        _isLoading = false; // Hide loading indicator
      });

      // Delete the compressed image file
      await File(compressedImagePath).delete();
      print("Compressed image deleted.");
    } catch (e) {
      setState(() {
        _isLoading = false; // Hide loading indicator on error
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
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.redAccent.shade200,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  // Show analysis result for a recent upload
  void _showRecentUploadResult(Map<String, dynamic> upload) {
    setState(() {
      result = upload['result'];
      processedImage = Image.file(File(upload['processedImagePath']));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          processedImage != null ? _buildResultScreen() : _buildHomeScreen(),
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
                    SizedBox(height: 16),
                    Text(
                      'Connecting to server...',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
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

  // Home Screen with Camera, Gallery Buttons, and Recent Uploads in a 3x3 Grid
  Widget _buildHomeScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.teal.shade100,
            Colors.white,
          ],
        ),
      ),
      child: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 40),
              Text(
                'Water Quality Analyzer',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade800,
                ),
              ),
              SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Camera Button
                  GestureDetector(
                    onTap: () => analyzeImage(ImageSource.camera),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.teal.shade300,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.shade200.withOpacity(0.5),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 30),
                  // Gallery Button
                  GestureDetector(
                    onTap: () => analyzeImage(ImageSource.gallery),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.teal.shade300,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.shade200.withOpacity(0.5),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.photo_library,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text(
                'Capture or Select an Image to Check Water Quality',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: Colors.teal.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              // Recent Uploads Section (3x3 Grid)
              if (recentUploads.isNotEmpty) ...[
                Text(
                  'Recent Uploads',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade800,
                  ),
                ),
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GridView.builder(
                    shrinkWrap:
                        true, // Ensure the grid takes only the space it needs
                    physics:
                        NeverScrollableScrollPhysics(), // Disable scrolling in GridView
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // 3 columns
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                      childAspectRatio: 1.0, // Square tiles
                    ),
                    itemCount: recentUploads.length,
                    itemBuilder: (context, index) {
                      final upload = recentUploads[index];
                      return GestureDetector(
                        onTap: () => _showRecentUploadResult(upload),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(upload['imagePath']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Result Screen
  Widget _buildResultScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.teal.shade100,
            Colors.white,
          ],
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(height: 40),
              Text(
                'Analysis Result',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade800,
                ),
              ),
              SizedBox(height: 20),
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: processedImage,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        result,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          color: Colors.teal.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    processedImage = null;
                    result = '';
                  });
                },
                child: Text('Check Another Sample'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
