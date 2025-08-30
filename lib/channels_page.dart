import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'repository.dart';

class ChannelsPage extends StatelessWidget {
  const ChannelsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Popular Channels'), centerTitle: true),
      body: GetBuilder<Repository>(
        builder: (repo) {
          final popularRooms = repo.getPopularRooms();

          if (popularRooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.forum_outlined,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No popular rooms at the moment',
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rooms will appear here when they become active',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: popularRooms.length,
            itemBuilder: (context, index) {
              final roomName = popularRooms[index];
              final roomMessages = repo.rooms[roomName] ?? [];
              final recentMessages = roomMessages.where((event) {
                final eventTime = DateTime.fromMillisecondsSinceEpoch(
                  event.createdAt * 1000,
                );
                return eventTime.isAfter(
                  DateTime.now().subtract(const Duration(minutes: 5)),
                );
              }).toList();

              final uniqueUserPubkeys = recentMessages
                  .map((event) => event.pubKey)
                  .toSet()
                  .toList();

              final userChips = <Widget>[];
              for (final pubkey in uniqueUserPubkeys) {
                final userName = repo.names[pubkey] ?? 'Unknown';
                userChips.add(
                  Chip(
                    label: Text(userName, style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0,
                    ),
                    shape: const StadiumBorder(),
                  ),
                );
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              roomName.startsWith('bc_')
                                  ? roomName.substring(3)
                                  : roomName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (roomName.startsWith('bc_'))
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                child: Chip(
                                  label: Text(
                                    'GEO',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
                                    ),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 0,
                                  ),
                                  shape: const StadiumBorder(),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${uniqueUserPubkeys.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.message,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${recentMessages.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  subtitle: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: userChips,
                  ),
                  isThreeLine: true,
                  onTap: () {
                    // TODO: Navigate to room detail page
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
