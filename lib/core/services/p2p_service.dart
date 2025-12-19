import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';

import 'package:projectdemo/data/models/device_detail_model.dart';
import 'package:projectdemo/data/models/user_profile_model.dart';
import 'package:projectdemo/data/models/message_model.dart';

class P2PService {
  FlutterP2pHost? _host;
  FlutterP2pClient? _client;

  bool isHost = false;
  UserProfile? currentUser;
  int? _maxMembers;
  bool isScanning = false;

  // Discovered devices
  final _discoveryController =
      StreamController<List<BleDiscoveredDevice>>.broadcast();
  Stream<List<BleDiscoveredDevice>> get discoveryStream =>
      _discoveryController.stream;

  // Members in the network
  final List<DeviceDetail> _members = [];
  final _membersController = StreamController<List<DeviceDetail>>.broadcast();
  Stream<List<DeviceDetail>> get membersStream => _membersController.stream;
  List<DeviceDetail> get members => List.unmodifiable(_members);

  // Chat messages
  final _messagesController = StreamController<Message>.broadcast();
  Stream<Message> get messagesStream => _messagesController.stream;

  // ---------------- SERVER METHODS ------------------

  Future<void> initializeServer(UserProfile me) async {
    try {
      isHost = true;
      currentUser = me;

      _host = FlutterP2pHost();

      await _host!.initialize();

      await _checkPermissions(_host!);

      _host!.streamReceivedTexts().listen(_handleIncomingPacket);

      _host!.streamClientList().listen((clients) {
        _syncMembersFromClientList(clients);
      });
    } catch (e) {
      debugPrint("❌ Failed to initialize server at some step: $e");
      rethrow;
    }
  }

  Future<void> createNetwork({required String name, required int max}) async {
    //todo name?
    try {
      _maxMembers = max;

      // Create P2P group
      await _host!.createGroup(advertise: true);
    } catch (e) {
      debugPrint("Failed to create network: $e");
      rethrow;
    }
  }

  /// Current maximum members allowed in this network (host side only).
  int? get maxMembers => _maxMembers;

  /// Update the maximum allowed members at runtime (host only).
  /// This does not re-negotiate any underlying OS limits, it is an
  /// app‑level guard enforced in `_syncMembersFromClientList`.
  void updateMaxMembers(int newMax) {
    if (newMax <= 0) return;
    _maxMembers = newMax;
  }

  Future<void> stopNetwork() async {
    try {
      if (isHost) {
        // Graceful shutdown: Notify all clients
        for (final member in _members) {
          if (member.deviceId != currentUser?.deviceId) {
            kickUser(member.deviceId);
          }
        }
        // Give time for kick messages to be sent
        await Future.delayed(const Duration(milliseconds: 200));

        await _host?.removeGroup();
      }
    } catch (e) {
      debugPrint("Error stopping network group: $e");
    } finally {
      disconnect();
    }
  }

  // ---------------- CLIENT METHODS ------------------

  Future<void> initializeClient(UserProfile me) async {
    isHost = false;
    currentUser = me;

    // Initialize P2P client
    _client = FlutterP2pClient();
    await _client!.initialize();
    await _checkPermissions(_client!);

    // Listen for incoming packets
    _client!.streamReceivedTexts().listen(_handleIncomingPacket);
  }

  Future<void> startDiscovery() async {
    if (_client == null) return;
    if (isScanning) return;

    isScanning = true;

    await _client!.startScan((List<BleDiscoveredDevice> devices) {
      _discoveryController.add(List.from(devices));
    });
  }

  Future<void> stopDiscovery() async {
    if (!isScanning) return;
    isScanning = false;

    await _client?.stopScan();
    _discoveryController.add([]);
  }

  Future<void> connectToServer(BleDiscoveredDevice device) async {
    // Stop scanning before connecting
    await _client!.stopScan();

    _client!.connectWithDevice(device);
    // Debounce state
    int lastClientCount = -1;

    // Listen to client list changes (automatic member management)
    _client!.streamClientList().listen((clients) {
      // Debounce: verify if count actually changed
      if (clients.length == lastClientCount) return; //todo
      lastClientCount = clients.length;

      _syncMembersFromClientList(clients);
    });

    // Wait for connection to be established (members list updated)
    try {
      await membersStream
          .firstWhere((members) => members.isNotEmpty)
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      disconnect();
      throw Exception('Connection timed out');
    }
  }

