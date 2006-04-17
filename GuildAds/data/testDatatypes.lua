--
-- Config
--
config = {
	playerName = "Zarkan";
	realmName = "Ner'zhul";
	faction = "Horde";
}

--
-- About WOW
--
SlashCmdList = {}
tinsert = table.insert;
getn = table.getn;

getglobal = function(name)
	return _G[name];
end

GetCVar = function(name)
	if name=="realmName" then
		return config.realmName;
	end
end

UnitName = function(name)
	if name=="player" then
		return config.playerName;
	end
end

--
-- About GuildAds
--
GUILDADS_VERSION = 200;

GuildAdsTask = {
	AddNamedSchedule = function(self, n, t, r, c, f, ...)
	end
}

GuildAds_ChatDebug = function(t, m)
end

AceEventFrame = {
	RegisterEvent = function(event)
	end;
}


dofile("C:\\Program Files\\World of Warcraft\\Interface\\AddOns\\Ace\\Ace.lua")
dofile("C:\\Program Files\\World of Warcraft\\Interface\\AddOns\\Ace\\AceDB.lua")
dofile("C:\\Program Files\\World of Warcraft\\Interface\\AddOns\\Ace\\AceData.lua")
dofile("C:\\Program Files\\World of Warcraft\\Interface\\AddOns\\Ace\\AceEvent.lua")
dofile("C:\\Program Files\\World of Warcraft\\Interface\\AddOns\\Ace\\AceHook.lua")
dofile("C:\\Program Files\\World of Warcraft\\Interface\\AddOns\\Ace\\AceModule.lua")
dofile("C:\\Program Files\\World of Warcraft\\Interface\\AddOns\\GuildAds\\data\\GuildAdsDB.lua");
dofile("C:\\Program Files\\World of Warcraft\\Interface\\AddOns\\GuildAds\\data\\GuildAdsDataType.lua");
dofile("C:\\Program Files\\World of Warcraft\\Interface\\AddOns\\GuildAds\\data\\GuildAdsTableDataType.lua");
dofile("C:\\Program Files\\World of Warcraft\\Interface\\AddOns\\GuildAds\\data\\datatypes\\GuildAdsTradeNeedData.lua");
dofile("C:\\Program Files\\World of Warcraft\\Interface\\AddOns\\GuildAds\\data\\datatypes\\GuildAdsTradeOfferData.lua");
dofile("C:\\Program Files\\World of Warcraft\\Interface\\AddOns\\GuildAds\\data\\datatypes\\GuildAdsTradeSkillData.lua");
dofile("C:\\Program Files\\World of Warcraft\\Interface\\AddOns\\GuildAds\\data\\datatypes\\GuildAdsSkillData.lua");
dofile("C:\\Program Files\\World of Warcraft\\WTF\\Account\\ALFINWOW\\SavedVariables\\GuildAds.lua");

GuildAds = {
	playerName = config.playerName;
	channelName = "GuildAdsInTartifletteWeTrust";
	realmName = config.realmName;
	factionName = config.faction;
	db = AceDatabase:new("GuildAdsDatabase");
}

GuildAds.db:Initialize();
GuildAdsDB:Initialize();

--
-- Tests
--

--[[
print ("Need (me) --------------");
for item, author, data in GuildAdsDB.channel[GuildAds.channelName].TradeNeed:iterator(GuildAds.playerName) do
	print(item);
end

print ("Need -------------------");
for _, item, playerName, data in GuildAdsDB.channel[GuildAds.channelName].TradeNeed:iterator() do
	print(item);
end

print ("Offer (me)--------------");
for item, author, data in GuildAdsDB.channel[GuildAds.channelName].TradeOffer:iterator(GuildAds.playerName) do
	print(item);
end

print ("Offer ------------------");
for _, item, playerName, data in GuildAdsDB.channel[GuildAds.channelName].TradeOffer:iterator() do
	print(item);
end
]]

function PrintUpdate(dataType, playerName, fromRevision)
	local currentRevision = dataType:getRevision(playerName);
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"currentRevision="..currentRevision);
	local t = {};
	local n = {};
	local newEntries = 0;
	-- send new entries >r1
	for id, _, data, revision in dataType:iterator(playerName) do
		if (revision>fromRevision) then
			newEntries = newEntries + 1;
			tinsert(n, { r=revision, i=id, d=data});
		else
			table.insert(t, revision);
		end
	end
	
	table.sort(n, function(a,b) return a.r<b.r end);
	local f = function(k, v)
		print("  -N["..v.r.."]="..tostring(v.i).."/"..tostring(v.d));
	end;
	table.foreach(n, f);

	if currentRevision-fromRevision~=newEntries then
		-- idealement : 1-10, 12-15, 17-30 au lieu de la liste complete
		table.sort(t);
		local f = function(k, v)
		end;
		table.foreach(t, f);
	end
end

print(GuildAdsDB.profile.TradeSkill:getRevision("Zarkan"));

PrintUpdate(GuildAdsDB.profile.TradeSkill, "Zarkan", 245);