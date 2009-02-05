----------------------------------------------------------------------------------
--
-- localization.de.lua
--
-- Authors: T-Base, Gobaresch, Graurock, Cloudernia, HolySheep
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

if ( GetLocale() == "deDE" ) then

GUILDADS_TITLE			= "GuildAds";

-- Minimap button
GUILDADS_BUTTON_TIP		= "Hier klicken um GuildAds zu \195\182ffnen.";
GUILDADS_UPGRADE_TIP		= "Neues GuildAds verfügbar: ";
GUILDADS_UPGRADE_TIP		= "Es ist eine neue Version von GuildAds verfügbar: ";
GUILDADS_STATUS_TIP		= "Verbleibende Suchl\195\164ufe:";

-- Options frame
GUILDADS_OPTIONS_TITLE		= "GuildAds Optionen";
GUILDADS_CHAT_OPTIONS		= "Chat Einstellungen";
GUILDADS_CHAT_USETHIS		= "Diesen Kanal benutzen :";
GUILDADS_CHAT_CHANNEL		= "Name";
GUILDADS_CHAT_PASSWORD		= "Passwort";
GUILDADS_CHAT_COMMAND		= "Slash Befehl";
GUILDADS_CHAT_ALIAS 		= "Kanal Alias";
GUILDADS_CHAT_SHOW_NEWEVENT	= "Zeige Aktualisierungen von 'Event'"
GUILDADS_CHAT_SHOW_NEWASK	= "Zeige Aktualisierungen von 'Gesuche'";
GUILDADS_CHAT_SHOW_NEWHAVE	= "Zeige Aktualisierungen von 'Angebote'";
GUILDADS_ADS_OPTIONS		= "Ads Einstellungen";
GUILDADS_PUBLISH		= "Publish my ads";
GUILDADS_VIEWMYADS		= "Meine Ads anzeigen";
GUILDADS_ICON_OPTIONS		= "Minikarten-Icon Einstellungen";
GUILDADS_ICON			= "Minikarten-Icon";
GUILDADS_ADJUST_ANGLE		= "Winkel einstellen";
GUILDADS_ADJUST_RADIUS		= "Radius einstellen";

GUILDADS_AUTOCHANNELCONFIG	= "Automatische Kanal Konfirguration";
GUILDADS_MANUALCHANNELCONFIG	= "Manuelle Kanal Konfiguration";

GUILDADS_ERROR_NOTINITIALIZED 	= "GuildAds ist nicht initialisiert."

GUILDADS_ERROR_TOOMANYCHANNELS	= "Du bist schon der maximalen Anzahl an Kanälen beigetreten"; 
GUILDADS_ERROR_JOINCHANNELFAILED = "Konnte dem Kanal aus unbekannten Grund nicht beitreten";
GUILDADS_ERROR_WRONGPASSWORD 	= "Das Passwort ist falsch";

GUILDADS_NEWDATATYPEVERSION	= "Datentyp \"%s\" : %s hat die neue Version %s. Bis du deine Version aktualisierst werden keine Updates durchgeführt.";

-- Main frame
GUILDADS_MYADS			= "Meine Gesuche/Angebote";
GUILDADS_BUTTON_ADDREQUEST	= "Suchen";
GUILDADS_BUTTON_ADDAVAILABLE	= "Anbieten";
GUILDADS_BUTTON_REMOVE		= REMOVE;
GUILDADS_QUANTITY		= "Anzahl";
GUILDADS_SINCE			= "Seit %s";
GUILDADS_SIMPLE_SINCE		= "Seit";
GUILDADS_GROUPBYACCOUNT		= "Nach Accounts gruppieren";


GUILDADS_TRADE_PROVIDER 	= "von";
GUILDADS_TRADE_NUMBER		= "Anz.";
GUILDADS_TRADE_OBJECT		= "Item";
GUILDADS_TRADE_ACTIVE		= "Aktiv";
GUILDADS_TRADE_TYPE		= "Typ";
GUILDADS_TRADE_SHIFTCLICKHELP 	= "Halte die SHIFT (HOCHSTELLEN) Taste gedr\195\188ckt w\195\164hrend du auf ein Item klickst, um es hier einzuf\195\188gen.";
GUILDADS_TRADE_MINLEVEL		= "Min. Level";

