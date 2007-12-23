if GetLocale() == "esES" then
GUILDADS_TITLE			= "GuildAds";

-- Minimap button
GUILDADS_BUTTON_TIP		= "Click aquí para mostrar/ocultar GuildAds.";

-- Options frame
GUILDADS_OPTIONS_TITLE		= "Opciones de GuildAds";
GUILDADS_CHAT_OPTIONS		= "Configuración de chat";
GUILDADS_CHAT_USETHIS		= "Usar este canal :";
GUILDADS_CHAT_CHANNEL		= "Nombre";
GUILDADS_CHAT_PASSWORD		= "Password";
GUILDADS_CHAT_COMMAND		= "Comando de barra";
GUILDADS_CHAT_ALIAS 		= "Alias de Canal";
GUILDADS_CHAT_SHOW_NEWEVENT	= "Mostrar noticias de 'Eventos'"
GUILDADS_CHAT_SHOW_NEWASK	= "Mostrar noticias de 'Pedir'";
GUILDADS_CHAT_SHOW_NEWHAVE	= "Mostrar noticias de 'Ofrecer'";
GUILDADS_ADS_OPTIONS		= "Configuración de Anuncios";
GUILDADS_PUBLISH		= "Publicar mis anuncios";
GUILDADS_VIEWMYADS		= "Mostrar mis anuncios";
GUILDADS_ICON_OPTIONS		= "Configurar icono del minimapa";
GUILDADS_ICON			= "Icono del minimapa";
GUILDADS_ADJUST_ANGLE		= "Ajustar ángulo";
GUILDADS_ADJUST_RADIUS		= "Ajustar radio";

GUILDADS_AUTOCHANNELCONFIG	= "Configurar canal automáticamente";
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
GUILDADS_TRADE_SHIFTCLICKHELP 	= "Para poner un objeto aquí, haz shift+click en él con esta ventana abierta";

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
	everythingelse = "Todo lo demás",
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
BINDING_NAME_SHOW_CONFIG = "Mostrar configuración de GuildAds"

GUILDADS_CMD = { "/guildads" }
GUILDADS_CMD_OPTIONS = {
	{
		option = "toggle",
		desc = BINDING_NAME_SHOW,
		method = "ToggleMainWindow"
	},
	{
		option = "options",
		desc = BINDING_NAME_SHOW_CONFIG,
		method = "ToggleOptionsWindow"
	},
	{
		option = "debug",
		desc = "Activa/desactiva mensajes de debug",
		args = {
			{
				option = "on",
				desc = "Activa mensajes de debug",
				method = "ToggleDebugOn",
			},
			{
				option = "off",
				desc = "Desactiva mensajes de debug",
				method = "ToggleDebugOff"
			},
			{
				option = "info",
				desc = "Muestra información general de debug",
				method = "DisplayDebugInfo"
			}
		}
	},
	{
		option = "reset",
		desc = "Reiniciar base de datos",
		args = {
			{
				option = "all",
				desc = "Reinicias todas las bases de datos excepto información de cuenta",
				method = "ResetAll"
			},
			{
				option = "channel",
				desc = "Reiniciar datos de canales",
				method = "ResetChannel"
			},
			{
				option = "others",
				desc = "Reiniciar toda la información sobre otros jugadores",
				method = "ResetOthers"
			}
		}
	},
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
	[2] = "Chamán",
	[3] = "Paladín",
	[4] = "Druida",
	[5] = "Pícaro",
	[6] = "Cazador",
	[7] = "Brujo",
	[8] = "Mago",
	[9] = "Sacerdote"
};


-- Skill
GUILDADS_SKILLS	= {
	[1]  = "Herbalismo",
	[2]  = "Minería",
	[3]  = "Desollar",
	[4]  = "Alquimia",
	[5]  = "Herrería",
	[6]  = "Ingeniería",
	[7]  = "Peletería",
	[8]  = "Sastrería",
	[9]  = "Encantamiento",
	[10] = "Pesca",
	[11] = "Primeros Auxilios",
	[12] = "Cocina",
	[13] = "Ganzúa",
	[14] = "Joyería",
	
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
	[14] = "Clan Lobo Gélido";
	[15] = "Los Rapiñadores";
	[16] = "Escoltas Grito de Guerra";
	[17] = "Bastión del Honor";
	[18] = "Thrallmar";
	[19] = "Kurenai";
	[20] = "Los Mag'har";
	[21] = "Expedición Cenarion";
	[22] = "Esporaggar";
	[23] = "El Consorcio";
	[24] = "Ala Abisal";
	[25] = "Ogri'la";
	[26] = "Juramorte Lengua de ceniza";
	[27] = "Bajo Arrabal";
	[28] = "Guardia del cielo Sha'tari";
	[29] = "Los Aldor";
	[30] = "Los Arúspices";
	[31] = "Los Sha'tar";
	[32] = "Bahía del Botín";
	[33] = "Vista Eterna";
	[34] = "Gadgetzan";
	[35] = "Trinquete";
	[36] = "El Alba Argenta";
	[37] = "Bucaneros Velasangre";
	[38] = "Linaje de Nozdormu";
	[39] = "Círculo Cenarion";
	[40] = "Feria de la Luna Negra";
	[41] = "Gelkis Clan Centaur";
	[42] = "Srs. del Agua de Hydraxis";
	[43] = "Magram Clan Centaur";
	[44] = "Ravenholdt";
	[45] = "Shen'dralar";
	[46] = "Syndicate"; -- to translate
	[47] = "Hermandad del torio";
	[48] = "Bastión Fauces de Madera";
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
