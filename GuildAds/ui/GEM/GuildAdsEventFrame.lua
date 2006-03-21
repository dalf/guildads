----------------------------------------------------------------------------------
--
-- GuildAdsEventFrame.lua
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

local oldGEMMain_SelectTab;
local firstShow = true;

GuildAdsGEMEvent = {
	metaInformations = { 
		name = "GuildEventManager",
        guildadsCompatible = 100,
		--
		ui = {
			main = {
				frame = "GuildAdsEventFrame",
				tab = "GuildAdsEventTab",
				tooltip = "Event tab",
				priority = 3
			}
		}
	
	};
	
	GUILDADSEVENT_TAB_EVENTLIST = 1;
	GUILDADSEVENT_TAB_NEW = 2;
	
	onLoad = function()
	    if (GEMListFrame) then 
			GuildAdsPlugin.setDebug(true);
			GuildAdsPlugin.UIregister(GuildAdsGEMEvent);
			
			-- hide minimap button
			GEMMinimapButton:Hide();
			
			-- hide tabs Event / New in GEM window
			GEMMainFrameTab1:Hide();
			GEMMainFrameTab2:Hide();
			GEMMainFrameTab4:Hide();
				
			-- change parents / location of GEMListFrame & GEMNewFrame
			GEMListFrame:SetParent("GuildListAdEventListFrame");
			GEMListFrame:ClearAllPoints();
		   	GEMListFrame:SetPoint("TOPLEFT","GuildAdsFrame","TOPLEFT",25,-78);
 			GEMListFrame:SetFrameLevel(2);
			
			GEMNewFrame:SetParent("GuildListAdCustomEventFrame");
			GEMNewFrame:ClearAllPoints();
			GEMNewFrame:SetPoint("TOPLEFT","GuildAdsFrame","TOPLEFT",22,-58);
			GEMNewFrame:SetFrameLevel(2);
			
			-- init tab in GA
			PanelTemplates_SelectTab(GuildAds_MyEventTab1);
			PanelTemplates_DeselectTab(GuildAds_MyEventTab2);
			
			-- show GEMListFrame
			GuildListAdEventListFrame:Show();
			GEMListFrame:Show();
			
			-- hide GEMNewFrame
			GuildListAdCustomEventFrame:Hide();
			GEMNewFrame:Hide();
			
			-- select config tab on GEM window
			GEMMain_SelectTab(3);
			
			-- hook GEMMain_SelectTab
			oldGEMMain_SelectTab = GEMMain_SelectTab;
			GEMMain_SelectTab = GuildAdsGEMEvent.GEMSelectTab;
		end;
	end;
		
	onShow = function() 
		if firstShow then
			GEMListFrame:Show();
			firstShow = false;
		end
	end;
	
	onChannelJoin = function()
		-- simple integration : one channel
		local alias = ""; -- GEM_COM_Channels[GEM_DefaultSendChannel].alias;
		local slash = ""; -- GEM_COM_Channels[GEM_DefaultSendChannel].slash;
		local channel, password = GuildAds:GetDefaultChannel();
		
		if strupper(channel) ~= strupper(GEM_DefaultSendChannel) then
			-- leave default channel
			GuildAdsGEMEvent.debug("Remove channel :"..GEM_DefaultSendChannel);
			GEMOptions_RemoveChannel(GEM_DefaultSendChannel);	
			-- join GuildAds channel
			GuildAdsGEMEvent.debug("Add channel :"..channel);
			GEMOptions_AddChannel(channel,password,alias,slash);
		end
	end;
	
	onChannelLeave = function()
		local channel = GuildAds:GetDefaultChannel();
		GuildAdsGEMEvent.debug("Remove channel :"..channel);
		GEMOptions_RemoveChannel(channel);
	end;
	
	GEMSelectTab = function(tab)
		if tab==1 or tab==2 then
			GuildAdsGEMEvent.selectTab(tab);
		else
			oldGEMMain_SelectTab(tab);
		end
	end;
	
	selectTab = function(tab)
		if (tab == GuildAdsGEMEvent.GUILDADSEVENT_TAB_EVENTLIST) then
			PanelTemplates_SelectTab(GuildAds_MyEventTab1);
			PanelTemplates_DeselectTab(GuildAds_MyEventTab2);
			GuildListAdCustomEventFrame:Hide();
			GEMNewFrame:Hide();
			GuildListAdEventListFrame:Show();
			GEMNew_CheckResetEdit();
			GEMListFrame:Show();
		elseif (tab == GuildAdsGEMEvent.GUILDADSEVENT_TAB_NEW) then 
			PanelTemplates_SelectTab(GuildAds_MyEventTab2);
			PanelTemplates_DeselectTab(GuildAds_MyEventTab1);
			GuildListAdEventListFrame:Hide();
			GEMListFrame:Hide();
			GuildListAdCustomEventFrame:Show();
			GEMNewFrame:Show();
		end;
	end;
}