-- Column headers
GUILDADS_HEADER_REQUEST		= "Gesucht";
GUILDADS_HEADER_AVAILABLE	= "Angeboten";
GUILDADS_HEADER_INVENTORY	= INSPECT;
GUILDADS_HEADER_SKILL 		= SKILLS;
GUILDADS_HEADER_ANNONCE		= GUILD;
GUILDADS_HEADER_FACTION		= "Ruf";
GUILDADS_HEADER_EVENT		= "Events";
GUILDADS_HEADER_FORUM		= "Forum";

GUILDADS_GUILD_GROUPWITHACCOUNT	= "Gruppiere %s mit dem Account von %s";
GUILDADS_GUILD_DEGROUP		= "Gruppierung von dem Account l\195\182sen";
GUILDADS_GUILD_BLACKLIST	= "Schwarze Liste"; 

GUILDADS_FORUM_SUBJECT		= MAIL_SUBJECT_LABEL; --"Subject:"
GUILDADS_FORUM_AUTHOR		= "Autor";
GUILDADS_FORUM_DATE		= "Datum";
GUILDADS_FORUM_NEWPOST		= "Neu";
GUILDADS_FORUM_EDITPOST		= "Bearbeiten";
GUILDADS_FORUM_REPLY		= REPLY_MESSAGE; --"Reply"
GUILDADS_FORUM_STICKY		= "Wichtig";
GUILDADS_FORUM_LOCKED		= "Geschlossen";
GUILDADS_FORUM_OFFICERPOST	= "Offiziersbeitrag";
GUILDADS_FORUM_POST		= "Abschicken";
GUILDADS_FORUM_EMPTYSUBJECT	= "<kein Titel>";
GUILDADS_FORUM_DELETEPOST	= "Beitrag löschen";

