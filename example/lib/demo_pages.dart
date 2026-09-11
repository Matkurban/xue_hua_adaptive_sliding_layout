import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/demo.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: ListView(
        children: [
          ListTile(
            key: DemoKeys.openInbox,
            title: const Text('Inbox'),
            subtitle: const Text('pushNamed from root — peer replace'),
            onTap: () =>
                demoNavigator.pushNamed(DemoRoutes.inbox, from: context),
          ),
          ListTile(
            key: DemoKeys.openSettings,
            title: const Text('Settings widget'),
            subtitle: const Text('push — pane split'),
            onTap: () => demoNavigator.push(
              const SettingsPage(),
              name: DemoRoutes.settings,
              title: 'Settings',
              from: context,
            ),
          ),
          ListTile(
            key: DemoKeys.openPeer,
            title: const Text('Peer'),
            subtitle: const Text('pushAndRemoveUntil — [root, peer]'),
            onTap: () => demoNavigator.pushAndRemoveUntil(
              const PeerPage(),
              AdaptiveNavigator.untilRoot,
              name: DemoRoutes.peer,
              title: 'Peer',
            ),
          ),
          ListTile(
            key: DemoKeys.openReplaced,
            title: const Text('Replace top'),
            subtitle: const Text('pushReplacementNamed — swap stack top only'),
            onTap: () =>
                demoNavigator.pushReplacementNamed(DemoRoutes.replaced),
          ),
          ListTile(
            key: DemoKeys.openChat,
            title: const Text('Chat-like'),
            subtitle: const Text('pushNamedAndRemoveUntil + switch tab'),
            onTap: () {
              demoShell.changePage(1);
              demoNavigator.pushNamedAndRemoveUntil(
                DemoRoutes.chat,
                AdaptiveNavigator.untilRoot,
              );
            },
          ),
          ListTile(
            key: DemoKeys.openPhoto,
            title: const Text('Photo'),
            subtitle: const Text('handlesRoute false — always fullscreen'),
            onTap: () =>
                demoNavigator.pushNamed(DemoRoutes.photo, from: context),
          ),
          ListTile(
            key: DemoKeys.popToRoot,
            title: const Text('Pop to root'),
            onTap: () => demoNavigator.popToRoot(),
          ),
        ],
      ),
    );
  }
}

class ExploreTab extends StatelessWidget {
  const ExploreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: ListView(
        children: [
          ListTile(
            key: DemoKeys.openProfile,
            title: const Text('Profile'),
            onTap: () =>
                demoNavigator.pushNamed(DemoRoutes.profile, from: context),
          ),
        ],
      ),
    );
  }
}

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoDetailPage(
      title: 'Inbox',
      body: 'Message list',
      children: [
        ListTile(
          key: DemoKeys.openThread,
          title: const Text('Open thread'),
          onTap: () => demoNavigator.pushNamed(
            DemoRoutes.thread,
            pathParameters: const {'id': '42'},
            queryParameters: const {'ref': 'inbox'},
            extra: 'hello-extra',
            from: context,
          ),
        ),
        ListTile(
          key: DemoKeys.reportTitle,
          title: const Text('Report title'),
          onTap: () => SlidingPageTitle.maybeOf(context)?.report('Alice'),
        ),
        ListTile(
          key: const Key('inbox-open-peer'),
          title: const Text('Open peer from inbox'),
          onTap: () => demoNavigator.pushAndRemoveUntil(
            const PeerPage(),
            AdaptiveNavigator.untilRoot,
            name: DemoRoutes.peer,
            title: 'Peer',
          ),
        ),
        ListTile(
          key: const Key('inbox-replace-top'),
          title: const Text('Replace top from inbox'),
          onTap: () => demoNavigator.pushReplacementNamed(DemoRoutes.replaced),
        ),
        ListTile(
          key: const Key('inbox-pop-to-root'),
          title: const Text('Pop to root from inbox'),
          onTap: () => demoNavigator.popToRoot(),
        ),
      ],
    );
  }
}

