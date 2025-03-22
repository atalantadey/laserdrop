# LaserDrop - Water Quality Analyzer

![LaserDrop Logo](assets/laserdrop_logo.png) <!-- Replace with your app logo if you have one -->

**LaserDrop** is a Flutter-based mobile application designed to analyze water quality by detecting impurities such as algae and air bubbles in water samples. The app uses image processing techniques to provide detailed analysis, including the concentration of impurities (in PPM) and the drinkability of the water based on WHO standards. It features a user-friendly interface for capturing or selecting images, viewing analysis results, and tracking recent uploads.

## Features

- **Image Capture and Selection**: Capture a water sample image using the camera or select one from the gallery.
- **Water Quality Analysis**:
  - Detects algae and air bubbles in the image.
  - Calculates total impurities and PPM (parts per million).
  - Determines drinkability ("Safe" or "Unsafe") based on WHO standards.
- **Processed Image Display**: Shows the analyzed image with marked impurities (red circles for bubbles, green circles for algae).
- **Recent Uploads**: Displays a 3x3 grid of recent uploads for quick access to past analyses.
- **Responsive Design**: Adapts to different screen sizes for a seamless experience on various devices.
- **Error Handling**: Provides clear error messages for network issues or failed analyses.

## Screenshots

### Home Screen
The home screen allows users to capture a new image or select one from the gallery. It also displays recent uploads in a 3x3 grid.

![Home Screen](screenshots/home_screen.png)

### Result Screen
The result screen displays the analysis results, including the number of bubbles, algae, total impurities, PPM, and drinkability. The processed image is shown with marked impurities.

![Result Screen](screenshots/result_screen.png)


