import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import 'package:logger/logger.dart';

var logger = Logger();

class ServerCommunication {
  late socket_io.Socket socket;
  bool isConnected = false;

  ServerCommunication() {
    _connectToServer();
  }

  void _connectToServer() {
    // ignore: avoid_print
    print('Connecting to socket...');

    // Replace with your Flask server address if needed
    socket = socket_io.io('http://192.168.1.42:5000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      logger.i('Connected to server');
      isConnected = true;
    });

    socket.onDisconnect((_) {
      logger.i('Disconnected from server');
      isConnected = false;
    });

    socket.on('connection_status', (data) {
      logger.i('Connection status: $data');
    });

    socket.connect();
  }

  void toggleDataGeneration(bool isGeneratingData) {
    if (isGeneratingData) {
      socket.emit('stop_data_generation');
    } else {
      socket.emit('start_data_generation');
    }
  }

  void getSingleReading(Function callback) {
    socket.emitWithAck('get_single_reading', {}, ack: (data) {
      callback(data);
    });
  }

  void onHealthData(void Function(dynamic) callback) {
    socket.on('health_data', (data) {
      logger.i('Received health data: $data');
      callback(data);
    });
  }

  void disconnect() {
    socket.disconnect();
    socket.dispose();
  }
}
