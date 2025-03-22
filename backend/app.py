from flask import Flask, request, jsonify
import cv2
import base64
import logging
from algae_detection import detect_algae_impurities

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

@app.route('/analyze', methods=['POST'])
def analyze_image():
    try:
        logger.info("Received request to analyze image")
        # Check if an image file is part of the request
        if 'image' not in request.files:
            logger.error("No image file provided in request")
            return jsonify({'error': 'No image file provided'}), 400

        file = request.files['image']
        file_path = 'temp_image.jpg'
        file.save(file_path)
        logger.info(f"Image saved to {file_path}")

        # Analyze the image for impurities
        logger.info("Starting image analysis")
        result = detect_algae_impurities(file_path)
        logger.info("Image analysis completed")

        # Read the processed image and encode it as base64
        with open(file_path, 'rb') as f:
            processed_image = base64.b64encode(f.read()).decode('utf-8')

        logger.info("Returning analysis result")
        return jsonify({
            'bubble_count': result['bubble_count'],
            'algae_count': result['algae_count'],
            'total_impurities': result['total_impurities'],
            'ppm': result['ppm'],
            'drinkability': result['drinkability'],
            'processed_image': processed_image
        })

    except Exception as e:
        logger.error(f"Error during image analysis: {str(e)}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    logger.info("Starting Flask server in development mode on 0.0.0.0:5000")
    app.run(host='0.0.0.0', port=5000, debug=True)