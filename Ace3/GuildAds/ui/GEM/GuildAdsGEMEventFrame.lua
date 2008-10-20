----------------------------------------------------------------------------------
--
-- GuildAdsGEMEventFrame.lua
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

-- function in GEM_List.lua that is called when there is a change in events: GEMList_NotifyNewEvent
-- #GEM_NewEvents == 0 -->> No new event.   > 0 -->> New event. Start flashing.

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
				tab = "GuildAdsGEMEventTab",
				tooltip = "Event tab",
				priority = 3
			},
			options = {
				frame = "GEMOptionsFrame",
				tab = "GuildAdsGEMOptionTab",
				priority = 3
			}
		}
	
	};
	
	GUILDADSEVENT_TAB_EVENTLIST = 1;
	GUILDADSEVENT_TAB_NEW = 2;
	GUILDADSEVENT_TAB_PLAYERS = 3;
	
	onLoad = function()
	    if GEMListFrame then 
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
		   	GEMListFrame:SetPoint("TOPLEFT","GuildAdsMainWindowFrame","TOPLEFT",25,-78);
 			GEMListFrame:SetFrameLevel(2);
			
			GEMNewFrame:SetParent("GuildListAdCustomEventFrame");
			GEMNewFrame:ClearAllPoints();
			GEMNewFrame:SetPoint("TOPLEFT","GuildAdsMainWindowFrame","TOPLEFT",22,-58);
			GEMNewFrame:SetFrameLevel(2);
			
			GEMPlayersFrame:SetParent("GuildListAdMemberFrame");
			GEMPlayersFrame:ClearAllPoints();
			GEMPlayersFrame:SetPoint("TOPLEFT","GuildAdsMainWindowFrame","TOPLEFT",25,-78);
			GEMPlayersFrame:SetFrameLevel(2);
			
			GEMOptionsFrame:SetParent("GuildAdsOptionsWindowFrame");
			GEMOptionsFrame:ClearAllPoints();
			GEMOptionsFrame:SetPoint("TOPLEFT","GuildAdsOptionsWindowFrame","TOPLEFT",-42, -30);
			GEM_MinimapArcSlider:Hide();
			GEM_MinimapRadiusSlider:Hide();
			i = 1;
			while getglobal("GEMOptions_Icon"..i) do
				getglobal("GEMOptions_Icon"..i):Hide();
				i=i+1;
			end
			GEMOptions_Validate:Hide();
			GEMOptionsFrame_IconChoice:Hide();
			GEMOptionsFrame:SetFrameLevel(2);
			
			-- init tab in GA
			PanelTemplates_SelectTab(GuildAds_GEMEventTab1);
			PanelTemplates_DeselectTab(GuildAds_GEMEventTab2);
			PanelTemplates_DeselectTab(GuildAds_GEMEventTab3);
			
			-- show GEMListFrame
			GuildListAdEventListFrame:Show();
			GEMListFrame:Show();
			
			-- hide GEMNewFrame
			GuildListAdCustomEventFrame:Hide();
			GEMNewFrame:Hide();
			
			-- hide GEMPlayersFrame
			GuildListAdMemberFrame:Hide();
			GEMPlayersFrame:Hide();
			
			-- select config tab on GEM window
			GEMMain_SelectTab(3);
			
			-- hook GEMMain_SelectTab
			oldGEMMain_SelectTab = GEMMain_SelectTab;
			GEMMain_SelectTab = GuildAdsGEMEvent.GEMSelectTab;
			
			-- hook GEMList_NotifyNewEvent
			if GuildAdsMinimapButtonCore then
				GEMList_NotifyNewEvent = GuildAdsGEMEvent.GEMList_NotifyNewEvent;
			end
		else
			-- hide GEM messages
			ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", GuildAdsGEMEvent.chatFrameFilter)
		end;
	end;
	
	chatFrameFilter = function(msg)
		if (string.sub(msg, 1, 4)=="<GEM") then
			return true
		end
	end;
	
	saveOptions = function()
		GEMOptions_Click_Validate();
		GEM_Toggle();
	end;
	
	defaultsOptions = function()
	end;
		
	onShow = function() 
		if firstShow then
			GEMListFrame:Show();
			firstShow = false;
		end
	end;
	
	onChannelJoin = function()
		local ChannelAddedByGA;
		local channelName, password = GuildAds:GetDefaultChannel();
		
		-- add GA channel to the GEM channel list
		if not GEM_IsChannelInList(string.lower(channelName)) then
			GEMOptions_AddChannel(channelName, password or "", "", "");	-- channelName, password, alias, slash
			ChannelAddedByGA = channelName;
		end
		-- update ChannelAddedByGA
		GuildAdsGEMEvent.setProfileValue(nil, "ChannelAddedByGA", ChannelAddedByGA);
	end;
	
	onChannelLeave = function()
		GuildAdsGEMEvent.debug("onChannelLeave");
