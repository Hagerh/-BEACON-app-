import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';

import '../data/model/deviceDetail_model.dart';
import '../data/model/message_model.dart';
import '../data/model/userProfile_model.dart';

class P2PService {
  FlutterP2pHost? _host;
  FlutterP2pClient? _client;

  bool isServer = false;
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

  // Chat messages
  final _messagesController = StreamController<Message>.broadcast();
  Stream<Message> get messagesStream => _messagesController.stream;

  // ---------------- SERVER METHODS ------------------

  Future<void> createNetwork({
    required UserProfile me,
    required String name,
    required int max,
  }) async {
    try {
      isServer = true;
      currentUser = me;
      _maxMembers = max;

      // Initialize P2P host
      _host = FlutterP2pHost();
      await _host!.initialize();
      await _checkPermissions(_host!);

      // Create P2P group
      await _host!.createGroup(advertise: true);

      // Listen for incoming packets
      _host!.streamReceivedTexts().listen(_handleIncomingPacket);

      // Add server as first member in dashboard
      _addMember(currentUser!.deviceId, currentUser!.name);
    } catch (e) {
      debugPrint("Failed to create network: $e");
      rethrow;
    }
  }

  Future<void> stopNetwork() async {
    if (isServer) await _host?.removeGroup();
    disconnect(); //? broadcast shutdown?
  }

  // ---------------- CLIENT METHODS ------------------

  Future<void> initializeClient(UserProfile me) async {
    isServer = false;
    currentUser = me;

    // Initialize P2P client
    _client = FlutterP2pClient();
    await _client!.initialize();
    await _checkPermissions(_client!);

    // Listen for incoming packets
    _client!.streamReceivedTexts().listen(_handleIncomingPacket);
  }