  Future<void> leaveNetwork() async {
    if (!isHost) {
      disconnect();
    }
  }

  // ---------------- PERMISSIONS ------------------

  Future<void> _checkPermissions(dynamic p) async {
    if (!await p.checkStoragePermission()) {
      await p.askStoragePermission();
    }
    if (!await p.checkP2pPermissions()) {
      await p.askP2pPermissions();
    }
    if (!await p.checkBluetoothPermissions()) {
      await p.askBluetoothPermissions();
    }
    if (!await p.checkWifiEnabled()) {
      await p.enableWifiServices();
    }
    if (!await p.checkLocationEnabled()) {
      await p.enableLocationServices();
    }
    if (!await p.checkBluetoothEnabled()) {
      await p.enableBluetoothServices();
    }
  }

  // ---------------- HIGH-LEVEL SEND API ------------------

  void sendBroadcast(String text) {
    final String fromId = _myP2pId ?? currentUser!.deviceId;
    final Map<String, dynamic> pkt = {
      "type": "broadcast",
      "from": fromId,
      "fromAppId": currentUser!.deviceId, // Add app UUID for reverse lookup
      "to": "ALL",
      "message": text,
      "senderName": currentUser!.name,
    };
    _sendToAll(pkt);
  }

  void sendPrivate(String receiverId, String text) {
    final String fromId = _myP2pId ?? currentUser!.deviceId;
    final Map<String, dynamic> pkt = {
      "type": "private",
      "from": fromId,
      "fromAppId": currentUser!.deviceId, // Add app UUID for reverse lookup
      "to": receiverId,
      "message": text,
      "senderName": currentUser!.name,
    };
    _sendToOne(receiverId, pkt);
  }

  void kickUser(String userId) {
    _sendToOne(userId, {
      "type": "kick",
      "from": currentUser!.deviceId,
      "to": userId,
      "message": "removed by server",
    });
  }

  // ---------------- LOW-LEVEL SEND HELPERS ------------------

  void _sendToAll(Map pkt) {
    final json = jsonEncode(pkt);

    if (isHost) {
      _host?.broadcastText(json);
    } else {
      _client?.broadcastText(json);
    }
  }

  void _sendToOne(String clientId, Map pkt) {
    final json = jsonEncode(pkt);

    if (isHost) {
      _host?.sendTextToClient(json, clientId);
    } else {
      _client?.sendTextToClient(json, clientId);
    }
  }

  // ---------------- RECEIVING PACKETS ------------------

  Future<void> _handleIncomingPacket(String raw) async {
    try {
      Map<String, dynamic> data = jsonDecode(raw);

      // Extract sender's P2P ID and app UUID
      final String? senderP2pId = data["from"]?.toString();
      final String? senderAppId = data["fromAppId"]?.toString();

      // Update mapping if both IDs are present
      if (senderP2pId != null && senderAppId != null) {
        _p2pIdToAppId[senderP2pId] = senderAppId;
        _appIdToP2pId[senderAppId] = senderP2pId;
      }

      switch (data["type"]) {
        case "broadcast":
          _messagesController.add(
            Message(
              text: data["message"],
              isMine: false,
              time: TimeOfDay.now(),
              isDelivered: true,
              senderDeviceId: senderP2pId, // Use P2P ID for consistency
            ),
          );
          break;

        case "private":
          _messagesController.add(
            Message(
              text: data["message"],
              isMine: false,
              time: TimeOfDay.now(),
              isDelivered: true,
              senderDeviceId: senderP2pId, // Use P2P ID for consistency
            ),
          );
          break;

        case "kick":
          disconnect();
          break;

        case "network_full":
          if (!isHost) {
            // todo: Handle network full - maybe show error to user
            debugPrint("Cannot join: ${data["message"]}");
            disconnect();
          }
          break;
      }
    } catch (e) {
      debugPrint("Error handling incoming packet: $e");
    }
  }

  // ---------------- MEMBERS MANAGEMENT ------------------

  // Current device's P2P ID (from the P2P library)
  String? _myP2pId;
  String? get myP2pId => _myP2pId;

  // Mapping between P2P library IDs and app UUIDs
  final Map<String, String> _p2pIdToAppId = {}; // p2pId -> appUuid
  final Map<String, String> _appIdToP2pId = {}; // appUuid -> p2pId

  /// Get the P2P library ID for a given app UUID
  String? getP2pIdForAppId(String appId) => _appIdToP2pId[appId];

