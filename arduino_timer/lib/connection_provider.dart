import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:arduino_timer/timers/timer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothConnectionCubit extends Cubit<BluetoothConnectionState> {
  final _bluetooth = FlutterBluetoothSerial.instance;
  // TODO: consider to remove this fields because they are also stored in base
  // class fields
  BluetoothConnection? _connection;
  final _devices = <BluetoothDevice>[];

  BluetoothConnectionCubit() : super(BluetoothConnectionState.initialState());

  Future<void> connectTo(BluetoothDevice device) async {
    try {
      _connection = await BluetoothConnection.toAddress(device.address);
      if (_devices.contains(device)) {
        _devices.remove(device);
        device = device.copyWith(isConnected: true);
        _devices.insert(0, device);
      }
      emit(
        state.copyWith(
          status: BluetoothConnectionStatus.connected,
          devices: _devices,
          connectedDevice: device,
        ),
      );

      _connection!.input?.listen((Uint8List data) {
        print('Data incoming: ${ascii.decode(data)}');

        // TODO: Consider to remove
        if (ascii.decode(data).contains('!')) {
          _connection!.finish();
          if (_devices.contains(device)) {
            _devices.remove(device);
            device = device.copyWith(isConnected: false);
            _devices.insert(0, device);
          }
          emit(
            state
                .copyWith(
                  status: BluetoothConnectionStatus.finished,
                  devices: _devices,
                )
                .copyWithNullConnectedDevice(),
          );
        }
      }).onDone(() {
        if (_devices.contains(device)) {
          _devices.remove(device);
          device = device.copyWith(isConnected: false);
          _devices.insert(0, device);
        }
        emit(
          state
              .copyWith(
                status: BluetoothConnectionStatus.finished,
                devices: _devices,
              )
              .copyWithNullConnectedDevice(),
        );
      });
    } catch (exception) {
      if (_devices.contains(device)) {
        _devices.remove(device);
        device = device.copyWith(isConnected: false);
        _devices.insert(0, device);
      }
      emit(
        state
            .copyWith(
              status: BluetoothConnectionStatus.finished,
              devices: _devices,
            )
            .copyWithNullConnectedDevice(),
      );
    }
  }

  Future<void> disconnect() async {
    await _connection?.finish();
    _connection?.dispose();
  }

  Future<void> scan() async {
    if (!(await _bluetooth.isEnabled ?? false)) {
      await _bluetooth.requestEnable();
    }

    final scaning = _bluetooth.startDiscovery();
    _devices.clear();
    emit(state.copyWith(devices: _devices, isScanning: true));

    scaning.listen((event) {
      _devices.add(event.device);
      emit(state.copyWith(devices: _devices));
    }, onError: (error, stackTrace) {
      log('$error -> $stackTrace');
      emit(state.copyWith(
        isScanning: false,
        status: BluetoothConnectionStatus.error,
      ));
    }, onDone: () {
      log('scanning stream is done');
      emit(state.copyWith(isScanning: false));
    });
  }

  Future<void> stopScan() async {
    await _bluetooth.cancelDiscovery();
  }

  Future<void> sendTestMessage() async {
    final oneTimer = [
      DateTime.now().hour,
      DateTime.now().minute,
      1, // статус
      19, // начальный час
      00, // начальная минута
      22, // конечный час
      00, // конечная минута
      13, // пин
      1, // значени, подаваемое на пин
    ];
    final data = Uint8List.fromList(oneTimer);
    _connection?.output.add(data); // Sending data
  }

  Future<void> sendTimers(List<Timer> timers) async {
    final package = [
      DateTime.now().hour,
      DateTime.now().minute,
      for (final timer in timers) ...timer.toBytes(),
    ];
    final data = Uint8List.fromList(package);
    _connection?.output.add(data);
  }

  Future<void> sendBytes(Uint8List bytes) async {
    _connection?.output.add(bytes);
  }
}

enum BluetoothConnectionStatus {
  connected,
  finished,
  done,
  error,
  unknown,
}

class BluetoothConnectionState {
  final BluetoothConnectionStatus status;
  final List<BluetoothDevice> devices;
  final BluetoothDevice? connectedDevice;
  final bool isScanning;

  BluetoothConnectionState(
    this.status,
    List<BluetoothDevice> devices, {
    this.connectedDevice,
    this.isScanning = false,
  }) : devices = List.from(devices);

  BluetoothConnectionState.initialState()
      : status = BluetoothConnectionStatus.unknown,
        devices = [],
        connectedDevice = null,
        isScanning = false;

  BluetoothConnectionState copyWith(
      {BluetoothConnectionStatus? status,
      List<BluetoothDevice>? devices,
      BluetoothDevice? connectedDevice,
      bool? isScanning}) {
    return BluetoothConnectionState(
      status ?? this.status,
      devices == null ? this.devices : List.from(devices),
      connectedDevice: connectedDevice ?? this.connectedDevice,
      isScanning: isScanning ?? this.isScanning,
    );
  }

  BluetoothConnectionState copyWithNullConnectedDevice() {
    return BluetoothConnectionState(
      status,
      devices,
      connectedDevice: null,
      isScanning: isScanning,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! BluetoothConnectionState) {
      return false;
    }

    if (devices.length != other.devices.length) {
      return false;
    }

    for (int i = 0; i < devices.length; i++) {
      if (devices[i].address != other.devices[i].address) {
        return false;
      }
      if (devices[i].isConnected != other.devices[i].isConnected) {
        return false;
      }
    }

    return other.status == status &&
        other.connectedDevice == connectedDevice &&
        other.isScanning == isScanning;
  }

  @override
  int get hashCode {
    return status.hashCode ^
        devices.hashCode ^
        connectedDevice.hashCode ^
        isScanning.hashCode;
  }
}

extension _DeviceCopyWith on BluetoothDevice {
  BluetoothDevice copyWith({
    String? name,
    String? address,
    BluetoothDeviceType? type = BluetoothDeviceType.unknown,
    bool? isConnected = false,
    BluetoothBondState? bondState = BluetoothBondState.unknown,
  }) {
    return BluetoothDevice(
      name: name ?? this.name,
      address: address ?? this.address,
      type: type ?? this.type,
      isConnected: isConnected ?? this.isConnected,
      bondState: bondState ?? this.bondState,
    );
  }
}
