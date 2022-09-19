import 'package:arduino_timer/home_page/available_device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import '../connection_provider.dart';
import '../sliver_list_with_contoller_layout.dart';

class ScanningDialog extends StatelessWidget {
  ScanningDialog({
    Key? key,
  }) : super(key: key);

  final availableDevicesListScrollController = ScrollController();
  final updateLayoutController = UpdateLayoutController();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child:
              BlocBuilder<BluetoothConnectionCubit, BluetoothConnectionState>(
                  builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    state.isScanning ? 'Busqueda...' : 'Encontrado',
                    style: const TextStyle(
                      fontSize: 24,
                    ),
                  ),
                ),
                Expanded(
                  child: state.devices.isNotEmpty
                      ? BlocListener<BluetoothConnectionCubit,
                          BluetoothConnectionState>(
                          listenWhen: (previous, current) {
                            return previous.devices.length !=
                                current.devices.length;
                          },
                          listener: (context, state) {
                            if (availableDevicesListScrollController
                                .hasClients) {
                              updateLayoutController.layoutUpdater?.call();
                              availableDevicesListScrollController.animateTo(
                                availableDevicesListScrollController
                                    .position.maxScrollExtent,
                                duration: const Duration(seconds: 1),
                                curve: Curves.ease,
                              );
                            }
                          },
                          child: BlocBuilder<BluetoothConnectionCubit,
                              BluetoothConnectionState>(
                            builder: (context, state) {
                              return CustomScrollView(
                                controller:
                                    availableDevicesListScrollController,
                                shrinkWrap: true,
                                slivers: [
                                  SliverListWithControlledLayout(
                                    updateLayoutController:
                                        updateLayoutController,
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final device = state.devices[index];
                                        return AvailableDevice(
                                          device: device,
                                          onConnect: () async {
                                            onAvailableDeviceSelected(
                                              context,
                                              device,
                                            );
                                          },
                                        );
                                      },
                                      childCount: state.devices.length,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        )
                      : const Text('Equipos no encontrado'),
                ),
              ],
            );
          }),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
          ),
        )
      ],
    );
  }

  Future<void> onAvailableDeviceSelected(
    BuildContext context,
    BluetoothDevice device,
  ) async {
    final connectionProvider = context.read<BluetoothConnectionCubit>();
    connectionProvider.connectTo(device).then(
      (value) {
        Navigator.pop(context);
      },
    );
  }
}
