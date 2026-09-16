import 'package:material_ui/material_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/data/demo_data.dart';

/// 回复草稿是否未保存，供路由 [AdaptiveRoute.onExit] 读取。
final Signal<bool> mailReplyDirty = signal(false);

/// Mail 根：文件夹列表。演示 `pushNamed` 滑入下一栏。
class MailFoldersPage extends StatelessWidget {
  const MailFoldersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final router = AdaptiveRouter.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Mail')),
      body: ListView(
        children: [
          for (final entry in mailFolders.entries)
            ListTile(
              key: Key('folder-${entry.key}'),
              title: Text(entry.value),
              subtitle: const Text('pushNamed — slide in the folder pane'),
              onTap: () => router.pushNamed('/mail/${entry.key}'),
            ),
        ],
      ),
    );
  }
}

/// 文件夹会话列表。换文件夹用 `pushReplacementNamed`；打开会话用 `pushNamed`。
class MailFolderPage extends StatelessWidget {
  const MailFolderPage({super.key, required this.folder});

  final String folder;

  @override
  Widget build(BuildContext context) {
    final router = AdaptiveRouter.of(context);
    final threads = mailThreads[folder] ?? const <MailThread>[];
    return Scaffold(
      appBar: AppBar(title: Text(mailFolders[folder] ?? folder)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              children: [
                for (final entry in mailFolders.entries)
                  ActionChip(
                    key: Key('switch-folder-${entry.key}'),
                    label: Text(entry.value),
                    onPressed: () => router.pushReplacementNamed(
                      '/mail/${entry.key}',
                    ),
                  ),
              ],
            ),
          ),
          const ListTile(
            subtitle: Text(
              'Chips: pushReplacementNamed (peer replace). Rows: pushNamed (slide).',
            ),
          ),
          for (final thread in threads)
            ListTile(
              key: Key('thread-${thread.id}'),
              title: Text(thread.subject),
              subtitle: Text(thread.from),
              onTap: () => router.pushNamed(
                '/mail/$folder/${thread.id}',
                arguments: thread,
              ),
            ),
        ],
      ),
    );
  }
}

/// 会话详情。异步把面包屑改成 subject；相关会话用 pushNamed 压到栈顶对比替换。
class MailThreadPage extends StatefulWidget {
  const MailThreadPage({
    super.key,
    required this.folder,
    required this.threadId,
  });

  final String folder;
  final String threadId;

  @override
  State<MailThreadPage> createState() => _MailThreadPageState();
}

class _MailThreadPageState extends State<MailThreadPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final thread = threadById(widget.folder, widget.threadId);
      if (!mounted || thread == null) return;
      AdaptivePaneScope.maybeOf(context)?.title.value = thread.subject;
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = AdaptiveRouter.of(context);
    final state = AdaptiveRouteState.of(context);
    final thread =
        threadById(widget.folder, widget.threadId) ??
        (state.arguments is MailThread ? state.arguments as MailThread : null);
    return Scaffold(
      appBar: AppBar(title: Text(thread?.subject ?? 'Thread ${widget.threadId}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(thread?.body ?? 'Missing thread'),
          Text('query ref=${state.queryParameters['ref']}'),
          Text('arguments=${state.arguments.runtimeType}'),
          const SizedBox(height: 12),
          ListTile(
            key: const Key('open-reply'),
            title: const Text('Reply'),
            subtitle: const Text('pushNamed — deeper pane + onExit on the draft'),
            onTap: () => router.pushNamed(
              '/mail/${widget.folder}/${widget.threadId}/reply',
            ),
          ),
          ListTile(
            key: const Key('open-related'),
            title: const Text('Related thread 3'),
            subtitle: const Text('pushNamed onto the stack (not replace)'),
            onTap: () => router.pushNamed('/mail/${widget.folder}/3'),
          ),
          ListTile(
            key: const Key('open-attachment'),
            title: const Text('Open attachment photo'),
            subtitle: const Text('pushNamed fullscreen overlay'),
            onTap: () => router.pushNamed('/photo/mail-${widget.threadId}'),
          ),
        ],
      ),
    );
  }
}

/// 回复草稿。TextField 用于 keep-alive；离开走 onExit。
class MailReplyPage extends StatefulWidget {
  const MailReplyPage({
    super.key,
    required this.folder,
    required this.threadId,
  });

  final String folder;
  final String threadId;

  @override
  State<MailReplyPage> createState() => MailReplyPageState();
}

/// 暴露 [dirty] 给路由表 onExit。
class MailReplyPageState extends State<MailReplyPage> {
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    mailReplyDirty.value = false;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reply')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          key: const Key('reply-draft'),
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'Draft is kept alive when this pane slides off-screen',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => mailReplyDirty.value = true,
        ),
      ),
    );
  }
}
