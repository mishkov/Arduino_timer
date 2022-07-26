import 'package:arduino_timer/home_page/connection_dashboard.dart';
import 'package:arduino_timer/home_page/status_bar.dart';
import 'package:arduino_timer/timers/database.dart';
import 'package:arduino_timer/timers/timers_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:arduino_timer/connection_provider.dart';

class HomePage extends StatefulWidget {
  static const route = '/';
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ардуино Таймер'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(30.0),
          child: StatusBar(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Align(
          alignment: Alignment.topCenter,
          child:
              BlocBuilder<BluetoothConnectionCubit, BluetoothConnectionState>(
            builder: (context, state) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const ConnectionDashboard(),
                  const Spacer(),
                  SizedBox(
                    width: 220,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          style: ButtonStyle(
                            padding: MaterialStateProperty.all<EdgeInsets>(
                              const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                            ),
                          ),
                          onPressed: state.status ==
                                  BluetoothConnectionStatus.connected
                              ? () {
                                  Navigator.pushNamed(
                                    context,
                                    TimersScreen.route,
                                  );
                                }
                              : null,
                          child: const Text('Таймеры'),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ButtonStyle(
                            padding: MaterialStateProperty.all<EdgeInsets>(
                              const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                            ),
                          ),
                          onPressed: state.status ==
                                  BluetoothConnectionStatus.connected
                              ? () async {
                                  final bluetooth =
                                      context.read<BluetoothConnectionCubit>();
                                  final timers =
                                      await Database.instance.getAllTimers();

                                  bluetooth.sendTimers(timers);
                                }
                              : null,
                          child: const Text('Синхронизировать'),
                        ),
                        const SizedBox(height: 180),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
