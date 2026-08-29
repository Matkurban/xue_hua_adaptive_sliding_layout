import 'package:flutter/material.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/demo_pages.dart';

/// Named routes used by the host demo.
sealed class DemoRoutes {
  static const inbox = '/inbox';
  static const thread = '/thread/:id';
  static const reply = '/reply/:id';
  static const attachment = '/attachment/:id';
  static const settings = '/settings';
  static const profile = '/profile';
  static const peer = '/peer';
  static const replaced = '/replaced';
  static const chat = '/chat';
  static const photo = '/photo';
}

/// Keys for widget tests and documented entry points.
sealed class DemoKeys {
  static const openInbox = Key('open-inbox');
  static const openThread = Key('open-thread');
  static const openReply = Key('open-reply');
  static const openAttachment = Key('open-attachment');
  static const openOtherAttachment = Key('open-other-attachment');
  static const openSettings = Key('open-settings');
  static const openPeer = Key('open-peer');
  static const openReplaced = Key('open-replaced');
  static const openChat = Key('open-chat');
  static const openPhoto = Key('open-photo');
  static const openProfile = Key('open-profile');
  static const popToRoot = Key('pop-to-root');
  static const reportTitle = Key('report-title');
  static const overlayMenu = Key('overlay-menu');
  static const navRail = Key('nav-rail');
  static const navBar = Key('nav-bar');
}

final GlobalKey<NavigatorState> demoNavKey = GlobalKey<NavigatorState>();

late SlidingShell demoShell;
late AdaptiveNavigator demoNavigator;

bool _ready = false;

void ensureDemoReady() {
  if (_ready) return;
  demoShell = SlidingShell(tabCount: 2)..init();
  demoNavigator = AdaptiveNavigator(
    isSlidingActive: () => demoShell.isSlidingActive,
    currentStack: () => demoShell.currentStack,
    buildPage: buildDemoPage,
    handlesRoute: (name) => name != DemoRoutes.photo,
    resolveTitle: resolveDemoTitle,
    fallback: const DemoNavigatorFallback(),
  );
  _ready = true;
}

/// Dispose and rebuild host state so widget tests do not leak stacks.
void resetDemo() {
  if (_ready) {
    demoShell.dispose();
  }
  _ready = false;
  ensureDemoReady();
}

String resolveDemoTitle(String name) {
  return switch (name) {
    DemoRoutes.inbox => 'Inbox',
    DemoRoutes.thread => 'Thread',
    DemoRoutes.reply => 'Reply',
    DemoRoutes.attachment => 'Attachment',
    DemoRoutes.settings => 'Settings',
    DemoRoutes.profile => 'Profile',
    DemoRoutes.peer => 'Peer',
    DemoRoutes.replaced => 'Replaced',
    DemoRoutes.chat => 'Chat',
    DemoRoutes.photo => 'Photo',
    _ => SlidingPageTitle.humanize(name),
  };
}

Widget buildDemoPage(AdaptiveRouteArgs args) {
  return switch (args.name) {
    DemoRoutes.inbox => const InboxPage(),
    DemoRoutes.thread => ThreadPage(
      id: args.pathParameters['id'] ?? '0',
      extra: args.extra,
      query: args.queryParameters,
    ),
    DemoRoutes.reply => ReplyPage(
      id: args.pathParameters['id'] ?? '0',
      extra: args.extra,
    ),
    DemoRoutes.attachment => AttachmentPage(
      id: args.pathParameters['id'] ?? '0',
      extra: args.extra,
    ),
    DemoRoutes.settings => const SettingsPage(),
    DemoRoutes.profile => const ProfilePage(),
    DemoRoutes.peer => const PeerPage(),
    DemoRoutes.replaced => const ReplacedPage(),
    DemoRoutes.chat => const ChatPage(),
    DemoRoutes.photo => const PhotoPage(),
    _ => DemoDetailPage(title: resolveDemoTitle(args.name), body: args.name),
  };
}

class DemoNavigatorFallback implements AdaptiveNavigatorFallback {
  const DemoNavigatorFallback();

  static Map<String, String> _stringify(Map<String, dynamic> query) {
    return query.map((key, value) => MapEntry(key, value.toString()));
  }

  Widget _page({
    required String name,
    Object? extra,
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
  }) {
    return buildDemoPage(
      AdaptiveRouteArgs(
        name: name,
        extra: extra,
        pathParameters: pathParameters,
        queryParameters: _stringify(queryParameters),
      ),
    );
  }

  @override
  Future<T?> push<T extends Object?>(Widget page, {BuildContext? from}) {
    final nav = from != null ? Navigator.of(from) : demoNavKey.currentState!;
    return nav.push<T>(MaterialPageRoute<T>(builder: (_) => page));
  }

  @override
  Future<T?> pushNamed<T extends Object?>(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) {
    return demoNavKey.currentState!.push<T>(
      MaterialPageRoute<T>(
        builder: (_) => _page(
          name: name,
          extra: extra,
          pathParameters: pathParameters,
          queryParameters: queryParameters,
        ),
      ),
    );
  }

  @override
  Future<T?> pushReplacement<T extends Object?>(
    Widget page, {
    BuildContext? from,
  }) {
    final nav = from != null ? Navigator.of(from) : demoNavKey.currentState!;
    return nav.pushReplacement<T, T>(
      MaterialPageRoute<T>(builder: (_) => page),
    );
  }

  @override
  Future<T?> pushReplacementNamed<T extends Object?>(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
    String? fragment,
  }) {
    return demoNavKey.currentState!.pushReplacement<T, T>(
      MaterialPageRoute<T>(
        builder: (_) => _page(
          name: name,
          extra: extra,
          pathParameters: pathParameters,
          queryParameters: queryParameters,
        ),
      ),
    );
  }

  @override
  Future<T?> pushAndRemoveUntil<T extends Object?>(
    Widget page,
    bool Function(SlidingWindowPage page) predicate, {
    BuildContext? from,
  }) {
    return pushReplacement<T>(page, from: from);
  }

  @override
  Future<T?> pushNamedAndRemoveUntil<T extends Object?>(
    String name,
    bool Function(SlidingWindowPage page) predicate, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) {
    return pushReplacementNamed<T>(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );
  }

  @override
  void pop<T extends Object?>([T? result]) {
    demoNavKey.currentState?.pop<T>(result);
  }

  @override
  bool canPop() => demoNavKey.currentState?.canPop() ?? false;

  @override
  bool popToRoot() {
    final nav = demoNavKey.currentState;
    if (nav == null) return false;
    nav.popUntil((route) => route.isFirst);
    return true;
  }
}
