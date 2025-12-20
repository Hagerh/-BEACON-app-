import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import 'package:projectdemo/core/services/encryption_service.dart';
import 'package:projectdemo/data/models/device_model.dart';
import 'package:projectdemo/data/models/device_detail_model.dart';
import 'package:projectdemo/data/models/message_model.dart';
import 'package:projectdemo/data/models/user_profile_model.dart';

class DatabaseHelper {
  // use singlton pattern
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('beacon_app.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    // Ensure directory exists
    try {
      await Directory(dirname(path)).create(recursive: true);
    } catch (_) {} // in case the directory already exists.

    // Get encryption key from secure storage
    final encryptionKey = await EncryptionService.getEncryptionKey();

    final db = await openDatabase(
      path,
      version: 2,
      password: encryptionKey, // SQLCipher encryption key
      onConfigure: (db) async {
        // Enable foreign keys
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB, // create tables if not exist
      onUpgrade: _upgradeDB,
    );

    // Some SQLite PRAGMA statements (like journal_mode) can be platform-sensitive when
    // executed during onConfigure. Run it here after openDatabase returns and ignore
    // failures so older SQLite implementations won't crash the app.
    try {
      await db.rawQuery('PRAGMA journal_mode = WAL');
    } catch (_) {
      print('Could not set journal_mode to WAL'); // remove
      // ignore - some platforms/versions may not accept this PRAGMA.
    }

    return db;
  }

  Future _createDB(Database db, int version) async {
    // Create Networks table first (without foreign key to Devices)
    // await db.execute('''
    //   CREATE TABLE Networks (
    //     network_id INTEGER PRIMARY KEY AUTOINCREMENT,
    //     network_name TEXT NOT NULL,
    //     host_device_id TEXT,
    //     status TEXT NOT NULL DEFAULT 'Active',
    //     created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    //   )
    // ''');

    // Create Devices table (references Networks)
    await db.execute('''
      CREATE TABLE Devices (
        device_id TEXT PRIMARY KEY,
        status TEXT NOT NULL,
        signal_strength INTEGER,
        avatar TEXT,
        color TEXT,
        last_seen_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        is_host INTEGER NOT NULL DEFAULT 0,
      )
    ''');

    // Add foreign key constraint from Networks to Devices after both tables exist
    // Note: SQLite doesn't support adding foreign keys via ALTER TABLE easily,
    // so we'll handle referential integrity in application logic
    // The host_device_id will be validated when devices are inserted/updated

    // Users
    await db.execute('''
      CREATE TABLE Users (
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        email TEXT,
        phone TEXT,
        address TEXT,
        blood_type TEXT,
        emergency_contact TEXT,
        device_id TEXT,
        FOREIGN KEY(device_id) REFERENCES Devices(device_id) ON DELETE SET NULL
      )
    ''');

    // Messages
    await db.execute('''
      CREATE TABLE Messages (
        message_id INTEGER PRIMARY KEY AUTOINCREMENT,
        sender_device_id TEXT NOT NULL,
        receiver_device_id TEXT NOT NULL,
        message_content TEXT NOT NULL,
        is_mine INTEGER NOT NULL DEFAULT 0,
        is_delivered INTEGER NOT NULL DEFAULT 1,
        sent_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(sender_device_id) REFERENCES Devices(device_id) ON DELETE CASCADE,
        FOREIGN KEY(receiver_device_id) REFERENCES Devices(device_id) ON DELETE CASCADE
        
      )
    ''');

    // Resources //todo
    await db.execute('''
      CREATE TABLE Resources (
        resource_id INTEGER PRIMARY KEY AUTOINCREMENT,
        network_id INTEGER NOT NULL,
        device_id TEXT,
        resource_type TEXT NOT NULL,
        description TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(network_id) REFERENCES Networks(network_id) ON DELETE CASCADE,
        FOREIGN KEY(device_id) REFERENCES Devices(device_id) ON DELETE SET NULL
      )
    ''');

    //todo
    await db.execute('''
      CREATE TABLE ResourceRequests (
        request_id INTEGER PRIMARY KEY AUTOINCREMENT,
        resource_id INTEGER NOT NULL,
        requester_device_id TEXT,
        quantity INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'Pending',
        requested_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(resource_id) REFERENCES Resources(resource_id) ON DELETE CASCADE,
        FOREIGN KEY(requester_device_id) REFERENCES Devices(device_id) ON DELETE SET NULL
      )
    ''');

    // Handle migrations for future versions
    await _upgradeDB(db, 1, version);
  }

  // Migration handler
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Ensure Resources has quantity and updated_at
      final columns = await db.rawQuery('PRAGMA table_info(Resources)');
      final hasQuantity = columns.any(
        (c) => c['name']?.toString() == 'quantity',
      );
      if (!hasQuantity) {
        await db.execute(
          'ALTER TABLE Resources ADD COLUMN quantity INTEGER NOT NULL DEFAULT 0',
        );
      }
      final hasUpdatedAt = columns.any(
        (c) => c['name']?.toString() == 'updated_at',
      );
      if (!hasUpdatedAt) {
        await db.execute(
          'ALTER TABLE Resources ADD COLUMN updated_at DATETIME DEFAULT CURRENT_TIMESTAMP',
        );
      }

      //todo
      // Ensure ResourceRequests table exists
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ResourceRequests (
          request_id INTEGER PRIMARY KEY AUTOINCREMENT,
          resource_id INTEGER NOT NULL,
          requester_device_id TEXT,
          quantity INTEGER NOT NULL,
          status TEXT NOT NULL DEFAULT 'Pending',
          requested_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY(resource_id) REFERENCES Resources(resource_id) ON DELETE CASCADE,
          FOREIGN KEY(requester_device_id) REFERENCES Devices(device_id) ON DELETE SET NULL
        )
      ''');
    }
  }

  // // Fetch network summaries - returns list of networks as Device objects
  // Future<List<Device>> fetchNetworkSummaries() async {
  //   final db = await instance.database;

  //   final rows = await db.rawQuery('''
  //     SELECT
  //       n.network_id AS id,
  //       n.network_name,
  //       n.host_device_id,
  //       (SELECT COUNT(*) FROM Devices d WHERE d.network_id = n.network_id) AS connectors,
  //       (SELECT last_seen_at FROM Devices d WHERE d.device_id = n.host_device_id) AS last_seen_at,
  //       (SELECT status FROM Devices d WHERE d.device_id = n.host_device_id) AS host_status
  //     FROM Networks n
  //     ORDER BY n.created_at DESC
  //   ''');

  //   return rows.map((r) => Device.fromMap(r as Map<String, dynamic>)).toList();
  // }

  // fetch devices for a given network name
  // Future<List<DeviceDetail>> fetchDevicesForNetwork(
  //   String networkName,
  //   int limit,
  // ) async {
  //   final db = await instance.database;
  //   final networks = await db.query(
  //     'Networks',
  //     where: 'network_name = ?',
  //     whereArgs: [networkName],
  //     limit: 1,
  //   );
  //   if (networks.isEmpty) return [];
  //   final nid = networks.first['network_id'];

  //   final rows = await db.query(
  //     'Devices',
  //     where: 'network_id = ?',
  //     whereArgs: [nid],
  //     limit: limit,
  //   );
  //   return rows
  //       .map((r) => DeviceDetail.fromMap(r as Map<String, dynamic>))
  //       .toList();
  // }

  Future<List<Message>> fetchRecentMessages({
    String? peerDeviceId,
    String? currentDeviceId,
    int limit = 50,
  }) async {
    final db = await instance.database;

    List<Map<String, Object?>> rows = [];

    if (peerDeviceId != null && currentDeviceId != null) {
      // Strict 1-to-1 history between currentDeviceId and peerDeviceId inside a network
      rows = await db.query(
        'Messages',
        where: '''
            (sender_device_id = ? AND receiver_device_id = ?)
            OR
            (sender_device_id = ? AND receiver_device_id = ?)
        ''',
        whereArgs: [
          peerDeviceId,
          currentDeviceId,
          currentDeviceId,
          peerDeviceId,
        ],
        orderBy: 'sent_at ASC',
        limit: limit,
      );
    }

    return rows.map((r) => Message.fromMap(r as Map<String, dynamic>)).toList();
  }

  // Get user profile by device_id (joins Users and Devices tables)
  Future<UserProfile?> getUserProfile(String deviceId) async {
    final db = await instance.database;

    final rows = await db.rawQuery(
      '''
      SELECT 
        u.username,
        u.email,
        u.phone,
        u.address,
        u.blood_type,
        u.device_id,
        u.emergency_contact,
        d.status,
        d.avatar,
        d.color
      FROM Users u
      LEFT JOIN Devices d ON u.device_id = d.device_id
      WHERE u.device_id = ?
      LIMIT 1
    ''',
      [deviceId],
    );

    if (rows.isEmpty) return null;
    return UserProfile.fromMap(rows.first as Map<String, dynamic>);
  }

  // Save or update user profile
  Future<void> saveUserProfile(UserProfile profile) async {
    final db = await instance.database;

    // Update or insert device info (avatar and color)
    // Check if device exists
    final existingDevices = await db.query(
      'Devices',
      where: 'device_id = ?',
      whereArgs: [profile.deviceId],
      limit: 1,
    );

    final profileMap = profile.toMap();

    // Prepare device data
    final deviceData = <String, dynamic>{
      'device_id': profile.deviceId,
      'name': profile.name,
      'status': profile.status,
      'avatar': profile.avatarLetter,
      'color': profileMap['color'],
    };

    if (existingDevices.isEmpty) {
      // Insert new device
      await db.insert('Devices', deviceData);
    } else {
      // Update existing device
      await db.update(
        'Devices',
        {
          'name': profile.name,
          'status': profile.status,
          'avatar': profile.avatarLetter,
          'color': profileMap['color'],
        },
        where: 'device_id = ?',
        whereArgs: [profile.deviceId],
      );
    }

    // NOW insert/update the user (after device exists)
    final existingUsers = await db.query(
      'Users',
      where: 'device_id = ?',
      whereArgs: [profile.deviceId],
      limit: 1,
    );

    final userData = profile.toUserMap();

    if (existingUsers.isEmpty) {
      // Insert new user
      // username is UNIQUE in this schema; avoid crashing when default usernames repeat.
      await db.insert(
        'Users',
        userData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      // Update existing user
      await db.update(
        'Users',
        userData,
        where: 'device_id = ?',
        whereArgs: [profile.deviceId],
      );
    }
  }

  // Insert or update a device in a network
  Future<void> upsertDevice({
    required String deviceId,
    required String name,
    required String status,
    int? signalStrength,
    String? avatar,
    String? color,
  }) async {
    final db = await instance.database;

    final existing = await db.query(
      'Devices',
      where: 'device_id = ?',
      whereArgs: [deviceId],
      limit: 1,
    );

    final deviceData = <String, dynamic>{
      'device_id': deviceId,
      'name': name,
      'status': status,
      'last_seen_at': DateTime.now().toIso8601String(),
    };

    if (signalStrength != null) deviceData['signal_strength'] = signalStrength;
    if (avatar != null) deviceData['avatar'] = avatar;
    if (color != null) deviceData['color'] = color;

    if (existing.isEmpty) {
      await db.insert('Devices', deviceData);
    } else {
      await db.update(
        'Devices',
        deviceData,
        where: 'device_id = ?',
        whereArgs: [deviceId],
      );
    }
  }

  // Update device last seen timestamp
  Future<void> updateDeviceLastSeen(String deviceId) async {
    final db = await instance.database;
    await db.update(
      'Devices',
      {'last_seen_at': DateTime.now().toIso8601String()},
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );
  }

  // Insert a new message
  Future<int> insertMessage({
    String? senderDeviceId,
    String? receiverDeviceId,
    required String messageContent,
    bool isMine = false,
    bool isDelivered = false,
  }) async {
    final db = await instance.database;

    return await db.insert('Messages', {
      'sender_device_id': senderDeviceId,
      'receiver_device_id': receiverDeviceId,
      'message_content': messageContent,
      'is_mine': isMine ? 1 : 0,
      'is_delivered': isDelivered ? 1 : 0,
      'sent_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteDevice(String deviceId) async {
    final db = await instance.database;
    await db.transaction(txn) async {
      final rows = await txn.query(
        'Devices',
        where: 'device_id = ?',
        whereArgs: [deviceId],
        limit: 1,
      );
      if (rows.isEmpty) return;

      final device = rows.first;
        // Just delete the device
        await txn.delete(
          'Devices',
          where: 'device_id = ?',
          whereArgs: [deviceId],
        );
      }
    };

  // Add a resource provided by a device to a network
  Future<int> addResource({
    required int networkId,
    required String deviceId,
    required String resourceType,
    required String description,
    required int quantity,
    String status = 'Available',
  }) async {
    final db = await instance.database;
    return await db.insert('Resources', {
      'network_id': networkId,
      'device_id': deviceId,
      'resource_type': resourceType,
      'description': description,
      'quantity': quantity,
      'status': status,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // Request a resource: deduct quantity atomically and log the request
  Future<void> requestResource({
    required int resourceId,
    required int requestQuantity,
    String? requesterDeviceId,
  }) async {
    final db = await instance.database;

    await db.transaction((txn) async {
      final rows = await txn.query(
        'Resources',
        where: 'resource_id = ?',
        whereArgs: [resourceId],
        limit: 1,
      );

      if (rows.isEmpty) {
        throw Exception('Resource not found');
      }

      final resource = rows.first;
      final currentQty = (resource['quantity'] is int)
          ? resource['quantity'] as int
          : int.tryParse(resource['quantity'].toString()) ?? 0;

      if (requestQuantity <= 0) {
        throw Exception('Requested quantity must be greater than zero');
      }
      if (currentQty < requestQuantity) {
        throw Exception('Not enough resource quantity available');
      }

      final remaining = currentQty - requestQuantity;
      final newStatus = remaining > 0
          ? (resource['status']?.toString() ?? 'Available')
          : 'Unavailable';

      await txn.update(
        'Resources',
        {
          'quantity': remaining,
          'status': newStatus,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'resource_id = ?',
        whereArgs: [resourceId],
      );

      await txn.insert('ResourceRequests', {
        'resource_id': resourceId,
        'requester_device_id': requesterDeviceId,
        'quantity': requestQuantity,
        // We deduct the full requested quantity or throw; so this is fulfilled.
        'status': 'Fulfilled',
        'requested_at': DateTime.now().toIso8601String(),
      });
    });
  }

  // Update resource quantity directly (provider/admin only) and log adjustment for audit
  Future<void> updateResourceQuantity({
    required int resourceId,
    required int quantity,
    required String providerDeviceId,
    String? status,
  }) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.update(
        'Resources',
        {
          'quantity': quantity,
          if (status != null) 'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'resource_id = ?',
        whereArgs: [resourceId],
      );

      // Log an adjustment as a special ResourceRequest entry for audit trail
      await txn.insert('ResourceRequests', {
        'resource_id': resourceId,
        'requester_device_id': providerDeviceId,
        'quantity': 0,
        'status': 'Adjusted',
        'requested_at': DateTime.now().toIso8601String(),
      });
    });
  }

  // Fetch resources for a network
  Future<List<Map<String, dynamic>>> fetchResources(int networkId) async {
    final db = await instance.database;
    return await db.query(
      'Resources',
      where: 'network_id = ?',
      whereArgs: [networkId],
      orderBy: 'created_at DESC',
    );
  }

  // Fetch requests for a given resource
  Future<List<Map<String, dynamic>>> fetchResourceRequests(
    int resourceId,
  ) async {
    final db = await instance.database;
    return await db.query(
      'ResourceRequests',
      where: 'resource_id = ?',
      whereArgs: [resourceId],
      orderBy: 'requested_at DESC',
    );
  }

  Future close() async {
    final db = _database;
    if (db != null) await db.close();
    _database = null;
  }
}