  Future<void> connectToServer(BleDiscoveredDevice device) async {
    // Stop scanning before connecting
    await _client!.stopScan();

    // Connect to the server
    await _client!.connectWithDevice(device);

    // Notify of joining
    sendJoin();
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

  Future<void> leaveNetwork() async {
    if (!isServer) {
      sendLeave();
      disconnect();
    }
  }

  // ---------------- PERMISSIONS ------------------

  Future<void> _checkPermissions(dynamic p) async {
    if (!await p.checkStoragePermission()) await p.askStoragePermission();
    if (!await p.checkP2pPermissions()) await p.askP2pPermissions();
    if (!await p.checkBluetoothPermissions()) await p.askBluetoothPermissions();
    if (!await p.checkWifiEnabled()) await p.enableWifiServices();
    if (!await p.checkLocationEnabled()) await p.enableLocationServices();
    if (!await p.checkBluetoothEnabled()) await p.enableBluetoothServices();
  }

  // ---------------- HIGH-LEVEL SEND API ------------------

  void sendBroadcast(String text) {
    _sendToAll({
      "type": "broadcast",
      "from": currentUser!.deviceId,
      "to": "ALL",
      "message": text, //? add senderName?
    });
  }

  void sendPrivate(String receiverId, String text) {
    _sendToOne(receiverId, {
      "type": "private",
      "from": currentUser!.deviceId,
      "to": receiverId,
      "message": text,
    });
  }

  void sendJoin() {
    _sendToAll({
      "type": "join",
      "from": currentUser!.deviceId,
      "to": "ALL",
      "message": currentUser!.name,
    });
  }

  void sendLeave() {
    _sendToAll({
      "type": "leave",
      "from": currentUser!.deviceId,
      "to": "ALL",
      "message": "left",
    });
  }

  void kickUser(String userId) {
    _sendToOne(userId, {
      "type": "kick",
      "from": currentUser!.deviceId,
      "to": userId,
      "message": "removed by server",
    });
  }

  void sendMemberList(String clientId) {
    _sendToOne(clientId, {
      "type": "member_list",
      "from": currentUser!.deviceId,
      "to": clientId,
      "members": _members
          .map((m) => {"deviceId": m.deviceId, "name": m.name})
          .toList(),
    });
  }

  void broadcastMemberAdded(String deviceId, String name) {
    _sendToAll({
      "type": "member_added",
      "from": currentUser!.deviceId,
      "to": "ALL",
      "message": ({"deviceId": deviceId, "name": name}),
    });
  }

  void broadcastMemberRemoved(String deviceId) {
    _sendToAll({
      "type": "member_removed",
      "from": currentUser!.deviceId,
      "to": "ALL",
      "message": deviceId,
    });
  }

  // ---------------- LOW-LEVEL SEND HELPERS ------------------

  void _sendToAll(Map pkt) {
    final json = jsonEncode(pkt);

    if (isServer) {
      _host?.broadcastText(json);
    } else {
      _client?.broadcastText(json);
    }
  }

  void _sendToOne(String clientId, Map pkt) {
    final json = jsonEncode(pkt);

    if (isServer) {
      _host?.sendTextToClient(json, clientId);
    } else {
      _client?.sendTextToClient(json, clientId);
    }
  }

  // ---------------- RECEIVING PACKETS ------------------

  void _handleIncomingPacket(String raw) {
    Map<String, dynamic> data = jsonDecode(raw);

    switch (data["type"]) {
      case "broadcast":
        _messagesController.add(
          Message(
            text: data["message"],
            isMine: false,
            time: TimeOfDay.now(),
            isDelivered: true,
          ),
        );
        break;

      case "private":
        if (data["to"] == currentUser!.deviceId) {
          _messagesController.add(
            Message(
              text: data["message"],
              isMine: false,
              time: TimeOfDay.now(),
              isDelivered: true,
            ),
          );
        }
        break;

      case "join":
        if (isServer) {
          String deviceId = data["from"];
          String name = data["message"] ?? "Unknown";

          // Check if network is full
          if (_members.length >= _maxMembers!) {
            _sendToOne(deviceId, {
              "type": "network_full",
              "from": currentUser!.deviceId,
              "to": deviceId,
              "message": "Network has reached maximum capacity",
            });
            return;
          }

          _addMember(deviceId, name);

          // Send full member list to NEW client only
          sendMemberList(deviceId);

          // Broadcast to ALL other clients that someone joined
          broadcastMemberAdded(deviceId, name);
        }
        break;

      case "leave":
        if (isServer) {
          String deviceId = data["from"];
          _removeMember(deviceId);
          broadcastMemberRemoved(deviceId);
        }
        break;

      case "kick":
        if (data["to"] == currentUser!.deviceId) {
          disconnect();
        }
        break;

      case "member_list":
        if (!isServer) {
          _members.clear();
          for (var member in data["members"]) {
            _addMember(member["deviceId"], member["name"]);
          }
        }
        break;

      case "member_added":
        if (!isServer) {
          _addMember(data["deviceId"], data["name"]);
        }
        break;

      case "member_removed":
        if (!isServer) {
          _removeMember(data["deviceId"]);
        }
        break;

      case "network_full":
        if (!isServer) {
          // Handle network full - maybe show error to user
          debugPrint("Cannot join: ${data["message"]}");
          disconnect();
        }
        break;
    }
  }

  // ---------------- MEMBERS MANAGEMENT ------------------

  void _addMember(String deviceId, String name) {
    _members.add(
      DeviceDetail(
        name: name,
        deviceId: deviceId,
        status: "Active",
        unread: 0,
        signalStrength: 100,
        distance: '--',
        avatar: name.isNotEmpty ? name[0] : '?',
        color: Colors.green,
      ),
    );
    _membersController.add(List.unmodifiable(_members));
  }

  void _removeMember(String deviceId) {
    _members.removeWhere((device) => device.deviceId == deviceId);
    _membersController.add(List.unmodifiable(_members));
  }

  // ---------------- DISCONNECT ------------------

  void disconnect() {
    // Clear all data
    _members.clear();
    _membersController.add(List.unmodifiable(_members));

    _discoveryController.add([]);

    // Dispose the P2P connections
    _host?.dispose();
    _client?.dispose();

    // Reset ALL state
    _host = null;
    _client = null;
    isServer = false;
    currentUser = null;
    _maxMembers = null;
    isScanning = false;
  }

  // ---------------- DISPOSE ------------------
  void dispose() {
    //TODO: call this on app shutdown
    // Close all controllers when app is shutting down
    if (!_discoveryController.isClosed) _discoveryController.close();
    if (!_membersController.isClosed) _membersController.close();
    if (!_messagesController.isClosed) _messagesController.close();

    _host?.dispose();
    _client?.dispose();
  }
}
