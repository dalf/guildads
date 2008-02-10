if GetLocale() == "esES" then
GUILDADS_TITLE			= "GuildAds";

-- Minimap button
GUILDADS_BUTTON_TIP		= "Click aqu\195\173 para mostrar/ocultar GuildAds.";

-- Options frame
GUILDADS_OPTIONS_TITLE		= "Opciones de GuildAds";
GUILDADS_CHAT_OPTIONS		= "Configuraci\195\179n de chat";
GUILDADS_CHAT_USETHIS		= "Usar este canal :";
GUILDADS_CHAT_CHANNEL		= "Nombre";
GUILDADS_CHAT_PASSWORD		= "Password";
GUILDADS_CHAT_COMMAND		= "Comando de barra";
GUILDADS_CHAT_ALIAS 		= "Alias de Canal";
GUILDADS_CHAT_SHOW_NEWEVENT	= "Mostrar noticias de \239\191\189Eventos\239\191\189"
GUILDADS_CHAT_SHOW_NEWASK	= "Mostrar noticias de \239\191\189Pedir\239\191\189";
GUILDADS_CHAT_SHOW_NEWHAVE	= "Mostrar noticias de \239\191\189Ofrecer\239\191\189";
GUILDADS_ADS_OPTIONS		= "Configuraci\195\179n de Anuncios";
GUILDADS_PUBLISH		= "Publicar mis anuncios";
GUILDADS_VIEWMYADS		= "Mostrar mis anuncios";
GUILDADS_ICON_OPTIONS		= "Configurar icono del minimapa";
GUILDADS_ICON			= "Icono del minimapa";
GUILDADS_ADJUST_ANGLE		= "Ajustar \195\161ngulo";
GUILDADS_ADJUST_RADIUS		= "Ajustar radio";

GUILDADS_AUTOCHANNELCONFIG	= "Configurar canal autom\195\161ticamente";
GUILDADS_MANUALCHANNELCONFIG	= "Configurar canal manualmente";

GUILDADS_ERROR_NOTINITIALIZED 	= "GuildAds no se ha iniciado."

GUILDADS_ERROR_TOOMANYCHANNELS		= "Ya te has unido al numero maximo de canales permitidos"; 
GUILDADS_ERROR_JOINCHANNELFAILED 	= "Error al unirse al canal por causas desconocidas";
GUILDADS_ERROR_WRONGPASSWORD 		= "La password es erronea";

GUILDADS_NEWDATATYPEVERSION = "El tipo de datos \"%s\" : %s tiene la nueva version %s. Hasta que actualices a dicha version, se desactivaran las actualizaciones.";

-- Main frame
GUILDADS_MYADS			= "Mis Anuncios";
GUILDADS_BUTTON_ADDREQUEST	= "Pedir";
GUILDADS_BUTTON_ADDAVAILABLE	= "Ofrecer";
GUILDADS_BUTTON_REMOVE		= REMOVE;
GUILDADS_QUANTITY		= "Cantidad";
GUILDADS_SINCE			= "Desde %s";
GUILDADS_SIMPLE_SINCE		= "Desde";
GUILDADS_GROUPBYACCOUNT		= "Agrupar por cuenta";


GUILDADS_TRADE_PROVIDER 	= "De";
GUILDADS_TRADE_NUMBER		= "Num";
GUILDADS_TRADE_OBJECT		= "Item";
GUILDADS_TRADE_ACTIVE		= "Activo";
GUILDADS_TRADE_TYPE		= "Tipo";
GUILDADS_TRADE_SHIFTCLICKHELP 	= "Para poner un objeto aqu\195\173, haz shift+click en \195\169l con esta ventana abierta";

-- Column headers
GUILDADS_HEADER_REQUEST		= "Pedir";
GUILDADS_HEADER_AVAILABLE	= "Ofrecer";
GUILDADS_HEADER_INVENTORY	= INSPECT;
GUILDADS_HEADER_SKILL 		= SKILLS;
GUILDADS_HEADER_ANNONCE		= GUILD;
GUILDADS_HEADER_EVENT		= "Eventos";

