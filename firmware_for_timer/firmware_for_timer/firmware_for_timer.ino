// ЗАМЕТКИ
//
// В последнем байте памяти лежит количество счетчиков

#include <Wire.h>
#include <iarduino_RTC.h>
#include <EEPROM.h>
#include <SoftwareSerial.h>

class Clock {
  public:
    int minutes = 0;
    int Hours = 0;
    
    void begin();
    void settime(int seconds = -1 , int minutes = -1, int hours = -1);
    void gettime();
};

void Clock::begin() {}

void Clock::settime(int seconds = -1 , int minutes = -1, int hours = -1) {
  if (minutes > 0 ) {
    this->minutes = minutes;
  }
  if (hours > 0) {
    this->Hours = hours;
  }
}

void Clock::gettime() {}

Clock time = Clock();

// переменная для получения данных
int values;

// функция для перевода часов и минут в минуты
unsigned int to_minutes(unsigned int hours, unsigned int minutes)
{
  return (60*hours)+minutes;
}

const byte rxPin = 11;
const byte txPin = 12;
SoftwareSerial bluetoothSerial(rxPin, txPin);


void setup()
{
  time.begin();
  Serial.begin(9600);
  bluetoothSerial.begin(9600);
}

// 1 - hour
// 2 - minute
// 3 - timer data
int nextByteType = 1;

void loop()
{
  if(bluetoothSerial.available() > 0)
  { 
    if (nextByteType == 1) {
      Serial.println("hour");
      
      values = bluetoothSerial.read();
      // считывание и установка часов
      time.settime(0,-1, values);

      nextByteType = 2;
        
      Serial.println(values);
      Serial.println();
    }
    if (nextByteType == 2) {
      Serial.println("minute");
      
      values = bluetoothSerial.read();
      // считывание и установка минут
      time.settime(0, values);

      nextByteType = 3;
      
      Serial.println(values);
      Serial.println();

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
        Serial.println("data");
        Serial.println(values);
        EEPROM.write(EEPROM.read(EEPROM.length() - 1) * 7 + i, values);

        i++;
        if (i == 7) {
          Serial.println("One timer is recieved");
          Serial.println();
          
          i = 0;
          EEPROM.write(EEPROM.length() - 1, EEPROM.read(EEPROM.length() - 1) + 1);
        }
      }
    }
  }
//      values = bluetoothSerial.read();
//      if (values == 255) {
//        nextByteType = 1;
//        return;
//      }
//      while (values >= 0) {
//        while (i < 7 && values >= 0) {
//          Serial.println("data");
//          Serial.println(values);
//          
//          EEPROM.write(EEPROM.read(EEPROM.length() - 1) * 7 + i, values);
//          values = bluetoothSerial.read();
//          if (values == 255) {
//            Serial.println("end");
//            Serial.println();
//            
//            nextByteType = 1;
//            return;
//          }
//          i++;
//        }
//
//        Serial.print(" * i = ");
//        Serial.print(i);
//        Serial.println(" >= 7");
//        if (i >= 7) {
//          Serial.println("One timer is recieved");
//          Serial.println();
//          
//          i = 0;
//          EEPROM.write(EEPROM.length() - 1, EEPROM.read(EEPROM.length() - 1) + 1);
//        }
//
//        values = bluetoothSerial.read();
//        if (values == 255) {
//          Serial.println("end");
//          Serial.println();
//          
//          nextByteType = 1;
//          return;
//        }
//      }
//    }
//  }

  delay(500);
  Serial.print(" * number of timers ");
  Serial.println(EEPROM.read(EEPROM.length() - 1));
  // проход по каждому таймеру
  for(int i = 0; i < EEPROM.read(EEPROM.length() - 1); ++i)
  {
    Serial.print(" * is ");
    Serial.print(i);
    Serial.print(" active = ");
    Serial.println(EEPROM.read(i * 7 + 0));
    // если таймер нужно проверять
    if(EEPROM.read(i * 7 + 0) == 1)
    {
      bool find = 0;
      time.gettime();
      Serial.print(" * ");
      Serial.print(to_minutes(EEPROM.read(i * 7 + 1), EEPROM.read(i * 7 + 2)));
      Serial.print(" <= ");
      Serial.print(to_minutes(time.Hours, time.minutes));
      Serial.print(" < ");
      Serial.println(to_minutes(EEPROM.read(i * 7 + 3), EEPROM.read(i * 7 + 4)));
      // если пришло время для работы
      if((to_minutes(EEPROM.read(i * 7 + 1), EEPROM.read(i * 7 + 2)) <= to_minutes(time.Hours, time.minutes)) &&
         (to_minutes(EEPROM.read(i * 7 + 3), EEPROM.read(i * 7 + 4)) > to_minutes(time.Hours, time.minutes))) 
      {
        // настраиваем пин таймера как выход
        pinMode(EEPROM.read(i * 7 + 5), OUTPUT);
        // посылаем на пин нужное значение
        digitalWrite(EEPROM.read(i * 7 + 5), EEPROM.read(i * 7 + 6));
        Serial.print(" * ");
        Serial.print(EEPROM.read(i * 7 + 5));
        Serial.print(" = ");
        Serial.println(EEPROM.read(i * 7 + 6));
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
              Serial.print(" > ");
              Serial.print(EEPROM.read(i * 7 + 5));
              Serial.print(" = ");
              Serial.println(EEPROM.read(j * 7 + 6));
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
