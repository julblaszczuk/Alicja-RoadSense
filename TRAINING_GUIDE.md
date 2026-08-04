# Trening YOLOv8n na BDD100K - Instrukcja

## 🚀 Szybki start (Google Colab)

1. Otwórz [Google Colab](https://colab.research.google.com/)
2. **Runtime → Change runtime type → T4 GPU**
3. Wklej kod z `train_yolov8_bdd100k.ipynb`
4. Uruchom wszystkie komórki (Ctrl+F9)
5. Pobierz `yolov8n_bdd100k_int8.tflite` i `labelmap.txt`

## ⏱️ Czas i koszty

| Etap | Czas | Koszt |
|------|------|-------|
| Pobranie datasetu | 15 min | Darmowe |
| Trening (50 epok) | 2-3h | Darmowe (Colab T4) |
| Export TFLite | 10 min | Darmowe |
| **Razem** | **~3h** | **$0** |

## 📊 Dataset BDD100K

### Klasy (10 wybranych):
```
0: ??? (background)
1: person
2: rider  
3: car
4: truck
5: bus
6: train
7: motorcycle
8: bicycle
9: traffic light
10: traffic sign
```

### Statystyki:
- **100,000** obrazów (70k train, 10k val, 20k test)
- **1280x720** rozdzielczość
- **40 klas** oryginalnie (używamy 11)
- Różne warunki: dzień/noc, deszcz/śnieg, miasto/autostrada

## 🔧 Integracja z Flutter

### Krok 1: Podmień pliki
```
models/
├── yolov8n_bdd100k_int8.tflite  ← nowy model
└── labelmap.txt                  ← nowa labelmap
```

### Krok 2: Zaktualizuj `vision_engine.dart`
```dart
// Zamień:
import 'vision_engine.dart';  // stary (SSD MobileNet)

// Na:
import 'vision_engine_yolov8.dart';  // nowy (YOLOv8)
```

### Krok 3: Zmień w `pubspec.yaml`
```yaml
assets:
  - models/yolov8n_bdd100k_int8.tflite  # zamiast mobilenet_ssd.tflite
  - models/labelmap.txt
```

## 📈 Oczekiwane wyniki

| Metryka | SSD MobileNet | YOLOv8n BDD100K |
|---------|---------------|-----------------|
| mAP50 (car) | ~25% | **~65%** |
| mAP50 (person) | ~20% | **~55%** |
| mAP50 (traffic light) | ~10% | **~45%** |
| Latencja (S25 Ultra) | ~50ms | **~30ms** |
| Rozmiar modelu | 5.8 MB | **6.2 MB** |

## 🐛 Troubleshooting

### Problem: "Out of memory" w Colab
**Rozwiązanie:** Zmniejsz batch size:
```python
model.train(batch=8)  # zamiast 16
```

### Problem: Dataset nie pobiera się z Roboflow
**Rozwiązanie:** Użyj oryginalnego BDD100K (Opcja B w notebooku)

### Problem: Model nie konwerguje
**Rozwiązanie:** Zwiększ liczbę epok lub learning rate:
```python
model.train(epochs=100, lr0=0.01)
```

### Problem: TFLite za duży (>10MB)
**Rozwiązanie:** Użyj INT8 quantization (już w notebooku)

## 📚 Alternatywne datasety

| Dataset | Klasy | Obrazy | Format |
|---------|-------|--------|--------|
| **BDD100K** | 40 | 100k | JSON → YOLO |
| COCO | 80 | 330k | JSON |
| KITTI | 8 | 15k | TXT |
| nuScenes | 23 | 40k | JSON |
| Waymo Open | 4 | 200k | TFRecord |

**BDD100K jest najlepszy** bo:
- ✅ Największy dataset jazdy
- ✅ Różne warunki pogodowe
- ✅ Lane markings
- ✅ Format YOLO (łatwa konwersja)

## 🎯 Następne kroki

1. ✅ Wytrenuj model w Colab
2. ✅ Podmień pliki w projekcie
3. ✅ Przetestuj na Samsung S25 Ultra
4. ⬜ Dodaj tracking (SORT/DeepSORT)
5. ⬜ Oblicz TTC (Time To Collision)
6. ⬜ System alertów (audio/haptic)
