import 'dart:convert';
import 'dart:typed_data';

class Timer {
  final int id;
  final String name;
  final int beginHour;
  final int beginMinute;
  final int endHour;
  final int endMinute;
  final int pin;
  final int pinValue;
  final bool isActive;

  Timer(this.id, this.name, this.beginHour, this.beginMinute, this.endHour,
      this.endMinute, this.pin, this.pinValue, this.isActive);

  Timer.simple({
    this.id = -1,
    this.name = 'Новый таймер',
    this.beginHour = 8,
    this.beginMinute = 0,
    this.endHour = 18,
    this.endMinute = 0,
    this.pin = 13,
    this.pinValue = 1,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'beginHour': beginHour,
      'beginMinute': beginMinute,
      'endHour': endHour,
      'endMinute': endMinute,
      'pin': pin,
      'pinValue': pinValue,
      'isActive': isActive ? 1 : 0,
    };
  }

  Uint8List toBytes() {
    return Uint8List.fromList([
      isActive ? 1 : 0,
      beginHour,
      beginMinute,
      endHour,
      endMinute,
      pin,
      pinValue
    ]);
  }

  Timer.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        name = map['name'],
        beginHour = map['beginHour'],
        beginMinute = map['beginMinute'],
        endHour = map['endHour'],
        endMinute = map['endMinute'],
        pin = map['pin'],
        pinValue = map['pinValue'],
        isActive = map['isActive'] == 0 ? false : true;

  String toJson() => json.encode(toMap());

  factory Timer.fromJson(String source) => Timer.fromMap(json.decode(source));
}
