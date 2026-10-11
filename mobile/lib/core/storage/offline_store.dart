import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class LocalIncident {
  final String incidentId;
  final String emergencyType;
  final String? message;
  final double latitude;
  final double longitude;
  final double accuracy;
  final String timestamp;
  final String deliveryStatus;
  final int isSynced;

  LocalIncident({
    required this.incidentId,
    required this.emergencyType,
    this.message,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    required this.deliveryStatus,
    this.isSynced = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'incident_id': incidentId,
      'emergency_type': emergencyType,
      'message': message,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': timestamp,
      'delivery_status': deliveryStatus,
      'is_synced': isSynced,
    };
  }

  factory LocalIncident.fromMap(Map<String, dynamic> map) {
    return LocalIncident(
      incidentId: map['incident_id'] as String,
      emergencyType: map['emergency_type'] as String,
      message: map['message'] as String?,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      accuracy: (map['accuracy'] as num).toDouble(),
      timestamp: map['timestamp'] as String,
      deliveryStatus: map['delivery_status'] as String,
      isSynced: map['is_synced'] as int? ?? 0,
    );
  }
}

class OfflineStore {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'guardvarx_offline.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE local_incidents (
            incident_id TEXT PRIMARY KEY,
            emergency_type TEXT NOT NULL,
            message TEXT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            accuracy REAL NOT NULL,
            timestamp TEXT NOT NULL,
            delivery_status TEXT NOT NULL,
            is_synced INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE outbox_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            endpoint TEXT NOT NULL,
            method TEXT NOT NULL,
            payload TEXT NOT NULL,
            created_at TEXT NOT NULL,
            retry_count INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  // Persist incident before network dispatch
  static Future<void> saveIncident(LocalIncident incident) async {
    final db = await database;
    await db.insert(
      'local_incidents',
      incident.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> updateIncidentStatus(String incidentId, String status, {bool isSynced = false}) async {
    final db = await database;
    await db.update(
      'local_incidents',
      {
        'delivery_status': status,
        'is_synced': isSynced ? 1 : 0,
      },
      where: 'incident_id = ?',
      whereArgs: [incidentId],
    );
  }

  static Future<LocalIncident?> getLatestIncident() async {
    final db = await database;
    final results = await db.query(
      'local_incidents',
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return LocalIncident.fromMap(results.first);
  }

  static Future<List<LocalIncident>> getUnsyncedIncidents() async {
    final db = await database;
    final results = await db.query(
      'local_incidents',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    return results.map((m) => LocalIncident.fromMap(m)).toList();
  }

  static Future<void> enqueueOutbox(String endpoint, String method, Map<String, dynamic> payload) async {
    final db = await database;
    await db.insert('outbox_queue', {
      'endpoint': endpoint,
      'method': method,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'retry_count': 0,
    });
  }
}
