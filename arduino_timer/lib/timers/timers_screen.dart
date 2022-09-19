import 'package:arduino_timer/connection_provider.dart';
import 'package:arduino_timer/timers/database.dart';
import 'package:arduino_timer/timers/timer.dart';
import 'package:arduino_timer/timers/timer_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TimersScreen extends StatefulWidget {
  static const route = '/timers';

  const TimersScreen({Key? key}) : super(key: key);

  @override
  State<TimersScreen> createState() => _TimersScreenState();
}

class _TimersScreenState extends State<TimersScreen> {
  Future<List<Timer>> futureTimers = Database.instance.getAllTimers();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.timers),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: FutureBuilder<List<Timer>>(
          future: futureTimers,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final timer = snapshot.data![index];

                  return Card(
                    child: ListTile(
                      title: Text(timer.name),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          TimerDetailsScreen.route,
                          arguments: timer,
                        ).then((_) {
                          setState(() {
                            futureTimers = Database.instance.getAllTimers();
                          });
                          final bluetooth =
                              context.read<BluetoothConnectionCubit>();

                          Database.instance.getAllTimers().then((timers) {
                            bluetooth.sendTimers(timers);
                          });
                        });
                      },
                    ),
                  );
                },
              );
            } else {
              return const CircularProgressIndicator();
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final timer = Timer.simple(
            name: AppLocalizations.of(context)!.newTimer,
          );
          Navigator.pushNamed(
            context,
            TimerDetailsScreen.route,
            arguments: timer,
          ).then((_) {
            setState(() {
              futureTimers = Database.instance.getAllTimers();
            });
            final bluetooth = context.read<BluetoothConnectionCubit>();

            Database.instance.getAllTimers().then((timers) {
              bluetooth.sendTimers(timers);
            });
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
