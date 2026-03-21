"""
aawaj_chatbot/chatbot_engine.py
================================
Core chatbot inference engine.
Loads the trained ML model and generates responses for the Aawaj mental health chatbot.
"""

import os
import pickle
import re
import random
import numpy as np

# ─────────────────────────────────────────────
# RESPONSE TEMPLATES PER INTENT
# ─────────────────────────────────────────────
RESPONSES = {

    "sadness": [
        "I can hear how much pain you're carrying right now. It takes real courage to speak about it. 💙 You don't have to face this alone — I'm right here with you.",
        "Feeling sad is a deeply human experience, and what you're going through is valid. Would you like to talk more about what's been weighing on you?",
        "I'm so sorry you're feeling this way. Sometimes our hearts need space to grieve. Take a breath — you're safe here, and I'm listening.",
        "That heaviness sounds so real. Your feelings matter. Can you tell me a little more about what's been happening?",
        "It's okay to feel sad. You don't have to pretend to be okay. I'm here to sit with you in this moment. 🌙",
    ],

    "anxiety": [
        "Anxiety can feel so overwhelming — like your mind won't give you a moment's peace. You're not alone in this. 🌬️ Would you like to try a quick breathing exercise to help ease the tension?",
        "I hear you — that constant worry is exhausting. Let's slow things down together. Take one gentle breath with me, and let's talk about what's stirring inside you.",
        "It makes complete sense that you're feeling anxious. Your nervous system is working overtime. Would a grounding exercise help right now?",
        "Anxiety is real and it's hard. You've reached out, which already takes strength. Tell me more about what's triggering these feelings.",
        "That racing mind is so hard to live with. Let's work through this together — one small moment at a time. 🌿",
    ],

    "crisis": [
        "🆘 I'm really glad you reached out right now. What you're feeling is serious, and you deserve immediate support. Please contact **TPO Nepal** at **01-4460084** or text a trusted person right now. You matter deeply.",
        "I hear you, and I'm taking what you're saying very seriously. Please reach out to a crisis counselor immediately — **Umang Helpline: 9840021600** (Nepal). You are not alone, and this moment will pass. 💙",
        "You've reached out, and that matters so much. Please call **TUTH Psychiatry Emergency: 01-4412404** right now. Your life has profound value. I am here with you, but please also contact someone who can help in person.",
        "Thank you for trusting me with this. Please don't face this alone — call **Nepal Police: 100** or **Patan Hospital Psychiatry: 01-5522266** immediately. You deserve care and protection. 🆘",
        "What you're sharing tells me you need real human support right now. Please reach out to **Sathi Sewa: 1166** (Nepal mental health helpline). You are loved and this pain is not permanent.",
    ],

    "breathing": [
        None,  # breathing uses special structured response - handled below
    ],

    "anger": [
        "Anger is a powerful emotion — it often hides deeper pain like hurt, fear, or injustice. 🔥 It's okay to feel it. Let's explore what's underneath together.",
        "Feeling intensely angry is exhausting. You're not a bad person for feeling this — it's a signal. Would you like to talk about what triggered it?",
        "I hear that anger, and it's valid. Let's slow down together. Can you tell me what happened that brought this up?",
        "Strong anger often means something important was crossed — a boundary, a trust, an expectation. You're safe to share here.",
        "It's okay to be angry. What matters is finding a safe way to process it. Tell me what's going on — I'm listening without judgment. 🌿",
    ],

    "loneliness": [
        "Loneliness can ache in such a deep way — like being in a room full of people and still feeling invisible. You are seen here. 💙",
        "I'm really glad you reached out. Connection matters, and the fact that you're looking for it shows your heart is still open. Tell me more about what's been making you feel so alone.",
        "Feeling isolated is one of the hardest human experiences. But right now, in this moment, you are not alone — I'm here with you.",
        "You deserve to feel connected and valued. What's been making it hard to connect with people around you?",
        "I hear how alone you feel, and I want you to know — you reaching out here is a form of connection. I'm listening. 🌙",
    ],

    "stress": [
        "That sounds like an enormous amount of pressure to carry. No wonder you're feeling stretched thin. Let's think through this together — what feels most overwhelming right now?",
        "Burnout and overwhelm are real. You're not weak for struggling under that weight. Can you tell me what's piling up the most?",
        "Being under so much stress affects your mind and body. You deserve rest and support. What's one thing that's been hardest lately?",
        "It sounds like you've been pushing yourself so hard. Let's find a way to bring a little relief. Is there anything we can untangle together?",
        "Stress builds up when we don't have enough support or space to breathe. I'm here to help you find some of that space. 🌿",
    ],

    "resources": [
        "Here are mental health resources available in Nepal: \n\n📞 **TPO Nepal:** 01-4460084\n📞 **Umang Helpline:** 9840021600\n📞 **Sathi Sewa:** 1166\n📞 **TUTH Psychiatry:** 01-4412404\n📞 **Patan Hospital Psychiatry:** 01-5522266\n\nWould you like guidance on which one might suit your situation best?",
        "You're taking such an important step by looking for help. In Nepal, you can reach:\n\n🏥 **TPO Nepal (Trauma, Psychosocial):** 01-4460084\n💬 **Umang Helpline:** 9840021600 (free counseling)\n📱 **Sathi Sewa:** 1166\n\nWould you like to talk about what kind of support you're looking for?",
        "There are people ready to support you right now:\n\n🆘 **Crisis Line - Sathi Sewa:** 1166\n🧠 **TPO Nepal:** 01-4460084\n🏥 **KIST Medical College Psychiatry:** 01-4371000\n💙 **Umang:** 9840021600\n\nI can also keep talking with you here. What feels right?",
    ],

    "greeting": [
        "Hello 💙 I'm Aawaj Support — a safe space for you to share how you're feeling. How are you doing today?",
        "Hi there. I'm so glad you reached out. This is a safe space, and I'm here to listen without judgment. How are you feeling right now?",
        "Hey, welcome. Whatever brought you here — big or small — I'm here for it. How are you doing?",
        "Hello 🌙 I'm here to support you. You don't have to be in crisis to talk. How's your heart today?",
        "Hi! I'm Aawaj Support. You're not alone — I'm here to listen. What's on your mind?",
    ],

    "gratitude": [
        "I'm really glad that helped. Remember — reaching out is always the right move. I'm here whenever you need me. 💙",
        "It means a lot to hear that. You deserve support, always. Take care of yourself today. 🌿",
        "I'm happy you're feeling a little better. Keep going — you're stronger than you know.",
        "That warms my heart. You did the hard part by showing up and talking. I'm always here. 💙",
        "So glad to be here for you. Anytime you need to talk, I'm right here. 🌙",
    ],

    "positive": [
        "That's wonderful to hear 🌟 Hold on to that feeling. What helped things feel a bit better today?",
        "I love hearing this! Small moments of light matter so much. Keep noticing them. 💙",
        "That's a real win. Progress isn't always loud — sometimes it's just getting through the day with a little more ease.",
        "You're doing great. Even one good moment is worth celebrating. What made today feel lighter?",
        "So glad to hear things feel a little better 🌿 You deserve those moments of peace.",
    ],

    "numbness": [
        "Feeling emotionally numb can be your mind's way of protecting you from too much at once. It's okay. Can you describe when this feeling started?",
        "Numbness is often a sign that you've been through a lot. Your feelings haven't disappeared — they may just need gentle coaxing. I'm here to help with that.",
        "Feeling disconnected from yourself or your emotions is difficult. You're not broken — you're coping. Let's talk about what's been happening.",
        "That flat, grey feeling is so hard to describe but so real. I hear you. Would it help to try a gentle grounding exercise?",
        "Sometimes our emotions go quiet when they've been overwhelmed. Tell me more about how long you've been feeling this way. 💙",
    ],

    "shame_guilt": [
        "Shame is such a heavy, silent burden. But you are not your mistakes — you are a whole person doing the best you can. 💙",
        "Guilt tells us we care. But you deserve compassion too — especially from yourself. Can you tell me what's been weighing on you?",
        "You reaching out is a sign of your goodness, not your failure. Whatever you're carrying, let's look at it gently together.",
        "Shame often lies to us — it tells us we're uniquely broken, but that's never true. You deserve forgiveness, including self-forgiveness.",
        "Being hard on yourself is exhausting. Let's talk about what happened — you deserve to be heard without judgment. 🌿",
    ],

    "sleep": [
        "Sleep problems are so closely tied to our emotional wellbeing. Not sleeping well can make everything feel harder. What's been keeping you up?",
        "Disrupted sleep is exhausting in every sense. Is it your mind racing, anxiety, or something else waking you? Let's figure this out together.",
        "Your body and mind need rest so much. Can you tell me more about what happens when you try to sleep?",
        "Sleep struggles can really compound how we feel emotionally. You deserve rest. Let's explore what might be getting in the way.",
        "That sounds really draining — both the lack of sleep and what might be causing it. Tell me more. 💙",
    ],

    "fallback": [
        "I'm here and I'm listening. Can you tell me a little more about what's going on? I want to understand. 💙",
        "Thank you for sharing that with me. I want to make sure I understand — can you tell me more about how you're feeling?",
        "I hear you. Let's take this one step at a time. What's been weighing on you most?",
        "You reached out, and that matters. I'm here with you. Can you share a bit more about what's on your mind?",
        "I'm listening, and I care about what you're going through. Tell me more. 🌿",
    ],
}

