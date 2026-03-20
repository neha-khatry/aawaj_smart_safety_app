import numpy as np
import librosa
import joblib
import os

SR = 22050
MAX_LEN = 3 * SR
OVERLAP = 0.5

# Load model and scaler once
#BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
svm_model = joblib.load(r"C:\Users\acer\AAWAJ-SOS-App-main\backend\scream_svm.pkl")
scaler = joblib.load(r"C:\Users\acer\AAWAJ-SOS-App-main\backend\svm_scaler.pkl")

# 1️⃣ Sliding window
def sliding_windows(audio, max_len=MAX_LEN, overlap=OVERLAP):
    step = int(max_len * (1 - overlap))
    windows = []
    for start in range(0, len(audio), step):
        chunk = audio[start:start+max_len]
        if len(chunk) < max_len:
            chunk = np.pad(chunk, (0, max_len - len(chunk)))
        if np.all(chunk == 0):
            continue
        windows.append(chunk)
    return windows

# 2️⃣ Feature extraction
def extract_features(audio):
    mfcc = librosa.feature.mfcc(y=audio, sr=SR, n_mfcc=40)
    mfcc = np.mean(mfcc.T, axis=0)
    chroma = np.mean(librosa.feature.chroma_stft(y=audio, sr=SR), axis=1)
    zcr = np.mean(librosa.feature.zero_crossing_rate(audio))
    rms = np.mean(librosa.feature.rms(y=audio))
    centroid = np.mean(librosa.feature.spectral_centroid(y=audio, sr=SR))
    return np.hstack([mfcc, chroma, zcr, rms, centroid])

# 3️⃣ Prediction
def predict_scream(audio_path, threshold=0.6, ratio=0.3):
    audio, _ = librosa.load(audio_path, sr=SR)
    audio, _ = librosa.effects.trim(audio, top_db=30)
    chunks = sliding_windows(audio)
    if not chunks:
        return {"prediction": "NON-SCREAM", "chunk_probs": []}

    predictions = []
    for chunk in chunks:
        features = extract_features(chunk)
        features_scaled = scaler.transform([features])
        prob = svm_model.predict_proba(features_scaled)[0][1]
        predictions.append(prob)

    predictions = np.array(predictions)
    scream_chunks = predictions > threshold
    scream_ratio = np.sum(scream_chunks) / len(predictions)

    final_pred = "SCREAM" if scream_ratio >= ratio else "NON-SCREAM"
    return {"prediction": final_pred, "chunk_probs": predictions.tolist()}
