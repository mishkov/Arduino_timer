// ЗАМЕТКИ
//
// В последнем байте памяти лежит количество счетчиков
//
// Подключение блютуз модуля: 
// HC-O5    Arduino
// VCC   ->      5V
// GND   ->     GND
// TXD   ->     D11
// RXD   ->     D12

#define DEBUG_SETUP false
#define DEBUG_TIMERS_COUNT false
#define DEBUG_CURRENT_TIME false
#define DEBUG_ACTIVE_TIMERS false

inline void LOG(String message) {
   Serial.print("DEBUG:");
   Serial.println(message);
}

#include <RTClib.h>
#include <EEPROM.h>
#include <SoftwareSerial.h>

RTC_DS3231 rtc;

const byte rxPin = 11;
const byte txPin = 12;
SoftwareSerial bluetoothSerial(rxPin, txPin);

void setup()
{  
#ifndef ESP8266
  while (!Serial); // wait for serial port to connect. Needed for native USB
#endif

  if (!rtc.begin()) {
    Serial.println("Couldn't find RTC");
    Serial.flush();
    while (1) delay(10);
  }

  if (rtc.lostPower()) {
    Serial.println("RTC lost power, let's set the time!");
    // When time needs to be set on a new device, or after a power loss, the
    // following line sets the RTC to the date & time this sketch was compiled
    rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));
  }
  
  Serial.begin(9600);
  bluetoothSerial.begin(9600);
  if (DEBUG_TIMERS_COUNT) {
    LOG("setup:tms_cnt:" + EEPROM.read(EEPROM.length() - 1));
  }

  if (DEBUG_ACTIVE_TIMERS) {
    for(int i = 0; i < EEPROM.read(EEPROM.length() - 1); ++i) {
      LOG(String("setup:acttm:" + i) + "=" + EEPROM.read(i * 7));
    }
  }
}

// 1 - hour
// 2 - minute
// 3 - timer data
int nextByteType = 1;
int hour;
byte values;
bool isInSyncMode = false;

unsigned int to_minutes(unsigned int hours, unsigned int minutes) {
  return (60*hours)+minutes;
}

void loop()
{
  if(bluetoothSerial.available() > 0)
  {
    isInSyncMode = true;
    if (DEBUG_SETUP) {
      LOG("bl recid smth");
    }
    if (nextByteType == 1) {
      values = bluetoothSerial.read();
      // считывание часов
      hour = values;

      nextByteType = 2;

    }
    if (nextByteType == 2) {
      // TODO: Add check for returned value
      values = bluetoothSerial.read();
      // считывание и установка времени
      rtc.adjust(DateTime(2022, 1, 1, hour, values, 0));
      
      nextByteType = 3;
      
      // очищаем энергонезависимую память
      for (int i = 0 ; i < EEPROM.length() ; i++)
      {
        EEPROM.write(i, 0);
      }
    }

    int i = 0;
    while(nextByteType == 3) {
      while(bluetoothSerial.available() > 0) {
        values = bluetoothSerial.read();
        if (values == 255) {
          nextByteType = 1;
          return;
        }
        
        EEPROM.write(EEPROM.read(EEPROM.length() - 1) * 7 + i, values);

        i++;
        if (i == 7) {
          i = 0;
          EEPROM.write(EEPROM.length() - 1, EEPROM.read(EEPROM.length() - 1) + 1);
        }
      }
    }

    isInSyncMode = false;

    if (DEBUG_TIMERS_COUNT) {
      LOG("setup:tms_cnt:" + EEPROM.read(EEPROM.length() - 1));
    }

    if (DEBUG_ACTIVE_TIMERS) {
      for(int i = 0; i < EEPROM.read(EEPROM.length() - 1); ++i) {
        LOG(String("setup:acttm:" + i) + "=" + EEPROM.read(i * 7));
      }
    }
  }

  if (DEBUG_CURRENT_TIME) {
    DateTime now = rtc.now();
    LOG("mnts:" + String(to_minutes(now.hour(), now.minute())));
  }
  
  delay(500);
  // проход по каждому таймеру
  for(int i = 0; i < EEPROM.read(EEPROM.length() - 1); ++i)
  { 
    // если таймер нужно проверять
    if(EEPROM.read(i * 7 + 0) == 1)
    {
      bool find = 0;
      DateTime now = rtc.now();
      
      // если пришло время для работы
      if((to_minutes(EEPROM.read(i * 7 + 1), EEPROM.read(i * 7 + 2)) <= to_minutes(now.hour(), now.minute())) &&
         (to_minutes(EEPROM.read(i * 7 + 3), EEPROM.read(i * 7 + 4)) > to_minutes(now.hour(), now.minute()))) 
      {
        // настраиваем пин таймера как выход
        pinMode(EEPROM.read(i * 7 + 5), OUTPUT);
        // посылаем на пин нужное значение
        digitalWrite(EEPROM.read(i * 7 + 5), EEPROM.read(i * 7 + 6));
      }
      // иначе если время не пришло
      else
      {
        // ищем таймер с таким же пином
        for (int j = 0; j < EEPROM.read(EEPROM.length() - 1); ++j)
        {
          if(EEPROM.read(i * 7 + 5) == EEPROM.read(j * 7 + 5) && (i != j) && (EEPROM.read(j * 7 + 0) == 1))
          {
            // и если нашли таймер с таким же пином и если для него время пришло
            if((to_minutes(EEPROM.read(j * 7 + 1), EEPROM.read(j * 7 + 2)) <= to_minutes(now.hour(), now.minute())) && 
               (to_minutes(EEPROM.read(j * 7 + 3), EEPROM.read(j * 7 + 4)) > to_minutes(now.hour(), now.minute())))
            {
              // настраиваем пин таймера как выход
              pinMode(EEPROM.read(i * 7 + 5), OUTPUT);
              // посылаем на пин нужное значение
              digitalWrite(EEPROM.read(i * 7 + 5), EEPROM.read(j * 7 + 6));
              find = 1;
            }
          }
        }

        // если таймер с таким же пином не найден
        if(find == 0)
        {
          // настраиваем пин таймера как выход
          pinMode(EEPROM.read(i * 7 + 5), OUTPUT);
          // посылаем на пин значение протиаоположное нужному
          digitalWrite(EEPROM.read(i * 7 + 5), !EEPROM.read(i * 7 + 6));
        }
      }
    }
  }
}
