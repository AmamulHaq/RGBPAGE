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
image_width = 256
image_height = 256

def rgb_to_hex(r, g, b):
    return f"#{r:02x}{g:02x}{b:02x}"

def image_to_base64(img):
    buffered = io.BytesIO()
    img.save(buffered, format="PNG")
    return base64.b64encode(buffered.getvalue()).decode("utf-8")

@app.route('/load_image', methods=['POST'])
def load_image():
    global image_array
    data = request.get_json()
    image_url = data.get('url')

    try:
        response = requests.get(image_url)
        if response.status_code != 200:
            return jsonify({'error': f'Failed to load image: {response.status_code}'}), 400
        
        img = Image.open(io.BytesIO(response.content)).resize((image_width, image_height))
        image_array = np.array(img)

        img_base64 = image_to_base64(img)
        return jsonify({'message': 'Image loaded successfully', 'image': img_base64}), 200
    except Exception as e:
        return jsonify({'error': f"Failed to load image: {str(e)}"}), 400

@app.route('/get_pixel_info', methods=['POST'])
def get_pixel_info():
    global image_array

    if image_array is None:
        return jsonify({'error': 'No image loaded'}), 400

    data = request.get_json()
    x, y = data.get('x'), data.get('y')

    # Validate container bounds
    if x is None or y is None or not (0 <= x < 258 and 0 <= y < 258):
        return jsonify({'error': 'Invalid or out-of-bounds position'}), 400

    # Limit to image bounds (256x256)
    if x >= image_width or y >= image_height:
        return jsonify({'r': 255, 'g': 255, 'b': 255, 'hex': '#ffffff', 'x': x, 'y': y}), 200

    try:
        r, g, b = image_array[y, x]
        return jsonify({'r': int(r), 'g': int(g), 'b': int(b), 'hex': rgb_to_hex(r, g, b), 'x': x, 'y': y}), 200
    except Exception as e:
        return jsonify({'error': f"Error processing pixel: {str(e)}"}), 500

if __name__ == '__main__':
    app.run(debug=True,port=5001)