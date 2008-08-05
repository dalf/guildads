----------------------------------------------------------------------------------
--
-- localization.ru.lua
--
-- Author: jID (Нэйлхунт, Азурегос EU)
-- Email : jid@red-code.ru
-- Версия перевода 1.01.
----------------------------------------------------------------------------------

if ( GetLocale() == "ruRU" ) then

GUILDADS_TITLE			= "GuildAds";

-- Minimap button
GUILDADS_BUTTON_TIP		= "Щёлкните здесь, чтобы скрыть/показать GuildAds.";
GUILDADS_UPGRADE_TIP		= "Появилась новая версия GuildAds: ";

-- Options frame
GUILDADS_OPTIONS_TITLE		= "Настройки GuildAds";
GUILDADS_CHAT_OPTIONS		= "Настройки Чата";
GUILDADS_CHAT_USETHIS		= "Использовать канал :";
GUILDADS_CHAT_CHANNEL		= "Имя канала";
GUILDADS_CHAT_PASSWORD		= "Пароль";
GUILDADS_CHAT_COMMAND		= "Слэш команда";
GUILDADS_CHAT_ALIAS 		= "Синоним канала";
GUILDADS_CHAT_SHOW_NEWEVENT	= "Показывать 'События'"
GUILDADS_CHAT_SHOW_NEWASK	= "Показывать 'Хочу'";
GUILDADS_CHAT_SHOW_NEWHAVE	= "Показывать 'Есть'";
GUILDADS_ADS_OPTIONS		= "Установки Обмена";
GUILDADS_FACTION_OPTIONS	= "Установки Фракций";
GUILDADS_FACTION_HIDE_COLLAPSED = "Скрывать свёрнутые фракции";
GUILDADS_FACTION_ONLY_LEVEL_70	= "Только 70 уровня";
GUILDADS_FACTION_FACTION	= "Показывать фракцию"; -- Should be updated runtime to either Horde or Alliance
GUILDADS_PUBLISH		= "Публиковать мой обмен";
GUILDADS_VIEWMYADS		= "Показывать Мой обмен";
GUILDADS_ICON_OPTIONS		= "Настройки пиктограммы миникарты";
GUILDADS_ICON			= "Пиктограмма миникарты";
GUILDADS_ADJUST_ANGLE		= "Выбрать угол";
GUILDADS_ADJUST_RADIUS		= "Выбрать радиус";

GUILDADS_AUTOCHANNELCONFIG	= "Автоматическая конфигурация канала";
GUILDADS_MANUALCHANNELCONFIG	= "Настройка конфигурации канала вручную";

GUILDADS_ERROR_NOTINITIALIZED 	= "GuildAds не настроен."

GUILDADS_ERROR_TOOMANYCHANNELS	= "Вы превысили максимально возможное количество каналов для подключения"; 
GUILDADS_ERROR_JOINCHANNELFAILED = "Невозможно подключиться к каналу по неизвестным причинам";
GUILDADS_ERROR_WRONGPASSWORD 	= "Неверно введён пароль";

GUILDADS_NEWDATATYPEVERSION	= "Формат данных \"%s\" : %s не соответствует новой версии %s. Обмен выключен, пока Вы не обновите аддон.";

-- Main frame
GUILDADS_MYADS			= "Мой Обмен";
GUILDADS_BUTTON_ADDREQUEST	= "Хочу";
GUILDADS_BUTTON_ADDAVAILABLE	= "Есть";
GUILDADS_BUTTON_REMOVE		= REMOVE;
GUILDADS_QUANTITY		= "Кол-во";
GUILDADS_SINCE			= "С добавления %s";
GUILDADS_SIMPLE_SINCE		= "С добавления";
GUILDADS_GROUPBYACCOUNT		= "Группировать по аккаунту";


GUILDADS_TRADE_PROVIDER 	= "Кто";
GUILDADS_TRADE_NUMBER		= "Кол";
GUILDADS_TRADE_OBJECT		= "Вещь";
GUILDADS_TRADE_ACTIVE		= "Вкл";
GUILDADS_TRADE_TYPE		= "Тип";
GUILDADS_TRADE_SHIFTCLICKHELP 	= "Чтобы выложить вещь, shift-клик её, пока окно открыто";
GUILDADS_TRADE_MINLEVEL		= "МинУр";

-- Column headers
GUILDADS_HEADER_REQUEST		= "Хочу";
GUILDADS_HEADER_AVAILABLE	= "Есть";
GUILDADS_HEADER_INVENTORY	= INSPECT;
GUILDADS_HEADER_SKILL 		= SKILLS;
GUILDADS_HEADER_ANNONCE		= GUILD;
GUILDADS_HEADER_FACTION		= "Репутация";
GUILDADS_HEADER_EVENT		= "События";

