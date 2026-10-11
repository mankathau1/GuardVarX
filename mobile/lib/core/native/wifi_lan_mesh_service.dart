import 'dart:async';
import 'dart:convert';
import 'dart:io';

class WifiLanMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String recipientId;
  final String text;
  final DateTime timestamp;
  final String channel; // 'WIFI_LAN_UDP' or 'BLE_MESH'
  final bool isEmergency;

  const WifiLanMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.recipientId,
    required this.text,
    required this.timestamp,
    this.channel = 'WIFI_LAN_UDP',
    this.isEmergency = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'senderName': senderName,
        'recipientId': recipientId,
        'text': text,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'channel': channel,
        'isEmergency': isEmergency,
      };

  factory WifiLanMessage.fromJson(Map<String, dynamic> map) {
    return WifiLanMessage(
      id: map['id'] as String? ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: map['senderId'] as String? ?? 'anonymous',
      senderName: map['senderName'] as String? ?? 'Nearby Peer',
      recipientId: map['recipientId'] as String? ?? 'broadcast',
      text: map['text'] as String? ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int)
          : DateTime.now(),
      channel: map['channel'] as String? ?? 'WIFI_LAN_UDP',
      isEmergency: map['isEmergency'] as bool? ?? false,
    );
  }
}

class WifiLanMeshService {
  static const int port = 58888;
  RawDatagramSocket? _socket;
  final StreamController<WifiLanMessage> _messageStreamController =
      StreamController<WifiLanMessage>.broadcast();

  Stream<WifiLanMessage> get messageStream => _messageStreamController.stream;
  bool get isRunning => _socket != null;

  Future<bool> startServer() async {
    try {
      if (_socket != null) return true;
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
      _socket!.broadcastEnabled = true;
      _socket!.multicastLoopback = false;

      _socket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket?.receive();
          if (datagram != null) {
            try {
              final raw = utf8.decode(datagram.data);
              final map = jsonDecode(raw) as Map<String, dynamic>;
              final msg = WifiLanMessage.fromJson(map);
              _messageStreamController.add(msg);
            } catch (_) {}
          }
        }
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> broadcastMessage(WifiLanMessage message) async {
    try {
      if (_socket == null) {
        await startServer();
      }
      final payload = utf8.encode(jsonEncode(message.toJson()));
      // Broadcast to all devices on the same Wi-Fi subnet
      _socket?.send(payload, InternetAddress('255.255.255.255'), port);
      return true;
    } catch (_) {
      return false;
    }
  }

  void stop() {
    _socket?.close();
    _socket = null;
  }
}
