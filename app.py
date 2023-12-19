from flask import Flask, request, jsonify, render_template,send_file
import os
import cv2
import numpy as np
from scipy import ndimage
from skimage import measure, color, io
import pandas as pd
import csv
import uuid
import matplotlib.pyplot as plt
from io import BytesIO

app = Flask(__name__)

UPLOAD_FOLDER = 'uploads'
CSV_FOLDER = 'csv_files'
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['CSV_FOLDER'] = CSV_FOLDER
pixels_to_um = 0.5  # 1 pixel = 500 nm (got this from the metadata of the original image)

propList = [
    'Area',
    'equivalent_diameter',  # Added... verify if it works
    'orientation',  # Added, verify if it works. Angle between x-axis and major axis.
    'MajorAxisLength',
    'MinorAxisLength',
    'Perimeter',
    'MinIntensity',
    'MeanIntensity',
    'MaxIntensity'
]

# Variable to store the most recently generated CSV file content
latest_csv_content = None

def process_image_and_save_csv(img_data):
    global latest_csv_content  # Declare that we want to use the global variable

    # Convert the image data to a NumPy array
    nparr = np.frombuffer(img_data.read(), np.uint8)
    img1 = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    
    img = cv2.cvtColor(img1, cv2.COLOR_BGR2GRAY)

    # Call the grain segmentation function.
    regions = grain_segmentation(img, img1)

    # Generate a unique filename for the CSV file
    csv_filename = f"{str(uuid.uuid4())}.csv"
    csv_file_path = os.path.join(app.config['CSV_FOLDER'], csv_filename)

    # Write CSV header
    with open(csv_file_path, 'w', newline='') as csv_file:
        csv_writer = csv.writer(csv_file)
        csv_writer.writerow(['FileName', 'Grain #'] + propList)

        grain_number = 1
        for region_props in regions:
            # Write image filename and grain number
            csv_writer.writerow([csv_filename, grain_number])

            # Write cluster properties to the CSV file
            for i, prop in enumerate(propList):
                if prop == 'Area':
                    to_print = region_props[prop] * pixels_to_um**2  # Convert pixel square to um square
                elif prop == 'orientation':
                    to_print = region_props[prop] * 57.2958  # Convert to degrees from radians
                elif prop.find('Intensity') < 0:  # Any prop without Intensity in its name
                    to_print = region_props[prop] * pixels_to_um
                else:
                    to_print = region_props[prop]  # Remaining props, basically the ones with Intensity in their name
                csv_writer.writerow(['', '', to_print])

            grain_number += 1

    # Read the CSV content into a DataFrame
    df = pd.read_csv(csv_file_path)

    # Convert DataFrame to JSON for display
    json_content = df.to_json(orient='records')

    # Update the global variable with the CSV content
    latest_csv_content = json_content

    return csv_file_path

