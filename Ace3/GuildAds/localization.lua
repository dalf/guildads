GUILDADS_TITLE			= "GuildAds";

-- Minimap button
GUILDADS_BUTTON_TIP		= "Click here to show or hide GuildAds.";
GUILDADS_UPGRADE_TIP		= "New GuildAds available: ";
GUILDADS_UPGRADE_TIP		= "There is a newer version of GuildAds available: ";
GUILDADS_STATUS_TIP		= "Remaining searches:";

GUILDADS_MAJOR_VERSION		= "GuildAds: New incompatible protocol noticed. Please upgrade."
GUILDADS_OLD_PROTOCOL = "%s is using old and incompatible protocol"
GUILDADS_BLACKLISTED_PLAYER = "GuildAds: Blacklisted player %s attempts to log on."

-- Options frame
GUILDADS_OPTIONS_TITLE		= "GuildAds options";
GUILDADS_CHAT_OPTIONS		= "Chat settings";
GUILDADS_CHAT_USETHIS		= "Use this channel :";
GUILDADS_CHAT_CHANNEL		= "Name";
GUILDADS_CHAT_PASSWORD		= "Password";
GUILDADS_CHAT_COMMAND		= "Slash Command";
GUILDADS_CHAT_ALIAS 		= "Channel Alias";
GUILDADS_CHAT_SHOW_NEWEVENT	= "Show news about 'Event'"
GUILDADS_CHAT_SHOW_NEWASK	= "Show news about 'Ask'";
GUILDADS_CHAT_SHOW_NEWHAVE	= "Show news about 'Have'";
GUILDADS_TOOLTIP_TAB		= "Tooltip";
GUILDADS_TOOLTIP_OPTIONS	= "Tooltip settings";
GUILDADS_TOOLTIP_SHOW_CRAFTED_BY = "Show 'Made by'" ;
GUILDADS_TOOLTIP_SHOW_NEW	= "Show 'Ask'";
GUILDADS_TOOLTIP_SHOW_HAVE	= "Show 'Have'";
GUILDADS_TOOLTIP_SHOW_EXTRA_TOOLTIP = "Show craft tooltip";
GUILDADS_TOOLTIP_SCALE		= "Craft tooltip scale";
GUILDADS_TOOLTIP_USED		= "GuildAds:";
GUILDADS_ADS_OPTIONS		= "Ads settings";
GUILDADS_PUBLISH		= "Publish my ads";
GUILDADS_VIEWMYADS		= "Show my ads";
GUILDADS_ICON_OPTIONS		= "Minimap icon settings";
GUILDADS_ICON			= "Minimap icon";
GUILDADS_ADJUST_ANGLE		= "Adjust angle";
GUILDADS_ADJUST_RADIUS		= "Adjust radius";

GUILDADS_AUTOCHANNELCONFIG	= "Automatic channel configuration";
GUILDADS_MANUALCHANNELCONFIG	= "Manual channel configuration";

GUILDADS_ERROR_NOTINITIALIZED 	= "GuildAds is not initialized."

GUILDADS_ERROR_TOOMANYCHANNELS	= "You have already joined the maximum number of channels"; 
GUILDADS_ERROR_JOINCHANNELFAILED = "Failed to join the channel for an unknown reason";
GUILDADS_ERROR_WRONGPASSWORD 	= "The password is incorrect";

GUILDADS_NEWDATATYPEVERSION	= "Data type \"%s\" : %s has the new version %s. Until you upgrade to this version, update are disabled.";

-- Main frame
GUILDADS_MYADS			= "My Ads";
GUILDADS_BUTTON_ADDREQUEST	= "Ask";
GUILDADS_BUTTON_ADDAVAILABLE	= "Have";
GUILDADS_BUTTON_REMOVE		= REMOVE;
GUILDADS_QUANTITY		= "Quantity";
GUILDADS_SINCE			= "Since %s";
GUILDADS_SIMPLE_SINCE		= "Since";
GUILDADS_GROUPBYACCOUNT		= "Group by account";


