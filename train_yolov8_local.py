#!/usr/bin/env python3
"""YOLOv8n Fine-tuning - Alicja RoadSense"""

import os
from pathlib import Path

WORK_DIR = Path.home() / 'alicja-training'
os.chdir(WORK_DIR)

import torch
print("=" * 60)
print("  Alicja RoadSense - YOLOv8 Training")
print("=" * 60)
print(f"\n  PyTorch: {torch.__version__}")
print(f"  CUDA: {torch.cuda.is_available()}")
print(f"  GPU: {torch.cuda.get_device_name(0)}")
print(f"  VRAM: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.1f} GB")

DATASET_DIR = WORK_DIR / 'bdd100k'
yaml_path = WORK_DIR / 'data.yaml'
yaml_path.write_text(f"""
path: {DATASET_DIR}
train: train/images
val: val/images

nc: 10
names:
  0: person
  1: rider
  2: car
  3: truck
  4: bus
  5: train
  6: motorcycle
  7: bicycle
  8: traffic light
  9: traffic sign
""")

ti = len(list((DATASET_DIR / "train" / "images").glob("*.jpg")))
tl = len(list((DATASET_DIR / "train" / "labels").glob("*.txt")))
vi = len(list((DATASET_DIR / "val" / "images").glob("*.jpg")))
vl = len(list((DATASET_DIR / "val" / "labels").glob("*.txt")))
print(f"\n  Dataset: Train={ti}img/{tl}lbl, Val={vi}img/{vl}lbl")

from ultralytics import YOLO

print("\n[2/4] Trening YOLOv8n (50 epochs, ~1.5h)...")
model = YOLO('yolov8n.pt')

results = model.train(
    data=str(yaml_path),
    epochs=50,
    imgsz=640,
    batch=16,
    device=0,
    patience=10,
    name='alicja_roadsense',
    project=str(WORK_DIR / 'runs'),
    hsv_h=0.015, hsv_s=0.7, hsv_v=0.4,
    degrees=0.0, translate=0.1, scale=0.5,
    fliplr=0.5, mosaic=1.0,
)

print("\n[3/4] Ewaluacja...")
metrics = model.val()
print(f"  mAP50: {metrics.box.map50:.4f}")
print(f"  mAP50-95: {metrics.box.map:.4f}")

print("\n[4/4] Export TFLite...")
best_pt = WORK_DIR / 'runs' / 'detect' / 'alicja_roadsense' / 'weights' / 'best.pt'
best_model = YOLO(str(best_pt))
best_model.export(format='tflite', int8=True, imgsz=640)

import glob, shutil
tflite_files = glob.glob(str(WORK_DIR / 'runs' / 'detect' / 'alicja_roadsense' / 'weights' / '*.tflite'), recursive=True)
if tflite_files:
    output = WORK_DIR / 'yolov8n_bdd100k_int8.tflite'
    shutil.copy2(tflite_files[0], output)
    print(f"  TFLite: {output} ({output.stat().st_size / 1024 / 1024:.1f} MB)")

labelmap = WORK_DIR / 'labelmap.txt'
labelmap.write_text("person\nrider\ncar\ntruck\nbus\ntrain\nmotorcycle\nbicycle\ntraffic light\ntraffic sign\n")
print(f"  Labelmap: {labelmap}")

print("\n" + "=" * 60)
print("  GOTOWE!")
print("=" * 60)