GUILDADS_GUILD_GROUPWITHACCOUNT	= "Группировать %s с аккаунтом %s";
GUILDADS_GUILD_DEGROUP		= "Отделить от аккаунта";
GUILDADS_GUILD_BLACKLIST	= "Чёрный список"; 
                    
-- Item
GUILDADS_ITEMS = {
	everything = "Всё",
	everythingelse = "Всё остальное",
	monster = "С монстров",
	classReagent = "Реагенты класса",
	tradeReagent = "Реагенты",
	vendor = "Продавец",
	trade = "Произведено",
	gather = "Собрано",
};
				
GUILDADS_ITEMS_SIMPLE = {
	everything = "Всё"
};

-- Equipment
GUILDADS_EQUIPMENT = "Обмундирование";

-- Tooltip requests
GUILDADS_ASKTOOLTIP = "%i запрос(ы)";
				
-- GuildAds button in craft frame
GUILDADS_TS_LINK = GUILDADS_TITLE;
GUILDADS_TS_ASKITEMS = "Хочу %i х %s";
GUILDADS_TS_ASKITEMS_TT	= "Измените кол-во создаваемых объектов для установки кол-ва.";

-- Binding
BINDING_HEADER_GUILDADS	= GUILDADS_TITLE;
BINDING_NAME_SHOW = "Показать GuildAds";
BINDING_NAME_SHOW_CONFIG = "Показать настройки GuildAds"

-- Race
GUILDADS_RACES	= {
	[1] = "Человек",
	[2] = "Дворф",
	[3] = "Ночной эльф",
	[4] = "Гном",
	[5] = "Орк",
	[6] = "Нежить",
	[7] = "Таурен",
	[8] = "Тролль",
	[9] = "Дреней",
	[10] = "Эльф Крови"
};

-- Faction
GUILDADS_ALLIANCE = 1;
GUILDADS_HORDE = 2;
GUILDADS_RACES_TO_FACTION = {
	[1] = GUILDADS_ALLIANCE,
	[2] = GUILDADS_ALLIANCE,
	[3] = GUILDADS_ALLIANCE,
	[4] = GUILDADS_ALLIANCE,
	[5] = GUILDADS_HORDE,
	[6] = GUILDADS_HORDE,
	[7] = GUILDADS_HORDE,
	[8] = GUILDADS_HORDE,
	[9] = GUILDADS_ALLIANCE,
	[10]= GUILDADS_HORDE
};

-- Class				
GUILDADS_CLASSES = {
	[1] = "Воин",
	[2] = "Шаман",
	[3] = "Паладин",
	[4] = "Друид",
	[5] = "Разбойник",
	[6] = "Охотник",
	[7] = "Чернокнижник",
	[8] = "Маг",
	[9] = "Жрец"
};


-- Skill
GUILDADS_SKILLS	= {
	[1]  = "Травничество",
	[2]  = "Горное дело",
	[3]  = "Свежевание",
	[4]  = "Алхимия",
	[5]  = "Кузнечное дело",
	[6]  = "Механика",
	[7]  = "Кожевное дело",
	[8]  = "Портняжное дело",
	[9]  = "Наложение чар",
	[10] = "Рыбная ловля",
	[11] = "Первая помощь",
	[12] = "Кулинария",
	[13] = "Вскрытие замков",
	[14] = "Ювелирное дело",
	
	[20] = "Рукопашный бой",
	[21] = "Кинжалы",
	[22] = "Мечи",
	[23] = "Двуручные мечи",
	[24] = "Ударное оружие",
	[25] = "Двуручное ударное оружие",
	[26] = "Топоры",
	[27] = "Двуручные топоры",
	[28] = "Глефы",
	[29] = "Посохи",
	[30] = "Метательное оружие",
	[31] = "Огнестрельное оружие",
	[32] = "Луки",
	[33] = "Арбалеты",
	[34] = "Жезлы"
};




GUILDADSTOOLTIPS_ADS_TITLE = TRADE;
GUILDADSTOOLTIPS_ADS =  "Позволяет смотреть вещи, выставленные на обмен среди согильдийцев";

GUILDADSTOOLTIPS_SKILL_TITLE = GUILDADS_HEADER_SKILL;
GUILDADSTOOLTIPS_SKILL =  "Позволяет смотреть торговые навыки и умения согильдийцев";

