# BEACON - Offline Emergency Communication Network
<img width="114" height="263" alt="Screenshot 2026-02-01 at 1 27 08 AM" src="https://github.com/user-attachments/assets/508ef858-034c-4f3b-8723-d8eb14d3cfda" /><img width="121" height="264" alt="Screenshot 2026-02-01 at 1 27 10 AM" src="https://github.com/user-attachments/assets/cd1b05f4-7cc7-4fc8-bf8f-867db6737429" /> <img width="121" height="263" alt="Screenshot 2026-02-01 at 1 27 26 AM" src="https://github.com/user-attachments/assets/5b97c94d-669e-40b6-9749-15916dda9efa" />
<img width="117" height="254" alt="Screenshot 2026-02-01 at 1 27 35 AM" src="https://github.com/user-attachments/assets/0499b4ab-ed9e-48a5-8b91-ba505cdcc9a5" />
<img width="124" height="261" alt="Screenshot 2026-02-01 at 1 27 41 AM" src="https://github.com/user-attachments/assets/bcbd0e0f-1831-4f74-b5d3-a11f1d7b145a" />

<img width="117" height="264" alt="Screenshot 2026-02-01 at 1 27 48 AM" src="https://github.com/user-attachments/assets/e5fd7c81-6363-43fc-bbd6-fe6b5a4fde33" />
<img width="347" height="262" alt="Screenshot 2026-02-01 at 1 28 12 AM" src="https://github.com/user-attachments/assets/494e808d-a5a9-4c62-8bbb-6a82d3b09d48" />

**BEACON** is a peer-to-peer (P2P) offline emergency communication network built with Flutter. It enables users to create and join local networks, exchange messages, share resources, and coordinate during emergencies—all without requiring internet connectivity.

---

