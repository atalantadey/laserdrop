import 'package:flutter/material.dart';

class ResultScreenContent extends StatelessWidget {
  final String result;
  final Image processedImage;
  final VoidCallback onBack;

  const ResultScreenContent({
    Key? key,
    required this.result,
    required this.processedImage,
    required this.onBack,
  }) : super(key: key);

  Widget _buildResultText(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final lines = result.split('\n');
    List<TextSpan> textSpans = [];

    for (var line in lines) {
      if (line.startsWith('Drinkability:')) {
        final drinkabilityValue = line.split(': ')[1];
        textSpans.add(
          TextSpan(
            text: 'Drinkability: ',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade800,
            ),
          ),
        );
        textSpans.add(
          TextSpan(
            text: drinkabilityValue,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.bold,
              color: drinkabilityValue == 'Safe' ? Colors.green : Colors.red,
            ),
          ),
        );
      } else {
        textSpans.add(
          TextSpan(
            text: line,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: screenWidth * 0.045,
              color: Colors.teal.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }
      textSpans.add(TextSpan(text: '\n'));
    }

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(children: textSpans),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.05),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: Colors.teal.shade800,
                      size: screenWidth * 0.06,
                    ),
                    onPressed: onBack,
                  ),
                  Text(
                    'Analysis Result',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade800,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.12),
                ],
              ),
              SizedBox(height: screenHeight * 0.03),
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Column(
                    children: [
                      Container(
                        height: screenHeight * 0.4,
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
                      SizedBox(height: screenHeight * 0.03),
                      _buildResultText(context),
                    ],
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              ElevatedButton(
                onPressed: onBack,
                child: Text(
                  'Check Another Sample',
                  style: TextStyle(fontSize: screenWidth * 0.04),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Developed by Atalanta Dey',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: screenWidth * 0.035,
                    color: Colors.teal.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
