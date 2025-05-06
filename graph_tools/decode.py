import sys
from PIL import Image

def decode_lsb_alpha(image_path):
    try:
        img = Image.open(image_path)
        if img.mode != 'RGBA':
            img = img.convert('RGBA')

        pixels = list(img.getdata())
        extracted_bits = ""
        pixel_count = len(pixels)
        
        if pixel_count < 32:
            raise ValueError("no header! too small!")

        # Extract length header (32 bits)
        for i in range(32):
            extracted_bits += str(pixels[i][3] & 1)
        
        data_length = int(extracted_bits, 2)
        
        required_pixels = 32 + data_length
        if pixel_count < required_pixels:
             raise ValueError(f"too small of an image {required_pixels} pixels, found {pixel_count}.")

        # Extract data bits
        for i in range(32, required_pixels):
             extracted_bits += str(pixels[i][3] & 1)

        binary_data = extracted_bits[32:]
        
        all_bytes = bytearray()
        for i in range(0, data_length, 8):
            byte_str = binary_data[i:i+8]
            if len(byte_str) < 8:
                 # This might indicate an issue, but try padding for robustness
                 byte_str = byte_str.ljust(8, '0') 
            all_bytes.append(int(byte_str, 2))

        return all_bytes.decode('utf-8', errors='replace')

    except FileNotFoundError:
        print(f"no file at {image_path}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"???: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("use: python decode.py <image_file.png>", file=sys.stderr)
        sys.exit(1)
    
    image_file = sys.argv[1]
    decoded_text = decode_lsb_alpha(image_file)
    if decoded_text is not None:
        print(decoded_text)
        with open("decode.txt", "w") as f:
            f.write(decoded_text)
