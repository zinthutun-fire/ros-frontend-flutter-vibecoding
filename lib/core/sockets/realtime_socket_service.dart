import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/constants/api_constants.dart';
import 'socket_service.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = RealtimeSocketService();
  ref.onDispose(() => service.disconnect());
  return service;
});

class RealtimeSocketService implements SocketService {
  WebSocketChannel? _channel;
  final Map<String, List<void Function(Map<String, dynamic>)>> _subscriptions = {};
  StreamSubscription<dynamic>? _subscription;
  bool _connected = false;
  String? _appKey;
  Timer? _pingTimer;

  @override
  bool get isConnected => _connected;

  @override
  void connect(String token) {
    _appKey = ApiConstants.reverbAppKey;
    final wsUrl = '${ApiConstants.reverbWsUrl}/app/$_appKey?protocol=7&client=flutter&version=1.0';

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _subscription = _channel!.stream.listen(_onMessage, onDone: _onDone, onError: _onError);
      _startPing();
    } catch (e) {
      _connected = false;
    }
  }

  @override
  void disconnect() {
    _pingTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _connected = false;
    _subscriptions.clear();
  }

  @override
  void subscribe(String channel, void Function(Map<String, dynamic>) onEvent) {
    _subscriptions.putIfAbsent(channel, () => []);
    _subscriptions[channel]!.add(onEvent);
    if (_connected && _channel != null) {
      _send({
        'event': 'pusher:subscribe',
        'data': {'channel': channel},
      });
    }
  }

  @override
  void unsubscribe(String channel) {
    _subscriptions.remove(channel);
    if (_connected && _channel != null) {
      _send({
        'event': 'pusher:unsubscribe',
        'data': {'channel': channel},
      });
    }
  }

  void _send(Map<String, dynamic> message) {
    try {
      _channel?.sink.add(jsonEncode(message));
    } catch (_) {}
  }

  void _onMessage(dynamic raw) {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final event = data['event'] as String?;

    if (event == 'pusher:connection_established') {
      _connected = true;
      _resubscribeAll();
      return;
    }

    if (event == 'pusher:ping') {
      _send({'event': 'pusher:pong', 'data': {}});
      return;
    }

    final channelName = data['channel'] as String?;
    final eventData = data['data'];
    if (channelName != null && eventData != null) {
      Map<String, dynamic> parsedData;
      if (eventData is String) {
        try {
          parsedData = jsonDecode(eventData) as Map<String, dynamic>;
        } catch (_) {
          return;
        }
      } else {
        try {
          parsedData = eventData as Map<String, dynamic>;
        } catch (_) {
          return;
        }
      }
      parsedData['_event'] = event;
      var callbacks = _subscriptions[channelName];
      if (callbacks == null) {
        final dotIndex = channelName.lastIndexOf('.');
        if (dotIndex > 0) {
          final prefix = channelName.substring(0, dotIndex);
          callbacks = _subscriptions['$prefix.*'];
        }
      }
      if (callbacks != null) {
        for (final cb in callbacks) {
          try {
            cb(parsedData);
          } catch (_) {}
        }
      }
    }
  }

  void _onDone() {
    _connected = false;
    _pingTimer?.cancel();
  }

  void _onError(Object error) {
    _connected = false;
    _pingTimer?.cancel();
  }

  void _resubscribeAll() {
    for (final channel in _subscriptions.keys) {
      _send({
        'event': 'pusher:subscribe',
        'data': {'channel': channel},
      });
    }
  }

  void _startPing() {
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_connected) {
        _send({'event': 'pusher:ping', 'data': {}});
      }
    });
  }
}
