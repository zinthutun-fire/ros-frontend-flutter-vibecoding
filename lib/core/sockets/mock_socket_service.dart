import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'socket_service.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  return MockSocketService();
});

class MockSocketService implements SocketService {
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  final Map<String, void Function(Map<String, dynamic>)> _subscriptions = {};
  Timer? _timer;
  bool _connected = false;

  @override
  bool get isConnected => _connected;

  @override
  void connect(String token) {
    _connected = true;
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      for (final callback in _subscriptions.values) {
        callback({
          'order_no': 'ORD-${1000 + DateTime.now().millisecondsSinceEpoch % 1000}',
          'table': 'T0${DateTime.now().second % 10 + 1}',
          'kitchen_id': 1,
          'items': [
            {
              'name': 'Cheese Burger',
              'qty': 2,
              'status': 'cooking',
            }
          ],
        });
      }
    });
  }

  @override
  void disconnect() {
    _connected = false;
    _timer?.cancel();
    _subscriptions.clear();
  }

  @override
  void subscribe(String channel, void Function(Map<String, dynamic>) onEvent) {
    _subscriptions[channel] = onEvent;
  }

  @override
  void unsubscribe(String channel) {
    _subscriptions.remove(channel);
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}
