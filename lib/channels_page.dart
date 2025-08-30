import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';
import 'repository.dart';

class ChannelsPage extends StatelessWidget {
  const ChannelsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Popular Channels',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/nostr.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.onSurface,
                BlendMode.srcIn,
              ),
            ),
            onPressed: () async {
              final url = Uri.parse(
                'https://nosta.me/b22b06b051fd5232966a9344a634d956c3dc33a7f5ecdcad9ed11ddc4120a7f2',
              );
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            tooltip: 'View on Nostr',
          ),
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/github.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.onSurface,
                BlendMode.srcIn,
              ),
            ),
            onPressed: () async {
              final url = Uri.parse('https://github.com/nogringo/bitstar');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            tooltip: 'View on GitHub',
          ),
        ],
      ),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      userName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                );
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.shadow.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      // Get the visible name (without bc_ prefix if it's a geo channel)
                      final visibleName = roomName.startsWith('bc_')
                          ? roomName.substring(3)
                          : roomName;

                      // Copy visible channel name to clipboard
                      Clipboard.setData(ClipboardData(text: visibleName));

                      // Show toast notification
                      toastification.show(
                        context: context,
                        title: const Text('Channel name copied'),
                        description: Text(visibleName),
                        type: ToastificationType.success,
                        style: ToastificationStyle.flat,
                        autoCloseDuration: const Duration(seconds: 3),
                        alignment: Alignment.bottomRight,
                        showProgressBar: false,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        roomName.startsWith('bc_')
                                            ? roomName.substring(3)
                                            : roomName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                        overflow: TextOverflow.ellipsis,
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
                                        ),
                                      ),
                                    if (repo.roomLanguages[roomName] != null)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        child: Chip(
                                          label: Text(
                                            repo.roomLanguages[roomName]!,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 0,
                                          ),
                                          shape: StadiumBorder(),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.group_rounded,
                                      size: 14,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${uniqueUserPubkeys.length}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 1,
                                      height: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline
                                          .withValues(alpha: 0.3),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.chat_bubble_rounded,
                                      size: 14,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${recentMessages.length}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(spacing: 4, runSpacing: 4, children: userChips),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
