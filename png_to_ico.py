from PIL import Image
import os

def convert_png_to_ico(png_path, ico_path, sizes=None):
    """Convert PNG to ICO format with multiple sizes"""
    if sizes is None:
        sizes = [16, 32, 48, 64, 128, 256]
    
    try:
        # Open the PNG image
        img = Image.open(png_path)
        
        # Create ICO file with multiple sizes
        img.save(ico_path, format='ICO', sizes=[(s, s) for s in sizes])
        
        print(f"Successfully converted {png_path} to {ico_path}")
        return True
    except Exception as e:
        print(f"Error converting PNG to ICO: {e}")
        return False

if __name__ == "__main__":
    # Get the current directory
    current_dir = os.getcwd()
    
    # Define input and output paths
    png_path = os.path.join(current_dir, "icon.png")
    ico_path = os.path.join(current_dir, "icon.ico")
    
    # Convert PNG to ICO
    convert_png_to_ico(png_path, ico_path)