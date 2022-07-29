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
              message = 'Estado de conexion desconocido';
            } else if (state.status == BluetoothConnectionStatus.connected) {
              message =
                  'Conectado con ${state.connectedDevice!.name ?? state.connectedDevice!.address}';
            } else if (state.status == BluetoothConnectionStatus.done) {
              message = 'Conexion terminada';
            } else if (state.status == BluetoothConnectionStatus.finished) {
              message = 'Conexion terminada';
            } else if (state.status == BluetoothConnectionStatus.error) {
              message = 'Sucedio un error';
            } else {
              message = 'Estado desconocido';
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