GUILDADS_GUILD_GROUPWITHACCOUNT	= "Grupo %s con la cuenta de %s";
GUILDADS_GUILD_DEGROUP			= "Desagrupar de la cuenta";
                    
-- Item
GUILDADS_ITEMS = {
	everything = "Todod",
	everythingelse = "Todo lo dem\195\161s",
	monster = "Loot de monstruo",
	classReagent = "Materiales de clases",
	tradeReagent = "Materiales de profesiones",
	vendor = "Vendedor",
	trade = "Productos de profesiones",
	gather = "Recolectar",
};
				
GUILDADS_ITEMS_SIMPLE = {
	everything = "Todo"
};

-- Equipment
GUILDADS_EQUIPMENT = "Equipo";

-- Tooltip requests
GUILDADS_ASKTOOLTIP = "%i peticion(es)";
				
-- GuildAds button in craft frame
GUILDADS_TS_LINK = GUILDADS_TITLE;
GUILDADS_TS_ASKITEMS = "Pedir materiales para %i %s";
GUILDADS_TS_ASKITEMS_TT	= "Modifica el numero de objetos a crear para establecer las cantidades.";

-- Binding
BINDING_HEADER_GUILDADS	= GUILDADS_TITLE;
BINDING_NAME_SHOW = "Mostrar GuildAds";
BINDING_NAME_SHOW_CONFIG = "Mostrar configuraci\195\179n de GuildAds"

GUILDADS_OPTIONS = {
	["toggle"]			= BINDING_NAME_SHOW;
	["options"]			= BINDING_NAME_SHOW_CONFIG;
	["debug"] 			= "Activa/desactiva mensajes de debug";
	["info"] 			= "Muestra informaci\195\179n general de debug";
	["reset"]			= "Reiniciar base de datos";
	["reset all"]		= "Reinicias todas las bases de datos excepto informaci\195\179n de cuenta";
	["reset channel"]	= "Reiniciar datos de canales";
	["reset others"]	= "Reiniciar toda la informaci\195\179n sobre otros jugadores";
	["clean"]			= "Clean the database";
	["clean other"]		= "Delete tradeskill information from other accounts that doesn't have recipe links";
	["admin"]			= "Handle access control of players and guilds";
	["admin show"]		= "Show current access control list";
	["admin deny"]		= "Deny player or @guild access (deletes player data)";
	["admin allow"]		= "Allow player or @guild access (deletes player data)";
	["admin remove"]	= "Remove player or @guild from access control list";
	["admin allowed"]	= "Checks if a player is allowed access";
}

-- Race
GUILDADS_RACES	= {
	[1] = "Humano",
	[2] = "Enano",
	[3] = "Elfo de la Noche",
	[4] = "Gnomo",
	[5] = "Orco",
	[6] = "No Muerto",
	[7] = "Tauren",
	[8] = "Trol",
	[9] = "Draenei",
	[10] = "Elfo de la Sangre"
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
	[1] = "Guerrero",
	[2] = "Cham\195\161n",
	[3] = "Palad\195\173n",
	[4] = "Druida",
	[5] = "P\195\173caro",
	[6] = "Cazador",
	[7] = "Brujo",
	[8] = "Mago",
	[9] = "Sacerdote"
};


