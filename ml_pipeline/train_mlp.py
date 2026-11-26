"""
FretMaster ML Pipeline: Step 2 - Train Lightweight MLP Classifier
Melatih Multi-Layer Perceptron (MLP) ringan pada 63 fitur koordinat landmark tangan ternormalisasi.
"""

import os
import json
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
import tensorflow as tf
from tensorflow.keras import layers, models, callbacks

WORKSPACE_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INPUT_CSV = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data", "landmarks_dataset.csv")
MODEL_OUTPUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")
KERAS_MODEL_PATH = os.path.join(MODEL_OUTPUT_DIR, "chord_mlp_model.keras")
LABELS_PATH = os.path.join(MODEL_OUTPUT_DIR, "labels.txt")
NORM_PARAMS_PATH = os.path.join(MODEL_OUTPUT_DIR, "normalization_params.json")

SEED = 42
np.random.seed(SEED)
tf.random.set_seed(SEED)

def train_mlp():
    os.makedirs(MODEL_OUTPUT_DIR, exist_ok=True)
    
    if not os.path.exists(INPUT_CSV):
        raise FileNotFoundError(f"File dataset {INPUT_CSV} belum ditemukan. Jalankan extract_landmarks.py terlebih dahulu.")
        
    df = pd.read_csv(INPUT_CSV)
    print(f"Dataset dimuat: {len(df)} sampel, {df.shape[1]} kolom.")
    
    X = df[[c for c in df.columns if c.startswith("feat_")]].values.astype(np.float32)
    y_raw = df["label"].values
    
    label_encoder = LabelEncoder()
    y = label_encoder.fit_transform(y_raw)
    class_names = list(label_encoder.classes_)
    num_classes = len(class_names)
    
    print(f"Kelas terdeteksi ({num_classes} kelas): {class_names}")
    
    # Simpan daftar label kelas
    with open(LABELS_PATH, "w", encoding="utf-8") as f:
        for name in class_names:
            f.write(f"{name}\n")
    print(f"Labels tersimpan di: {LABELS_PATH}")
    
    # Normalization parameters metadata (untuk sinkronisasi Flutter)
    norm_params = {
        "num_features": 63,
        "landmark_count": 21,
        "channels": 3,
        "reference_joint_origin": 0,       # Wrist
        "reference_joint_scale_target": 9, # Middle MCP
        "epsilon": 1e-4,
        "classes": class_names
    }
    with open(NORM_PARAMS_PATH, "w", encoding="utf-8") as f:
        json.dump(norm_params, f, indent=2)
    print(f"Parameter normalisasi tersimpan di: {NORM_PARAMS_PATH}")
    
    X_train, X_val, y_train, y_val = train_test_split(
        X, y,
        test_size=0.2,
        random_state=SEED,
        stratify=y
    )
    
    print(f"Ukuran training: {len(X_train)} | Validasi: {len(X_val)}")
    
    # Arsitektur Deep Lightweight MLP (~60K parameter, <250KB, inferensi mobile sub-millisecond)
    model = models.Sequential([
        layers.Input(shape=(63,), name="hand_landmarks_63"),
        
        layers.Dense(256, kernel_initializer='he_normal'),
        layers.BatchNormalization(),
        layers.Activation('swish'),
        layers.Dropout(0.20),
        
        layers.Dense(128, kernel_initializer='he_normal'),
        layers.BatchNormalization(),
        layers.Activation('swish'),
        layers.Dropout(0.15),
        
        layers.Dense(64, kernel_initializer='he_normal'),
        layers.BatchNormalization(),
        layers.Activation('swish'),
        layers.Dropout(0.10),
        
        layers.Dense(32, kernel_initializer='he_normal'),
        layers.Activation('swish'),
        
        layers.Dense(num_classes, activation='softmax', name="chord_probabilities")
    ])
    
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=0.0015),
        loss='sparse_categorical_crossentropy',
        metrics=['accuracy']
    )
    
    model.summary()
    
    cbs = [
        callbacks.EarlyStopping(
            monitor='val_accuracy',
            patience=18,
            restore_best_weights=True,
            verbose=1
        ),
        callbacks.ReduceLROnPlateau(
            monitor='val_loss',
            factor=0.5,
            patience=5,
            min_lr=1e-5,
            verbose=1
        )
    ]
    
    history = model.fit(
        X_train, y_train,
        validation_data=(X_val, y_val),
        epochs=70,
        batch_size=32,
        callbacks=cbs,
        verbose=1
    )
    
    val_loss, val_acc = model.evaluate(X_val, y_val, verbose=0)
    print("\n" + "=" * 60)
    print(f"Training Selesai! Final Validation Accuracy: {val_acc * 100:.2f}% (Loss: {val_loss:.4f})")
    print("=" * 60)
    
    model.save(KERAS_MODEL_PATH)
    print(f"Model Keras tersimpan di: {KERAS_MODEL_PATH}")

if __name__ == "__main__":
    train_mlp()
