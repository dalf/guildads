----------------------------------------------------------------------------------
--
-- GuildAdsWindow.lua
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

local AceOO = AceLibrary("AceOO-2.0");
GuildAdsWindow = AceOO.Class();

--------------------------------------------------------------------------------
--
-- New
-- 
--------------------------------------------------------------------------------
function GuildAdsWindow.prototype:init(t)
	GuildAdsDataType.super.prototype.init(self)
	
	if type(t)=="table" then
		for k,v in pairs(t) do
			self[k] = v
		end
	end
	
	if self.name then
		GuildAds.windows[self.name] = self;
	else
		tinsert(GuildAds.windows, self)
	end
end;

--------------------------------------------------------------------------------
--
-- Create (called by GuildAds)
-- 
--------------------------------------------------------------------------------
function GuildAdsWindow.prototype:Create()
	-- Escape hide the window
	tinsert(UISpecialFrames,self.frame);

	-- Initialize tabs
	self:InitializeTabs();
end

---------------------------------------------------------------------------------
--
-- Choose a tab (Available, Request, Event, ...)
-- 
---------------------------------------------------------------------------------
function GuildAdsWindow.prototype:InitializeTabs()
	local currTab, previousTab;
--~ 	GuildAds:CustomPrint(1, 0, 0, nil, nil, nil,"ml"..self.name);
	self.tabDescription = GuildAdsPlugin_GetUI(self.name);
	if self.name ~= nil then
GuildAds:CustomPrint(1, 0, 0, nil, nil, nil,"GAW init["..self.name.."]");
else 
GuildAds:CustomPrint(1, 0, 0, nil, nil, nil,"GAW init[".."nil".."]");

end

	for id, info in pairs(self.tabDescription) do

		currTab = getglobal(info.tab);
		if info.tooltip then
			currTab.tooltip = info.tooltip;
		end
        if info.tooltiptitle then
			currTab.tooltiptitle = info.tooltiptitle;
		end
		currTab.window = self;		
		self:InitializeTab(currTab, id, info, previousTab);
		
		previousTab = currTab;
	end
end

function GuildAdsWindow.prototype:InitializeTab(currTab, id, info, previousTab)
	currTab:SetID(id);
	currTab:ClearAllPoints();
	currTab:SetParent(self.frame);
	if (previousTab == nil) then
		currTab:SetPoint("CENTER", self.frame, "BOTTOMLEFT", 65, -27);
		getglobal(info.frame):Show();
		self:SelectTab(currTab);
	else
		currTab:SetPoint("LEFT", previousTab:GetName(), "RIGHT", -7, 0);
		getglobal(info.frame):Hide()
		self:DeselectTab(currTab);
	end
end

function GuildAdsWindow.prototype:TabOnClick(tab)	
    for id, info in pairs(self.tabDescription) do

		if id == tab then
			getglobal(info.frame):Show();
			self:SelectTab(getglobal(info.tab));
		else
			getglobal(info.frame):Hide();
			self:DeselectTab(getglobal(info.tab));
		end
	end
end

function GuildAdsWindow.prototype:SelectTab(tab)
	local name = tab:GetName();
	getglobal(name.."Left"):Hide();
	getglobal(name.."Middle"):Hide();
	getglobal(name.."Right"):Hide();
	--tab:LockHighlight();
	tab:Disable();
	getglobal(name.."LeftDisabled"):Show();
	getglobal(name.."MiddleDisabled"):Show();
	getglobal(name.."RightDisabled"):Show();
	
	if ( GameTooltip:IsOwned(tab) ) then
		GameTooltip:Hide();
	end
end

function GuildAdsWindow.prototype:DeselectTab(tab)
	local name = tab:GetName();
	getglobal(name.."Left"):Show();
	getglobal(name.."Middle"):Show();
	getglobal(name.."Right"):Show();
	--tab:UnlockHighlight();
	tab:Enable();
	getglobal(name.."LeftDisabled"):Hide();
	getglobal(name.."MiddleDisabled"):Hide();
	getglobal(name.."RightDisabled"):Hide();
end
