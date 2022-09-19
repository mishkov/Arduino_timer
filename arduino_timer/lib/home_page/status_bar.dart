import 'package:arduino_timer/connection_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
              message = AppLocalizations.of(context)!.unknownConnectionState;
            } else if (state.status == BluetoothConnectionStatus.connected) {
              message =
                  '${AppLocalizations.of(context)!.connectedTo} ${state.connectedDevice!.name ?? state.connectedDevice!.address}';
            } else if (state.status == BluetoothConnectionStatus.done) {
              message = AppLocalizations.of(context)!.doneConnection;
            } else if (state.status == BluetoothConnectionStatus.finished) {
              message = AppLocalizations.of(context)!.endConnection;
            } else if (state.status == BluetoothConnectionStatus.error) {
              message = AppLocalizations.of(context)!.errorOccured;
            } else {
              message = AppLocalizations.of(context)!.undefinedState;
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
