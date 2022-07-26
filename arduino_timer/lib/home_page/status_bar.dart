import 'package:arduino_timer/connection_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StatusBar extends StatelessWidget {
  const StatusBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: BlocBuilder<BluetoothConnectionCubit, BluetoothConnectionState>(
          builder: (context, state) {
            String message;
            if (state.status == BluetoothConnectionStatus.unknown) {
              message = 'Состояние соединения незивестно';
            } else if (state.status == BluetoothConnectionStatus.connected) {
              message =
                  'Подключено к ${state.connectedDevice!.name ?? state.connectedDevice!.address}';
            } else if (state.status == BluetoothConnectionStatus.done) {
              message = 'Соединение завершено';
            } else if (state.status == BluetoothConnectionStatus.finished) {
              message = 'Соединение закончилось';
            } else if (state.status == BluetoothConnectionStatus.error) {
              message = 'Произошла ошибка';
            } else {
              message = 'Определенное состояние';
            }

            return Text(
              message,
              style: const TextStyle(
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }
}