--~ 		-- delete previous GA channel from the the GEM channel list
--~ 		if GuildAdsGEMEvent.getProfileValue(nil, "ChannelAddedByGA") then
--~ 			local channelName = GuildAdsGEMEvent.getProfileValue(nil, "ChannelAddedByGA");
--~ 			GuildAdsGEMEvent.debug("   - leave : "..channelName..","..tostring(GEM_COM_Channels[channelName]));
--~ 			GEMOptions_RemoveChannel(GuildAdsGEMEvent.getProfileValue(nil, "ChannelAddedByGA"));
--~ 		end
	end;
	
	showNewEvents = function()
		GuildAds:SelectWindowFrame("main", GuildAdsGEMEvent.metaInformations.ui.main.frame);
		GuildAdsGEMEvent.selectTab(GuildAdsGEMEvent.GUILDADSEVENT_TAB_EVENTLIST);
	end;
	
	getNewEventsText = function()
		return GEM_TEXT_NEW_EVENTS_AVAILABLE..#GEM_NewEvents;
	end;
	
	GEMList_NotifyNewEvent = function()
		GuildAdsMinimapButtonCore.addAlertFunction(
			GuildAdsGEMEvent.getNewEventsText, 
			GuildAdsGEMEvent.showNewEvents);
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
			PanelTemplates_SelectTab(GuildAds_GEMEventTab1);
			PanelTemplates_DeselectTab(GuildAds_GEMEventTab2);
			PanelTemplates_DeselectTab(GuildAds_GEMEventTab3);
			GuildListAdCustomEventFrame:Hide();
			GEMNewFrame:Hide();
			GuildListAdEventListFrame:Show();
			GEMNew_CheckResetEdit();
			GEMListFrame:Show();
			GuildListAdMemberFrame:Hide();
			GEMPlayersFrame:Hide();
		elseif (tab == GuildAdsGEMEvent.GUILDADSEVENT_TAB_NEW) then 
			PanelTemplates_SelectTab(GuildAds_GEMEventTab2);
			PanelTemplates_DeselectTab(GuildAds_GEMEventTab1);
			PanelTemplates_DeselectTab(GuildAds_GEMEventTab3);
			GuildListAdEventListFrame:Hide();
			GEMListFrame:Hide();
			GuildListAdCustomEventFrame:Show();
			GEMNewFrame:Show();
			GuildListAdMemberFrame:Hide();
			GEMPlayersFrame:Hide();
		elseif (tab == GuildAdsGEMEvent.GUILDADSEVENT_TAB_PLAYERS) then 
			PanelTemplates_DeselectTab(GuildAds_GEMEventTab1);
			PanelTemplates_DeselectTab(GuildAds_GEMEventTab2);
			PanelTemplates_SelectTab(GuildAds_GEMEventTab3);
			GuildListAdEventListFrame:Hide();
			GEMListFrame:Hide();
			GuildListAdCustomEventFrame:Hide();
			GEMNewFrame:Hide();
			GuildListAdMemberFrame:Show();
			GEMPlayersFrame:Show();
		end
	end;
}