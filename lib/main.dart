import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ndk/ndk.dart';

class NoEventVerifier extends EventVerifier {
  @override
  Future<bool> verify(Nip01Event event) async {
    return true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final ndk = Ndk(
    NdkConfig(
      eventVerifier: NoEventVerifier(),
      cache: MemCacheManager(),
      bootstrapRelays: [
        "wss://relay.primal.net",
        "wss://relay.damus.io",
        "wss://nos.lol",
        "wss://relay.snort.social",
        "wss://nostr21.com",
        "wss://offchain.pub",
      ],
    ),
  );
  Get.put(ndk);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Hello World!'),
        ),
      ),
    );
  }
}
