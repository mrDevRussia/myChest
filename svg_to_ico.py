from PIL import Image
import cairosvg
import io
import os

def convert_svg_to_ico(svg_path, ico_path, sizes=None):
    """Convert SVG to ICO format with multiple sizes"""
    if sizes is None:
        sizes = [16, 32, 48, 64, 128, 256]
    
    try:
        # Read the SVG file
        with open(svg_path, 'rb') as svg_file:
            svg_data = svg_file.read()
        
        # Create a list to store images of different sizes
        images = []
        
        # Convert SVG to PNG at different sizes
        for size in sizes:
            png_data = cairosvg.svg2png(bytestring=svg_data, output_width=size, output_height=size)
            img = Image.open(io.BytesIO(png_data))
            images.append(img)
        
        # Save as ICO with all sizes
        images[0].save(ico_path, format='ICO', sizes=[(img.width, img.height) for img in images], append_images=images[1:])
        
        print(f"Successfully converted {svg_path} to {ico_path}")
        return True
    except Exception as e:
        print(f"Error converting SVG to ICO: {e}")
        return False

if __name__ == "__main__":
    # Get the current directory
    current_dir = os.getcwd()
    
    # Define input and output paths
    svg_path = os.path.join(current_dir, "icon.svg")
    ico_path = os.path.join(current_dir, "icon.ico")
    
    # Convert SVG to ICO
    convert_svg_to_ico(svg_path, ico_path)