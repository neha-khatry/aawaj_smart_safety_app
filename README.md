# 🛡️ Aawaj: Smart Safety App
### *'Your voice against violence'*

A comprehensive personal safety Android application developed as a Major
Project for the Bachelor of Engineering in Computer Engineering at
Kathmandu Engineering College, Tribhuvan University.

---

## 📌 About

Aawaj addresses growing concerns around physical security and emotional
well-being. It combines real-time SOS alerting, AI-powered scream
detection, and a mental health chatbot into a single mobile application
— designed specifically for real-world safety scenarios in Nepal.

---

## ✨ Features

### 🆘 Emergency & SOS
- Multiple SOS activation methods — button, voice, trigger-input, and time-based alerts
- Automatic SMS with real-time GPS location to trusted contacts
- Works in **low/no internet** environments via SMS
- Silent background **audio recording** for evidence collection

### 🤖 AI-Powered Scream Detection
- Detects distress sounds automatically using **MFCC (Mel-Frequency Cepstral Coefficients)**
- Classified using **Support Vector Machine (SVM)**
- Triggers SOS alert automatically on detecting a scream

### 💬 Mental Health Chatbot
- AI chatbot for emotional support built with **TF-IDF** feature extraction
- Soft-voting ensemble classifier combining **Linear SVC + Logistic Regression**
- Provides guided breathing and grounding exercises
- Crisis escalation with **Nepal-specific helpline** recommendations

### 🗺️ Additional Features
- **Real-time map tracking**
- **Safe Mode** — discreet operation during emergencies
- **Disguise Mode** — hides the app's true purpose on screen

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) — Android |
| Backend | Django (Python) |
| Database | PostgreSQL, Firebase |
| ML — Scream Detection | SVM, MFCC, Scikit-learn |
| ML — Chatbot | TF-IDF, Linear SVC, Logistic Regression |

![Flutter](https://img.shields.io/badge/-Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![Django](https://img.shields.io/badge/-Django-092E20?style=flat&logo=django&logoColor=white)
![Python](https://img.shields.io/badge/-Python-3776AB?style=flat&logo=python&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/-PostgreSQL-4169E1?style=flat&logo=postgresql&logoColor=white)
![Firebase](https://img.shields.io/badge/-Firebase-FFCA28?style=flat&logo=firebase&logoColor=black)

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.41.5+
- Python 3.10+
- PostgreSQL
- Firebase account

### Frontend Setup
```bash
git clone https://github.com/Nehu2021/aawaj_smart_safety_app.git
cd aawaj_smart_safety_app
flutter pub get
flutter run
```

### Backend Setup
```bash
cd backend
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

---

## 👥 Team

| Name | GitHub |
|------|--------|
| Neha Khatri | [@Nehu2021](https://github.com/Nehu2021) |
| Prasiddha Raj Gautam | — |
| Sudip Shrestha | — |
| Susan Baral | — |

**Supervisor:** Assoc. Prof. Er. Sharad Neupane
**Department of Computer Engineering, Kathmandu Engineering College**

---

## 👩‍💻 Author
**Neha Khatri** — [GitHub](https://github.com/Nehu2021) · [LinkedIn](https://www.linkedin.com/in/neha-khatri-1a5917335/)