GUILDADSTOOLTIPS_GUILD_TITLE = GUILD;
GUILDADSTOOLTIPS_GUILD = "Позволяет посмотреть список согильдийцев";

--Factions (only factions mentioned here can be synchronized)
-- Taken from http://www.wowwiki.com/Reputation#Reputation_sheet
GUILDADS_FACTIONS = {
	[1]  = "Дарнасс";  -- Alliance
	[2]  = "Экзодар";
	[3]  = "Изгнанники Гномрегана";
	[4]  = "Стальгорн";
	[5]  = "Штормград";
	[6]  = "Среброкрылые Часовые";
	[7]  = "Стража Грозовой Вершины";
	[8]  = "Лига Аратора";
	[9]  = "Тролли Черного Копья"; -- Horde
	[10] = "Оргриммар";
	[11] = "Луносвет";
	[12] = "Громовой Утес";
	[13] = "Подгород";
	[14] = "Клан Северного Волка";
	[15] = "Осквернители";
	[16] = "Всадники Песни Войны";
	[17] = "Оплот Чести"; -- Outland
	[18] = "Траллмар";
	[19] = "Куренай";
	[20] = "Маг'хары";
	[21] = "Экспедиция Ценариона";
	[22] = "Спореггар";
	[23] = "Консорциум";
	[24] = "Крылья Пустоверти";
	[25] = "Огри'ла";
	[26] = "Пеплоусты-служители";
	[27] = "Нижний Город"; -- Shattrath City
	[28] = "Стражи Небес Ша'тар";
	[29] = "Алдоры";
	[30] = "Провидцы";
	[31] = "Ша'тар";
	[55] = "Армия Расколотого Солнца";
	[32] = "Пиратская бухта"; -- Steamwheedle Cartel
	[33] = "Круговзор";
	[34] = "Прибамбасск";
	[35] = "Кабестан";
	[36] = "Серебряный Рассвет"; -- Other
	[37] = "Пираты Кровавого Паруса";
	[38] = "Род Ноздорму";
	[39] = "Служители Ценариона";
	[40] = "Ярмарка Новолуния";
	[41] = "Кентавры из племени Гелкис";
	[42] = "Гидраксианские Повелители Вод";
	[43] = "Кентавры племени Маграм";
	[44] = "Черный Ворон";
	[45] = "Шен'дралар";
	[46] = "Синдикат";
	[47] = "Братство Тория";
	[48] = "Древобрюхи";
	[49] = "Укротители ледопардовs";
	[50] = "Племя Зандалар";
	[51] = "Хранители Времени"; -- Other - BC
	[52] = "Песчаная Чешуя";
	[53] = "Транквиллион";
	[54] = "Аметистовое Око";
}; -- last one used is 55

GUILDADS_FACTION_SHOWFACTION = "Показывать Фракцию";
GUILDADS_FACTION_SHOWFACTIONFORCES = "Показывать Силы Фракции";
GUILDADS_FACTION_SHOWOUTLAND = "Показывать Запределье";
GUILDADS_FACTION_SHOWSHATTRATHCITY = "Показывать Шаттрат";
GUILDADS_FACTION_SHOWSTEAMWHEEDLECARTEL = "Показывать Картель Хитрая Шестерёнка";
GUILDADS_FACTION_SHOWOTHER = "Показывать Остальные";

GUILDADS_OPTIONS = {
	["toggle"]			= BINDING_NAME_SHOW;
	["options"]			= BINDING_NAME_SHOW_CONFIG;
	["debug"] 			= "Включить / выключить отладончные сообщения";
	["info"] 			= "Показывать основную отладочную информацию";
	["reset"]			= "Обнулить БД";
	["reset all"]		= "Обнулить БД кроме информации об аккаунтах";
	["reset channel"]	= "Обнулить данные каналов";
	["reset others"]	= "Обнулить всю информацию об игроках";
	["reset player"]	= "Обнулить всю информацию о конкретном игроке";
	["clean"]			= "Почистить БД";
	["clean other"]		= "Удалить информацию о навыках других аккаунтов, не имеющих ссылок на рецепты";
	["admin"]			= "Управлять доступом игроков и гильдий";
	["admin show"]		= "Показать текущий список управления";
	["admin deny"]		= "Запретить игроку или  @гильдии доступ (удаляет данные игроков)";
	["admin allow"]		= "Разрешить игроку или  @гильдии доступ (удаляет данные игроков)";
	["admin remove"]	= "Удалить игрока или @гильдию из списка контроля";
	["admin allowed"]	= "Проверить, есть ли у игрока доступ";
}

end