## 📋 Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Technology Stack](#technology-stack)
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [Key Components](#key-components)
- [Database Schema](#database-schema)
- [Security](#security)
- [Voice Control](#voice-control)
- [Testing](#testing)

---

## ✨ Features

### 🌐 Network Management
- **Create Network**: Host a local P2P network with configurable settings
- **Join Network**: Discover and connect to nearby networks via Bluetooth/WiFi Direct
- **Network Dashboard**: Real-time view of connected devices and network status
- **Host Controls**: Kick users, manage connections, and configure network settings

### 💬 Communication
- **Private Chat**: One-to-one encrypted messaging between devices
- **Broadcast Messages**: Send announcements to all network members
- **Quick Send**: Pre-defined emergency messages for rapid communication
- **Message Persistence**: Chat history stored locally in encrypted database

### 🤝 Resource Sharing
- **Offer Resources**: Share medical supplies, amenities, clothing, etc.
- **Request Resources**: Send requests to resource providers
- **Category-Based Organization**: Filter resources by type
- **Real-time Updates**: P2P synchronization of resource availability

### 👤 User Profiles
- **Emergency Information**: Name, phone, email, address, blood type
- **Emergency Contact**: Designated contact information
- **Profile Broadcasting**: Share profile data across the network
- **Avatar Customization**: Personalized user identification

### 🎤 Voice Control
- **Hands-Free Navigation**: Voice commands to navigate the app
- **Voice Messaging**: Send messages using voice input
- **Text-to-Speech Feedback**: Audio confirmations and responses
- **Continuous Listening**: Active voice session mode

### 🔒 Security & Privacy
- **AES-256 Encryption**: SQLCipher-encrypted local database
- **Secure Storage**: Encryption keys stored in platform keychain
- **Device ID Persistence**: Unique, secure device identification
- **Local-Only Processing**: No cloud dependencies

---

## 🏗️ Architecture

BEACON follows **Clean Architecture** principles with a clear separation of concerns:

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  (Screens, Widgets, UI Components)      │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│         Business Logic Layer            │
│     (Cubits, State Management)          │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│           Data Layer                    │
│  (Models, Database, Services)           │
└─────────────────────────────────────────┘
```

### Design Patterns
- **BLoC Pattern**: State management using flutter_bloc
- **Repository Pattern**: Data access abstraction
- **Singleton Pattern**: Database and service instances
- **Observer Pattern**: Real-time P2P communication streams

---

## 🛠️ Technology Stack

### Core Framework
- **Flutter 3.8.1**: Cross-platform UI framework
- **Dart**: Programming language

### State Management
- **flutter_bloc 9.1.1**: Reactive state management
- **bloc 9.1.0**: Core BLoC library

### Networking & P2P
- **flutter_p2p_connection 3.0.3**: Bluetooth/WiFi Direct P2P communication

### Database & Storage
- **sqflite_sqlcipher 3.4.0**: Encrypted SQLite database
- **flutter_secure_storage 9.0.0**: Secure key storage

### Voice Features
- **speech_to_text 7.3.0**: Voice recognition
- **flutter_tts 4.2.3**: Text-to-speech synthesis

### Utilities
- **permission_handler 11.3.1**: Runtime permissions
- **flutter_local_notifications 19.5.0**: Local notifications
- **uuid**: Unique identifier generation
- **path 1.8.4**: File path manipulation

### Testing
- **flutter_test**: Unit and widget testing
- **bloc_test 10.0.0**: BLoC testing utilities
- **mocktail 1.0.4**: Mocking framework
- **integration_test**: End-to-end testing

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.8.1 or higher
- Dart SDK 3.8.1 or higher
- Android Studio / Xcode for platform-specific builds
- Physical device (P2P features require Bluetooth/WiFi)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd projectdemo
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Platform-Specific Setup

#### Android
Add the following permissions to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.NEARBY_WIFI_DEVICES" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

#### iOS
Add the following to `ios/Runner/Info.plist`:
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>BEACON needs Bluetooth to connect with nearby devices</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>BEACON needs location access for P2P connectivity</string>
<key>NSMicrophoneUsageDescription</key>
<string>BEACON needs microphone access for voice commands</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>BEACON uses speech recognition for voice control</string>
```

---

## 📁 Project Structure

```
lib/
├── business/                 # Business logic layer
│   └── cubit/               # State management (BLoC)
│       ├── create_network/
│       ├── network_dashboard/
│       ├── network_discovery/
│       ├── private_chat/
│       └── profile/
├── core/                    # Core utilities
│   ├── constants/          # App-wide constants
│   └── services/           # Core services
│       ├── device_id_service.dart
│       ├── encryption_service.dart
│       ├── notification_service.dart
│       └── p2p_service.dart
├── data/                   # Data layer
│   ├── local/             # Local data sources
│   │   └── database_helper.dart
│   └── models/            # Data models
│       ├── device_detail_model.dart
│       ├── message_model.dart
│       ├── resources.dart
│       └── user_profile_model.dart
├── presentation/          # Presentation layer
│   ├── routes/           # App routing
│   ├── screens/          # UI screens
│   │   ├── create_network_screen.dart
│   │   ├── join_networks_screen.dart
│   │   ├── network_dashboard_screen.dart
│   │   ├── private_chat_screen.dart
│   │   ├── profile_screen.dart
│   │   └── resource_sharing_screen.dart
│   └── widgets/          # Reusable UI components
└── main.dart             # App entry point
```

---

## 🔑 Key Components

### P2P Service (`p2p_service.dart`)
The core networking component handling:
- Network creation and discovery
- Device connection management
- Message routing (broadcast/private)
- Profile synchronization
- Resource sharing

**Key Methods:**
- `initializeServer()` - Set up as network host
- `initializeClient()` - Set up as network client
- `createNetwork()` - Create P2P group
- `connectToServer()` - Join existing network
- `sendBroadcast()` / `sendPrivate()` - Message transmission
- `kickUser()` / `leaveNetwork()` - Connection management

### Database Helper (`database_helper.dart`)
Manages encrypted local storage:
- Networks, devices, users, messages, resources
- Encrypted with AES-256 (SQLCipher)
- Automatic schema migrations
- Foreign key constraints for data integrity

**Key Tables:**
- `Networks` - Network metadata
- `Devices` - Connected device information
- `Users` - User profiles
- `Messages` - Chat history
- `Resources` - Shared resource inventory

### Cubits (State Management)
- **CreateNetworkCubit**: Network creation workflow
- **NetworkDashboardCubit**: Active network state
- **NetworkCubit**: Network discovery
- **PrivateChatCubit**: Private messaging
- **ProfileCubit**: User profile management

---

## 🗃️ Database Schema

```sql
Networks
├── network_id (PK)
├── network_name
├── host_device_id (FK → Devices)
├── status
└── created_at

Devices
├── device_id (PK)
├── network_id (FK → Networks)
├── name
├── status
├── signal_strength
├── avatar
├── color
├── last_seen_at
└── is_host

Users
├── user_id (PK)
├── username
├── email
├── phone
├── address
├── blood_type
├── emergency_contact
└── device_id (FK → Devices)

Messages
├── message_id (PK)
├── network_id (FK → Networks)
├── sender_device_id (FK → Devices)
├── receiver_device_id (FK → Devices)
├── message_content
├── is_mine
├── is_delivered
└── sent_at

Resources
├── resource_id (PK)
├── network_id (FK → Networks)
├── device_id (FK → Devices)
├── resource_type
├── description
├── quantity
├── status
└── created_at
```

---

## 🔐 Security

### Encryption
- **Database**: AES-256 encryption via SQLCipher
- **Key Storage**: Platform-specific secure storage (Keychain/Keystore)
- **Device ID**: Securely generated and persisted

### Privacy
- **No Cloud**: All data remains on device
- **No Tracking**: No analytics or external services
- **Local Processing**: All AI/ML features run on-device

### Best Practices
- Encryption keys never leave secure storage
- Database password derived from secure random generation
- Foreign key cascades prevent orphaned data
- Input validation on all user data

---

## 🎙️ Voice Control

### Supported Commands

**Navigation:**
- "Go home" / "Home"
- "Create network"
- "Join network"
- "Profile"
- "Resources"

**Communication:**
- "Broadcast [message]"
- "Send [message]" (in private chat)
- "Leave network"

**Session Control:**
- "Stop listening"

### Voice Flow
1. Tap microphone button to start session
2. Speak command
3. Receive audio feedback
4. Automatic re-listening until "Stop listening"

---

## 🧪 Testing

### Run Unit Tests
```bash
flutter test
```

### Run Integration Tests
```bash
flutter test integration_test/
```

### Test Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---
