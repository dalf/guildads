----------------------------------------------------------------------------------
--
-- localization.de.lua
--
-- Authors: T-Base, Gobaresch, Graurock, Cloudernia
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

if ( GetLocale() == "deDE" ) then

GUILDADS_TITLE = "GuildAds";

-- Minimap button
GUILDADS_BUTTON_TIP = "Klicken Sie hier um GuildAds zu \195\182ffnen.";

-- Config
GUILDADS_CHAT_OPTIONS = "Chat Optionen";
GUILDADS_CHAT_USETHIS = "Benutze diesen Kanal:";
GUILDADS_CHAT_CHANNEL = "Name";
GUILDADS_CHAT_PASSWORD = "Passwort";
GUILDADS_CHAT_COMMAND = "Slash Befehl";
GUILDADS_CHAT_ALIAS = "Kanal Alias";
GUILDADS_CHAT_SHOW_NEWEVENT = "Zeige Aktualisierungen bei 'Event'";
GUILDADS_CHAT_SHOW_NEWASK = "Zeige Aktualisierungen bei 'Anfrage'";
GUILDADS_CHAT_SHOW_NEWHAVE = "Zeige Aktualisierungen bei 'Angebote'";
GUILDADS_ADS_OPTIONS = "Ads Optionen";
GUILDADS_FACTION_OPTIONS	= "Fraktionen Einstellungen";
GUILDADS_FACTION_HIDE_COLLAPSED = "Verstecke Eingeklappte";
GUILDADS_FACTION_ONLY_LEVEL_70	= "Zeige nur Level 70 Spieler";
GUILDADS_FACTION_FACTION	= "Zeige Fraktion"; -- Should be updated runtime to either Horde or Alliance
GUILDADS_PUBLISH = "Ver\195\182ffentliche meine Anzeigen";
GUILDADS_VIEWMYADS = "Zeige auch meine eigenen Gesuche/Angebote";
GUILDADS_ICON_OPTIONS = "Minikartensymbol Optionen";
GUILDADS_ICON = "Minikartensymbol";
GUILDADS_ADJUST_ANGLE = "Winkel anpassen";
GUILDADS_ADJUST_RADIUS = "Radius anpassen";

GUILDADS_AUTOCHANNELCONFIG = "Automatische Kanal Konfiguration";
GUILDADS_MANUALCHANNELCONFIG = "Manuelle Kanal Konfiguration";

GUILDADS_ERROR_NOTINITIALIZED 	= "GuildAds ist noch nicht initialisiert."

GUILDADS_ERROR_TOOMANYCHANNELS = "Man kann immer nur in h\195\182chstens 10 Kan\195\164len gleichzeitig sein"; 
GUILDADS_ERROR_JOINCHANNELFAILED = "Fehler beim Betreten des Kanals";
GUILDADS_ERROR_WRONGPASSWORD = "Falsches Passwort";

-- Main frame
GUILDADS_MYADS = "Meine Gesuche/Angebote";
GUILDADS_BUTTON_ADDREQUEST = "Suchen";
GUILDADS_BUTTON_ADDAVAILABLE = "Anbieten";
GUILDADS_BUTTON_REMOVE = REMOVE;
GUILDADS_QUANTITY = "Anzahl";
GUILDADS_SINCE = "Seit %s";
GUILDADS_SIMPLE_SINCE = "Seit";
GUILDADS_GROUPBYACCOUNT = "Nach Accounts gruppieren";

GUILDADS_TRADE_PROVIDER = "von";
GUILDADS_TRADE_NUMBER="Anz.";
GUILDADS_TRADE_OBJECT="Item";
GUILDADS_TRADE_ACTIVE="Aktiv";
GUILDADS_TRADE_TYPE="Typ";
GUILDADS_TRADE_SHIFTCLICKHELP="Halten Sie die SHIFT (HOCHSTELLEN) Taste gedr\195\188ckt w\195\164hrend Sie auf ein Item klicken, um es hier einzuf\195\188gen.";
-- Column headers
GUILDADS_HEADER_REQUEST = "Gesucht";
GUILDADS_HEADER_AVAILABLE = "Angeboten";
GUILDADS_HEADER_INVENTORY = INSPECT;
GUILDADS_HEADER_SKILL = SKILLS;
GUILDADS_HEADER_ANNONCE = GUILD;
GUILDADS_HEADER_FACTION	= "Ruf";
GUILDADS_HEADER_EVENT = "Events";

