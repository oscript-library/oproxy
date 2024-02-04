//ДвоичныеДанные, по которым можно определить что очередной пакет является концом серии пакетов
Перем СигнатураПоискаКонца;
Перем РазмерСигнатурыКонца;
//ДвоичныеДанные, по которым можно определить что очередной пакет является пакетом проверки связи
Перем СигнатураПоискаПинга;
Перем РазмерСигнатурыПинга;
//ДвоичныеДанные, по которым можно определить что очередной пакет является началом сообщения (в начале слово POST)
Перем СигнатураНачалаСообщения;
Перем РазмерСигнатурыНачалаСообщения;

//ДвоичныеДанные, по которым можно определить что в очередном пакете содержится начало XML данных
Перем СигнатураНачалаXML;
Перем РазмерСигнатурыНачалаXML;
//массив имен методов хранилища, которые подлежат проверке
Перем ПроверяемыеМетоды;

Процедура ПриСозданииОбъекта()
	СигнатураПоискаКонца = ПолучитьДвоичныеДанныеИзHexСтроки("6653B2A6");
	РазмерСигнатурыКонца = СигнатураПоискаКонца.Размер();
	СигнатураПоискаПинга = ПолучитьДвоичныеДанныеИзHexСтроки("214754B3");
	РазмерСигнатурыПинга = СигнатураПоискаПинга.Размер();
	СигнатураНачалаСообщения = ПолучитьДвоичныеДанныеИзСтроки("POST");
	РазмерСигнатурыНачалаСообщения = СигнатураНачалаСообщения.Размер();
	СигнатураНачалаXML = ПолучитьДвоичныеДанныеИзСтроки("<?xml");
	РазмерСигнатурыНачалаXML = СигнатураНачалаXML.Размер();
	ПроверяемыеМетоды = Новый Массив;
	ПроверяемыеМетоды.Добавить("DevDepot_commitObjects");
	ПроверяемыеМетоды.Добавить("DevDepot_changeVersion");
КонецПроцедуры

Функция ЭтоПинг(ВходныеДанные) Экспорт
	Если НЕ ВходныеДанные.Размер() Тогда
		Возврат Истина;
	КонецЕсли;
	
	Поток = ВходныеДанные.ОткрытьПотокДляЧтения();
	Размер = Поток.Размер();
	Размер4Байта = 4;
	
	Если Размер % Размер4Байта <> 0 Тогда
		Поток.Закрыть();
		Возврат Ложь;
	КонецЕсли;
	
	Нашли = Истина;
	
	Буфер = Новый БуферДвоичныхДанных(РазмерСигнатурыПинга);
	Пока Поток.ТекущаяПозиция() < Размер Цикл
		Поток.Прочитать(Буфер, 0, РазмерСигнатурыПинга);
		Если СигнатураПоискаПинга <> ПолучитьДвоичныеДанныеИзБуфераДвоичныхДанных(Буфер) Тогда
			Нашли = Ложь;
			Прервать;
		КонецЕсли;
	КонецЦикла;
	Поток.Закрыть();
	Возврат Нашли;
КонецФункции

Функция ЕстьКонецСообщения(ВходныеДанные) Экспорт
	Поток = ВходныеДанные.ОткрытьПотокДляЧтения();
	Размер = Поток.Размер();
	Если Размер < РазмерСигнатурыКонца Тогда
		Поток.Закрыть();
		Возврат Ложь;
	КонецЕсли;
	Поток.Перейти(-РазмерСигнатурыКонца, ПозицияВПотоке.Конец);
	Буфер = Новый БуферДвоичныхДанных(РазмерСигнатурыКонца);
	Поток.Прочитать(Буфер, 0, РазмерСигнатурыКонца);
	
	Поток.Закрыть();
	
	КонецДанныхРазмеромСигнатуры = ПолучитьДвоичныеДанныеИзБуфераДвоичныхДанных(Буфер);
	Результат = КонецДанныхРазмеромСигнатуры = СигнатураПоискаКонца;
	Возврат Результат;
КонецФункции

