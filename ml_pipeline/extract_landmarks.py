"""
FretMaster ML Pipeline: Step 1 - Real-World Hand Landmark Extraction & Augmentation
Mengekstrak 21 titik landmarks 3D sendi tangan nyata dari ribuan foto open chord gitar
pada folder `flutter_application_1/dataset/` menggunakan model MediaPipe Hand Landmarker (`hand_landmark.tflite`).

Dilengkapi:
1. Filter Hand Presence nyata (hanya sampel tangan valid yang diproses).
2. Augmentasi data dunia nyata (variasi sudut kamera, rotasi 3D, jitter jari pemain, dan variasi ukuran tangan).
3. Normalisasi Spasial 100% sinkron dengan aplikasi Flutter (Wrist origin + Middle MCP scale).
"""

import os
import glob
import json
import cv2
import numpy as np
import pandas as pd
import tensorflow as tf

WORKSPACE_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATASET_DIR = os.path.join(WORKSPACE_ROOT, "flutter_application_1", "dataset")
LANDMARK_MODEL_PATH = os.path.join(WORKSPACE_ROOT, "flutter_application_1", "assets", "models", "hand_landmark.tflite")
OUTPUT_CSV = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data", "landmarks_dataset.csv")
DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")

CLASSES = ['A', 'Am', 'B', 'C', 'D', 'Dm', 'E', 'Em', 'F', 'G']

# Folder mapping dari dataset asli ke nama kelas chord
FOLDER_MAP = {
    'A': os.path.join(DATASET_DIR, 'A'),
    'Am': os.path.join(DATASET_DIR, 'am_chord'),
    'B': os.path.join(DATASET_DIR, 'B'),
    'C': os.path.join(DATASET_DIR, 'C'),
    'D': os.path.join(DATASET_DIR, 'D'),
    'Dm': os.path.join(DATASET_DIR, 'Dm'),
    'E': os.path.join(DATASET_DIR, 'E'),
    'Em': os.path.join(DATASET_DIR, 'Em'),
    'F': os.path.join(DATASET_DIR, 'F'),
    'G': os.path.join(DATASET_DIR, 'G'),
}

def spatial_normalize(landmarks_21x3):
    """
    SPATIAL NORMALIZATION (100% IDENTIK DENGAN DART DI FLUTTER):
    1. Translation Invariance: Geser titik acuan pergelangan tangan (wrist / index 0) ke origin (0, 0, 0).
    2. Scale Invariance: Bagi semua koordinat dengan jarak Euclidean wrist (0) ke middle finger MCP (9).
    """
    wrist = landmarks_21x3[0].copy()
    translated = landmarks_21x3 - wrist
    
    scale = np.linalg.norm(translated[9])
    if scale < 1e-4:
        scale = np.max(np.linalg.norm(translated, axis=1))
    if scale < 1e-4:
        scale = 1.0
        
    normalized = translated / scale
    return normalized.flatten()

def augment_landmarks(landmarks_21x3):
    """
    Data Augmentation untuk ketahanan dunia nyata:
    - Rotasi 3D (Roll Z ±12 deg, Pitch X ±10 deg, Yaw Y ±8 deg)
    - Skala tangan acak (simulasi ukuran tangan pemain 0.82 - 1.22)
    - Jitter mikro sendi jari (getaran tangan & variasi senar)
    - Variasi tekanan senar pada ujung jari
    """
    theta_z = np.radians(np.random.normal(0, 12.0))
    theta_x = np.radians(np.random.normal(0, 10.0))
    theta_y = np.radians(np.random.normal(0, 8.0))
    
    cz, sz = np.cos(theta_z), np.sin(theta_z)
    Rz = np.array([[cz, -sz, 0], [sz, cz, 0], [0, 0, 1]], dtype=np.float32)
    
    cx, sx = np.cos(theta_x), np.sin(theta_x)
    Rx = np.array([[1, 0, 0], [0, cx, -sx], [0, sx, cx]], dtype=np.float32)

    cy, sy = np.cos(theta_y), np.sin(theta_y)
    Ry = np.array([[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]], dtype=np.float32)
    
    R = Rz @ Rx @ Ry
    
    scale = np.random.uniform(0.80, 1.25)
    jitter = np.random.normal(0, 0.012, size=(21, 3)).astype(np.float32)
    
    # Variasi tekanan senar pada ujung jari (4: jempol, 8: telunjuk, 12: tengah, 16: manis, 20: kelingking)
    finger_tips = [4, 8, 12, 16, 20]
    tip_press_var = np.random.normal(0, 0.015, size=(len(finger_tips), 3)).astype(np.float32)
    jitter[finger_tips] += tip_press_var

    augmented = (landmarks_21x3 @ R) * scale + jitter
    return augmented

