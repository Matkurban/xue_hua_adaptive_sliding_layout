import 'package:flutter/widgets.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_route_match_list.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_router.dart';

/// 路由信息解析器：将平台 [RouteInformation] 解析为 [AdaptiveRouteMatchList]。
class AdaptiveRouteInformationParser
    extends RouteInformationParser<AdaptiveRouteMatchList> {
  AdaptiveRouteInformationParser(this.router);

  final AdaptiveRouter router;

  @override
  Future<AdaptiveRouteMatchList> parseRouteInformationWithDependencies(
    RouteInformation routeInformation,
    BuildContext context,
  ) {
    return router.resolve(context, routeInformation.uri);
  }

  @override
  RouteInformation? restoreRouteInformation(
    AdaptiveRouteMatchList configuration,
  ) {
    return RouteInformation(uri: configuration.uri);
  }
}