GUILDADS_TRADE_PROVIDER 	= "By";
GUILDADS_TRADE_NUMBER		= "Nb";
GUILDADS_TRADE_OBJECT		= "Item";
GUILDADS_TRADE_ACTIVE		= "Active";
GUILDADS_TRADE_TYPE		= "Type";
GUILDADS_TRADE_SHIFTCLICKHELP 	= "To put an item here, shift-click it while this window is opened";
GUILDADS_TRADE_MINLEVEL		= "MinLevel";
GUILDADS_TRADE_ALT_TOOLTIP	= "Hold ALT for craft tooltip";
GUILDADS_TRADE_SEARCHHELP	= "Use regular expression\nSpecial characters: ().%+-*?[]^$\nEscape with % (e.g. [ -> %[ )";

-- Column headers
GUILDADS_HEADER_REQUEST		= "Ask";
GUILDADS_HEADER_AVAILABLE	= "Have";
GUILDADS_HEADER_INVENTORY	= INSPECT;
GUILDADS_HEADER_SKILL 		= SKILLS;
GUILDADS_HEADER_ANNONCE		= GUILD;
GUILDADS_HEADER_FACTION		= "Reputation";
GUILDADS_HEADER_EVENT		= "Events";
GUILDADS_HEADER_FORUM		= "Forum";
GUILDADS_HEADER_QUEST		= QUESTS_LABEL; -- "Quests";

GUILDADS_SKILL_TOOLTIP		= "TradeLink available"
GUILDADS_SKILL_TOOLTIP2		= "Click to open tradelink\nShift-click to send tradelink"

GUILDADS_QUEST_GROUP		= "Quest group";
GUILDADS_QUEST_NAME		= "Quest name";
GUILDADS_QUEST_TYPE		= "Difficulty";
GUILDADS_QUEST_PLAYERS		= "Players";
GUILDADS_QUEST_ONLYMYQUESTS	= "Show only my quests";

GUILDADS_GUILD_GROUPWITHACCOUNT	= "Group %s with the account of %s";
GUILDADS_GUILD_DEGROUP		= "Degroup from the account";
GUILDADS_GUILD_BLACKLIST	= "Blacklist"; 

GUILDADS_FORUM_SUBJECT		= MAIL_SUBJECT_LABEL; --"Subject:"
GUILDADS_FORUM_AUTHOR		= "Author";
GUILDADS_FORUM_DATE		= "Date";
GUILDADS_FORUM_NEWPOST		= "New";
GUILDADS_FORUM_EDITPOST		= "Edit";
GUILDADS_FORUM_REPLY		= REPLY_MESSAGE; --"Reply"
GUILDADS_FORUM_STICKY		= "Sticky";
GUILDADS_FORUM_LOCKED		= "Locked";
GUILDADS_FORUM_OFFICERPOST	= "Officer post";
GUILDADS_FORUM_POST		= "Post";
GUILDADS_FORUM_EMPTYSUBJECT	= "<no subject>";
GUILDADS_FORUM_DELETEPOST	= "Delete post";

-- Item
GUILDADS_ITEMS = {
	everything = "Everything",
	everythingelse = "Everything else",
	monster = "Monster drop",
	classReagent = "Class reagents",
	tradeReagent = "Tradeskills reagents",
	vendor = "Vendor",
	trade = "Tradeskills production",
	gather = "Gather",
};
				
GUILDADS_ITEMS_SIMPLE = {
	everything = "Everything"
};

-- Equipment
GUILDADS_EQUIPMENT = "Equipment";

-- Tooltip requests
GUILDADS_ASKTOOLTIP = "%i request(s)";
				
-- GuildAds button in craft frame
GUILDADS_TS_LINK = GUILDADS_TITLE;
GUILDADS_TS_ASKITEMS = "Ask for items of %i %s";
GUILDADS_TS_ASKITEMS_TT	= "Modify the number of objects to be created to set the quantities.";

-- Binding
BINDING_HEADER_GUILDADS	= GUILDADS_TITLE;
BINDING_NAME_SHOW = "Show GuildAds";
BINDING_NAME_SHOW_CONFIG = "Show GuildAds configuration"