def extract_real_and_augmented_dataset(target_samples_per_class=1800):
    os.makedirs(DATA_DIR, exist_ok=True)
    
    print("=" * 65)
    print("FRETMASTER PILAR 3: REAL-WORLD HAND LANDMARK EXTRACTION & AUGMENTATION")
    print(f"Model Landmarker: {LANDMARK_MODEL_PATH}")
    print(f"Target Kelas: {CLASSES}")
    print(f"Target Sampel per Kelas: {target_samples_per_class}")
    print("=" * 65)
    
    interp = tf.lite.Interpreter(model_path=LANDMARK_MODEL_PATH)
    interp.allocate_tensors()
    
    input_idx = interp.get_input_details()[0]['index']
    landmarks_idx = interp.get_output_details()[0]['index']
    presence_idx = interp.get_output_details()[1]['index']
    
    records = []
    real_landmarks_by_class = {c: [] for c in CLASSES}
    
    # 1. Ekstraksi Landmarks dari Foto Asli di Dataset
    for chord, folder in FOLDER_MAP.items():
        if not os.path.exists(folder):
            print(f"[WARN] Folder tidak ditemukan: {folder}")
            continue
            
        img_files = glob.glob(os.path.join(folder, "*.*"))
        img_files = [f for f in img_files if f.lower().endswith(('.jpg', '.png', '.jpeg'))]
        print(f"\n[INFO] Memproses {len(img_files)} foto nyata untuk akord {chord}...")
        
        extracted_count = 0
        for fpath in img_files:
            img = cv2.imread(fpath)
            if img is None:
                continue
            
            rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
            resized = cv2.resize(rgb, (224, 224)).astype(np.float32) / 255.0
            inp = np.expand_dims(resized, axis=0)
            
            interp.set_tensor(input_idx, inp)
            interp.invoke()
            
            presence = interp.get_tensor(presence_idx)[0][0]
            if presence >= 0.35: # Tangan terdeteksi valid
                raw_lms = interp.get_tensor(landmarks_idx)[0]
                # Reshape ke [21, 3] dalam satuan piksel/normalisasi
                lms_21x3 = raw_lms.reshape(21, 3).copy() / 224.0
                real_landmarks_by_class[chord].append(lms_21x3)
                extracted_count += 1
                
        print(f"  -> Berhasil mengekstrak {extracted_count} landmarks nyata untuk akord {chord}")

    # 2. Penanganan sampel Em jika foto Em nyata kurang dari 200
    if len(real_landmarks_by_class['Em']) < 200 and len(real_landmarks_by_class['E']) > 0:
        print("\n[INFO] Menambah variasi sampel Em dari pose fisik akord E (jari telunjuk terbuka)...")
        for e_lms in real_landmarks_by_class['E']:
            em_lms = e_lms.copy()
            em_lms[8] += [-0.04, 0.05, -0.03]  # Angkat telunjuk tip
            em_lms[7] += [-0.02, 0.03, -0.02]
            real_landmarks_by_class['Em'].append(em_lms)
        print(f"  -> Total basis landmarks untuk Em: {len(real_landmarks_by_class['Em'])}.")

    # 3. Augmentasi data untuk mencapai keseimbangan kelas sempurna (~700 sampel per kelas)
    print("\n[INFO] Menjalankan Real-World Data Augmentation (Rotasi 3D, Sudut Pandang, Jitter)...")
    for chord in CLASSES:
        real_list = real_landmarks_by_class[chord]
        if len(real_list) == 0:
            print(f"[WARN] Tidak ada basis nyata untuk {chord}, menggunakan variasi!")
            continue
            
        # Simpan sampel nyata asli
        for base in real_list:
            feat = spatial_normalize(base)
            records.append(feat.tolist() + [chord])
            
        # Tambahkan sampel augmentasi hingga mencapai target
        needed = max(0, target_samples_per_class - len(real_list))
        print(f"  Akord {chord:2s}: {len(real_list)} sampel nyata + {needed} sampel augmentasi")
        
        idx = 0
        for _ in range(needed):
            base_pose = real_list[idx % len(real_list)]
            aug_pose = augment_landmarks(base_pose)
            feat = spatial_normalize(aug_pose)
            records.append(feat.tolist() + [chord])
            idx += 1

    columns = [f"feat_{i}" for i in range(63)] + ["label"]
    df = pd.DataFrame(records, columns=columns)
    
    # Acak dataset (Shuffle)
    df = df.sample(frac=1.0, random_state=42).reset_index(drop=True)
    df.to_csv(OUTPUT_CSV, index=False)
    
    print("\n" + "=" * 65)
    print("HASIL EKSTRAKSI & AUGMENTASI DATASET DUNIA NYATA:")
    print(f"Tersimpan di : {OUTPUT_CSV}")
    print(f"Total Sampel : {len(df)}")
    print(df["label"].value_counts())
    print("=" * 65)

if __name__ == "__main__":
    extract_real_and_augmented_dataset()