Функция ПолучитьПараметрыЗапроса(ДвоичныеДанныеЗапроса) Экспорт
	ТелоЗапроса = ПолучитьТекстХМЛ(ДвоичныеДанныеЗапроса);
	Если ПустаяСтрока(ТелоЗапроса) Тогда
		Возврат Неопределено;
	КонецЕсли;
	СтруктураОтвета = НовыйСтруктураОтвета();
	Попытка
		Чтение = Новый ЧтениеXML;
		Чтение.УстановитьСтроку(ТелоЗапроса); //удалить BOM

		Пока Чтение.Прочитать() Цикл
			Если Чтение.ТипУзла <> ТипУзлаXML.НачалоЭлемента Тогда
				Продолжить;
			КонецЕсли;
			Если Чтение.ЛокальноеИмя = "call" Тогда
				СтруктураОтвета.Вставить("ИмяСистемы", Нрег(Чтение.ЗначениеАтрибута("alias")));
				СтруктураОтвета.Вставить("ВерсияПлатформы", Чтение.ЗначениеАтрибута("version"));
				СтруктураОтвета.Вставить("ИмяМетода", Чтение.ЗначениеАтрибута("name"));
				Если ПроверяемыеМетоды.Найти(СтруктураОтвета.ИмяМетода) = Неопределено Тогда
					Прервать; //если метод не нужно проверять, не надо дочитывать весь XML до конца
				КонецЕсли;
				СтруктураОтвета.Вставить("Проверять", Истина);
				Если СтруктураОтвета.ИмяМетода = "DevDepot_commitObjects" Тогда
					ПродолжитьРазборПомещениеДанныхВХранилище(Чтение, СтруктураОтвета);
				ИначеЕсли СтруктураОтвета.ИмяМетода = "DevDepot_changeVersion" Тогда
					ПродолжитьРазборИзменениеВерсииВХранилище(Чтение, СтруктураОтвета);
				Иначе
					ВызватьИсключение "не поддерживается разбор метода " + СтруктураОтвета.ИмяМетода;
				КонецЕсли;
			КонецЕсли;

		КонецЦикла;
		Чтение.Закрыть();
		Чтение = Неопределено;
	Исключение
		Чтение.Закрыть();
		Чтение = Неопределено;
		//конфигуратор и хранилище общаются пакетами, а не целыми сообщениями
		//при длинных сообщениях конфигуратор может отдать только часть XML
	КонецПопытки;
	Возврат СтруктураОтвета;
КонецФункции

Функция НовыйСтруктураОтвета()
	Перем результат;
	результат = Новый Структура;
	результат.Вставить("ИмяСистемы");
	результат.Вставить("ИмяМетода");
	результат.Вставить("ВерсияПлатформы");
	результат.Вставить("Проверять");
	результат.Вставить("ИмяПользователя");
	результат.Вставить("ВерсияКонфигурации");
	результат.Вставить("Комментарий");
	результат.Вставить("КомментарийБыл");
	результат.Вставить("Метка");
	результат.Вставить("КомментарийМетки");
	
	Возврат результат;
КонецФункции

Процедура ПродолжитьРазборПомещениеДанныхВХранилище(Чтение, СтруктураОтвета)
	Пока Чтение.Прочитать() Цикл
		Если Чтение.ТипУзла <> ТипУзлаXML.НачалоЭлемента Тогда
			Продолжить;
		КонецЕсли;
		Если Чтение.ЛокальноеИмя = "auth" Тогда
			СтруктураОтвета.Вставить("ИмяПользователя", Чтение.ЗначениеАтрибута("user"));
		ИначеЕсли Чтение.ЛокальноеИмя = "comment" Тогда
			Чтение.Прочитать();
			СтруктураОтвета.Вставить("Комментарий", СокрЛП(Чтение.Значение));
		ИначеЕсли Чтение.ЛокальноеИмя = "code" Тогда
			СтруктураОтвета.Вставить("ВерсияКонфигурации", Чтение.ЗначениеАтрибута("value"));
		КонецЕсли;
	КонецЦикла;
КонецПроцедуры

