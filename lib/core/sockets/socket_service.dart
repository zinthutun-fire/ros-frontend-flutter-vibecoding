abstract class SocketService {
  void connect(String token);
  void disconnect();
  void subscribe(String channel, void Function(Map<String, dynamic>) onEvent);
  void unsubscribe(String channel);
  bool get isConnected;
}
