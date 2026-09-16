import 'package:signals_flutter/signals_flutter.dart';

/// 示例用的登录态。真实应用换成自己的 auth 服务。
final Signal<bool> signedIn = signal(false);
