import base64
import io
import numpy as np
from PIL import Image
import requests
import plotly.graph_objects as go
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Function to convert RGB to Hex
def rgb_to_hex(r, g, b):
    return f"#{int(r):02X}{int(g):02X}{int(b):02X}"

# Function to plot the 3D RGB Cube
def plot_3d_rgb_cube(r_vals, g_vals, b_vals):
    fig = go.Figure()

    # Scatter3d plot
    fig.add_trace(go.Scatter3d(
        x=r_vals, y=g_vals, z=b_vals,
        mode='markers',
        marker=dict(
            size=3,
            color=[f'rgb({r},{g},{b})' for r, g, b in zip(r_vals, g_vals, b_vals)],
            opacity=0.8
        ),
        text=[f"RGB: ({r},{g},{b})<br>Hex: {rgb_to_hex(r, g, b)}" for r, g, b in zip(r_vals, g_vals, b_vals)],
    ))

    # Layout configuration
    fig.update_layout(
        scene=dict(
            xaxis_title="Red",
            yaxis_title="Green",
            zaxis_title="Blue",
            xaxis=dict(range=[0, 255]),
            yaxis=dict(range=[0, 255]),
            zaxis=dict(range=[0, 255]),
        ),
        margin=dict(l=0, r=0, t=40, b=0),
    )

    # Convert plot to HTML and encode it to base64
    html_content = fig.to_html(full_html=False)
    encoded_html = base64.b64encode(html_content.encode('utf-8')).decode('utf-8')
    
    return encoded_html

@app.route('/generate_cube', methods=['POST'])
def generate_cube():
    try:
        data = request.json
        image_url = data.get('imageUrl')

        if not image_url:
            return jsonify({'error': 'No image URL provided'}), 400

        # Fetch image from URL
        response = requests.get(image_url, stream=True)
        if response.status_code != 200:
            return jsonify({'error': 'Failed to download image'}), 400

        # Open and resize the image
        img = Image.open(io.BytesIO(response.content)).convert('RGB')
        img = img.resize((256, 256))
        pixels = np.array(img)

        # Extract RGB values
        r_vals = pixels[..., 0].flatten()
        g_vals = pixels[..., 1].flatten()
        b_vals = pixels[..., 2].flatten()

        # Generate the 3D RGB cube plot and get base64 encoded HTML content
        html_base64 = plot_3d_rgb_cube(r_vals, g_vals, b_vals)
        return jsonify({'cubeHtml': html_base64})

    except Exception as e:
        # Return error response in case of exceptions
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    # Run the Flask app on port 5000
    app.run(debug=True, port=5000)