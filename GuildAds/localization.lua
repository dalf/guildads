GUILDADS_TITLE			= "GuildAds";

-- Minimap button
GUILDADS_BUTTON_TIP		= "Click here to show or hide GuildAds.";

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

-- Column headers
GUILDADS_HEADER_REQUEST		= "Ask";
GUILDADS_HEADER_AVAILABLE	= "Have";
GUILDADS_HEADER_INVENTORY	= INSPECT;
GUILDADS_HEADER_SKILL 		= SKILLS;
GUILDADS_HEADER_ANNONCE		= GUILD;
GUILDADS_HEADER_EVENT		= "Events";

GUILDADS_GUILD_GROUPWITHACCOUNT	= "Group %s with the account of %s";
GUILDADS_GUILD_DEGROUP		= "Degroup from the account";
                    
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

GUILDADS_CMD = { "/guildads" }
GUILDADS_CMD_OPTIONS = {
	type = 'group',
	desc = '',
	args = {
		show = {
			name = 'show',
			type = 'execute',
			desc = BINDING_NAME_SHOW,
			func = "ToggleMainWindow"
		},
		config = {
			name = 'config',
			type = 'execute',
			desc = BINDING_NAME_SHOW_CONFIG,
			func = "ToggleOptionsWindow"
		},
		debug = {
			name = 'debug',
			type = 'toggle',
			desc = "Toggle on or off debug message",
			get = "IsDebugging",
			set = "SetDebug",
			map = { 
				[true] = "Toggle on debug message",
				[false] = "Toggle off debug message" 
			}
		},
		debugInfo = {
			name = 'debugInfo',
			type = 'execute',
			desc = "Show general debug information",
			func = "DisplayDebugInfo"
		},
		reset = {
			name = 'reset',
			type = 'group',
			desc = 'Reset database',
			args = {
				all = {
					name = 'all',
					type = 'execute',
					desc = "Reset all database except account information",
					func = "ResetAll"
				},
				channel = {
					name = 'channel',
					type = 'execute',
					desc = "Reset all channel datas",
					func = "ResetChannel"
				},
				others = {
					name = 'others',
					type = 'execute',
					desc = "Reset all informations about others players",
					func = "ResetOthers"
				}
			}
		}
	}
}

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
	[9] = "Priest"
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
	
	[20] = "Fist Weapons",
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

GUILDADSTOOLTIPS_SKILL_TITLE = GUILDADS_HEADER_SKILL;
GUILDADSTOOLTIPS_SKILL =  "Allow you to see skills and professions of your current guildads mate";

GUILDADSTOOLTIPS_GUILD_TITLE = GUILD;
GUILDADSTOOLTIPS_GUILD = "Allow you to see roster of current guildads mate";