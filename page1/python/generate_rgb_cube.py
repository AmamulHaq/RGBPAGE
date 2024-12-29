import plotly.graph_objects as go
import numpy as np
import os

# Function to convert RGB to Hex
def rgb_to_hex(r, g, b):
    return f"#{int(r):02X}{int(g):02X}{int(b):02X}"

# Cube size and resolution
cube_size = 255  # RGB range (0-255)
resolution = 16  # Number of points per axis

# Generate RGB cube points
grid = np.linspace(0, cube_size, resolution)
x, y, z = np.meshgrid(grid, grid, grid)
r, g, b = x / cube_size, y / cube_size, z / cube_size  # Normalize RGB values

# Flatten arrays for scatter plot
x_flat, y_flat, z_flat = x.flatten(), y.flatten(), z.flatten()

# Calculate hex codes for each point
hex_codes = [
    rgb_to_hex(int(255 * r.flatten()[i]), int(255 * g.flatten()[i]), int(255 * b.flatten()[i]))
    for i in range(len(r.flatten()))
]

# Define the path for saving the HTML file in Flutter's assets directory
html_file_path = "/home/amamul/Desktop/page/page1/assets/rgb_cube_3d.html"  # Adjust to your Flutter assets path

# Ensure the 'assets' directory exists
os.makedirs(os.path.dirname(html_file_path), exist_ok=True)

# Create the figure for the RGB Cube
fig = go.Figure()

# Add the RGB cube
fig.add_trace(go.Scatter3d(
    x=x_flat, y=y_flat, z=z_flat,
    mode='markers',
    marker=dict(size=5, color=np.array([r.flatten(), g.flatten(), b.flatten()]).T, opacity=0.6),
    name='RGB Cube',
    hovertemplate="RGB: (%{x}, %{y}, %{z})<br>Hex: %{text}<extra></extra>",
    text=hex_codes
))

# Update layout for better visualization
fig.update_layout(
    title="3D RGB Cube with RGB and Hex Code",
    scene=dict(
        xaxis_title='X-axis (Red)',
        yaxis_title='Y-axis (Green)',
        zaxis_title='Z-axis (Blue)',
        xaxis=dict(range=[-10, 265]),
        yaxis=dict(range=[-10, 265]),
        zaxis=dict(range=[-10, 265])
    ),
    margin=dict(l=0, r=0, b=0, t=40),
    showlegend=False  # Remove legend trace
)

# Save the figure as an HTML file
fig.write_html(html_file_path)

print(f"New RGB Cube 3D dynamic visualization saved as {html_file_path}")
