from flask import Flask, jsonify, request
from flask_cors import CORS
from PIL import Image
import numpy as np
import io
import requests
import base64

app = Flask(__name__)
CORS(app)

image_array = None
image_width = 256  # Fixed image width for 256x256
image_height = 256  # Fixed image height for 256x256

# Helper functions to convert RGB to HEX and image to base64
def rgb_to_hex(r, g, b):
    return f"#{r:02x}{g:02x}{b:02x}"

def image_to_base64(img):
    buffered = io.BytesIO()
    img.save(buffered, format="PNG")
    img_str = base64.b64encode(buffered.getvalue()).decode("utf-8")
    return img_str

# Route to load and resize the image
@app.route('/load_image', methods=['POST'])
def load_image():
    global image_array
    data = request.get_json()
    image_url = data.get('url')

    try:
        response = requests.get(image_url)
        if response.status_code != 200:
            return jsonify({'error': f'Failed to load image: {response.status_code}'}), 400
        
        # Open and resize the image to 256x256
        img = Image.open(io.BytesIO(response.content))
        img = img.resize((image_width, image_height))
        image_array = np.array(img)

        img_base64 = image_to_base64(img)

        return jsonify({'message': 'Image loaded successfully', 'image': img_base64}), 200
    except Exception as e:
        return jsonify({'error': f"Failed to load image: {str(e)}"}), 400

# Route to get pixel information at specific coordinates
@app.route('/get_pixel_info', methods=['POST'])
def get_pixel_info():
    global image_array

    if image_array is None:
        return jsonify({'error': 'No image loaded'}), 400

    data = request.get_json()
    x = data.get('x')
    y = data.get('y')

    if x is None or y is None:
        return jsonify({'error': 'Invalid pixel coordinates'}), 400

    try:
        x, y = int(x), int(y)

        # Ensure the coordinates are within the 256x256 image bounds
        if x < 0 or x >= image_width or y < 0 or y >= image_height:
            return jsonify({'error': 'Pixel out of bounds'}), 400

        # Fetch the RGB values for the pixel
        r, g, b = image_array[y, x]
        hex_color = rgb_to_hex(r, g, b)

        return jsonify({'r': int(r), 'g': int(g), 'b': int(b), 'hex': hex_color}), 200
    except Exception as e:
        return jsonify({'error': f"Error processing pixel: {str(e)}"}), 500

# Run the app
if __name__ == '__main__':
    app.run(debug=True)