Процедура ПродолжитьРазборИзменениеВерсииВХранилище(Чтение, СтруктураОтвета)

	ЭтоНоваяВерсия = Ложь;
	ЭтоМетка = Ложь;
	ЭтоИнфо = Ложь;

	Пока Чтение.Прочитать() Цикл
		Если Чтение.ТипУзла = ТипУзлаXML.НачалоЭлемента Тогда
			Если Чтение.ЛокальноеИмя = "auth" Тогда
				СтруктураОтвета.Вставить("ИмяПользователя", Чтение.ЗначениеАтрибута("user"));
			ИначеЕсли Чтение.ЛокальноеИмя = "newVersion" Тогда
				ЭтоНоваяВерсия = Истина;
			ИначеЕсли Чтение.ЛокальноеИмя = "info" Тогда
				ЭтоИнфо = Истина;
			ИначеЕсли Чтение.ЛокальноеИмя = "label" Тогда
				ЭтоМетка = Истина;
			ИначеЕсли Чтение.ЛокальноеИмя = "comment" И ЭтоИнфо И ЭтоНоваяВерсия Тогда
				Чтение.Прочитать();
				СтруктураОтвета.Вставить("Комментарий", СокрЛП(Чтение.Значение));
			ИначеЕсли Чтение.ЛокальноеИмя = "comment" И ЭтоИнфо И НЕ ЭтоНоваяВерсия Тогда
				Чтение.Прочитать();
				СтруктураОтвета.Вставить("КомментарийБыл", СокрЛП(Чтение.Значение));
			ИначеЕсли Чтение.ЛокальноеИмя = "code" И ЭтоИнфо И ЭтоНоваяВерсия Тогда
				СтруктураОтвета.Вставить("ВерсияКонфигурации", Чтение.ЗначениеАтрибута("value"));
			ИначеЕсли Чтение.ЛокальноеИмя = "name" И ЭтоМетка И ЭтоНоваяВерсия Тогда
				СтруктураОтвета.Вставить("Метка", Чтение.ЗначениеАтрибута("value"));
			ИначеЕсли Чтение.ЛокальноеИмя = "comment" И ЭтоМетка И ЭтоНоваяВерсия Тогда
				Чтение.Прочитать();
				СтруктураОтвета.Вставить("КомментарийМетки", СокрЛП(Чтение.Значение));	
			КонецЕсли;
		ИначеЕсли Чтение.ТипУзла = ТипУзлаXML.КонецЭлемента Тогда
			Если Чтение.ЛокальноеИмя = "newVersion" Тогда
				ЭтоНоваяВерсия = Ложь;
			ИначеЕсли Чтение.ЛокальноеИмя = "info" Тогда
				ЭтоИнфо = Ложь;
			ИначеЕсли Чтение.ЛокальноеИмя = "label" Тогда
				ЭтоМетка = Ложь;
			КонецЕсли
		КонецЕсли;
	КонецЦикла;
КонецПроцедуры

Функция ПолучитьТекстХМЛ(ДвоичныеДанныеЗапроса)
	Результат = "";
	ПотокЧтения = ДвоичныеДанныеЗапроса.ОткрытьПотокДляЧтения();
	БуферПроверкиХМЛ = Новый БуферДвоичныхДанных(РазмерСигнатурыНачалаXML);
	
	БуферПроверкиНачала = Новый БуферДвоичныхДанных(РазмерСигнатурыНачалаСообщения);
	ПотокЧтения.Прочитать(БуферПроверкиНачала, 0, РазмерСигнатурыНачалаСообщения);
	Если ПолучитьДвоичныеДанныеИзБуфераДвоичныхДанных(БуферПроверкиНачала) <> СигнатураНачалаСообщения Тогда
		ПотокЧтения.Закрыть();
		Возврат Результат;
	КонецЕсли;
	
	НашлиХМЛ = Ложь;
	Пока НЕ НашлиХМЛ Цикл
		ПотокЧтения.Прочитать(БуферПроверкиХМЛ, 0, РазмерСигнатурыНачалаXML);
		Если ПолучитьДвоичныеДанныеИзБуфераДвоичныхДанных(БуферПроверкиХМЛ) = СигнатураНачалаXML Тогда
			НашлиХМЛ = Истина;
			Прервать;
		КонецЕсли;
		ПотокЧтения.Перейти(1 - РазмерСигнатурыНачалаXML, ПозицияВПотоке.Текущая);
	КонецЦикла;
	
	Если НашлиХМЛ Тогда
		ПотокЧтения.Перейти(-РазмерСигнатурыНачалаXML, ПозицияВПотоке.Текущая);
		РазмерЧтения = ПотокЧтения.Размер() - ПотокЧтения.ТекущаяПозиция();
		БуферХМЛ = Новый БуферДвоичныхДанных(РазмерЧтения);
		ПотокЧтения.Прочитать(БуферХМЛ, 0, РазмерЧтения);
		Результат = ПолучитьСтрокуИзБуфераДвоичныхДанных(БуферХМЛ);
	КонецЕсли;
	ПотокЧтения.Закрыть();
	Возврат Результат;
