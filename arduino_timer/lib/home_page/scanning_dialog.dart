import 'package:arduino_timer/home_page/available_device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
        BlocBuilder<BluetoothConnectionCubit, BluetoothConnectionState>(
            builder: (context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  state.isScanning ? 'Поиск...' : 'Обнаружено',
                  style: const TextStyle(
                    fontSize: 24,
                  ),
                ),
              ),
              state.devices.isNotEmpty
                  ? BlocListener<BluetoothConnectionCubit,
                      BluetoothConnectionState>(
                      listenWhen: (previous, current) {
                        return previous.devices.length !=
                            current.devices.length;
                      },
                      listener: (context, state) {
                        if (availableDevicesListScrollController.hasClients) {
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
                            controller: availableDevicesListScrollController,
                            shrinkWrap: true,
                            slivers: [
                              SliverListWithControlledLayout(
                                updateLayoutController: updateLayoutController,
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final device = state.devices[index];
                                    return AvailableDevice(
                                      device: device,
                                      onConnect: () {
                                        final connectionProvider = context
                                            .read<BluetoothConnectionCubit>();
                                        connectionProvider.connectTo(device);
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
                  : const Text('Устройств не обнуружено'),
            ],
          );
        }),
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('отмена'),
            ),
          ),
        )
      ],
    );
  }
}
