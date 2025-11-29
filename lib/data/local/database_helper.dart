import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../model/device_model.dart';
import '../model/deviceDetail_model.dart';
import '../model/message_model.dart';
import '../model/userProfile_model.dart';
import '../../services/encryption_service.dart';

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
      version: 1,
      password: encryptionKey, // SQLCipher encryption key
      onConfigure: (db) async {
        // Enable foreign keys
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB, // create tables if not exist
    );

    // Some SQLite PRAGMA statements (like journal_mode) can be platform-sensitive when
    // executed during onConfigure. Run it here after openDatabase returns and ignore
    // failures so older SQLite implementations won't crash the app.
    try {
      await db.rawQuery('PRAGMA journal_mode = WAL');
    } catch (_) {
        print('Could not set journal_mode to WAL');  // remove 
      // ignore - some platforms/versions may not accept this PRAGMA.
    }

    return db;
  }

  Future _createDB(Database db, int version) async {
    // Networks
    await db.execute('''
      CREATE TABLE Networks (
        network_id INTEGER PRIMARY KEY AUTOINCREMENT,
        network_name TEXT NOT NULL,
        host_device_id TEXT,
        status TEXT NOT NULL DEFAULT 'Active',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(host_device_id) REFERENCES Devices(device_id) ON DELETE SET NULL
      )
    ''');
    // Devices
    await db.execute('''
      CREATE TABLE Devices (
        device_id TEXT PRIMARY KEY,
        network_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        status TEXT NOT NULL,
        unread INTEGER DEFAULT 0,
        signal_strength INTEGER,
        distance TEXT,
        avatar TEXT,
        color TEXT,
        ip_address TEXT,
        last_seen_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        is_host INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY(network_id) REFERENCES Networks(network_id) ON DELETE CASCADE
      )
    ''');

    // Users
    await db.execute('''
      CREATE TABLE Users (
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        email TEXT,
        phone TEXT,
        address TEXT,
        blood_type TEXT,
        device_id TEXT,
        FOREIGN KEY(device_id) REFERENCES Devices(device_id) ON DELETE SET NULL
      )
    ''');

    // Messages
    await db.execute('''
      CREATE TABLE Messages (
        message_id INTEGER PRIMARY KEY AUTOINCREMENT,
        network_id INTEGER NOT NULL,
        sender_device_id TEXT,
        receiver_device_id TEXT,
        message_content TEXT NOT NULL,
        is_mine INTEGER NOT NULL DEFAULT 0,
        is_delivered INTEGER NOT NULL DEFAULT 0,
        sent_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(network_id) REFERENCES Networks(network_id) ON DELETE CASCADE,
        FOREIGN KEY(sender_device_id) REFERENCES Devices(device_id) ON DELETE SET NULL,
        FOREIGN KEY(receiver_device_id) REFERENCES Devices(device_id) ON DELETE SET NULL
        
      )
    ''');

    // Resources
    await db.execute('''
      CREATE TABLE Resources (
        resource_id INTEGER PRIMARY KEY AUTOINCREMENT,
        network_id INTEGER NOT NULL,
        device_id TEXT,
        resource_type TEXT NOT NULL,
        description TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(network_id) REFERENCES Networks(network_id) ON DELETE CASCADE,
        FOREIGN KEY(device_id) REFERENCES Devices(device_id) ON DELETE SET NULL
      )
    ''');

    // Seed some dummy data
    await _seedDummyData(db);
  }

  Future _seedDummyData(Database db) async {
    // Insert a couple of networks
    final n1 = await db.insert('Networks', {
      'network_name': 'Family Group',
      'status': 'Active',
    });

    final n2 = await db.insert('Networks', {
      'network_name': 'Rescue Team',
      'status': 'Active',
    });

    // Insert host devices and peers
    await db.insert('Devices', {
      'device_id': 'host-001',
      'network_id': n1,
      'name': 'Emergency hub 01',
      'status': 'Active',
      'unread': 0,
      'signal_strength': 95,
      'distance': '0m',
      'avatar': 'E',
      'color': '#FF8A00',
      'ip_address': '192.168.1.10',
      'is_host': 1,
    });

    await db.insert('Devices', {
      'device_id': 'peer-101',
      'network_id': n1,
      'name': 'Available Network 02',
      'status': 'Active',
      'unread': 1,
      'signal_strength': 78,
      'distance': '50m',
      'avatar': 'A',
      'color': '#00BFA6',
      'ip_address': '192.168.1.11',
      'is_host': 0,
    });

    await db.insert('Devices', {
      'device_id': 'host-002',
      'network_id': n2,
      'name': 'Available Network 03',
      'status': 'Active',
      'unread': 0,
      'signal_strength': 88,
      'distance': '30m',
      'avatar': 'R',
      'color': '#0086FF',
      'ip_address': '10.0.0.5',
      'is_host': 1,
    });

    // link networks to host devices
    await db.update('Networks', {'host_device_id': 'host-001'}, where: 'network_id = ?', whereArgs: [n1]);
    await db.update('Networks', {'host_device_id': 'host-002'}, where: 'network_id = ?', whereArgs: [n2]);

    // Insert messages
    await db.insert('Messages', {
      'network_id': n1,
      'sender_device_id': 'peer-101',
      'receiver_device_id': 'host-001',
      'message_content': 'Hey! Are you safe?',
      'is_mine': 0,
      'is_delivered': 1,
    });

    await db.insert('Messages', {
      'network_id': n1,
      'sender_device_id': 'host-001',
      'receiver_device_id': 'peer-101',
      'message_content': 'Yes, I\'m okay. Just staying indoors.',
      'is_mine': 1,
      'is_delivered': 1,
    });

    await db.insert('Messages', {
      'network_id': n2,
      'sender_device_id': 'host-002',
      'receiver_device_id': 'peer-101',
      'message_content': 'Good to hear! Do you need any supplies?',
      'is_mine': 0,
      'is_delivered': 1,
    });

    // Resources
    await db.insert('Resources', {
      'network_id': n1,
      'device_id': 'peer-101',
      'resource_type': 'Medical',
      'description': 'Need first aid kit',
      'status': 'Pending',
    });
  }

  //
  Future<List<Device>> fetchNetworkSummaries() async {
    final db = await instance.database;

    final rows = await db.rawQuery('''
      SELECT n.network_id, n.network_name, n.host_device_id,
        (SELECT COUNT(*) FROM Devices d WHERE d.network_id = n.network_id) AS connectors,
        (SELECT last_seen_at FROM Devices d WHERE d.device_id = n.host_device_id) AS last_seen_at,
        (SELECT status FROM Devices d WHERE d.device_id = n.host_device_id) AS host_status
      FROM Networks n
      ORDER BY n.created_at DESC
    ''');

    return rows.map((r) => Device.fromMap(r as Map<String, dynamic>)).toList();
  }

  // fetch devices for a given network name
  Future<List<DeviceDetail>> fetchDevicesForNetwork(String networkName, int limit) async {
    final db = await instance.database;
    final networks = await db.query('Networks', where: 'network_name = ?', whereArgs: [networkName], limit: 1);
    if (networks.isEmpty) return [];
    final nid = networks.first['network_id'];

    final rows = await db.query('Devices', where: 'network_id = ?', whereArgs: [nid], limit: limit);
    return rows.map((r) => DeviceDetail.fromMap(r as Map<String, dynamic>)).toList();
  }

  Future<List<Message>> fetchRecentMessages({
    int? networkId,
    String? forDeviceId,
    int limit = 50,
  }) async {
    final db = await instance.database;

    List<Map<String, Object?>> rows;

    if (forDeviceId != null) {
      if (networkId != null) {
        rows = await db.query(
          'Messages',
          where: 'network_id = ? AND (sender_device_id = ? OR receiver_device_id = ?)',
          whereArgs: [networkId, forDeviceId, forDeviceId],
          orderBy: 'sent_at ASC',
          limit: limit,
        );
      } else {
        rows = await db.query(
          'Messages',
          where: 'sender_device_id = ? OR receiver_device_id = ?',
          whereArgs: [forDeviceId, forDeviceId],
          orderBy: 'sent_at ASC',
          limit: limit,
        );
      }
    } else if (networkId != null) {
      rows = await db.query(
        'Messages',
        where: 'network_id = ?',
        whereArgs: [networkId],
        orderBy: 'sent_at ASC',
        limit: limit,
      );
    } else {
      rows = await db.query('Messages', orderBy: 'sent_at ASC', limit: limit);
    }

    return rows.map((r) => Message.fromMap(r as Map<String, dynamic>)).toList();
  }



  // Get user profile by device_id (joins Users and Devices tables)
  Future<UserProfile?> getUserProfile(String deviceId) async {
    final db = await instance.database;

    final rows = await db.rawQuery('''
      SELECT 
        u.username,
        u.email,
        u.phone,
        u.address,
        u.blood_type,
        u.device_id,
        d.status,
        d.avatar,
        d.color
      FROM Users u
      LEFT JOIN Devices d ON u.device_id = d.device_id
      WHERE u.device_id = ?
      LIMIT 1
    ''', [deviceId]);

    if (rows.isEmpty) return null;
    return UserProfile.fromMap(rows.first as Map<String, dynamic>);
  }

  // Save or update user profile
  Future<void> saveUserProfile(UserProfile profile) async {
    final db = await instance.database;

    final existingUsers = await db.query(
      'Users',
      where: 'device_id = ?',
      whereArgs: [profile.deviceId],
      limit: 1,
    );

    final userData = profile.toUserMap();

    if (existingUsers.isEmpty) {
      // Insert new user
      await db.insert('Users', userData);
    } else {
      // Update existing user
      await db.update(
        'Users',
        userData,
        where: 'device_id = ?',
        whereArgs: [profile.deviceId],
      );
    }

    // Update or insert device info (avatar and color)
    final existingDevices = await db.query(
      'Devices',
      where: 'device_id = ?',
      whereArgs: [profile.deviceId],
      limit: 1,
    );

    final profileMap = profile.toMap();
    final deviceData = {
      'device_id': profile.deviceId,
      'name': profile.name,
      'status': profile.status,
      'avatar': profile.avatarLetter,
      'color': profileMap['color'],
    };

    if (existingDevices.isEmpty) {
      final networks = await db.query('Networks', limit: 1);
      if (networks.isNotEmpty) {
        deviceData['network_id'] = networks.first['network_id'];
        deviceData['is_host'] = 0;
        await db.insert('Devices', deviceData);
      }
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
  }

  Future close() async {
    final db = _database;
    if (db != null) await db.close();
    _database = null;
  }
}