# ─────────────────────────────────────────────
# BREATHING EXERCISE STEPS
# ─────────────────────────────────────────────
BREATHING_EXERCISES = [
    {
        "name": "4-7-8 Breathing",
        "description": "A powerful technique to calm your nervous system quickly.",
        "steps": [
            "🌬️ Find a comfortable seated position and close your eyes.",
            "👃 Breathe IN slowly through your nose for **4 counts**.",
            "⏸️ Hold your breath gently for **7 counts**.",
            "💨 Exhale completely through your mouth for **8 counts**.",
            "🔄 Repeat this cycle 3–4 times.",
            "✅ Notice how your body begins to soften with each breath."
        ]
    },
    {
        "name": "Box Breathing",
        "description": "Used by Navy SEALs and therapists alike to restore calm.",
        "steps": [
            "📦 Imagine drawing a box as you breathe.",
            "➡️ Breathe IN for **4 counts** (draw the top).",
            "⬇️ Hold for **4 counts** (draw the right side).",
            "⬅️ Breathe OUT for **4 counts** (draw the bottom).",
            "⬆️ Hold for **4 counts** (draw the left side).",
            "🔄 Repeat 4 times. Feel the stillness settle in. 🌿"
        ]
    },
    {
        "name": "5-4-3-2-1 Grounding",
        "description": "Anchor yourself to the present moment using your senses.",
        "steps": [
            "👀 Name **5 things** you can SEE around you right now.",
            "✋ Name **4 things** you can TOUCH. Feel their texture.",
            "👂 Name **3 things** you can HEAR. Listen carefully.",
            "👃 Name **2 things** you can SMELL (or recall a favourite scent).",
            "👅 Name **1 thing** you can TASTE.",
            "✅ You are here. You are safe. 💙"
        ]
    },
]