class ThreadPage extends StatelessWidget {
  const ThreadPage({
    super.key,
    required this.id,
    this.extra,
    this.query = const {},
  });

  final String id;
  final Object? extra;
  final Map<String, String> query;

  @override
  Widget build(BuildContext context) {
    return DemoDetailPage(
      title: 'Thread',
      body: 'thread-id:$id',
      children: [
        Text('thread-extra:$extra', key: const Key('thread-extra')),
        Text('thread-ref:${query['ref']}', key: const Key('thread-ref')),
        ListTile(
          key: DemoKeys.openReply,
          title: const Text('Open reply'),
          onTap: () => demoNavigator.pushNamed(
            DemoRoutes.reply,
            pathParameters: {'id': id},
            extra: extra,
            from: context,
          ),
        ),
      ],
    );
  }
}

class ReplyPage extends StatelessWidget {
  const ReplyPage({super.key, required this.id, this.extra});

  final String id;
  final Object? extra;

  @override
  Widget build(BuildContext context) {
    return DemoDetailPage(
      title: 'Reply',
      body: 'reply-id:$id',
      children: [
        Text('reply-extra:$extra', key: const Key('reply-extra')),
        ListTile(
          key: DemoKeys.openAttachment,
          title: const Text('Open attachment'),
          onTap: () => demoNavigator.pushNamed(
            DemoRoutes.attachment,
            pathParameters: {'id': '1'},
            extra: 'file-a',
            from: context,
          ),
        ),
        ListTile(
          key: DemoKeys.openOtherAttachment,
          title: const Text('Open other attachment'),
          onTap: () => demoNavigator.pushNamed(
            DemoRoutes.attachment,
            pathParameters: const {'id': '99'},
            extra: 'other-file',
            from: context,
          ),
        ),
        ListTile(
          key: const Key('reply-pop-to-root'),
          title: const Text('Pop to root from reply'),
          onTap: () => demoNavigator.popToRoot(),
        ),
      ],
    );
  }
}

class AttachmentPage extends StatelessWidget {
  const AttachmentPage({super.key, required this.id, this.extra});

  final String id;
  final Object? extra;

  @override
  Widget build(BuildContext context) {
    return DemoDetailPage(
      title: 'Attachment',
      body: 'attachment-id:$id',
      children: [
        Text('attachment-extra:$extra', key: const Key('attachment-extra')),
      ],
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DemoDetailPage(title: 'Settings', body: 'Preferences');
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DemoDetailPage(title: 'Profile', body: 'Account');
  }
}

class PeerPage extends StatelessWidget {
  const PeerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DemoDetailPage(title: 'Peer', body: 'Replaces the right pane');
  }
}

class ReplacedPage extends StatelessWidget {
  const ReplacedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DemoDetailPage(title: 'Replaced', body: 'Stack top only');
  }
}

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DemoDetailPage(title: 'Chat', body: 'Peer chat on Explore');
  }
}

class PhotoPage extends StatelessWidget {
  const PhotoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DemoDetailPage(
      title: 'Photo fullscreen',
      body: 'Not intercepted',
    );
  }
}

class DemoDetailPage extends StatelessWidget {
  const DemoDetailPage({
    super.key,
    required this.title,
    required this.body,
    this.children = const [],
  });

  final String title;
  final String body;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: inSlidingWindow(context) ? const SlidingBackButton() : null,
        actions: [
          PopupMenuButton<String>(
            key: title == 'Inbox'
                ? DemoKeys.overlayMenu
                : Key('overlay-menu-$title'),
            useRootNavigator: inSlidingWindow(context),
            itemBuilder: (context) => const [
              PopupMenuItem<String>(value: 'pin', child: Text('Pin')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [Text(body), ...children],
      ),
    );
  }
}