def grain_segmentation(img, img1):
    #Threshold image to binary using OTSU. All thresholded pixels will be set to 255
    ret1, thresh = cv2.threshold(img, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

    # Morphological operations to remove small noise - opening
    # To remove holes, we can use closing
    kernel = np.ones((3, 3), np.uint8)
    opening = cv2.morphologyEx(thresh, cv2.MORPH_OPEN, kernel, iterations=1)

    # Now we know that the regions at the center of cells are for sure cells
    # The region far away is the background.
    # We need to extract sure regions. For that, we can use erode.
    # But we have cells touching, so erode alone will not work.
    # To separate touching objects, the best approach would be distance transform and then thresholding.

    # let us start by identifying sure background area
    # dilating pixels a few times increases cell boundary to the background.
    # This way whatever is remaining for sure will be the background.
    sure_bg = cv2.dilate(opening, kernel, iterations=2)

    # Finding sure foreground area using distance transform and thresholding
    # Intensities of the points inside the foreground regions are changed to
    # distance their respective distances from the closest 0 value (boundary).
    dist_transform = cv2.distanceTransform(opening, cv2.DIST_L2, 3)

    # Let us threshold the dist transform by starting at 1/2 its max value.
    # print(dist_transform.max()) gives about 21.9
    ret2, sure_fg = cv2.threshold(dist_transform, 0.2 * dist_transform.max(), 255, 0)

    # 0.2 * max value seems to separate the cells well.
    # High value like 0.5 will not recognize some grain boundaries.

    # Unknown ambiguous region is nothing but background - foreground
    sure_fg = np.uint8(sure_fg)
    unknown = cv2.subtract(sure_bg, sure_fg)

    # Now we create a marker and label the regions inside.
    # For sure regions, both foreground and background will be labeled with positive numbers.
    # Unknown regions will be labeled 0.
    # For markers let us use ConnectedComponents.
    ret3, markers = cv2.connectedComponents(sure_fg)

    # One problem right now is that the entire background pixels are given value 0.
    # This means watershed considers this region as unknown.
    # So let us add 1 to all labels so that sure background is not 0, but 1
    markers = markers + 10

    # Now, mark the region of unknown with zero
    markers[unknown == 255] = 0

    # Watershed filling
    markers = cv2.watershed(img1, markers)

    # The boundary region will be marked -1
    img1[markers == -1] = [0, 255, 255]

    img2 = color.label2rgb(markers, bg_label=0)

    cv2.imshow('Overlay on original image', img1)
    cv2.imshow('Colored Grains', img2)
    cv2.waitKey(0)

    # Extract properties of detected cells
    # regionprops function in skimage measure module calculates useful parameters for each object.
    regions = measure.regionprops(markers, intensity_image=img)
    return regions


def perform_compactness_analysis(df):
    # Calculate compactness parameters
    df['AspectRatio'] = df['MajorAxisLength'] / df['MinorAxisLength']
    df['Circularity'] = (4 * np.pi * df['Area']) / (df['Perimeter']**2)
    df['Elongation'] = df['MajorAxisLength'] / df['MinorAxisLength']

    # Return compactness parameters as a dictionary
    compactness_results = {
        'mean_aspect_ratio': df['AspectRatio'].mean(),
        'mean_circularity': df['Circularity'].mean(),
        'mean_elongation': df['Elongation'].mean()
    }

    return compactness_results


@app.route('/grain_char', methods=['POST'])
def process_image():
    global latest_csv_content  # Declare that we want to use the global variable

    if 'image' not in request.files:
        return jsonify({'error': 'No image file provided'}), 400

    image_file = request.files['image']

    # Process the image and get the path to the generated CSV file
    csv_file_path = process_image_and_save_csv(image_file)

    # Return the CSV content in the response
    return jsonify({'csv_content': latest_csv_content})

@app.route('/view_latest_csv', methods=['GET'])
def view_latest_csv():
    global latest_csv_content  # Declare that we want to use the global variable

    # Check if a CSV file has been processed previously
    if latest_csv_content is None:
        return jsonify({'error': 'No CSV file has been processed yet'}), 400

    # Return the CSV content in the response
    return jsonify({'csv_content': latest_csv_content})

@app.route('/sorting', methods=['GET'])
def analyze_csv():
    global latest_csv_content  # Declare that we want to use the global variable

    # Check if a CSV file has been processed previously
    if latest_csv_content is None:
        return jsonify({'error': 'No CSV file has been processed yet'}), 400

    # Convert JSON content to DataFrame
    df = pd.read_json(latest_csv_content, orient='records')

    # Load the image for further processing (you may want to modify this part)

    # Sorting Index (σ) based on Area
    sorting_index_area = np.std(df['Area'])


# Sorting Index (σ) based on Equivalent Diameter
    sorting_index_diameter = np.std(df['EquivalentDiameter (um)'])


# Skewness (S) based on Orientation
    skewness_orientation = df['Orientation (degrees)'].skew()

# Kurtosis (K) based on MajorAxisLength
    kurtosis_major_axis = df['MajorAxisLength'].kurtosis()

# Graphic Standard Deviation (GSD) based on Equivalent Diameter
    gsd_diameter = np.std(df['EquivalentDiameter (um)'])

# Sorting Coefficient (Kz) based on Area
    sorting_coefficient_area = (df['Area'].quantile(0.84) - df['Area'].quantile(0.16)) / (2 * np.median(df['Area']))

   
    df['EquivalentDiameter (um)'] = df['equivalent_diameter'] * pixels_to_um
    df['Orientation (degrees)'] = df['orientation'] * 57.2958

    # Your existing analysis code...

    # Example: Return some analysis results as JSON
    analysis_results = {
        'sorting_index_area': sorting_index_area,
        'sorting_index_diameter': sorting_index_diameter,
        'skewness_orientation': skewness_orientation,
        'kurtosis_major_axis': kurtosis_major_axis,
        'gsd_diameter': gsd_diameter,
        'sorting_coefficient_area': sorting_coefficient_area
    }

    return jsonify(analysis_results)

@app.route('/compactness', methods=['GET'])
def compactness_analysis():
    global latest_csv_content

    if latest_csv_content is None:
        return jsonify({'error': 'No CSV file has been processed yet'}), 400

    # Convert JSON content to DataFrame
    df = pd.read_json(latest_csv_content, orient='records')

    # Call the compactness analysis function
    compactness_results = perform_compactness_analysis(df)

    return jsonify(compactness_results)

@app.route('/roundness', methods=['GET'])
def roundness_analysis():
    global latest_csv_content

    if latest_csv_content is None:
        return jsonify({'error': 'No CSV file has been processed yet'}), 400

    # Convert JSON content to DataFrame
    df = pd.read_json(latest_csv_content, orient='records')

    # Calculate roundness and add it as a new column
    df['Roundness'] = df['MajorAxisLength'] / df['MinorAxisLength']

    # Define roundness categories
    very_round = (0.9, 1.1)  # Adjust the range as needed
    round_category = (0.8, 0.9)
    irregular = (0.6, 0.8)
    highly_irregular = (0, 0.6)

    # Categorize roundness
    df['RoundnessCategory'] = pd.cut(df['Roundness'], bins=[very_round[0], round_category[0], irregular[0], highly_irregular[0], 1],
                                     labels=['Very Round', 'Round', 'Irregular', 'Highly Irregular'])

    # Plot histogram
    plt.figure(figsize=(10, 6))
    df['RoundnessCategory'].value_counts().sort_index().plot(kind='bar', color='skyblue')
    plt.title('Roundness Categories Histogram')
    plt.xlabel('Roundness Category')
    plt.ylabel('Count')

    # Save the plot as an in-memory image
    image_stream = BytesIO()
    plt.savefig(image_stream, format='png')
    image_stream.seek(0)

    # Close the plot to release resources
    plt.close()

    # Return the in-memory image to the user
    return send_file(image_stream, mimetype='image/png')

if __name__ == '__main__':
    os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
    os.makedirs(app.config['CSV_FOLDER'], exist_ok=True)
    app.run(host='0.0.0.0', port=5000, debug=True)