# ─────────────────────────────────────────────
# TEXT PREPROCESSING
# ─────────────────────────────────────────────
def preprocess_text(text: str) -> str:
    text = text.lower().strip()
    text = re.sub(r"[^a-z0-9\s']", " ", text)
    text = re.sub(r"\s+", " ", text)
    return text


# ─────────────────────────────────────────────
# CHATBOT ENGINE CLASS
# ─────────────────────────────────────────────
class AawajChatbotEngine:
    """
    Core inference engine for the Aawaj mental health chatbot.
    Loads trained sklearn pipeline and generates empathetic responses.
    """

    CONFIDENCE_THRESHOLD = 0.30   # below this → fallback
    CRISIS_INTENTS       = {"crisis"}

    def __init__(self, model_dir: str):
        self.model_dir = model_dir
        self._load_model()

    def _load_model(self):
        pipeline_path = os.path.join(self.model_dir, "intent_pipeline.pkl")
        le_path       = os.path.join(self.model_dir, "label_encoder.pkl")

        if not os.path.exists(pipeline_path):
            raise FileNotFoundError(
                f"Model not found at {pipeline_path}. "
                "Please run ml/train_model.py first."
            )

        with open(pipeline_path, "rb") as f:
            self.pipeline = pickle.load(f)

        with open(le_path, "rb") as f:
            self.le = pickle.load(f)

        self.classes = list(self.le.classes_)
        print(f"[Aawaj] Chatbot model loaded. Intents: {self.classes}")

    def predict_intent(self, text: str):
        """Returns (intent_label, confidence_score)."""
        processed = preprocess_text(text)
        proba = self.pipeline.predict_proba([processed])[0]
        idx = int(np.argmax(proba))
        label = self.le.inverse_transform([idx])[0]
        confidence = float(proba[idx])
        return label, confidence

    def get_response(self, user_message: str) -> dict:
        """
        Main inference method.
        Returns a dict with: intent, confidence, message, is_crisis, exercise (optional)
        """
        intent, confidence = self.predict_intent(user_message)

        # Low confidence → fallback
        if confidence < self.CONFIDENCE_THRESHOLD:
            intent = "fallback"

        is_crisis = intent in self.CRISIS_INTENTS
        exercise  = None
        message   = ""

        if intent == "breathing":
            exercise = random.choice(BREATHING_EXERCISES)
            message  = (
                f"Let's do a **{exercise['name']}** together 🌬️\n\n"
                f"*{exercise['description']}*\n\n"
                + "\n".join(exercise["steps"])
                + "\n\n💙 Take your time. There's no rush."
            )
        else:
            templates = RESPONSES.get(intent, RESPONSES["fallback"])
            message = random.choice(templates)

        return {
            "intent":     intent,
            "confidence": round(confidence, 4),
            "message":    message,
            "is_crisis":  is_crisis,
            "exercise":   exercise,
        }
