#include <Wire.h>                                            //библиотека для работы с шиной i2c
#include <iarduino_RTC.h>                                    //библиотека для rtc модуля(если cчто, лежит в папке проекта(Timer->firmware_for_timer->iarduino_RTC))     
#include <EEPROM.h>                                          //библиотека для работы с энергонезависимой памятью

iarduino_RTC time(RTC_DS1307);                               //создание объекта для работы с модулем реального времени

int values;                                                  //переменная для получения данных

unsigned int to_minutes(unsigned int hours, unsigned int minutes)//функция для перевода часов и минут в минуты
{
  return (60*hours)+minutes;
}

void setup()
{
  time.begin();                                             //начало работы часов
  Serial.begin(9600);                                       //открытие сериал порта
  
}

void loop()
{
  if(Serial.available() > 0)                                //если что-то пришло
  { 
    values = Serial.read();
    time.settime(0,-1, values);                             //считывание и установка часов
    delay(50);
    values = Serial.read();
    time.settime(0, values);                                //считывание и установка минут
    delay(50);

    //очищаем энергонезависимую память
    for (int i = 0 ; i < EEPROM.length() ; i++)
    {
      EEPROM.write(i, 0);
    }
    //////////////////////////////////
    
    values = Serial.read();                                 
    delay(50);
    
    //запись данных в энергонезависимую память, полученых с телефона
    while (values > 0)                                        //пока есть что получать
    {
      for(int i = 0; i < 7; ++i)
      {
        EEPROM.write(EEPROM.read(EEPROM.length() - 1) * 7 + i, Serial.read());
        delay(50);
      }

      EEPROM.write(EEPROM.length() - 1, EEPROM.read(EEPROM.length() - 1) + 1);

      values = Serial.read();
      delay(50);
    }
    /////////////////////////////////////////
  }

  //проход по каждому таймеру
  for(int i = 0; i < EEPROM.read(EEPROM.length() - 1); ++i)
  {
    if(EEPROM.read(i * 7 + 0) == 1)                                                                               //если таймер нужно проверять
    {
      bool find = 0;                                                                                              //флаг
      time.gettime();
      if((to_minutes(EEPROM.read(i * 7 + 1), EEPROM.read(i * 7 + 2)) <= to_minutes(time.Hours, time.minutes)) && //если пришло время для работы
         (to_minutes(EEPROM.read(i * 7 + 3), EEPROM.read(i * 7 + 4)) > to_minutes(time.Hours, time.minutes))) 
      {
        pinMode(EEPROM.read(i * 7 + 5), OUTPUT);                                                                  //настраиваем пин таймера как выход
        digitalWrite(EEPROM.read(i * 7 + 5), EEPROM.read(i * 7 + 6));                                             //посылаем на пин нужное значение
      }                           
      else                                                                                                        //иначе если время не пришло
      {
        //ищем таймер с таким же пином
        for (int j = 0; j < EEPROM.read(EEPROM.length() - 1); ++j)
        {
          if(EEPROM.read(i * 7 + 5) == EEPROM.read(j * 7 + 5) && (i != j) && (EEPROM.read(j * 7 + 0) == 1))
          {
            //и если нашли таймер с таким же пином и если для него время пришло
            if((to_minutes(EEPROM.read(j * 7 + 1), EEPROM.read(j * 7 + 2)) <= to_minutes(time.Hours, time.minutes)) && 
               (to_minutes(EEPROM.read(j * 7 + 3), EEPROM.read(j * 7 + 4)) > to_minutes(time.Hours, time.minutes))) //если пришло время для работы
            {
              pinMode(EEPROM.read(i * 7 + 5), OUTPUT);                                                             //настраиваем пин таймера как выход
              digitalWrite(EEPROM.read(i * 7 + 5), EEPROM.read(j * 7 + 6));                                        //посылаем на пин нужное значение
              find = 1;                                                                                            //поднимаем флаг
            }
          }
        }

        if(find == 0)                                                                                              //если таймер с таким же пином не найден 
        {
          pinMode(EEPROM.read(i * 7 + 5), OUTPUT);                                                                 //настраиваем пин таймера как выход
          digitalWrite(EEPROM.read(i * 7 + 5), !EEPROM.read(i * 7 + 6));                                           //посылаем на пин значение протиаоположное нужному
        }
      }
    }
  }
}
