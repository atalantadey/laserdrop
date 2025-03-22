import cv2
import numpy as np

def detect_algae_impurities(image_path, roi_fraction=0.99):  # Reduced ROI fraction
    # Step 1: Read the image
    img = cv2.imread(image_path)
    if img is None:
        raise ValueError(f"Image not found at {image_path}")

    # Step 2: Define ROI
    height, width = img.shape[:2]
    roi_height = int(height * roi_fraction)
    roi_width = int(width * roi_fraction)
    start_x = (width - roi_width) // 2
    start_y = (height - roi_height) // 2
    cropped_img = img[start_y:start_y + roi_height, start_x:start_x + roi_width]

    # Step 3: Convert to HSV for better color-based segmentation
    hsv_img = cv2.cvtColor(cropped_img, cv2.COLOR_BGR2HSV)

    # Step 4: Create masks for bubbles and algae based on color
    _, _, v = cv2.split(hsv_img)
    bubble_mask = cv2.threshold(v, 190, 255, cv2.THRESH_BINARY)[1]
    algae_mask = cv2.threshold(v, 0, 130, cv2.THRESH_BINARY)[1]
    algae_mask = cv2.bitwise_not(algae_mask)

    # Step 5: Convert to grayscale for further processing
    grayscale_img = cv2.cvtColor(cropped_img, cv2.COLOR_BGR2GRAY)

    # Step 6: Apply Gaussian blur to reduce noise
    blurred_img = cv2.GaussianBlur(grayscale_img, (5, 5), 0)  # Reduced kernel size

    # Step 7: Enhance contrast with CLAHE
    clahe = cv2.createCLAHE(clipLimit=4.0, tileGridSize=(8, 8))  # Reduced clipLimit
    enhanced_img = clahe.apply(blurred_img)

    # Step 8: Apply median filter to denoise
    denoised_img = cv2.medianBlur(enhanced_img, 5)  # Reduced kernel size

    # Step 9: Adaptive thresholding for edge detection
    adaptive_thresh = cv2.adaptiveThreshold(
        denoised_img, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY_INV, 11, 3)

    # Step 10: Morphological transformations to clean up the binary image
    kernel = np.ones((3, 3), np.uint8)  # Reduced kernel size
    morph_open = cv2.morphologyEx(adaptive_thresh, cv2.MORPH_OPEN, kernel, iterations=1)  # Reduced iterations
    morph_close = cv2.morphologyEx(morph_open, cv2.MORPH_CLOSE, kernel, iterations=1)

    # Step 11: Edge detection
    edges = cv2.Canny(morph_close, 10, 140)

    # Step 12: Blob detection for bubbles
    bubble_params = cv2.SimpleBlobDetector_Params()
    bubble_params.filterByArea = True
    bubble_params.minArea = 150
    bubble_params.maxArea = 99999
    bubble_params.filterByCircularity = True
    bubble_params.minCircularity = 0.9
    bubble_params.filterByInertia = True
    bubble_params.minInertiaRatio = 0.2

    bubble_detector = cv2.SimpleBlobDetector_create(bubble_params)
    bubble_keypoints = bubble_detector.detect(cv2.bitwise_and(denoised_img, denoised_img, mask=bubble_mask))

    # Step 13: Contour detection for algae
    algae_contours, _ = cv2.findContours(
        cv2.bitwise_and(edges, edges, mask=algae_mask),
        cv2.RETR_EXTERNAL,
        cv2.CHAIN_APPROX_SIMPLE
    )
    min_contour_area = 100
    max_contour_area = 99999
    valid_algae_contours = []

    for cnt in algae_contours:
        area = cv2.contourArea(cnt)
        if min_contour_area < area < max_contour_area:
            perimeter = cv2.arcLength(cnt, True)
            if perimeter == 0:
                continue
            circularity = 4 * np.pi * (area / (perimeter * perimeter))
            if circularity < 0.7:
                valid_algae_contours.append(cnt)

    # Step 14: Draw results on the image
    output_img = cropped_img.copy()
    for kp in bubble_keypoints:
        x, y = int(kp.pt[0]), int(kp.pt[1])
        cv2.circle(output_img, (x, y), int(kp.size / 2), (255, 0, 0), 2)
    cv2.drawContours(output_img, valid_algae_contours, -1, (0, 0, 255), 2)

    # Step 15: Calculate PPM
    total_pixels = roi_height * roi_width
    bubble_count = len(bubble_keypoints)
    algae_count = len(valid_algae_contours)
    total_impurities = bubble_count + algae_count
    ppm_per_impurity = 1000 / total_pixels
    estimated_ppm = total_impurities * ppm_per_impurity

    # Step 16: Determine drinkability based on WHO standards
    who_ppm_threshold = 0.05
    drinkability = 'Safe' if estimated_ppm < who_ppm_threshold else 'Unsafe'

    # Step 17: Place the cropped output back onto the original image
    img[start_y:start_y + roi_height, start_x:start_x + roi_width] = output_img

    # Step 18: Save the processed image back to the same path
    cv2.imwrite(image_path, img)

    # Step 19: Return counts, PPM, and drinkability
    return {
        'bubble_count': bubble_count,
        'algae_count': algae_count,
        'total_impurities': total_impurities,
        'ppm': round(estimated_ppm, 2),
        'drinkability': drinkability
    }