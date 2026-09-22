sealed class RouterNames {
  ///启动页
  static const String splash = '/splash';

  ///登录
  static const String login = '/login';

  ///注册
  static const String register = '/register';

  ///首页
  static const String home = '/home';

  ///购物车
  static const String shopping = '/shopping';

  ///联系人
  static const String contacts = '/contacts';

  ///我的
  static const String mine = '/mine';

  ///主题页。挂在「我的」下面。
  static const String theme = '/mine/theme';

  ///账号页。未登录时 redirect 到登录。
  static const String account = '/mine/account';

  ///关于页。全屏对话框。
  static const String about = '/mine/about';

  ///商品详情的路由名，交给 namedLocation。
  static const String product = 'product';

  ///商品图片预览的路由名。
  static const String preview = 'preview';

  ///联系人详情的路由名。
  static const String contact = 'contact';

  ///编辑联系人备注的路由名。
  static const String contactEdit = 'contactEdit';
}
