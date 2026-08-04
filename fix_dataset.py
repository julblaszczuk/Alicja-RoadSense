import kagglehub, os, shutil
from pathlib import Path

path = kagglehub.dataset_download("solesensei/solesensei_bdd100k")
print(f"Dataset path: {path}")
print(f"\nContents:")

for root, dirs, files in os.walk(path):
    level = root.replace(path, "").count(os.sep)
    indent = "  " * level
    basename = os.path.basename(root) or "root"
    print(f"{indent}{basename}/")
    if level < 3:
        for f in files[:5]:
            print(f"{indent}  {f}")
        if len(files) > 5:
            print(f"{indent}  ... and {len(files)-5} more")

# Copy to expected structure
WORK_DIR = Path.home() / 'alicja-training'
DATASET_DIR = WORK_DIR / 'bdd100k'

(DATASET_DIR / 'train' / 'images').mkdir(parents=True, exist_ok=True)
(DATASET_DIR / 'train' / 'labels').mkdir(parents=True, exist_ok=True)
(DATASET_DIR / 'val' / 'images').mkdir(parents=True, exist_ok=True)
(DATASET_DIR / 'val' / 'labels').mkdir(parents=True, exist_ok=True)

# Find actual structure
for root, dirs, files in os.walk(path):
    for f in files:
        src = os.path.join(root, f)
        if f.endswith('.jpg'):
            if 'train' in root:
                dst = DATASET_DIR / 'train' / 'images' / f
            elif 'val' in root or 'valid' in root:
                dst = DATASET_DIR / 'val' / 'images' / f
            else:
                continue
            shutil.copy2(src, dst)
        elif f.endswith('.txt'):
            if 'train' in root:
                dst = DATASET_DIR / 'train' / 'labels' / f
            elif 'val' in root or 'valid' in root:
                dst = DATASET_DIR / 'val' / 'labels' / f
            else:
                continue
            shutil.copy2(src, dst)

train_imgs = len(list((DATASET_DIR / 'train' / 'images').glob('*.jpg')))
val_imgs = len(list((DATASET_DIR / 'val' / 'images').glob('*.jpg')))
print(f"\nCopied: Train={train_imgs}, Val={val_imgs}")

# Clean cache
shutil.rmtree(path, ignore_errors=True)
print("Cache cleaned")
