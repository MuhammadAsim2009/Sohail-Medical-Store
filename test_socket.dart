import 'dart:io';

void main() async {
  try {
    print('Testing Socket.connect...');
    final socket = await Socket.connect('firestore.googleapis.com', 443, timeout: const Duration(seconds: 3));
    print('Success! Remote address: ${socket.remoteAddress}');
    socket.destroy();
  } catch (e) {
    print('Failed: $e');
  }
}
