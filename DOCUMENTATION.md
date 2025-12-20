# BEACON Network App - Documentation

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Project Structure](#project-structure)
4. [Key Components](#key-components)
5. [Features](#features)
6. [Technical Stack](#technical-stack)
7. [Data Flow](#data-flow)
8. [Code Organization](#code-organization)
9. [Database Schema](#database-schema)
10. [P2P Communication](#p2p-communication)
11. [State Management](#state-management)
12. [Security](#security)

---

## Overview

**BEACON Network** is a Flutter-based mobile application that enables peer-to-peer (P2P) communication and networking between Android devices without requiring internet connectivity. The app creates local mesh networks using Wi-Fi Direct and Bluetooth Low Energy (BLE) technologies, allowing users to:

- Create or join local networks
- Send private messages between devices
- Broadcast messages to all network members
- Share resources and emergency information
- Manage user profiles with emergency contact details
- View connected devices and their status

The app is designed with emergency situations in mind, providing a reliable communication platform when traditional network infrastructure is unavailable.

---

## Architecture

The app follows a **clean architecture** pattern with clear separation of concerns:

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│    (Screens, Widgets, Routes)           │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│         Business Logic Layer            │
│    (Cubits/State Management)            │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│         Data Layer                      │
│    (Models, Database, Services)          │
└─────────────────────────────────────────┘
```

### Architecture Layers:

1. **Presentation Layer** (`lib/presentation/`)
   - UI screens and widgets
   - Navigation and routing
   - User interactions

2. **Business Logic Layer** (`lib/business/`)
   - State management using BLoC/Cubit pattern
   - Business rules and logic
   - Event handling

3. **Data Layer** (`lib/data/`)
   - Data models
   - Database operations
   - Local storage

4. **Core Services** (`lib/core/`)
   - P2P communication service
   - Encryption service
   - Notification service
   - Device ID service

---

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── business/                          # Business logic layer
│   └── cubit/                         # State management
│       ├── create_network/            # Network creation logic
│       ├── network_dashboard/         # Dashboard state management
│       ├── network_discovery/         # Network discovery logic
│       ├── private_chat/              # Private messaging logic
│       └── profile/                   # User profile management
├── core/                              # Core services and constants
│   ├── constants/
│   │   └── colors.dart                # App color scheme
│   └── services/
│       ├── p2p_service.dart            # P2P communication service
│       ├── encryption_service.dart    # Data encryption
│       ├── notfication_service.dart   # Push notifications
│       └── device_id_service.dart     # Device identification
├── data/                              # Data layer
│   ├── local/
│   │   └── database_helper.dart       # SQLite database operations
│   └── models/                        # Data models
│       ├── device_detail_model.dart
│       ├── device_model.dart
│       ├── message_model.dart
│       ├── user_profile_model.dart
│       ├── resources.dart
│       └── resource_request.dart
└── presentation/                      # UI layer
    ├── routes/
    │   └── app_routes.dart            # Navigation routes
    ├── screens/                       # App screens
    │   ├── splash_screen.dart
    │   ├── landing_screen.dart
    │   ├── create_network_screen.dart
    │   ├── network_dashboard_screen.dart
    │   ├── private_chat_screen.dart
    │   ├── profile_screen.dart
    │   └── resource_sharing_screen.dart
    └── widgets/                       # Reusable UI components
        ├── device_card.dart
        ├── voice_widget.dart
        ├── broadcast_dialog.dart
        └── ...
```

---

## Key Components

### 1. P2PService (`lib/core/services/p2p_service.dart`)

The core service managing all P2P communication. It handles:

- **Server Mode (Host)**: Creates and manages a network group
- **Client Mode**: Discovers and connects to existing networks
- **Message Routing**: Sends/receives broadcast and private messages
- **Member Management**: Tracks connected devices
- **Profile Broadcasting**: Shares user profiles across the network

**Key Methods:**
- `initializeServer()`: Sets up host mode
- `initializeClient()`: Sets up client mode
- `createNetwork()`: Creates a new P2P group
- `startDiscovery()`: Scans for available networks
- `connectToServer()`: Connects to a discovered network
- `sendBroadcast()`: Sends message to all members
- `sendPrivate()`: Sends message to specific device
- `disconnect()`: Cleans up connections

### 2. DatabaseHelper (`lib/data/local/database_helper.dart`)

Manages local SQLite database with SQLCipher encryption. Stores:

- User profiles
- Messages (private and broadcast)
- Network information
- Device details
- Resource sharing data

**Key Features:**
- Encrypted database using SQLCipher
- Foreign key relationships
- WAL (Write-Ahead Logging) mode for performance
- Singleton pattern for database access

### 3. State Management (Cubits)

The app uses **BLoC/Cubit** pattern for state management:

- **PrivateChatCubit**: Manages private chat state and messages
- **NetworkDashboardCubit**: Manages network dashboard state
- **CreateNetworkCubit**: Handles network creation flow
- **NetworkDiscoveryCubit**: Manages network discovery
- **UserProfileCubit**: Manages user profile state

### 4. Main App (`lib/main.dart`)

Application entry point that:
- Initializes notification service
- Sets up MaterialApp with dark theme
- Configures navigation routes
- Provides P2PService instance to screens
- Sets up BLoC providers for state management

---

## Features

### 1. Network Management
- **Create Network**: Host creates a new P2P network with configurable member limit
- **Join Network**: Client scans and connects to available networks
- **Network Dashboard**: View all connected devices, their status, and network info
- **Network Settings**: Host can configure network settings and stop the network

### 2. Messaging
- **Private Messages**: One-to-one encrypted messaging between devices
- **Broadcast Messages**: Send messages to all network members
- **Quick Messages**: Predefined emergency messages for quick communication
- **Message History**: Persistent message storage in encrypted database

### 3. User Profiles
- **Profile Management**: Create and edit user profiles
- **Emergency Information**: Store blood type, emergency contacts, medical info
- **Profile Sharing**: Automatically share profiles with network members
- **Avatar System**: Color-coded avatars for easy identification

### 4. Resource Sharing
- **Resource Offers**: Share resources (food, water, medical supplies, etc.)
- **Resource Requests**: Request resources from network members
- **Resource Management**: Track available resources in the network

### 5. Device Management
- **Device Discovery**: Real-time discovery of nearby devices
- **Status Tracking**: Monitor device connection status (Active/Inactive)
- **Signal Strength**: Display connection quality
- **Kick Users**: Host can remove devices from network

### 6. Voice Features
- **Voice Widget**: Voice input/output capabilities (using speech_to_text and flutter_tts)

---

## Technical Stack

### Core Technologies
- **Flutter**: Cross-platform mobile framework (Dart SDK ^3.8.1)
- **BLoC/Cubit**: State management (`flutter_bloc: ^9.1.1`)
- **SQLite**: Local database (`sqflite_sqlcipher: ^3.4.0`)
- **P2P Communication**: `flutter_p2p_connection: ^3.0.3`

### Key Dependencies
- `flutter_local_notifications`: Push notifications
- `flutter_secure_storage`: Secure credential storage
- `permission_handler`: Runtime permissions
- `speech_to_text`: Voice input
- `flutter_tts`: Text-to-speech
- `google_fonts`: Custom typography

### Platform Support
- Android (primary platform)
- iOS (configured but may need additional setup)
- Windows, Linux, macOS (basic support)

---

## Data Flow

### Creating a Network
```
User → CreateNetworkScreen → CreateNetworkCubit → P2PService.initializeServer()
                                                      ↓
                                              P2PService.createNetwork()
                                                      ↓
                                              NetworkDashboardScreen
```

### Joining a Network
```
User → NetworkDiscoveryScreen → NetworkDiscoveryCubit → P2PService.startDiscovery()
                                                              ↓
                                                      P2PService.connectToServer()
                                                              ↓
                                                      NetworkDashboardScreen
```

### Sending a Message
```
User Input → PrivateChatScreen → PrivateChatCubit.sendMessage()
                                        ↓
                                DatabaseHelper.saveMessage()
                                        ↓
                                P2PService.sendPrivate()
                                        ↓
                                Recipient receives via P2PService.messagesStream
                                        ↓
                                PrivateChatCubit receives and updates state
```

### Profile Broadcasting
```
User Profile Update → ProfileCubit → DatabaseHelper.saveUserProfile()
                                              ↓
                                      P2PService.broadcastProfile()
                                              ↓
                                      All network members receive profile
                                              ↓
                                      DatabaseHelper.saveUserProfile() (on each device)
```

---

## Code Organization

### State Management Pattern

Each feature has its own Cubit and State:

```dart
// Example: PrivateChatCubit
class PrivateChatCubit extends Cubit<PrivateChatState> {
  final P2PService p2pService;
  
  // Methods that emit new states
  Future<void> sendMessage(String text) async {
    // Business logic
    emit(state.copyWith(messages: updatedMessages));
  }
}
```

### Service Pattern

Services are singleton-like and provide functionality:

```dart
// P2PService usage
final p2pService = P2PService();
await p2pService.initializeServer(userProfile);
await p2pService.createNetwork(name: "MyNetwork", max: 10);
```

### Model Pattern

Data models are immutable and use copyWith for updates:

```dart
class Message {
  final String text;
  final bool isMine;
  final TimeOfDay time;
  final bool isDelivered;
  
  Message copyWith({...}) {
    // Returns new instance with updated fields
  }
}
```

---

## Database Schema

The app uses SQLite with SQLCipher encryption. Key tables:

### Networks Table
```sql
CREATE TABLE Networks (
  network_id INTEGER PRIMARY KEY AUTOINCREMENT,
  network_name TEXT NOT NULL,
  host_device_id TEXT,
  status TEXT NOT NULL DEFAULT 'Active',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)
```

### Devices Table
```sql
CREATE TABLE Devices (
  device_id TEXT PRIMARY KEY,
  network_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  status TEXT NOT NULL,
  unread INTEGER DEFAULT 0,
  signal_strength INTEGER,
  avatar TEXT,
  color TEXT,
  ip_address TEXT,
  last_seen_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  is_host INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY(network_id) REFERENCES Networks(network_id) ON DELETE CASCADE
)
```

### Messages Table
```sql
CREATE TABLE Messages (
  message_id INTEGER PRIMARY KEY AUTOINCREMENT,
  sender_device_id TEXT NOT NULL,
  receiver_device_id TEXT NOT NULL,
  text TEXT NOT NULL,
  is_mine INTEGER NOT NULL DEFAULT 0,
  is_delivered INTEGER NOT NULL DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  network_id INTEGER,
  FOREIGN KEY(network_id) REFERENCES Networks(network_id) ON DELETE CASCADE
)
```

### Users Table
```sql
CREATE TABLE Users (
  device_id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  address TEXT,
  blood_type TEXT,
  emergency_contact TEXT,
  avatar TEXT,
  color TEXT,
  status TEXT DEFAULT 'Idle',
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
)
```

---

## P2P Communication

### Protocol

The app uses JSON-based message protocol:

```json
{
  "type": "broadcast|private|profile|kick|p2p_id_assign",
  "from": "sender_p2p_id",
  "to": "receiver_p2p_id|ALL",
  "message": "message content",
  "senderName": "sender name"
}
```

### Message Types

1. **broadcast**: Message sent to all network members
2. **private**: One-to-one message
3. **profile**: User profile data
4. **kick**: Remove user from network
5. **p2p_id_assign**: Assign P2P ID to device
6. **resource**: Resource sharing data
7. **inactive_notify**: Device inactive notification
8. **active_notify**: Device active notification

### Connection Flow

**Host Side:**
1. Initialize FlutterP2pHost
2. Create group with advertising enabled
3. Listen for client connections
4. Assign P2P IDs to connected clients
5. Broadcast host profile

**Client Side:**
1. Initialize FlutterP2pClient
2. Start scanning for networks
3. Connect to discovered host
4. Receive P2P ID assignment
5. Broadcast own profile

---

## State Management

### BLoC/Cubit Pattern

The app uses Cubit (simpler version of BLoC) for state management:

**State Classes:**
- Immutable state classes extending base state
- `copyWith()` method for state updates
- Clear state transitions

**Cubit Classes:**
- Business logic in Cubit methods
- Emit new states using `emit()`
- Stream subscriptions for reactive updates

**Example Flow:**
```dart
// State
class PrivateChatState {
  final List<Message> messages;
  final bool isLoading;
  // ...
}

// Cubit
class PrivateChatCubit extends Cubit<PrivateChatState> {
  Future<void> sendMessage(String text) async {
    // 1. Create message
    // 2. Save to database
    // 3. Send via P2P
    // 4. Update state
    emit(state.copyWith(messages: updatedMessages));
  }
}
```

---

## Security

### Data Encryption
- **SQLCipher**: Database encrypted at rest
- **Encryption Key**: Stored securely using `flutter_secure_storage`
- **Key Generation**: Unique encryption key per device

### Permissions
The app requires several permissions:
- **Storage**: For database access
- **Bluetooth**: For P2P discovery
- **Wi-Fi**: For Wi-Fi Direct
- **Location**: Required for BLE scanning (Android requirement)

### Secure Storage
- Device IDs stored securely
- Encryption keys protected
- User credentials secured

---

## Navigation Flow

```
SplashScreen
    ↓
LandingScreen
    ├──→ CreateNetworkScreen → NetworkDashboardScreen
    ├──→ NetworkDiscoveryScreen → NetworkDashboardScreen
    └──→ ProfileScreen

NetworkDashboardScreen
    ├──→ PrivateChatScreen
    ├──→ NetworkProfileScreen (peer profiles)
    └──→ NetworkSettingsScreen (host only)

PrivateChatScreen
    └──→ ProfileScreen (peer profile)
```

---

## Key Implementation Details

### 1. P2P ID Mapping
- Each device has a P2P ID (assigned by host) and an App Device ID
- Host assigns P2P IDs to clients for routing
- Mapping maintained for message routing

### 2. Member Synchronization
- Members list synced from P2P client list
- Real-time updates via streams
- Host manages member list and assignments

### 3. Message Persistence
- All messages saved to encrypted database
- Message history loaded on chat screen open
- Messages linked to network and device IDs

### 4. Profile Management
- Profiles stored locally and synced across network
- Profile updates broadcast to all members
- Emergency information prominently displayed

### 5. Network Lifecycle
- Host controls network lifecycle
- Clients can leave but cannot stop network
- Graceful disconnection handling

---

## Development Notes

### Testing
- Unit tests for business logic (using `bloc_test`)
- Integration tests for critical flows
- Mock services for testing

### Error Handling
- Try-catch blocks around critical operations
- User-friendly error messages
- Graceful degradation on failures

### Performance
- Database WAL mode for better concurrency
- Stream-based updates for real-time UI
- Efficient list rendering with ListView.builder

### Future Enhancements
- File sharing capabilities
- Location sharing
- Enhanced resource management
- Network statistics and analytics
- Offline map integration

---

## Getting Started

### Prerequisites
- Flutter SDK ^3.8.1
- Android Studio / VS Code
- Android device with Wi-Fi Direct and BLE support

### Setup
1. Clone the repository
2. Run `flutter pub get`
3. Configure Android permissions in `android/app/src/main/AndroidManifest.xml`
4. Run `flutter run` on connected device

### Building
- **Debug**: `flutter build apk --debug`
- **Release**: `flutter build apk --release`

---

## Troubleshooting

### Common Issues

1. **P2P Connection Fails**
   - Ensure Wi-Fi Direct and Bluetooth are enabled
   - Check location permissions
   - Verify devices are in range

2. **Database Errors**
   - Clear app data and restart
   - Check encryption key storage

3. **Message Delivery Issues**
   - Verify network connection
   - Check device P2P ID assignment
   - Review message routing logic

---

## License

This project is a Flutter application for educational/demonstration purposes.

---

## Contact & Support

For issues, questions, or contributions, please refer to the project repository.

---

*Last Updated: December 2024*

