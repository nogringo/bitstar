import 'package:bitchat_channels/config.dart';
import 'package:get/get.dart';
import 'package:ndk/ndk.dart';

class Repository extends GetxController {
  static Repository get to => Get.find();
  static Ndk get ndk => Get.find();

  Map<String, List<Nip01Event>> rooms = {};
  Map<String, String> names = {};
  Map<String, String> roomLanguages = {};
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

  String _detectLanguage(String text) {
    // Simple heuristic-based language detection
    final lowerText = text.toLowerCase();

    // Common word patterns for different languages
    if (RegExp(
      r'\b(the|and|is|are|was|were|have|has|will|can|do|does)\b',
    ).hasMatch(lowerText)) {
      return 'EN'; // English
    } else if (RegExp(
      r'\b(le|la|les|de|et|est|sont|avec|pour|dans|un|une)\b',
    ).hasMatch(lowerText)) {
      return 'FR'; // French
    } else if (RegExp(
      r'\b(el|la|los|las|de|es|son|con|para|en|un|una)\b',
    ).hasMatch(lowerText)) {
      return 'ES'; // Spanish
    } else if (RegExp(
      r'\b(der|die|das|ist|sind|mit|für|in|ein|eine)\b',
    ).hasMatch(lowerText)) {
      return 'DE'; // German
    } else if (RegExp(
      r'\b(o|a|os|as|de|é|são|com|para|em|um|uma)\b',
    ).hasMatch(lowerText)) {
      return 'PT'; // Portuguese
    } else if (RegExp(
      r'\b(il|la|le|di|è|sono|con|per|in|un|una)\b',
    ).hasMatch(lowerText)) {
      return 'IT'; // Italian
    } else if (RegExp(r'[\u4e00-\u9fff]').hasMatch(text)) {
      return 'ZH'; // Chinese
    } else if (RegExp(r'[\u3040-\u309f\u30a0-\u30ff]').hasMatch(text)) {
      return 'JA'; // Japanese
    } else if (RegExp(r'[\uac00-\ud7af]').hasMatch(text)) {
      return 'KO'; // Korean
    } else if (RegExp(r'[\u0600-\u06ff]').hasMatch(text)) {
      return 'AR'; // Arabic
    } else if (RegExp(r'[\u0400-\u04ff]').hasMatch(text)) {
      return 'RU'; // Russian/Cyrillic
    }

    return 'EN'; // Default to English
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

    // Simple language detection from message content
    if (roomLanguages[roomName] == null && event.content.isNotEmpty) {
      roomLanguages[roomName] = _detectLanguage(event.content);
    }

    if (!rooms.containsKey(roomName)) {
      rooms[roomName] = <Nip01Event>[].obs;
    }
    rooms[roomName]!.add(event);
    update();
  }
}
