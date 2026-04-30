"""
phrase_detector/phrase_engine.py
==================================
Core inference engine for Aawaj phrase detection.
Loads trained ML model and classifies spoken text as emergency or background.
"""

import os
import re
import pickle
import numpy as np
import logging

logger = logging.getLogger(__name__)

# ── All emergency phrases (for keyword fallback) ─────────────────────────
EMERGENCY_KEYWORDS_EN = [
    "help me", "help please", "somebody help", "call police",
    "call the police", "emergency", "i am in danger", "danger",
    "i am being attacked", "let me go", "stop stop", "save me",
    "i am trapped", "i am hurt", "he is hurting me", "she is hurting me",
    "i need help", "i am being followed", "i am being harassed",
    "please help", "call 100", "call ambulance", "i am being abused",
    "help me escape", "help help",
]

EMERGENCY_KEYWORDS_NP = [
    "bachau", "madad", "madad gara", "help gara", "khatara",
    "police bolau", "aafat", "malaai bachau", "mero jaan",
    "koi madad", "chhad malaai", "nacha nai", "koi aau",
    "khatara chha", "malaai chhad", "help garnus",
]

ALL_KEYWORDS = EMERGENCY_KEYWORDS_EN + EMERGENCY_KEYWORDS_NP

# Confidence threshold — above this → emergency confirmed
CONFIDENCE_THRESHOLD = 0.60
# Keyword boost — if keyword found, lower threshold applies
KEYWORD_CONFIDENCE_THRESHOLD = 0.45


def preprocess(text: str) -> str:
    text = str(text).lower().strip()
    text = re.sub(r"[^a-z0-9\s'àáâãäåæçèéêëìíîïðñòóôõöùúûüýþÿ]", " ", text)
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def keyword_check(text: str) -> bool:
    """Fast keyword scan before ML inference."""
    t = preprocess(text)
    for kw in ALL_KEYWORDS:
        if kw in t:
            return True
    return False


class PhraseDetectionEngine:
    """
    Loads trained sklearn pipeline and classifies speech text.
    Combines ML confidence with keyword fallback for maximum recall.
    """

    def __init__(self, model_dir: str):
        self.model_dir = model_dir
        self._load_model()

    def _load_model(self):
        pipeline_path = os.path.join(self.model_dir, "phrase_pipeline.pkl")
        le_path       = os.path.join(self.model_dir, "phrase_label_encoder.pkl")

        if not os.path.exists(pipeline_path):
            raise FileNotFoundError(
                f"Phrase model not found at {pipeline_path}. "
                "Run ml/train_phrase_model.py first."
            )

        with open(pipeline_path, "rb") as f:
            self.pipeline = pickle.load(f)
        with open(le_path, "rb") as f:
            self.le = pickle.load(f)

        self.emergency_idx = int(
            np.where(self.le.classes_ == "emergency")[0][0]
        )
        logger.info(f"[PhraseDetection] Model loaded. Classes: {list(self.le.classes_)}")

    def classify(self, text: str) -> dict:
        """
        Classify transcribed speech text.

        Returns:
            {
              "text":           original text,
              "processed":      cleaned text,
              "is_emergency":   bool,
              "confidence":     float (0-1),
              "method":         "ml" | "keyword_boost" | "keyword_only",
              "matched_keyword": str | None
            }
        """
        processed       = preprocess(text)
        has_keyword     = keyword_check(text)
        matched_keyword = None

        # Find which keyword matched
        if has_keyword:
            for kw in ALL_KEYWORDS:
                if kw in processed:
                    matched_keyword = kw
                    break

        # ML inference
        try:
            proba        = self.pipeline.predict_proba([processed])[0]
            emerg_prob   = float(proba[self.emergency_idx])
            method       = "ml"

            # Apply keyword boost (lower threshold if keyword found)
            threshold    = KEYWORD_CONFIDENCE_THRESHOLD if has_keyword else CONFIDENCE_THRESHOLD
            is_emergency = emerg_prob >= threshold

            # Keyword-only fallback: if ML uncertain but keyword strongly matches
            if not is_emergency and has_keyword and emerg_prob >= 0.35:
                is_emergency = True
                method       = "keyword_boost"

        except Exception as e:
            logger.error(f"ML inference failed: {e}, falling back to keyword")
            emerg_prob   = 1.0 if has_keyword else 0.0
            is_emergency = has_keyword
            method       = "keyword_only"

        return {
            "text":            text,
            "processed":       processed,
            "is_emergency":    is_emergency,
            "confidence":      round(emerg_prob, 4),
            "method":          method,
            "matched_keyword": matched_keyword,
        }