-- Race
GUILDADS_RACES	= {
	[1] = "Human",
	[2] = "Dwarf",
	[3] = "Night Elf",
	[4] = "Gnome",
	[5] = "Orc",
	[6] = "Undead",
	[7] = "Tauren",
	[8] = "Troll",
	[9] = "Draenei",
	[10] = "Blood Elf"
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
	[1] = "Warrior",
	[2] = "Shaman",
	[3] = "Paladin",
	[4] = "Druid",
	[5] = "Rogue",
	[6] = "Hunter",
	[7] = "Warlock",
	[8] = "Mage",
	[9] = "Priest",
	[10] = "Death Knight"
};


-- Skill
GUILDADS_SKILLS	= {
	[1]  = "Herbalism",
	[2]  = "Mining",
	[3]  = "Skinning",
	[4]  = "Alchemy",
	[5]  = "Blacksmithing",
	[6]  = "Engineering",
	[7]  = "Leatherworking",
	[8]  = "Tailoring",
	[9]  = "Enchanting",
	[10] = "Fishing",
	[11] = "First Aid",
	[12] = "Cooking",
	[13] = "Lockpicking",
	[14] = "Jewelcrafting",
	[15] = "Inscription", -- NEW patch 3.02
	
	[20] = "Unarmed", -- was known as "Fist Weapons"
	[21] = "Daggers",
	[22] = "Swords",
	[23] = "Two-Handed Swords",
	[24] = "Maces",
	[25] = "Two-Handed Maces",
	[26] = "Axes",
	[27] = "Two-Handed Axes",
	[28] = "Polearms",
	[29] = "Staves",
	[30] = "Thrown",
	[31] = "Guns",
	[32] = "Bows",
	[33] = "Crossbows",
	[34] = "Wands"
};




GUILDADSTOOLTIPS_ADS_TITLE = TRADE;
GUILDADSTOOLTIPS_ADS =  "Allow you to see the current adds of your guildads mate";

GUILDADSTOOLTIPS_FACTION_TITLE = GUILDADS_HEADER_FACTION;
GUILDADSTOOLTIPS_FACTION = "Allows you to see the reputation of your guildads mate";

GUILDADSTOOLTIPS_SKILL_TITLE = GUILDADS_HEADER_SKILL;
GUILDADSTOOLTIPS_SKILL =  "Allow you to see skills and professions of your current guildads mate";

GUILDADSTOOLTIPS_QUEST_TITLE = GUILDADS_HEADER_QUEST;
GUILDADSTOOLTIPS_QUEST = "Allow you to see the current quests of your guildads mate";

GUILDADSTOOLTIPS_GUILD_TITLE = GUILD;
GUILDADSTOOLTIPS_GUILD = "Allow you to see roster of current guildads mate";

GUILDADSTOOLTIPS_FORUM_TITLE = GUILDADS_HEADER_FORUM;
GUILDADSTOOLTIPS_FORUM = "Allow you to see the in-game guildads forum";

