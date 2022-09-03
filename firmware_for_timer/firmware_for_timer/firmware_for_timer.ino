// ЗАМЕТКИ
//
// В последнем байте памяти лежит количество счетчиков
//
// Сколько скетч занимал без дебаг кода
// Sketch uses 11234 bytes (78%) of program storage space. Maximum is 14336 bytes.
// Global variables use 717 bytes (70%) of dynamic memory, leaving 307 bytes for local variables. Maximum is 1024 bytes.

#define DEBUG_SETUP false
#define DEBUG_TIMERS_COUNT false
#define DEBUG_CURRENT_TIME true
#define DEBUG_ACTIVE_TIMERS false

inline void LOG(String message) {
   Serial.print("DEBUG:");
   Serial.println(message);
}

#include <Wire.h>
#include <iarduino_RTC.h>
#include <EEPROM.h>
#include <SoftwareSerial.h>

iarduino_RTC time(RTC_DS1307);

const byte rxPin = 11;
const byte txPin = 12;
SoftwareSerial bluetoothSerial(rxPin, txPin);

void setup()
{  
  time.begin();
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

byte values;

unsigned int to_minutes(unsigned int hours, unsigned int minutes) {
  return (60*hours)+minutes;
}

void loop()
{
  if(bluetoothSerial.available() > 0)
  {
    if (DEBUG_SETUP) {
      LOG("bl recid smth");
    }
    if (nextByteType == 1) {
      values = bluetoothSerial.read();
      // считывание и установка часов
      time.settime(0,-1, values);

      nextByteType = 2;

    }
    if (nextByteType == 2) {
      values = bluetoothSerial.read();
      // считывание и установка минут
      time.settime(0, values);

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
    time.gettime();
    LOG("mnts:" + String(to_minutes(time.Hours, time.minutes)));
  }
  
  delay(500);
  // проход по каждому таймеру
  for(int i = 0; i < EEPROM.read(EEPROM.length() - 1); ++i)
  { 
    // если таймер нужно проверять
    if(EEPROM.read(i * 7 + 0) == 1)
    {
      bool find = 0;
      time.gettime();
      
      // если пришло время для работы
      if((to_minutes(EEPROM.read(i * 7 + 1), EEPROM.read(i * 7 + 2)) <= to_minutes(time.Hours, time.minutes)) &&
         (to_minutes(EEPROM.read(i * 7 + 3), EEPROM.read(i * 7 + 4)) > to_minutes(time.Hours, time.minutes))) 
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
            if((to_minutes(EEPROM.read(j * 7 + 1), EEPROM.read(j * 7 + 2)) <= to_minutes(time.Hours, time.minutes)) && 
               (to_minutes(EEPROM.read(j * 7 + 3), EEPROM.read(j * 7 + 4)) > to_minutes(time.Hours, time.minutes)))
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
