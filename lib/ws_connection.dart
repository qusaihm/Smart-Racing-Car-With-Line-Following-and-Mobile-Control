import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;


class WsConnection {
  final WebSocketChannel channel;
  final Stream<dynamic> stream;

  WsConnection({required this.channel})
      : stream = channel.stream.asBroadcastStream();

  void send(String msg) => channel.sink.add(msg);

  Future<void> close([int? closeCode]) async {
    await channel.sink.close(closeCode ?? status.goingAway);
  }
}