КонецФункции

Функция ПолучитьДвоичныеДанныеОтветаОшибки(ТекстОшибки) Экспорт
	ТекстОшибки = СтрЗаменить(ТекстОшибки, """", "'");
	СтрокаВнутрОшибки = СтрЗаменить(
			"{
			|{3ccb2518-9616-4445-aaa7-20048fead174,""" + ТекстОшибки + """,
			|{00000000-0000-0000-0000-000000000000},""core83.dll:0x0000000000085BE8 crcore.dll:0x000000000003542A crcore.dll:0x000000000010E48C VCRUNTIME140.dll:0x0000000000001030 VCRUNTIME140.dll:0x00000000000032E8 unknown:0x0000000000000000 crcore.dll:0x00000000000C078F crserver.exe:0x0000000000009399 core83.dll:0x00000000002B256B core83.dll:0x00000000002B259C core83.dll:0x0000000000176F3E ucrtbase.dll:0x0000000000000000 KERNEL32.DLL:0x0000000000000000 unknown:0x0000000000000000 "",""0000000000000000000000"",00000000-0000-0000-0000-000000000000},4,
			|{""file://С:\folder\confstore"",0},""""}",
			Символы.ПС, Символы.ВК + Символы.ПС);
	ДвоичныеДанныеСтрокиВнутр = ПолучитьДвоичныеДанныеИзСтроки(СтрокаВнутрОшибки, "UTF-8", Истина);
	Base64СтрокаВнутр = ПолучитьBase64СтрокуИзДвоичныхДанных(ДвоичныеДанныеСтрокиВнутр);
	ТекстХМЛ = СтрШаблон(
	"<?xml version=""1.0"" encoding=""UTF-8""?><crs:call_exception xmlns:crs=""http://v8.1c.ru/8.2/crs"" "
	+ "clsid=""3ccb2518-9616-4445-aaa7-20048fead174"">%1</crs:call_exception>"
	, Base64СтрокаВнутр);
	ДД_БОМ = ПолучитьДвоичныеДанныеИзHexСтроки("EFBBBF");
	РазмерХМЛ = ПолучитьДвоичныеДанныеИзСтроки(ТекстХМЛ).Размер() + ДД_БОМ.Размер();
	ТекстОтвета = СтрЗаменить(
			"HTTP/1.1 200 OK
			|Content-Length: " + РазмерХМЛ + "
			|Content-Type: application/xml
			|
			|",
			Символы.ПС, Символы.ВК + Символы.ПС);
	ПотокВПамяти = Новый ПотокВПамяти;
	
	Запись = Новый ЗаписьДанных(ПотокВПамяти, "UTF-8", , "");
	Запись.ЗаписатьСтроку(ТекстОтвета);
	Запись.Записать(ДД_БОМ);
	Запись.ЗаписатьСтроку(ТекстХМЛ);
	Запись.Записать(СигнатураПоискаКонца);
	
	ПотокВПамяти.Перейти(0, ПозицияВПотоке.Начало);
	ОтветДД = ПотокВПамяти.ЗакрытьИПолучитьДвоичныеДанные();
	Запись.Закрыть();

	Возврат ОтветДД;
КонецФункции