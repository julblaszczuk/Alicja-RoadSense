#!/usr/bin/env python3
"""
Download MobileNet SSD TFLite model from public sources.

Alternative sources for MobileNet SSD models:
- TensorFlow Lite Model Zoo
- Kaggle Models
- GitHub Releases
"""

import os
import sys
import urllib.request
from pathlib import Path

MODEL_URLS = [
    # MobileNet V1 SSD (COCO) - 27MB
    "https://github.com/google-coral/test_data/raw/master/ssd_mobilenet_v1_coco_quant_postprocess.tflite",
    # MobileNet V2 SSD (COCO) - alternative
    "https://github.com/google-coral/test_data/raw/master/ssd_mobilenet_v2_coco_quant.tflite",
]

def download_model(url: str, output_path: str) -> bool:
    """Download model from URL."""
    try:
        print(f"Trying: {url}")
        urllib.request.urlretrieve(url, output_path)
        
        size_mb = os.path.getsize(output_path) / (1024 * 1024)
        print(f"[OK] Downloaded: {size_mb:.2f} MB")
        return True
    except Exception as e:
        print(f"[FAIL] Failed: {e}")
        return False

def main():
    """Download MobileNet SSD model."""
    output_dir = Path(__file__).parent.parent / "models"
    output_dir.mkdir(exist_ok=True)
    output_path = output_dir / "mobilenet_ssd.tflite"
    
    print("=" * 60)
    print("MobileNet SSD TFLite Model Downloader")
    print("=" * 60)
    print()
    
    # Try each URL
    for url in MODEL_URLS:
        if download_model(url, str(output_path)):
            print()
            print("=" * 60)
            print("SUCCESS!")
            print("=" * 60)
            print(f"Model saved to: {output_path}")
            print()
            print("Model details:")
            print("  - Type: MobileNet SSD (COCO)")
            print("  - Classes: 90 (vehicles, pedestrians, etc.)")
            print("  - Input: 300x300 RGB")
            print("  - Format: TFLite (quantized)")
            print()
            print("Detected classes:")
            print("  - Cars, trucks, buses")
            print("  - Motorcycles, bicycles")
            print("  - Pedestrians (persons)")
            print("  - Traffic lights, stop signs")
            print("  - And 80+ other objects")
            return 0
    
    print()
    print("=" * 60)
    print("FAILED - All download attempts failed")
    print("=" * 60)
    print()
    print("Manual download options:")
    print()
    print("1. Google Coral Test Data:")
    print("   https://github.com/google-coral/test_data")
    print()
    print("2. TensorFlow Lite Model Zoo:")
    print("   https://www.tensorflow.org/lite/models/modify/model_maker/object_detection")
    print()
    print("3. Kaggle Models:")
    print("   https://www.kaggle.com/models?query=mobilenet+ssd")
    print()
    print("Download the .tflite file and place it in:")
    print(f"  {output_path}")
    print()
    return 1

if __name__ == "__main__":
    sys.exit(main())
