import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';

import 'package:projectdemo/data/models/device_detail_model.dart';
import 'package:projectdemo/data/models/user_profile_model.dart';
import 'package:projectdemo/data/models/message_model.dart';
import 'package:projectdemo/data/local/database_helper.dart';

// Event emitted when a local message is marked delivered (ACK received)
class DeliveryUpdate {
  final int messageId;
  final bool delivered;
  DeliveryUpdate(this.messageId, this.delivered);
}

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

  // Delivery ACK notifications
  // Emits DeliveryUpdate when a message is marked delivered
  final _deliveryController = StreamController<DeliveryUpdate>.broadcast();
  Stream<DeliveryUpdate> get deliveryStream => _deliveryController.stream;

  // Lightweight delivery update model
  // messageId: local DB message id
  // delivered: whether message was delivered
  // Note: kept in this file for brevity; can be moved to a shared models file if needed

  // DeliveryUpdate class defined below to avoid top-level changes

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

  void sendBroadcast(String text, {int? localMessageId}) {
    final Map<String, dynamic> pkt = {
      "type": "broadcast",
      "from": currentUser!.deviceId,
      "to": "ALL",
      "message": text,
      "senderName": currentUser!.name,
    };
    if (localMessageId != null) pkt['mid'] = localMessageId;
    _sendToAll(pkt);
  }

  void sendPrivate(String receiverId, String text, {int? localMessageId}) {
    final Map<String, dynamic> pkt = {
      "type": "private",
      "from": currentUser!.deviceId,
      "to": receiverId,
      "message": text,
      "senderName": currentUser!.name,
    };
    if (localMessageId != null) pkt['mid'] = localMessageId;
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

      switch (data["type"]) {
        case "broadcast":
          _messagesController.add(
            Message(
              text: data["message"],
              isMine: false,
              time: TimeOfDay.now(),
              isDelivered: true,
              senderDeviceId: data["from"]?.toString(),
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
              senderDeviceId: data["from"]?.toString(),
            ),
          );
          break;

        case 'ack':
          // Received an ack for a previously sent message
          try {
            final mid = data['mid'];
            if (mid != null) {
              // mark message as delivered in DB
              final id = mid is int ? mid : int.tryParse(mid.toString());
              if (id != null) {
                await DatabaseHelper.instance.updateMessageDelivery(id, true);

                // Notify listeners (cubits) that this message was delivered
                try {
                  if (!_deliveryController.isClosed) {
                    _deliveryController.add(DeliveryUpdate(id, true));
                  }
                } catch (_) {}
              }
            }
          } catch (e) {
            debugPrint('Failed to process ack: $e');
          }
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

  void _syncMembersFromClientList(List<P2pClientInfo> clients) {
    // Check if network is full (server only, and only when a limit is set)
    final max = _maxMembers;
    if (isHost && max != null && clients.length > max) {
      debugPrint("Network full: ${clients.length}/$max");

      // todo: Send network full message to clients trying to join

      return;
    }

    _members.clear();

    for (var client in clients) {
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

    _host?.dispose();
    _client?.dispose();

    _host = null;
    _client = null;
  }

  // ---------------- DISPOSE ------------------
  void dispose() {
    // Close all controllers when app is shutting down
    if (!_discoveryController.isClosed) _discoveryController.close();
    if (!_membersController.isClosed) _membersController.close();
    if (!_messagesController.isClosed) _messagesController.close();
    if (!_deliveryController.isClosed) _deliveryController.close();

    _host?.dispose();
    _client?.dispose();
  }
}
