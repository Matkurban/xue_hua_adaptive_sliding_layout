import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/match.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/route.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/route_state.dart';

Widget _page(BuildContext context, AdaptiveRouteState state) {
  return Text(state.matchedLocation, textDirection: TextDirection.ltr);
}

List<AdaptiveRouteBase> _routes() {
  return [
    AdaptiveRoute(path: '/', redirect: (_, _) => '/mail'),
    AdaptiveRoute(
      path: '/login',
      name: 'login',
      fullscreen: true,
      builder: _page,
    ),
    AdaptiveRoute(
      path: '/photo/:id',
      name: 'photo',
      fullscreen: true,
      builder: _page,
    ),
    AdaptiveShellRoute(
      builder: (context, shell, child) => child,
      branches: [
        AdaptiveBranch(
          routes: [
            AdaptiveRoute(
              path: '/mail',
              name: 'mail',
              title: (_) => 'Mail',
              builder: _page,
              routes: [
                AdaptiveRoute(
                  path: 'compose',
                  fullscreenDialog: true,
                  builder: _page,
                ),
                AdaptiveRoute(
                  path: ':folder',
                  name: 'folder',
                  builder: _page,
                  routes: [
                    AdaptiveRoute(
                      path: ':threadId',
                      name: 'thread',
                      title: (s) => 'Thread ${s.pathParameters['threadId']}',
                      builder: _page,
                      routes: [
                        AdaptiveRoute(path: 'reply', name: 'reply', builder: _page),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        AdaptiveBranch(
          routes: [
            AdaptiveRoute(
              path: '/contacts',
              name: 'contacts',
              builder: _page,
              routes: [
                AdaptiveRoute(
                  path: ':id',
                  name: 'contact',
                  builder: _page,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ];
}

void main() {
  late RouteRegistry registry;

  setUp(() {
    registry = RouteRegistry(_routes());
  });

  group('PathPattern', () {
    test('empty pattern matches only the root', () {
      final pattern = PathPattern('/');
      expect(pattern.match(const []), isNotNull);
      expect(pattern.match(const ['mail']), isNull);
    });

    test('literal and param extract values', () {
      final pattern = PathPattern('/mail/:folder/:id');
      final hit = pattern.match(['mail', 'inbox', '42']);
      expect(hit, isNotNull);
      expect(hit!.consumed, 3);
      expect(hit.params, {'folder': 'inbox', 'id': '42'});
    });

    test('mismatch returns null', () {
      final pattern = PathPattern('/mail/:folder');
      expect(pattern.match(['contacts', '1']), isNull);
    });

    test('expand fills params and encodes', () {
      final pattern = PathPattern('/mail/:folder');
      expect(pattern.expand({'folder': 'in box'}), '/mail/in%20box');
    });

    test('expand throws when a param is missing', () {
      expect(() => PathPattern('/:id').expand({}), throwsArgumentError);
    });
  });

  group('joinPaths', () {
    test('joins relative child', () {
      expect(joinPaths('/mail', ':folder'), '/mail/:folder');
    });

    test('absolute child replaces parent', () {
      expect(joinPaths('/mail', '/login'), '/login');
    });

    test('root parent', () {
      expect(joinPaths('/', 'mail'), '/mail');
    });
  });

  group('RouteRegistry.match', () {
    test('matches nested mail thread', () {
      final list = registry.match(Uri.parse('/mail/inbox/42'));
      expect(list.error, isNull);
      expect(list.branchIndex, 0);
      expect(
        list.matches.map((m) => m.matchedLocation),
        ['/mail', '/mail/inbox', '/mail/inbox/42'],
      );
      expect(list.matches.last.pathParameters, {
        'folder': 'inbox',
        'threadId': '42',
      });
      expect(list.matches.last.title.value, 'Thread 42');
      expect(list.matches.last.name, 'thread');
    });

    test('matches query parameters', () {
      final list = registry.match(Uri.parse('/mail/inbox?ref=home'));
      expect(list.matches.last.queryParameters['ref'], 'home');
      expect(list.uri.queryParameters['ref'], 'home');
    });

    test('root path matches the redirect route', () {
      final list = registry.match(Uri.parse('/'));
      expect(list.error, isNull);
      expect(list.matches.single.matchedLocation, '/');
      expect(list.matches.single.route.redirect, isNotNull);
    });

    test('fullscreen photo is overlay', () {
      final list = registry.match(Uri.parse('/photo/9'));
      expect(list.matches.single.pathParameters['id'], '9');
      expect(list.overlayMatches, hasLength(1));
      expect(list.branchMatches, isEmpty);
    });

    test('fullscreenDialog compose overlays the mail branch', () {
      final list = registry.match(Uri.parse('/mail/compose'));
      expect(list.error, isNull);
      expect(list.branchIndex, 0);
      expect(list.last!.isOverlay, isTrue);
      expect(list.branchMatches, hasLength(1));
      expect(list.overlayMatches.single.route.fullscreenDialog, isTrue);
    });

    test('contacts branch index is 1', () {
      final list = registry.match(Uri.parse('/contacts/7'));
      expect(list.branchIndex, 1);
      expect(list.matches.map((m) => m.matchedLocation), [
        '/contacts',
        '/contacts/7',
      ]);
    });

    test('unknown path is notFound', () {
      final list = registry.match(Uri.parse('/nope'));
      expect(list.error, isNotNull);
      expect(list.matches, isEmpty);
    });

    test('first matching route wins', () {
      final local = RouteRegistry([
        AdaptiveRoute(path: '/mail/inbox', builder: _page),
        AdaptiveRoute(path: '/mail/:folder', builder: _page),
      ]);
      final list = local.match(Uri.parse('/mail/inbox'));
      expect(list.matches.single.fullPath, '/mail/inbox');
    });

    test('unmatched leftover is notFound', () {
      final list = registry.match(Uri.parse('/mail/inbox/42/nope'));
      expect(list.error, isNotNull);
    });
  });

  group('namedLocation', () {
    test('fills path and query', () {
      expect(
        registry.namedLocation(
          'thread',
          pathParameters: {'folder': 'inbox', 'threadId': '42'},
          queryParameters: {'ref': 'x'},
        ),
        '/mail/inbox/42?ref=x',
      );
    });

    test('unknown name throws', () {
      expect(() => registry.namedLocation('missing'), throwsArgumentError);
    });

    test('duplicate name throws at registry build', () {
      expect(
        () => RouteRegistry([
          AdaptiveRoute(path: '/a', name: 'x', builder: _page),
          AdaptiveRoute(path: '/b', name: 'x', builder: _page),
        ]),
        throwsArgumentError,
      );
    });
  });

  group('humanizePath', () {
    test('uses last non-param segment', () {
      expect(humanizePath('/mail/inbox'), 'Inbox');
    });
  });
}
