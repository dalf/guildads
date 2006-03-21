GUILDADS_VERSION = 200;
SlashCmdList = {}
tinsert = table.insert;
getn = table.getn;

getglobal = function(name)
	return _G[name];
end

GAS_currentTime = function()
	return 4012;
end

dofile("C:\\Program Files\\World of Warcraft\\Interface\\AddOns\\Ace\\Ace.lua")
dofile("C:\\Program Files\\World of Warcraft\\Interface\\AddOns\\Ace\\AceDB.lua")
dofile("C:\\Program Files\\World of Warcraft\\Interface\\AddOns\\Ace\\AceData.lua")
dofile("C:\\Program Files\\World of Warcraft\\Interface\\AddOns\\Ace\\AceEvent.lua")
dofile("C:\\Program Files\\World of Warcraft\\Interface\\AddOns\\Ace\\AceHook.lua")
dofile("C:\\Program Files\\World of Warcraft\\Interface\\AddOns\\Ace\\AceModule.lua")
dofile("C:\\Program Files\\World of Warcraft\\Interface\\AddOns\\GuildAds\\data\\GuildAdsDB.lua");
dofile("C:\\Program Files\\World of Warcraft\\Interface\\AddOns\\GuildAds\\data\\GuildAdsDataType.lua");
dofile("C:\\Program Files\\World of Warcraft\\Interface\\AddOns\\GuildAds\\data\\datatypes\\GuildAdsTradeNeedData.lua");
dofile("C:\\Program Files\\World of Warcraft\\Interface\\AddOns\\GuildAds\\data\\datatypes\\GuildAdsTradeOfferData.lua");
dofile("C:\\Program Files\\World of Warcraft\\Interface\\AddOns\\GuildAds\\data\\datatypes\\GuildAdsSkillData.lua");
dofile("C:\\Program Files\\World of Warcraft\\WTF\\Account\\ALFINWOW\\SavedVariables\\GuildAds.lua");

GuildAds = {
	playerName = "Ingird";
	channelName = "GuildAdsInTartifletteWeTrust";
	realmName = "Ner'zhul";
	factionName = "Horde";
	db = AceDatabase:new("GuildAdsDatabase");
}

GuildAds.db:Initialize();
GuildAdsDB:Initialize();

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

--~ local players = GuildAdsDB.channel[GuildAds.channelName]:getPlayers();
local players = GuildAdsDB.channel[GuildAds.channelName].db.Players;
for i,j in pairs(players) do
	print(tostring(i)..","..tostring(j));
end

for id, playerName , data in GuildAdsSkillDataType:iterator(nil, 12) do
	print("  - add("..tostring(playerName)..","..tostring(id)..")");
end