-- Item
GUILDADS_ITEMS = {
	everything = "Alles",
	everythingelse = "Alles Andere",
	monster = "Monster drops",
	classReagent = "Klassenreagenzien",
	tradeReagent = "Berufsreagenzien",
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
GUILDADS_ASKTOOLTIP = "%i Anfrage(n)";
				
-- GuildAds button in craft frame
GUILDADS_TS_LINK = GUILDADS_TITLE;
GUILDADS_TS_ASKITEMS = "Nachfragen nach %i %s";
GUILDADS_TS_ASKITEMS_TT	= "\195\132ndere die Objektanzahl um die Anzahl zu \195\164ndern.";

-- Binding
BINDING_HEADER_GUILDADS	= GUILDADS_TITLE;
BINDING_NAME_SHOW = "Zeige GuildAds";
BINDING_NAME_SHOW_CONFIG = "Zeige GuildAds Konfiguration"

-- Race
GUILDADS_RACES	= {
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

-- Class				
GUILDADS_CLASSES = {
	[1] = "Krieger",
	[2] = "Schamane",
	[3] = "Paladin",
	[4] = "Druide",
	[5] = "Schurke",
	[6] = "J\195\164ger",
	[7] = "Hexenmeister",
	[8] = "Magier",
	[9] = "Priester",
	[10] = "Todesritter"
};


-- Skill
GUILDADS_SKILLS	= {
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
	[15] = "Inschriftenkunde", -- NEW patch 3.02
	
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
GUILDADSTOOLTIPS_ADS =  "Zeigt dir die aktuellen Angebote deiner Gildenmitglieder";

GUILDADSTOOLTIPS_FACTION_TITLE = GUILDADS_HEADER_FACTION;
GUILDADSTOOLTIPS_FACTION = "Zeigt dir den Fraktionsruf deiner Gildenmitglieder";

GUILDADSTOOLTIPS_SKILL_TITLE = GUILDADS_HEADER_SKILL;
GUILDADSTOOLTIPS_SKILL = "Zeigt dir die Fertigkeiten und Berufe deiner Gildenmitglieder";

GUILDADSTOOLTIPS_GUILD_TITLE = GUILD;
GUILDADSTOOLTIPS_GUILD = "Zeigt dir deine aktuelle Gildenmitglieder Liste";

GUILDADSTOOLTIPS_FORUM_TITLE = GUILDADS_HEADER_FORUM;
GUILDADSTOOLTIPS_FORUM = "Zeigt dir das Ingame GuildAds Forum";

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
	[9]  = "Dunkelspeertrolle"; -- Horde
	[10] = "Orgrimmar";
	[11] = "Silbermond";
	[12] = "Donnerfels";
	[13] = "Unterstadt";
	[14] = "Frostwolfklan"; -- Horde - PvP
	[15] = "Die Entweihten";
	[16] = "Kriegshymnenklan";
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
	[27] = "Unteres Viertel"; -- Shattrath
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
	[56] = "Ritter der Schwarzen Klinge", -- WotLK -- Other
	[57] = "Argentumkreuzzug", -- Nordend
	[58] = "Forscherliga",
	[59] = "Stamm der Wildherzen",
	[60] = "Die Frosterben",
	[61] = "Die Hand der Rache",
	[62] = "Die Kalu'ak",
	[63] = "Die Orakel",
	[64] = "Die S\195\182hne Hodirs",
	[65] = "Die Taunka",
	[66] = "Expedition Valianz",
	[67] = "Kriegshymnenoffensive",
	[68] = "Der Wyrmruhpakt",
	[69] = "Kirin Tor", -- Dalaran
	[70] = "Der Silberbund",
	[71] = "Die Sonnenh\195\164scher"
}; -- The last one used is 71

GUILDADS_FACTION_OPTIONS	= "Fraktionseinstellungen";
GUILDADS_FACTION_HIDE_COLLAPSED = "Verberge zusammengefasste Fraktionen";
GUILDADS_FACTION_ONLY_LEVEL_80	= "Zeige nur Level 80 Spieler";
GUILDADS_FACTION_FACTION	= "Zeige Fraktion"; -- Should be updated runtime to either Horde or Alliance

GUILDADS_FACTION_SHOWFACTION = "Zeige Fraktion";
GUILDADS_FACTION_SHOWFACTIONFORCES = "Zeige Fraktionsstreitkr\195\164fte";
GUILDADS_FACTION_SHOWOUTLAND = "Zeige Scherbenwelt";
GUILDADS_FACTION_SHOWSHATTRATHCITY = "Zeige Shattrath";
GUILDADS_FACTION_SHOWSTEAMWHEEDLECARTEL = "Zeige Dampfdruckkartell";
GUILDADS_FACTION_SHOWOTHER = "Zeige Andere";
GUILDADS_FACTION_SHOWNORTHREND = "Zeigen Nordend";
GUILDADS_FACTION_SHOWDALARAN = "Zeige Dalaran";
GUILDADS_FACTION_SHOWRAID = "Zeige Raid"


GUILDADS_OPTIONS = {
	["toggle"]			= BINDING_NAME_SHOW;
	["options"]			= BINDING_NAME_SHOW_CONFIG;
	["debug"] 			= "Umschalten der Anzeige von Debugmeldungen";
	["info"] 			= "Zeige allgemeine Debuginformationen";
	["reset"]			= "Datenbank zur\195\188cksetzen";
	["reset all"]		= "Alles bist auf Accountinformationen zur\195\188cksetzen";
	["reset channel"]	= "Alle Kanaldaten zur\195\188cksetzen";
	["reset others"]	= "Alle Informationen \195\188ber andere Spieler zur\195\188cksetzen";
	["reset player"]	= "Alle Informationen eines bestimmten Spielers zur\195\188cksetzen";
	["clean"]			= "Datenbank \195\164";
	["clean other"]		= "L\195\182sche Berufsinformationen von anderen Accounts die keine Rezeptlinks haben";
	["admin"]			= "Zugriffskontrolle von Spielern und Gilden";
	["admin show"]		= "Zeige derzeitige Zugriffskontrollliste";
	["admin deny"]		= "Verweigere Spieler oder @Gilde Zugriff (Löscht Spielerdaten)";
	["admin allow"]		= "Erlaube Spieler oder @Gilde Zugriff (Löscht Spielerdaten)";
	["admin remove"]	= "Lösche Spieler oder @Gilde von Zugriffskontrollliste";
	["admin allowed"]	= "\195\156berpr\195\188ft ob ein Spieler Zugriff hat";
}

end
