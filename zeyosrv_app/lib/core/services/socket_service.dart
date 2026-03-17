import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class SocketService {
  static IO.Socket? socket;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) return;

    socket = IO.io(ApiConstants.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'auth': {'token': token}
    });

    socket!.onConnect((_) {
      print('Connected to Socket Service');
    });

    socket!.onDisconnect((_) => print('Disconnected from Socket Service'));
  }

  static void listen(String event, Function(dynamic) callback) {
    socket?.on(event, callback);
  }

  static void emit(String event, dynamic data) {
    socket?.emit(event, data);
  }

  static void off(String event) {
    socket?.off(event);
  }
}
