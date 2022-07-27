import 'package:arduino_timer/timers/database.dart' as localdb;
import 'package:arduino_timer/connection_provider.dart';
import 'package:arduino_timer/timers/timer.dart';
import 'package:arduino_timer/timers/timer_details_screen.dart';
import 'package:arduino_timer/timers/timers_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'home_page/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  localdb.Database.instance.init();
  runApp(
    BlocProvider(
      create: (context) => BluetoothConnectionCubit(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    final mySystemTheme = SystemUiOverlayStyle.light.copyWith(
      systemNavigationBarColor: Colors.blue,
      systemNavigationBarDividerColor: Colors.blue,
      systemNavigationBarIconBrightness: Brightness.light,
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: mySystemTheme,
      child: MaterialApp(
        title: 'Arduino Timer',
        initialRoute: HomePage.route,
        onGenerateRoute: (routeSettings) {
          return MaterialPageRoute(
            builder: (context) {
              if (routeSettings.name == TimersScreen.route) {
                return const TimersScreen();
              }
              if (routeSettings.name == TimerDetailsScreen.route) {
                return TimerDetailsScreen(
                  timer: routeSettings.arguments as Timer,
                );
              } else {
                return const HomePage();
              }
            },
          );
        },
      ),
    );
  }
}
