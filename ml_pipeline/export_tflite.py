"""
FretMaster ML Pipeline: Step 3 - Export Lightweight MLP to TensorFlow Lite (.tflite)
Mengonversi model Keras ke format TensorFlow Lite yang dioptimasi untuk mobile deployment di Flutter.
"""

import os
import shutil
import tensorflow as tf

WORKSPACE_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")
KERAS_MODEL_PATH = os.path.join(DATA_DIR, "chord_mlp_model.keras")
TFLITE_OUTPUT_PATH = os.path.join(DATA_DIR, "chord_model.tflite")
LABELS_PATH = os.path.join(DATA_DIR, "labels.txt")
NORM_PARAMS_PATH = os.path.join(DATA_DIR, "normalization_params.json")

FLUTTER_ASSETS_DIR = os.path.join(WORKSPACE_ROOT, "flutter_application_1", "assets", "models")

def export_to_tflite():
    if not os.path.exists(KERAS_MODEL_PATH):
        raise FileNotFoundError(f"Model Keras {KERAS_MODEL_PATH} tidak ditemukan. Jalankan train_mlp.py dulu.")
        
    print(f"Memuat model Keras dari: {KERAS_MODEL_PATH}")
    model = tf.keras.models.load_model(KERAS_MODEL_PATH)
    
    # Inisialisasi TFLite Converter
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    
    tflite_model = converter.convert()
    
    with open(TFLITE_OUTPUT_PATH, "wb") as f:
        f.write(tflite_model)
        
    size_kb = len(tflite_model) / 1024.0
    print("\n" + "=" * 60)
    print(f"Export TFLite Berhasil! Ukuran file: {size_kb:.2f} KB")
    print(f"Tersimpan di: {TFLITE_OUTPUT_PATH}")
    print("=" * 60)
    
    # Salin otomatis ke assets Flutter
    os.makedirs(FLUTTER_ASSETS_DIR, exist_ok=True)
    
    target_tflite = os.path.join(FLUTTER_ASSETS_DIR, "chord_model.tflite")
    shutil.copyfile(TFLITE_OUTPUT_PATH, target_tflite)
    print(f"Disalin ke Flutter assets: {target_tflite}")
    
    if os.path.exists(LABELS_PATH):
        target_labels = os.path.join(FLUTTER_ASSETS_DIR, "labels.txt")
        shutil.copyfile(LABELS_PATH, target_labels)
        print(f"Disalin ke Flutter assets: {target_labels}")
        
    if os.path.exists(NORM_PARAMS_PATH):
        target_norm = os.path.join(FLUTTER_ASSETS_DIR, "normalization_params.json")
        shutil.copyfile(NORM_PARAMS_PATH, target_norm)
        print(f"Disalin ke Flutter assets: {target_norm}")
        
    # Verifikasi input dan output tensor TFLite
    interpreter = tf.lite.Interpreter(model_path=TFLITE_OUTPUT_PATH)
    interpreter.allocate_tensors()
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    print("\n[Verifikasi Tensor TFLite]")
    print(f"  Input Shape : {input_details[0]['shape']} | Type: {input_details[0]['dtype']}")
    print(f"  Output Shape: {output_details[0]['shape']} | Type: {output_details[0]['dtype']}")

if __name__ == "__main__":
    export_to_tflite()
