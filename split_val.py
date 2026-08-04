import os, shutil, random
from pathlib import Path

WORK = Path.home() / "alicja-training" / "bdd100k"
train_labels = list((WORK / "train" / "labels").glob("*.txt"))
random.shuffle(train_labels)

val_count = int(len(train_labels) * 0.1)
print(f"Total labels: {len(train_labels)}, moving {val_count} to val")

for i, txt in enumerate(train_labels[:val_count]):
    stem = txt.stem
    img = WORK / "train" / "images" / f"{stem}.jpg"
    
    dst_txt = WORK / "val" / "labels" / txt.name
    dst_img = WORK / "val" / "images" / img.name
    
    shutil.move(str(txt), str(dst_txt))
    if img.exists():
        shutil.move(str(img), str(dst_img))
    
    if (i + 1) % 1000 == 0:
        print(f"  Moved {i+1}/{val_count}")

ti = len(list((WORK / "train" / "images").glob("*.jpg")))
tl = len(list((WORK / "train" / "labels").glob("*.txt")))
vi = len(list((WORK / "val" / "images").glob("*.jpg")))
vl = len(list((WORK / "val" / "labels").glob("*.txt")))
print(f"\nFinal: Train={ti}img/{tl}lbl, Val={vi}img/{vl}lbl")