  /// Get the app UUID for a given P2P library ID
  String? getAppIdForP2pId(String p2pId) => _p2pIdToAppId[p2pId];

  void _syncMembersFromClientList(List<P2pClientInfo> clients) {
    // Check if network is full (server only, and only when a limit is set)
    final max = _maxMembers;
    if (isHost && max != null && clients.length > max) {
      // todo: Send network full message to clients trying to join
      return;
    }

    _members.clear();

    // Find current device's P2P ID in the client list
    for (var client in clients) {
      if ((isHost && client.isHost) ||
          (!isHost && client.username == currentUser?.name)) {
        _myP2pId = client.id;
        // Map our own IDs
        if (currentUser != null) {
          _p2pIdToAppId[client.id] = currentUser!.deviceId;
          _appIdToP2pId[currentUser!.deviceId] = client.id;
        }
      }

      _members.add(
        DeviceDetail(
          name: client.username,
          deviceId: client.id, // Use P2P ID as the primary ID in members list
          status: "Active",
          unread: 0,
          signalStrength: 100,
          distance: '--',
          avatar: client.username.isNotEmpty ? client.username[0] : '?',
          color: client.isHost ? Colors.blue : Colors.green,
        ),
      );
    }

    _membersController.add(List.unmodifiable(_members));
  }

  // ---------------- DISCONNECT ------------------

  void disconnect() {
    isHost = false;
    currentUser = null;
    _maxMembers = null;
    isScanning = false;

    _members.clear();
    _membersController.add(List.unmodifiable(_members));

    _discoveryController.add([]);

    // Clear ID mappings
    _p2pIdToAppId.clear();
    _appIdToP2pId.clear();
    _myP2pId = null;

    _host?.dispose();
    _client?.dispose();

    _host = null;
    _client = null;
  }

  // ---------------- DEBUG/TEST METHODS ------------------

  /// Add a mock device for testing (debug only)
  void addMockDevice({
    String? name,
    String? deviceId,
    String status = 'Active',
    int signalStrength = 85,
    String distance = '5m',
  }) {
    final mockDevice = DeviceDetail(
      name: name ?? 'Mock Device',
      deviceId: deviceId ??
          'mock-device-${DateTime.now().millisecondsSinceEpoch}',
      status: status,
      unread: 0,
      signalStrength: signalStrength,
      distance: distance,
      avatar: (name ?? 'M')[0].toUpperCase(),
      color: Colors.purple,
    );

    // Add to members list
    _members.add(mockDevice);

    // Emit updated list to trigger cubit updates
    _membersController.add(List.unmodifiable(_members));

    debugPrint('✅ Mock device added: ${mockDevice.name} (${mockDevice.deviceId})');
  }

  /// Remove a mock device (debug only)
  void removeMockDevice(String deviceId) {
    final initialLength = _members.length;
    _members.removeWhere((d) => d.deviceId == deviceId);
    final removed = initialLength - _members.length;
    
    if (removed > 0) {
      _membersController.add(List.unmodifiable(_members));
      debugPrint('🗑️ Mock device removed: $deviceId');
    } else {
      debugPrint('❌ Mock device not found: $deviceId');
    }
  }

  /// Update mock device properties to test conditional emit (debug only)
  void updateMockDeviceProperty({
    required String deviceId,
    String? name,
    String? status,
    int? signalStrength,
    String? distance,
  }) {
    final index = _members.indexWhere((d) => d.deviceId == deviceId);
    if (index == -1) {
      debugPrint('❌ Mock device not found: $deviceId');
      return;
    }

    final current = _members[index];
    _members[index] = DeviceDetail(
      name: name ?? current.name,
      deviceId: current.deviceId,
      status: status ?? current.status,
      unread: current.unread,
      signalStrength: signalStrength ?? current.signalStrength,
      distance: distance ?? current.distance,
      avatar: current.avatar,
      color: current.color,
    );

    _membersController.add(List.unmodifiable(_members));
    debugPrint('🔄 Mock device updated: $deviceId');
  }

  // ---------------- DISPOSE ------------------
  void dispose() {
    // Close all controllers when app is shutting down
    if (!_discoveryController.isClosed) _discoveryController.close();
    if (!_membersController.isClosed) _membersController.close();
    if (!_messagesController.isClosed) _messagesController.close();

    _host?.dispose();
    _client?.dispose();
  }
}
