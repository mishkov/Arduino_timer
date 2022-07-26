// ЗАМЕТКИ
//
// В последнем байте памяти лежит количество счетчиков

#include <Wire.h>
#include <iarduino_RTC.h>
#include <EEPROM.h>

iarduino_RTC time(RTC_DS1307);

// переменная для получения данных
int values;

// функция для перевода часов и минут в минуты
unsigned int to_minutes(unsigned int hours, unsigned int minutes)
{
  return (60*hours)+minutes;
}

void setup()
{
  time.begin();
  Serial.begin(9600);
  
}

void loop()
{
  if(Serial.available() > 0)
  { 
    values = Serial.read();
    // считывание и установка часов
    time.settime(0,-1, values);
    
    delay(50);
    values = Serial.read();
    // считывание и установка минут
    time.settime(0, values);
    delay(50);

    // очищаем энергонезависимую память
    for (int i = 0 ; i < EEPROM.length() ; i++)
    {
      EEPROM.write(i, 0);
    }
    
    values = Serial.read();                                 
    delay(50);
    
    // запись данных в энергонезависимую память, полученых с телефона
    while (values > 0)
    {
      // 7 - количество параметров одного таймера
      for(int i = 0; i < 7; ++i)
      {
        // записываем последовательно в память параметры полученного таймера
        //
        // EEPROM.length() - 1 - последний байт
        // 7 - количество параметров одного таймера
        EEPROM.write(EEPROM.read(EEPROM.length() - 1) * 7 + i, Serial.read());
        delay(50);
      }

      // увеличиваем последний байт в памяти на единицу, тем самым увеличивая количество полученный таймеров
      EEPROM.write(EEPROM.length() - 1, EEPROM.read(EEPROM.length() - 1) + 1);

      // читаем следующий полученый байт
      values = Serial.read();
      delay(50);
    }
  }

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
