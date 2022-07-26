import 'package:arduino_timer/timers/database.dart';
import 'package:arduino_timer/timers/timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TimerDetailsScreen extends StatefulWidget {
  static const route = '/timer_details';

  const TimerDetailsScreen({Key? key, required this.timer}) : super(key: key);

  final Timer timer;

  @override
  State<TimerDetailsScreen> createState() => _TimerDetailsScreenState();
}

class _TimerDetailsScreenState extends State<TimerDetailsScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController beginHourController = TextEditingController();
  TextEditingController endHourController = TextEditingController();
  TextEditingController beginMinuteController = TextEditingController();
  TextEditingController endMinuteController = TextEditingController();
  TextEditingController pinController = TextEditingController();
  int timerPinValue = 0;
  bool isTimerActive = true;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController.fromValue(
      TextEditingValue(text: widget.timer.name),
    );
    beginHourController = TextEditingController.fromValue(
      TextEditingValue(text: widget.timer.beginHour.toString()),
    );
    beginMinuteController = TextEditingController.fromValue(
      TextEditingValue(text: widget.timer.beginMinute.toString()),
    );
    endHourController = TextEditingController.fromValue(
      TextEditingValue(text: widget.timer.endHour.toString()),
    );
    endMinuteController = TextEditingController.fromValue(
      TextEditingValue(text: widget.timer.endMinute.toString()),
    );
    pinController = TextEditingController.fromValue(
      TextEditingValue(text: widget.timer.pin.toString()),
    );

    timerPinValue = widget.timer.pinValue;
    isTimerActive = widget.timer.isActive;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Редактирование таймера')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('имя'),
            TextField(controller: nameController),
            const SizedBox(height: 8),
            const Text('от'),
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    controller: beginHourController,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 100,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    controller: beginMinuteController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('до'),
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    controller: endHourController,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 100,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    controller: endMinuteController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('подавать на пин'),
            TextField(
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              controller: pinController,
            ),
            const SizedBox(height: 8),
            const Text('значение'),
            DropdownButton<int>(
              value: timerPinValue,
              items: List.generate(2, (index) {
                return DropdownMenuItem(
                  value: index,
                  child: Text(index.toString()),
                );
              }),
              onChanged: (value) {
                setState(() {
                  timerPinValue = value ?? 0;
                });
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('состояние'),
                Switch(
                  value: isTimerActive,
                  onChanged: (value) {
                    setState(() {
                      isTimerActive = value;
                    });
                  },
                )
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Database.instance.deleteTimer(widget.timer.id);
                      Navigator.pop(context);
                    },
                    child: const Text('Удалить'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Timer? timer;
                      try {
                        timer = Timer(
                          widget.timer.id,
                          nameController.text,
                          int.parse(beginHourController.text),
                          int.parse(beginMinuteController.text),
                          int.parse(endHourController.text),
                          int.parse(endMinuteController.text),
                          int.parse(pinController.text),
                          timerPinValue,
                          isTimerActive,
                        );
                      } catch (e) {
                        const snackBar = SnackBar(
                          content: Text('неверный формат данных'),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      }

                      if (timer != null) {
                        if (widget.timer.id >= 1) {
                          Database.instance.updateTimer(timer);
                        } else {
                          Database.instance.insertTimer(timer);
                        }

                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Сохранить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