-- Skill
GUILDADS_SKILLS	= {
	[1]  = "Bot\195\161nica",
	[2]  = "Miner\195\173a",
	[3]  = "Desollar",
	[4]  = "Alquimia",
	[5]  = "Herrer\195\173a",
	[6]  = "Ingenier\195\173a",
	[7]  = "Peleter\195\173a",
	[8]  = "Sastrer\195\173a",
	[9]  = "Encantamiento",
	[10] = "Pesca",
	[11] = "Primeros Auxilios",
	[12] = "Cocina",
	[13] = "Ganz\195\186a",
	[14] = "Joyer\195\173a",
	
	[20] = "Armas de puño",
	[21] = "Dagas",
	[22] = "Espadas",
	[23] = "Espadas a dos manos",
	[24] = "Mazas",
	[25] = "Mazas a dos manos",
	[26] = "Hachas",
	[27] = "Hachas a dos manos",
	[28] = "Armas de Asta",
	[29] = "Bastones",
	[30] = "Armas Arrojadizas",
	[31] = "Rifles",
	[32] = "Arcos",
	[33] = "Ballestas",
	[34] = "Varitas"
};

-- Reputation
GUILDADS_FACTIONS = {
	[1]  = "Darnassus";
	[2]  = "Exodar";
	[3]  = "Exiliados de Gnomeregan";
	[4]  = "Forjaz";
	[5]  = "Ventormenta";
	[6] = "Centinelas Ala de Plata";
	[7] = "Guardia Pico Tormenta";
	[8] = "Liga de Arathor";
	[9]  = "Trols Lanza Negra";
	[10] = "Orgrimmar";
	[11] = "Ciudad de Lunargenta";
	[12] = "Cima del Trueno";
	[13] = "Entrañas";
	[14] = "Clan Lobo G\195\169lido";
	[15] = "Los Rapiñadores";
	[16] = "Escoltas Grito de Guerra";
	[17] = "Basti\195\179n del Honor";
	[18] = "Thrallmar";
	[19] = "Kurenai";
	[20] = "Los Mag\239\191\189har";
	[21] = "Expedici\195\179n Cenarion";
	[22] = "Esporaggar";
	[23] = "El Consorcio";
	[24] = "Ala Abisal";
	[25] = "Ogri\239\191\189la";
	[26] = "Juramorte Lengua de ceniza";
	[27] = "Bajo Arrabal";
	[28] = "Guardia del cielo Sha\239\191\189tari";
	[29] = "Los Aldor";
	[30] = "Los Ar\195\186spices";
	[31] = "Los Sha\239\191\189tar";
	[32] = "Bah\195\173a del Bot\195\173n";
	[33] = "Vista Eterna";
	[34] = "Gadgetzan";
	[35] = "Trinquete";
	[36] = "El Alba Argenta";
	[37] = "Bucaneros Velasangre";
	[38] = "Linaje de Nozdormu";
	[39] = "C\195\173rculo Cenarion";
	[40] = "Feria de la Luna Negra";
	[41] = "Gelkis Clan Centaur";
	[42] = "Srs. del Agua de Hydraxis";
	[43] = "Magram Clan Centaur";
	[44] = "Ravenholdt";
	[45] = "Shen\239\191\189dralar";
	[46] = "Syndicate"; -- to translate
	[47] = "Hermandad del torio";
	[48] = "Basti\195\179n Fauces de Madera";
	[49] = "Entrenadores Sable de Invierno"; -- to check
	[50] = "Tribu Zandalar";
	[51] = "Vigilantes del tiempo";
	[52] = "La Escama de las Arenas";
	[53] = "Tranquillien";
	[54] = "El Ojo Violeta";
};

GUILDADSTOOLTIPS_ADS_TITLE = TRADE;
GUILDADSTOOLTIPS_ADS =  "Te permite ver los anuncios actuales de tus compañeros de GuildAds";

GUILDADSTOOLTIPS_SKILL_TITLE = GUILDADS_HEADER_SKILL;
GUILDADSTOOLTIPS_SKILL =  "Te permite ver las habilidades y profesiones de tus compañeros de GuildAds";

GUILDADSTOOLTIPS_GUILD_TITLE = GUILD;
GUILDADSTOOLTIPS_GUILD = "Te permite ver la lista de tus compañeros de GuildAds";

end
