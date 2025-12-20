import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';

import 'package:projectdemo/data/models/device_detail_model.dart';
import 'package:projectdemo/data/models/user_profile_model.dart';
import 'package:projectdemo/data/models/message_model.dart';
import 'package:projectdemo/data/local/database_helper.dart';

class P2PService {
  FlutterP2pHost? _host;
  FlutterP2pClient? _client;

  String? _myP2pId;
  String? get myP2pId => _myP2pId;

  bool isHost = false;
  UserProfile? currentUser;
  bool isScanning = false;
  bool newNetwork = true;

  int? _maxMembers;
  int? get maxMembers => _maxMembers;
  String? _netwrokName; //todo
  String? get networkName => null; //todo

  int lastClientCount = -1;
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
        if (clients.length == lastClientCount) return;

        lastClientCount = clients.length;
        _syncMembersFromClientList(clients);

        //todo
        // // Broadcast profile when new members join so they know who Host is
        // if (clients.length > lastClientCount) {
        //   // Future.delayed(
        //   //   const Duration(milliseconds: 500),
        //   //   broadcastHandshake,
        //   // ); // Fast handshake first
        //   // Future.delayed(const Duration(seconds: 1), broadcastProfile);
        // }
      });
    } catch (e) {
      debugPrint("❌ Failed to initialize server at some step: $e");
      rethrow;
    }
  }

  Future<void> createNetwork({required String name, required int max}) async {
    //todo name?
    try {
      _maxMembers = max; //todo netwrok name

      // Create P2P group
      await _host!.createGroup(advertise: true);
      _myP2pId = "HOST";
      _registerHostAsMember();
    } catch (e) {
      debugPrint("Failed to create network: $e");
      rethrow;
    }
  }

  void updateMaxMembers(int newMax) {
    if (newMax <= 0) return;
    _maxMembers = newMax;
  }

  void updateNetworkName(String newName) {
    //todo network name?
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

  void _registerHostAsMember() {
    if (currentUser == null) return;

    final hostEntry = DeviceDetail(
      name: currentUser!.name,
      deviceId: _myP2pId!,
      status: "Active",
      unread: 0,
      signalStrength: 100,
      distance: '--',
      avatar: currentUser!.name.isNotEmpty ? currentUser!.name[0] : '?',
      color: Colors.blue,
    );

    _members
      ..clear()
      ..add(hostEntry);

    _membersController.add(List.unmodifiable(_members));
  }

  String getHostP2pId(List<P2pClientInfo> clients) {
    String hostId = '';
    for (var client in clients) {
      if (client.isHost) {
        hostId = client.id;
        print("✅ Host P2P ID assigned: $hostId");
        break;
      }
    }
    return hostId;
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

    _client!.streamClientList().listen((clients) {
      if (clients.length == lastClientCount) return; //todo
      lastClientCount = clients.length;

      _syncMembersFromClientList(clients);
    });

    // Wait for connection to be established before proceeding to dashboard
    try {
      await membersStream
          .firstWhere((members) => members.isNotEmpty)
          .timeout(const Duration(seconds: 15));

      //todo
      // // 1. Handshake immediately so everyone gets our UUID mapping
      // broadcastHandshake();

      // // 2. Announce profile shortly after
      // Future.delayed(const Duration(milliseconds: 500), broadcastProfile);
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
    final Map<String, dynamic> pkt = {
      "type": "broadcast",
      "from": _myP2pId,
      "to": "ALL",
      "message": text,
      "senderName": currentUser!.name,
    };
    _sendToAll(pkt);
  }

  void sendPrivate(String receiverId, String text) {
    debugPrint("🥸 Sending private message to $receiverId: $text");
    debugPrint("My P2P ID: $_myP2pId");
    debugPrint("Text: $text");

    final Map<String, dynamic> pkt = {
      "type": "private",
      "from": _myP2pId,
      "to": receiverId,
      "message": text,
      "senderName": currentUser!.name,
    };
    _sendToOne(receiverId, pkt);
  }

  void kickUser(String userId) {
    _sendToOne(userId, {
      "type": "kick",
      "from": _myP2pId,
      "to": userId,
      "message": "removed by server",
    });
  }

  void assignP2pId(String userId) {
    _sendToOne(userId, {
      "type": "p2p_id_assign",
      "from": _myP2pId,
      "to": userId,
      "message": userId,
    });
  }

  // // Lightweight UUID broadcast to ensure mapping
  // void broadcastHandshake() {
  //   if (currentUser == null) return;

  //   final String fromId = _myP2pId ?? currentUser!.deviceId;
  //   final Map<String, dynamic> pkt = {
  //     "type": "handshake",
  //     "from": fromId,
  //     "fromAppId": currentUser!.deviceId,
  //   };
  //   _sendToAll(pkt);
  // }

  // Broadcast current user's profile to all peers
  void broadcastProfile() {
    if (currentUser == null) return;

    final String fromId = _myP2pId ?? currentUser!.deviceId;
    final Map<String, dynamic> pkt = {
      "type": "profile",
      "from": fromId,
      "fromAppId": currentUser!.deviceId,
      "name": currentUser!.name,
      "email": currentUser!.email,
      "phone": currentUser!.phone,
      "address": currentUser!.address,
      "bloodType": currentUser!.bloodType,
      "emergencyContact": currentUser!.emergencyContact,
      "avatar": currentUser!.avatarLetter,
      "color": currentUser!.avatarColor.value.toString(),
      "status": currentUser!.status,
    };
    _sendToAll(pkt);
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
      final String? senderP2pId = data["from"]?.toString();
      final String? receiverP2pId = data["to"]?.toString();

      switch (data["type"]) {
        case "broadcast":
          _messagesController.add(
            Message(
              text: data["message"],
              isMine: false,
              time: TimeOfDay.now(),
              isDelivered: true,
              senderDeviceId: senderP2pId,
              receiverDeviceId: 'ALL',
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
              senderDeviceId: senderP2pId,
              receiverDeviceId: receiverP2pId,
            ),
          );
          break;

        case "kick":
          disconnect();
          break;

        // case "network_full":
        //   if (!isHost) {
        //     // todo: Handle network full - maybe show error to user
        //     debugPrint("Cannot join: ${data["message"]}");
        //     disconnect();
        //   }
        //   break;

        case "p2p_id_assign":
          final String? assignedId = data["message"]?.toString();
          _myP2pId = assignedId;
          break;

        case "profile":
          // Receive peer's profile data and save to database
          await _handleProfileUpdate(data);
          break;
      }
    } catch (e) {
      debugPrint("Error handling incoming packet: $e");
    }
  }

  // Handle incoming profile data from peers
  Future<void> _handleProfileUpdate(Map<String, dynamic> data) async {
    try {
      final deviceId = data["fromAppId"]?.toString();
      if (deviceId == null) return;

      // Don't save our own profile
      if (deviceId == currentUser?.deviceId) return;

      // Create UserProfile from received data
      final profile = UserProfile(
        name: data["name"]?.toString() ?? "Unknown",
        email: data["email"]?.toString() ?? "",
        phone: data["phone"]?.toString() ?? "",
        address: data["address"]?.toString() ?? "",
        bloodType: data["bloodType"]?.toString() ?? "",
        emergencyContact: data["emergencyContact"]?.toString() ?? "",
        avatarLetter: data["avatar"]?.toString() ?? "?",
        avatarColor: Color(int.parse(data["color"]?.toString() ?? "0")),
        status: data["status"]?.toString() ?? "Idle",
        deviceId: deviceId,
      );

      // Save to database
      await DatabaseHelper.instance.saveUserProfile(profile);
    } catch (e) {
      debugPrint("❌ Error handling profile update: $e");
    }
  }

  // ---------------- MEMBERS MANAGEMENT ------------------

  void _syncMembersFromClientList(List<P2pClientInfo> clients) {
    // Check if network is full (server only, and only when a limit is set)
    final max = _maxMembers;
    if (isHost && max != null && clients.length > max) {
      // todo: Send network full message to clients trying to join
      return;
    }

    // if (newNetwork) {
    //   getHostP2pId(clients);
    //   newNetwork = false;
    // }

    // _members.removeWhere((m) => m.deviceId == "NULL");
    // _membersController.add(List.unmodifiable(_members));

    for (var client in clients) {
      debugPrint("🔄 Syncing member: ${client.username} (ID: ${client.id}, Host: ${client.isHost})");
      if (_members.any((m) => m.deviceId == client.id)) continue;

      _members.add(
        DeviceDetail(
          name: client.username,
          deviceId: client.id,
          status: "Active",
          unread: 0,
          signalStrength: 100,
          distance: '--',
          avatar: client.username.isNotEmpty ? client.username[0] : '?',
          color: client.isHost ? Colors.blue : Colors.green,
        ),
      );

      // if (newNetwork && client.isHost) {
      //   assignP2pId(client.id);
      //   newNetwork = false;
      //   debugPrint("💃 Host P2P ID assigned during sync: $_myP2pId");
      // }

      if (isHost) {
        assignP2pId(client.id);
      }
    }
    // if ((isHost && client.isHost) ||
    //     (!isHost && client.username == currentUser?.name)) {
    //   _myP2pId = client.id;
    //   // Map our own IDs
    //   if (currentUser != null) {
    //     _p2pIdToAppId[client.id] = currentUser!.deviceId;
    //     _appIdToP2pId[currentUser!.deviceId] = client.id;
    //   }

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
      deviceId:
          deviceId ?? 'mock-device-${DateTime.now().millisecondsSinceEpoch}',
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

    debugPrint(
      '✅ Mock device added: ${mockDevice.name} (${mockDevice.deviceId})',
    );
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
