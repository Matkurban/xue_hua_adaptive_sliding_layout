/// Client entrypoint: hydrates every `@client` component (here: [App]).
library;

import 'package:jaspr/client.dart';

import 'main.client.options.dart';

void main() {
  Jaspr.initializeApp(options: defaultClientOptions);
  runApp(const ClientApp());
}
