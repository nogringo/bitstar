import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ndk/ndk.dart';
import 'channels_page.dart';
import 'repository.dart';

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

  final repository = Repository();
  Get.put(repository);
  repository.listenRooms();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: "Bitstar",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const ChannelsPage(),
    );
  }
}
