import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

var logger = Logger();

class ServerCommunication {
  socket_io.Socket? socket;
  bool isConnected = false;
  String ipAddress = "http://127.0.0.1:5000";

  ServerCommunication() {
    _loadIP().then((_) {
      _connectToServer();
    });
  }

  Future<void> _loadIP() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? ip = prefs.getString('simulator_ip');
    if (ip?.isNotEmpty ?? false) {
      ipAddress = ip!;
    }
  }

  void _connectToServer() {
    logger.i(
        ' ------------------------------ Connecting to socket at $ipAddress ...');
    socket = socket_io.io(ipAddress, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket!.onConnect((_) {
      logger.i('Connected to server');
      isConnected = true;
    });

    socket!.onDisconnect((_) {
      logger.i('Disconnected from server');
      isConnected = false;
    });

    socket!.on('connection_status', (data) {
      logger.i('Connection status: $data');
    });

    socket!.connect();
  }

  void toggleDataGeneration(bool isGeneratingData) {
    if (socket == null) return;

    if (isGeneratingData) {
      socket!.emit('stop_data_generation');
    } else {
      socket!.emit('start_data_generation');
    }
  }

  void getSingleReading(Function callback) {
    if (socket == null) return;

    socket!.emitWithAck('get_single_reading', {}, ack: (data) {
      callback(data);
    });
  }

  void onHealthData(void Function(dynamic) callback) {
    if (socket == null) return;

    socket!.on('health_data', (data) {
      logger.i('Received health data: $data');
      callback(data);
    });
  }

  void disconnect() {
    if (socket == null) return;

    socket!.disconnect();
    socket!.dispose();
  }
}
