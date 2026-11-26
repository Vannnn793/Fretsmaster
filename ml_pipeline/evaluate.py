"""
FretMaster ML Pipeline: Step 4 - Model Evaluation
Evaluasi performa klasifikasi chord: Classification Report, Confusion Matrix, dan per-class accuracy.
"""

import os
import numpy as np
import pandas as pd
from sklearn.metrics import classification_report, confusion_matrix
import tensorflow as tf

DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")
INPUT_CSV = os.path.join(DATA_DIR, "landmarks_dataset.csv")
TFLITE_PATH = os.path.join(DATA_DIR, "chord_model.tflite")
LABELS_PATH = os.path.join(DATA_DIR, "labels.txt")

def evaluate_model():
    if not os.path.exists(TFLITE_PATH) or not os.path.exists(LABELS_PATH):
        raise FileNotFoundError("Model TFLite atau file labels belum tersedia.")
        
    with open(LABELS_PATH, "r", encoding="utf-8") as f:
        labels = [l.strip() for l in f if l.strip()]
        
    df = pd.read_csv(INPUT_CSV)
    X = df[[c for c in df.columns if c.startswith("feat_")]].values.astype(np.float32)
    y_str = df["label"].values
    
    label_to_idx = {name: i for i, name in enumerate(labels)}
    y_true = np.array([label_to_idx[name] for name in y_str if name in label_to_idx])
    X = np.array([row for row, name in zip(X, y_str) if name in label_to_idx])
    
    # Jalankan inferensi menggunakan TFLite Interpreter
    interpreter = tf.lite.Interpreter(model_path=TFLITE_PATH)
    interpreter.allocate_tensors()
    input_idx = interpreter.get_input_details()[0]["index"]
    output_idx = interpreter.get_output_details()[0]["index"]
    
    y_pred = []
    for sample in X:
        inp = np.expand_dims(sample, axis=0).astype(np.float32)
        interpreter.set_tensor(input_idx, inp)
        interpreter.invoke()
        out = interpreter.get_tensor(output_idx)[0]
        y_pred.append(np.argmax(out))
        
    y_pred = np.array(y_pred)
    
    print("\n" + "=" * 60)
    print("HASIL EVALUASI TFLITE MLP CHORD CLASSIFIER")
    print("=" * 60)
    print(classification_report(y_true, y_pred, target_names=labels, digits=4))
    
    cm = confusion_matrix(y_true, y_pred)
    print("Confusion Matrix:")
    print(cm)
    
    acc = np.mean(y_true == y_pred)
    print(f"\nOverall Top-1 Accuracy: {acc * 100:.2f}%")
    print("=" * 60)

if __name__ == "__main__":
    evaluate_model()
