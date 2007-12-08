----------------------------------------------------------------------------------
--
-- GuildAdsWindow.lua
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

GuildAdsWindow = {};

--------------------------------------------------------------------------------
--
-- New
-- 
--------------------------------------------------------------------------------
function GuildAdsWindow:new(t, ...)
	-- Set metatable
	self.__index = self
	t = setmetatable(t or {}, self)
	-- Register this new window into GuildAds object
	if t.name then
		GuildAds.windows[t.name] = t;
	else
		tinsert(GuildAds.windows, t)
	end
	-- return new object
	return t
end

--------------------------------------------------------------------------------
--
-- Create (called by GuildAds)
-- 
--------------------------------------------------------------------------------
function GuildAdsWindow:Create()
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
function GuildAdsWindow:InitializeTabs()
	local currTab, previousTab;
	
	self.tabDescription = GuildAdsPlugin_GetUI(self.name);

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

function GuildAdsWindow:GetTabPosition()
	return 65, -27
end

function GuildAdsWindow:InitializeTab(currTab, id, info, previousTab)
	currTab:SetID(id);
	currTab:ClearAllPoints();
	currTab:SetParent(self.frame);
	if (previousTab == nil) then
		currTab:SetPoint("CENTER", self.frame, "BOTTOMLEFT", self:GetTabPosition());
		getglobal(info.frame):Show();
		self:SelectTab(currTab);
	else
		currTab:SetPoint("LEFT", previousTab:GetName(), "RIGHT", -7, 0);
		getglobal(info.frame):Hide()
		self:DeselectTab(currTab);
	end
end

function GuildAdsWindow:SelectFrame(frameName)
    for id, info in pairs(self.tabDescription) do
		if frameName == info.frame then
			getglobal(info.frame):Show();
			self:SelectTab(getglobal(info.tab));
		else
			getglobal(info.frame):Hide();
			self:DeselectTab(getglobal(info.tab));
		end
	end
end

function GuildAdsWindow:TabOnClick(tab)	
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

function GuildAdsWindow:SelectTab(tab)
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

function GuildAdsWindow:DeselectTab(tab)
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
