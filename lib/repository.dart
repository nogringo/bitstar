import 'package:bitchat_channels/config.dart';
import 'package:get/get.dart';
import 'package:ndk/ndk.dart';

class Repository extends GetxController {
  static Repository get to => Get.find();
  static Ndk get ndk => Get.find();

  Map<String, List<Nip01Event>> rooms = {};
  Map<String, String> names = {};
  NdkResponse? roomsSubscription;

  List<String> getPopularRooms() {
    final timeWindowAgo = DateTime.now().subtract(
      Duration(minutes: popularRoomTimeWindowMinutes),
    );

    final popularRooms =
        rooms.entries
            .map((entry) {
              // Get messages from time window
              final recentMessages = entry.value.where((event) {
                final eventTime = DateTime.fromMillisecondsSinceEpoch(
                  event.createdAt * 1000,
                );
                return eventTime.isAfter(timeWindowAgo);
              }).toList();

              // Count unique users
              final uniqueUsers = recentMessages
                  .map((event) => event.pubKey)
                  .toSet()
                  .length;

              // Room is popular if it meets the configured criteria
              final isPopular =
                  recentMessages.length >= popularRoomMinMessages &&
                  uniqueUsers >= popularRoomMinUniqueUsers;

              return MapEntry(entry.key, isPopular ? recentMessages.length : 0);
            })
            .where(
              (entry) => entry.value > 0,
            ) // Only rooms meeting the criteria
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return popularRooms.map((entry) => entry.key).toList();
  }

  listenRooms() {
    if (roomsSubscription != null) return;

    roomsSubscription = ndk.requests.subscription(
      filters: [
        Filter(
          kinds: [20000, 23333],
          since: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ),
      ],
    );

    roomsSubscription!.stream.listen(onEvent);
  }

  onEvent(Nip01Event event) async {
    final uid = event.pubKey.substring(event.pubKey.length - 4);
    final nTag = event.getFirstTag("n");
    final metadata = await ndk.metadata.loadMetadata(event.pubKey);
    final anonName = "Anon#$uid";

    if (metadata != null) {
      names[event.pubKey] = metadata.displayName ?? metadata.name ?? anonName;
    } else if (nTag != null) {
      names[event.pubKey] = "$nTag#$uid";
    } else {
      names[event.pubKey] = anonName;
    }

    String? gTag = event.getFirstTag("g");
    if (gTag != null) gTag = "bc_$gTag";

    final dTag = event.getFirstTag("d");

    final roomName = gTag ?? dTag;
    if (roomName == null) return;

    if (!rooms.containsKey(roomName)) {
      rooms[roomName] = <Nip01Event>[].obs;
    }
    rooms[roomName]!.add(event);
    update();
  }
}
