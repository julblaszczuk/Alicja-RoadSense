import kagglehub, json, os, shutil
from pathlib import Path

CLASS_MAP = {
    "person": 0, "rider": 1, "car": 2, "truck": 3, "bus": 4,
    "train": 5, "motorcycle": 6, "bicycle": 7,
    "traffic light": 8, "traffic sign": 9
}

WORK = Path.home() / "alicja-training" / "bdd100k"

print("Downloading...")
path = kagglehub.dataset_download("solesensei/solesensei_bdd100k")
print(f"Path: {path}")

# Find JSON files
train_json = None
val_json = None
for root, dirs, files in os.walk(path):
    for f in files:
        if f == "bdd100k_labels_images_train.json":
            train_json = os.path.join(root, f)
        elif f == "bdd100k_labels_images_val.json":
            val_json = os.path.join(root, f)

print(f"Train JSON: {train_json}")
print(f"Val JSON: {val_json}")

def convert(json_file, img_dir, out_dir, w=1280, h=720):
    print(f"Converting {json_file}...")
    with open(json_file) as f:
        data = json.load(f)
    os.makedirs(out_dir, exist_ok=True)
    count = 0
    for img in data:
        name = Path(img["name"]).stem + ".txt"
        txt_path = os.path.join(out_dir, name)
        img_path = os.path.join(img_dir, img["name"])
        if not os.path.exists(img_path):
            continue
        with open(txt_path, "w") as out:
            for label in img.get("labels", []):
                cat = label["category"]
                if cat not in CLASS_MAP:
                    continue
                box = label.get("box2d", {})
                if not box:
                    continue
                x1 = box["x1"] / w
                y1 = box["y1"] / h
                x2 = box["x2"] / w
                y2 = box["y2"] / h
                cx = (x1 + x2) / 2
                cy = (y1 + y2) / 2
                bw = x2 - x1
                bh = y2 - y1
                if bw > 0 and bh > 0:
                    cid = CLASS_MAP[cat]
                    out.write(f"{cid} {cx:.6f} {cy:.6f} {bw:.6f} {bh:.6f}\n")
        count += 1
    print(f"  Done: {count} images")

if train_json:
    convert(train_json, WORK / "train" / "images", WORK / "train" / "labels")
if val_json:
    convert(val_json, WORK / "val" / "images", WORK / "val" / "labels")

tl = len(list((WORK / "train" / "labels").glob("*.txt")))
vl = len(list((WORK / "val" / "labels").glob("*.txt")))
print(f"Total: Train labels={tl}, Val labels={vl}")

shutil.rmtree(path, ignore_errors=True)
print("Cache cleaned")