--Factions (only factions mentioned here can be synchronized)
-- Taken from http://www.wowwiki.com/Reputation#Reputation_sheet
GUILDADS_FACTIONS = {
	[1]  = "Darnassus";  -- Alliance
	[2]  = "Exodar";
	[3]  = "Gnomeregan Exiles";
	[4]  = "Ironforge";
	[5]  = "Stormwind";
	[6]  = "Silverwing Sentinels";
	[7]  = "Stormpike Guard";
	[8]  = "The League of Arathor";
	[9]  = "Darkspear Trolls"; -- Horde
	[10] = "Orgrimmar";
	[11] = "Silvermoon City";
	[12] = "Thunder Bluff";
	[13] = "Undercity";
	[14] = "Frostwolf Clan";
	[15] = "The Defilers";
	[16] = "Warsong Outriders";
	[17] = "Honor Hold"; -- Outland
	[18] = "Thrallmar";
	[19] = "Kurenai";
	[20] = "The Mag'har";
	[21] = "Cenarion Expedition";
	[22] = "Sporeggar";
	[23] = "The Consortium";
	[24] = "Netherwing";
	[25] = "Ogri'la";
	[26] = "Ashtongue Deathsworn";			-- Raid
	[27] = "Lower City"; -- Shattrath City
	[28] = "Sha'tari Skyguard";
	[29] = "The Aldor";
	[30] = "The Scryers";
	[31] = "The Sha'tar";
	[55] = "Shattered Sun Offensive";
	[32] = "Booty Bay"; -- Steamwheedle Cartel
	[33] = "Everlook";
	[34] = "Gadgetzan";
	[35] = "Ratchet";
	[36] = "Argent Dawn"; -- Other
	[37] = "Bloodsail Buccaneers";
	[38] = "Brood of Nozdormu";			-- Raid
	[39] = "Cenarion Circle";			-- Raid
	[40] = "Darkmoon Faire";
	[41] = "Gelkis Clan Centaur";
	[42] = "Hydraxian Waterlords";			-- Raid
	[43] = "Magram Clan Centaur";
	[44] = "Ravenholdt";
	[45] = "Shen'dralar";
	[46] = "Syndicate";
	[47] = "Thorium Brotherhood";
	[48] = "Timbermaw Hold";
	[49] = "Wintersaber Trainers";
	[50] = "Zandalar Tribe";			-- Raid
	[51] = "Keepers of Time"; -- Other - BC
	[52] = "The Scale of the Sands";		-- Raid
	[53] = "Tranquillien";
	[54] = "The Violet Eye";
	[56] = "Knights of the Ebon Blade", -- WotLK -- Other
	[57] = "Argent Crusade", -- Northrend
	[58] = "Explorer's League",
	[59] = "Frenzyheart Tribe",
	[60] = "The Frostborn",
	[61] = "The Hand of Vengeance",
	[62] = "The Kalu'ak",
	[63] = "The Oracles",
	[64] = "The Sons of Hodir",
	[65] = "The Taunka",
	[66] = "Valiance Expedition",
	[67] = "Warsong Offensive",
	[68] = "The Wyrmrest Accord",
	[69] = "Kirin Tor", -- Dalaran
	[70] = "The Silver Covenant",
	[71] = "The Sunreavers"
}; -- The last one used is 71

GUILDADS_FACTION_OPTIONS	= "Faction settings";
GUILDADS_FACTION_HIDE_COLLAPSED = "Hide collapsed factions";
GUILDADS_FACTION_ONLY_LEVEL_80	= "Show only level 80 players";
GUILDADS_FACTION_FACTION	= "Show Faction"; -- Should be updated runtime to either Horde or Alliance

GUILDADS_FACTION_SHOWFACTION = "Show Faction";
GUILDADS_FACTION_SHOWFACTIONFORCES = "Show Faction Forces";
GUILDADS_FACTION_SHOWOUTLAND = "Show Outland";
GUILDADS_FACTION_SHOWSHATTRATHCITY = "Show Shattrath City";
GUILDADS_FACTION_SHOWSTEAMWHEEDLECARTEL = "Show Steamwheedle Cartel";
GUILDADS_FACTION_SHOWOTHER = "Show Other";
GUILDADS_FACTION_SHOWNORTHREND = "Show Northrend";
GUILDADS_FACTION_SHOWDALARAN = "Show Dalaran";
GUILDADS_FACTION_SHOWRAID = "Show Raid"


GUILDADS_OPTIONS = {
	["toggle"]			= BINDING_NAME_SHOW;
	["options"]			= BINDING_NAME_SHOW_CONFIG;
	["debug"] 			= "Toggle on or off debug message";
	["info"] 			= "Show general debug information";
	["reset"]			= "Reset database";
	["reset all"]		= "Reset all database except account information";
	["reset channel"]	= "Reset all channel datas";
	["reset others"]	= "Reset all informations about others players";
	["reset player"]	= "Reset all information about a particular player";
	["clean"]			= "Clean the database";
	["clean other"]		= "Delete tradeskill information from other accounts that doesn't have recipe links";
	["admin"]			= "Handle access control of players and guilds";
	["admin show"]		= "Show current access control list";
	["admin deny"]		= "Deny player or @guild access (deletes player data)";
	["admin allow"]		= "Allow player or @guild access (deletes player data)";
	["admin remove"]	= "Remove player or @guild from access control list";
	["admin allowed"]	= "Checks if a player is allowed access";
}