GUILDADS_GUILD_GROUPWITHACCOUNT	= "Gruppiere %s mit dem Account von %s";
GUILDADS_GUILD_DEGROUP		= "Vom Account l\195\182sen";
GUILDADS_GUILD_BLACKLIST	= "Schwarze Liste"; 
-- fertig/completed


GUILDADS_ITEMS = {
	everything = "Alles",
	everythingelse = "Alles andere",
	monster = "Monster drops",
	classReagent = "Klassen Reagenzien",
	tradeReagent = "Handelsfertigkeitsreagenz",
	vendor = "H\195\164ndler",
	trade = "Herstellbar",
	gather = "Sammelbar",
};

GUILDADS_ITEMS_SIMPLE = {
	everything = "Alles"
};

-- Equipment
GUILDADS_EQUIPMENT = "Ausr\195\188stung";

-- Tooltip requests
GUILDADS_ASKTOOLTIP = "Anfragen: %i";

-- GuildAds
GUILDADS_TS_LINK = GUILDADS_TITLE;
GUILDADS_TS_ASKITEMS = "Nachfrage nach %i %s";
GUILDADS_TS_ASKITEMS_TT = "\195\132ndere die Objektanzahl um die Anzahl zu \195\164ndern.";

-- Binding
BINDING_HEADER_GUILDADS = GUILDADS_TITLE;
BINDING_NAME_SHOW = "GuildAds anzeigen";
BINDING_NAME_SHOW_CONFIG = "GuildAds Konfiguration anzeigen"

GUILDADS_RACES = {
	[1] = "Mensch",
	[2] = "Zwerg",
	[3] = "Nachtelf",
	[4] = "Gnom",
	[5] = "Orc",
	[6] = "Untoter",
	[7] = "Tauren",
	[8] = "Troll",
	[9] = "Draenei",
	[10] = "Blutelf"
};

GUILDADS_CLASSES = {
	[1] = "Krieger",
	[2] = "Schamane",
	[3] = "Paladin",
	[4] = "Druide",
	[5] = "Schurke",
	[6] = "J\195\164ger",
	[7] = "Hexenmeister",
	[8] = "Magier",
	[9] = "Priester"
};

-- Skill
GUILDADS_SKILLS = {
	[1] = "Kr\195\164uterkunde",
	[2] = "Bergbau",
	[3] = "K\195\188rschnerei",
	[4] = "Alchimie",
	[5] = "Schmiedekunst",
	[6] = "Ingenieurskunst",
	[7] = "Lederverarbeitung",
	[8] = "Schneiderei",
	[9] = "Verzauberkunst",
	[10] = "Angeln",
	[11] = "Erste Hilfe",
	[12] = "Kochkunst",
	[13] = "Schlossknacken",
	[14] = "Juwelenschleifen",

	[20] = "Faustwaffen",
	[21] = "Dolche",
	[22] = "Schwerter",
	[23] = "Zweihandschwerter",
	[24] = "Streitkolben",
	[25] = "Zweihandstreitkolben",
	[26] = "\195\132xte",
	[27] = "Zweihand\195\164xte",
	[28] = "Stangenwaffen",
	[29] = "St\195\164be",
	[30] = "Wurfwaffen",
	[31] = "Schusswaffen",
	[32] = "Bogen",
	[33] = "Armbr\195\188ste",
	[34] = "Zauberst\195\164be"
};

GUILDADSTOOLTIPS_ADS_TITLE = TRADE;
GUILDADSTOOLTIPS_ADS =  "Zeigt Dir die aktuellen Angebote Deiner Gilden Mitglieder";

GUILDADSTOOLTIPS_SKILL_TITLE = GUILDADS_HEADER_SKILL;
GUILDADSTOOLTIPS_SKILL =  "Zeigt Dir die Fertigkeiten und Berufe Deiner Gilden Mitglieder";

