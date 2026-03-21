"""
Aawaj Mental Health Chatbot - Model Training Script
====================================================
This script trains an intent classification model using TF-IDF + Logistic Regression.
Run this script to generate the trained model files used by the Django backend.

Usage:
    python train_model.py

Output:
    - models/intent_classifier.pkl   (trained classifier)
    - models/tfidf_vectorizer.pkl    (fitted vectorizer)
    - models/label_encoder.pkl       (label encoder)
    - models/training_report.txt     (evaluation metrics)
"""

import os
import pickle
import numpy as np
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import LabelEncoder
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score
from sklearn.pipeline import Pipeline
import re
import warnings
warnings.filterwarnings('ignore')

# ─────────────────────────────────────────────
# CONFIG
# ─────────────────────────────────────────────
DATA_PATH   = "../data/mental_health_dataset.csv"
MODEL_DIR   = "./models"
RANDOM_SEED = 42
TEST_SIZE   = 0.2

os.makedirs(MODEL_DIR, exist_ok=True)


# ─────────────────────────────────────────────
# TEXT PREPROCESSING
# ─────────────────────────────────────────────
def preprocess_text(text: str) -> str:
    """Clean and normalise input text."""
    text = text.lower().strip()
    text = re.sub(r"[^a-z0-9\s']", " ", text)
    text = re.sub(r"\s+", " ", text)
    return text


# ─────────────────────────────────────────────
# LOAD DATA
# ─────────────────────────────────────────────
def load_data(path: str):
    print(f"[INFO] Loading dataset from {path}...")
    df = pd.read_csv(path)
    df.dropna(inplace=True)
    df['text'] = df['text'].apply(preprocess_text)
    print(f"[INFO] Dataset loaded: {len(df)} samples, {df['intent'].nunique()} intents")
    print(f"[INFO] Intent distribution:\n{df['intent'].value_counts().to_string()}\n")
    return df


# ─────────────────────────────────────────────
# TRAIN MODEL
# ─────────────────────────────────────────────
def train(df: pd.DataFrame):
    X = df['text'].values
    y = df['intent'].values

    # Encode labels
    le = LabelEncoder()
    y_encoded = le.fit_transform(y)

    # Train/test split
    X_train, X_test, y_train, y_test = train_test_split(
        X, y_encoded, test_size=TEST_SIZE, random_state=RANDOM_SEED, stratify=y_encoded
    )

    # Build pipeline: TF-IDF + Logistic Regression
    pipeline = Pipeline([
        ('tfidf', TfidfVectorizer(
            ngram_range=(1, 2),       # unigrams + bigrams
            max_features=5000,
            sublinear_tf=True,        # apply log normalization
            min_df=1,
            analyzer='word',
            stop_words='english'
        )),
        ('clf', LogisticRegression(
            max_iter=1000,
            C=5.0,                    # regularization
            solver='lbfgs',
            random_state=RANDOM_SEED
        ))
    ])

    print("[INFO] Training model...")
    pipeline.fit(X_train, y_train)

    # Evaluate
    y_pred = pipeline.predict(X_test)
    acc = accuracy_score(y_test, y_pred)
    print(f"[INFO] Test Accuracy: {acc:.4f} ({acc*100:.2f}%)\n")

    # Cross-validation
    cv_scores = cross_val_score(pipeline, X, y_encoded, cv=5, scoring='accuracy')
    print(f"[INFO] 5-Fold CV Accuracy: {cv_scores.mean():.4f} ± {cv_scores.std():.4f}\n")

    # Full classification report
    report = classification_report(y_test, y_pred, target_names=le.classes_)
    print("[INFO] Classification Report:\n")
    print(report)

    # Save report
    report_path = os.path.join(MODEL_DIR, "training_report.txt")
    with open(report_path, "w") as f:
        f.write(f"Aawaj Chatbot - Intent Classification Report\n")
        f.write(f"{'='*50}\n")
        f.write(f"Test Accuracy : {acc:.4f}\n")
        f.write(f"CV Accuracy   : {cv_scores.mean():.4f} ± {cv_scores.std():.4f}\n")
        f.write(f"Intents       : {list(le.classes_)}\n\n")
        f.write(report)
    print(f"[INFO] Training report saved to {report_path}")

    return pipeline, le


# ─────────────────────────────────────────────
# SAVE ARTIFACTS
# ─────────────────────────────────────────────
def save_artifacts(pipeline, le):
    """Save the vectorizer, classifier, and label encoder separately for flexibility."""

    # Save full pipeline (easy inference)
    pipeline_path = os.path.join(MODEL_DIR, "intent_pipeline.pkl")
    with open(pipeline_path, "wb") as f:
        pickle.dump(pipeline, f)
    print(f"[INFO] Pipeline saved → {pipeline_path}")

    # Save label encoder
    le_path = os.path.join(MODEL_DIR, "label_encoder.pkl")
    with open(le_path, "wb") as f:
        pickle.dump(le, f)
    print(f"[INFO] Label encoder saved → {le_path}")

    # Save class list as plain text for reference
    classes_path = os.path.join(MODEL_DIR, "intent_classes.txt")
    with open(classes_path, "w") as f:
        for cls in le.classes_:
            f.write(cls + "\n")
    print(f"[INFO] Intent classes saved → {classes_path}")


# ─────────────────────────────────────────────
# QUICK TEST INFERENCE
# ─────────────────────────────────────────────
def quick_test(pipeline, le):
    test_inputs = [
        "I feel so sad and hopeless",
        "I want to hurt myself",
        "Help me breathe I'm panicking",
        "I'm so angry all the time",
        "I feel completely alone",
        "I need help, what resources are available?",
        "Hello, I need someone to talk to",
        "I feel numb and disconnected",
        "I'm stressed about my exams",
        "Thank you that really helped me",
    ]

    print("\n[INFO] Quick inference test:\n")
    print(f"{'Input':<50} {'Predicted Intent':<20} {'Confidence'}")
    print("-" * 85)
    for text in test_inputs:
        processed = preprocess_text(text)
        proba = pipeline.predict_proba([processed])[0]
        pred_idx = np.argmax(proba)
        pred_label = le.inverse_transform([pred_idx])[0]
        confidence = proba[pred_idx]
        print(f"{text:<50} {pred_label:<20} {confidence:.2%}")


# ─────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────
if __name__ == "__main__":
    print("=" * 60)
    print("  Aawaj Mental Health Chatbot - Model Training")
    print("=" * 60 + "\n")

    df = load_data(DATA_PATH)
    pipeline, le = train(df)
    save_artifacts(pipeline, le)
    quick_test(pipeline, le)

    print("\n[SUCCESS] Training complete. Model artifacts saved to ./models/")
