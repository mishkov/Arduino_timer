import 'package:arduino_timer/connection_provider.dart';
import 'package:arduino_timer/home_page/scanning_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConnectionDashboard extends StatelessWidget {
  const ConnectionDashboard({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final connectionProvider = context.read<BluetoothConnectionCubit>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        BlocBuilder<BluetoothConnectionCubit, BluetoothConnectionState>(
          builder: (context, state) {
            return ElevatedButton(
              onPressed: state.connectedDevice != null
                  ? connectionProvider.disconnect
                  : null,
              child: const Text('Desconectar'),
            );
          },
        ),
        const SizedBox(
          width: 8,
        ),
        ElevatedButton(
          onPressed: () {
            connectionProvider.scan();
            showDialog(
              context: context,
              builder: (context) {
                return const Dialog(
                  child: ScanningDialog(),
                );
              },
            );
            connectionProvider.stopScan();
          },
          child: const Text('Escanear'),
        ),
      ],
    );
  }
}
