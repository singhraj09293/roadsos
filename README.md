# 🛡️ RoadSoS — Smart Road Accident Emergency Response

> Built for **National Road Safety Hackathon 2026** | IIT Madras CoERS  
> Theme: **AI in Road Safety** | Topic: **RoadSoS**

---

## 📱 What is RoadSoS?

RoadSoS is a Flutter-based emergency response app for India that **automatically detects road accidents** using your phone's accelerometer and instantly alerts emergency contacts and services — even if you're unconscious.

---

## ✨ Key Features

| Feature | Description |
|---|---|
| 🔍 **Auto Crash Detection** | Detects impact via accelerometer, confirms via 3s stillness check |
| ⏱️ **Are You Safe? Dialog** | 30s countdown with PIN cancel — prevents false alarms |
| 📍 **Live GPS** | Grabs precise location instantly on SOS trigger |
| 📲 **Auto SMS** | Sends location + hospital info to all emergency contacts |
| 🏥 **Nearest Hospitals** | Shows closest hospitals, ambulances, police on map |
| 🇮🇳 **India Emergency DB** | Pre-loaded numbers for all 28 states (108, 100, 1033) |
| 📊 **SOS Stats** | Tracks India-wide SOS count and accident hotspots |
| 🔋 **Background Running** | Works with screen off, app minimised |

---

## 🧠 How Crash Detection Works

```
Impact detected (force > 25 m/s²)
        ↓
3 second stillness check
        ↓
"Are You Safe?" — 30s countdown
        ↓
No response → SOS auto-fires
```

**3 Layer False Alarm Protection:**
1. Stillness check (normal drops = phone picked up = reset)
2. Speed context (walking speed = 60s countdown instead of 30s)
3. PIN cancel + "I AM SAFE" button

---

## 🏗️ Tech Stack

| Layer | Technology |
|---|---|
| App | Flutter (Dart) |
| State | Riverpod |
| Backend | Firebase Firestore |
| Auth | Firebase Auth |
| Location | Geolocator + Geocoding |
| Maps | Google Maps Flutter |
| Crash Detection | sensors_plus |
| Communication | url_launcher |
| Background | flutter_foreground_task |

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants/       # Emergency numbers, thresholds
│   ├── services/        # Accelerometer, Location, SMS
│   └── theme/           # App theme
├── features/
│   ├── detection/       # Crash detection logic + dialog
│   ├── home/            # Home screen + SOS button
│   ├── map/             # Nearby hospitals map
│   ├── onboarding/      # First time setup
│   ├── profile/         # User + emergency contacts
│   ├── history/         # Past SOS events
│   └── stats/           # India SOS statistics
└── models/              # Data models
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK >= 3.0.0
- Firebase project
- Google Maps API key

### Setup

**1. Clone the repo**
```bash
git clone https://github.com/YOUR_USERNAME/roadsos.git
cd roadsos
```

**2. Install dependencies**
```bash
flutter pub get
```

**3. Firebase setup**
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Install FlutterFire CLI  
dart pub global activate flutterfire_cli

# Configure Firebase (replaces firebase_options.dart)
flutterfire configure
```

**4. Add Google Maps API key**

In `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_KEY"/>
```

**5. Run**
```bash
flutter run
```

---

## 👥 Team

| Name | Role |
|---|---|
| Member 1 | Flutter UI + Detection Logic |
| Member 2 | Firebase + Location + SMS |
| Member 3 | Presentation + Documentation |

---

## 🗂️ Branch Strategy

```
main          → stable, demo-ready code only
dev           → active development
feature/xxx   → individual features
```

**Branch naming:**
- `feature/crash-detection`
- `feature/firebase-setup`
- `feature/map-screen`
- `feature/sos-sms`
- `feature/stats-screen`

---

## 📋 Submission

- **Platform:** Unstop
- **Hackathon:** National Road Safety Hackathon 2026
- **Organizer:** CoERS, IIT Madras
- **Deadline:** May 31, 2026

---

## 📄 License

Built for hackathon purposes. All rights reserved.
