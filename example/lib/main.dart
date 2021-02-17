import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/locator.dart';
import 'services/telegram_service.dart';
import 'utils/const.dart';
import 'utils/router.dart' as route;

void main() {
  //SystemChrome.setSystemUIOverlayStyle(SystemUiOverlay.);

  WidgetsFlutterBinding.ensureInitialized();
  Provider.debugCheckInvalidValueType = null;
  setupLocator();
  runApp(
    MultiProvider(
      providers: [
        Provider<TelegramService>(
          create: (_) => TelegramService(lastRouteName: initRoute),
          lazy: false,
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  MyApp();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: locator<NavigationService>().navigatorKey,
      title: 'Flutter Demo',
      theme: ThemeData.dark(),
      onGenerateRoute: route.Router.generateRoute,
      initialRoute: initRoute,
    );
  }
}