GUILDADSTOOLTIPS_GUILD_TITLE = GUILD;
GUILDADSTOOLTIPS_GUILD = "Zeigt Dir Deine aktuelle Gilden Mitglieder Liste";

--Factions (only factions mentioned here can be synchronized)
-- Taken from http://www.wowwiki.com/Reputation#Reputation_sheet
GUILDADS_FACTIONS = {
	[1]  = "Darnassus";  -- Alliance
	[2]  = "Die Exodar";
	[3]  = "Gnomeregangnome";
	[4]  = "Eisenschmiede";
	[5]  = "Sturmwind";
	[6]  = "Silberschwingen"; -- Alliance -PvP
	[7]  = "Sturmlanzengarde";
	[8]  = "Der Bund von Arathor";
	[9]  = "Darkspear Trolls"; -- Horde
	[10] = "Orgrimmar";
	[11] = "Silbermond Stadt";
	[12] = "Thunder Bluff";
	[13] = "Unterstadt";
	[14] = "Frostwolf Clan"; -- Horde - PvP
	[15] = "The Defilers";
	[16] = "Warsong Outriders";
	[17] = "Ehrenfeste"; -- Outland
	[18] = "Thrallmar";
	[19] = "Kurenai";
	[20] = "Die Mag'har";
	[21] = "Expedition des Cenarius";
	[22] = "Sporeggar";
	[23] = "Das Konsortium";
	[24] = "Netherschwingen";
	[25] = "Ogri'la";
	[26] = "Die Todesh\195\182rigen";
	[27] = "Unteres Viertel"; -- Shattrath City
	[28] = "Himmelswache der Sha'tari";
	[29] = "Die Aldor";
	[30] = "Die Seher";
	[31] = "Die Sha'tar";
	[55] = "Offensive der Zerschmetterten Sonne";
	[32] = "Beutebucht"; -- Dampfdruckkartell
	[33] = "Ewige Warte";
	[34] = "Gadgetzan";
	[35] = "Ratschet";
	[36] = "Argentumd\195\164mmerung"; -- Other
	[37] = "Blutsegelbukaniere";
	[38] = "Brut Nozdormus";
	[39] = "Zirkel des Cenarius";
	[40] = "Dunkelmond-Jahrmarkt";
	[41] = "Gelkisklan";
	[42] = "Hydraxianer";
	[43] = "Magramklan";
	[44] = "Rabenholdt";
	[45] = "Shen'dralar";
	[46] = "Syndikat";
	[47] = "Thoriumbruderschaft";
	[48] = "Holzschlundfeste";
	[49] = "Winters\195\164blerausbilder";
	[50] = "Stamm der Zandalar";
	[51] = "H\195\188ter der Zeit"; -- Other - BC
	[52] = "Die W\195\164chter der Sande";
	[53] = "Tranquillien";
	[54] = "Das Violette Auge";
};

-- Left side: Profile options (do NOT modify), Right side: CheckButton label
--GUILDADS_FACTION_GROUP_LABELS = {
--	"ShowFaction" = "Zeige Fraktion",
--	"ShowFactionForces" = "Zeige Fraktion Einheiten",
--	"ShowOutland" = "Zeige Scherbenwelt",
--	"ShowShattrathCity" = "Zeige Shattrath Stadt",
--	"ShowSteamwheedleCartel" = "Zeige Dampfdruckkartell",
--	"ShowOther" = "Zeige Sonstige"
--};
GUILDADS_FACTION_SHOWFACTION = "Zeige Fraktion";
GUILDADS_FACTION_SHOWFACTIONFORCES = "Zeige Fraktion Einheiten";
GUILDADS_FACTION_SHOWOUTLAND = "Zeige Scherbenwelt";
GUILDADS_FACTION_SHOWSHATTRATHCITY = "Zeige Shattrath Stadt";
GUILDADS_FACTION_SHOWSTEAMWHEEDLECARTEL = "Zeige Dampfdruckkartell";
GUILDADS_FACTION_SHOWOTHER = "Zeige Sonstige";

end
