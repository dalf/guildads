----------------------------------------------------------------------------------
--
-- GuildAdsMainWindow.lua
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------
local AceOO = AceLibrary("AceOO-2.0");

local GuildAdsMainWindowClass = AceOO.Class(GuildAdsWindow);
--~ GuildAdsWindow:new();

--~ { name="main", frame = "GuildAdsMainWindowFrame" });

--~ GuildAdsMainWindowClass.name="main";
--~ GuildAdsMainWindowClass.frame="GuildAdsMainWindowFrame";

function GuildAdsMainWindowClass.prototype:init()
self.name="main";
self.frame = "GuildAdsMainWindowFrame" 
    GuildAdsMainWindowClass.super.prototype.init(self)
     GuildAds:CustomPrint(1, 0, 0, nil, nil, nil,"sa222lute");
	-- 
--~ 	name="main"
--~ 	frame = "GuildAdsMainWindowFrame" 
    -- do stuff here
end
function GuildAdsMainWindowClass:Create()
	-- Call parent method
	GuildAdsWindow.super.prototype:Create(GuildAdsMainWindow);
    GuildAds:CustomPrint(1, 0, 0, nil, nil, nil,"salute");
	-- Update version number
	GuildAdsVersion:SetText(GuildAds.version);
end

local GuildAdsMainWindow = GuildAdsMainWindowClass:new();