----------------------------------------------------------------------------------
--
-- GuildAdsFactionFrame.lua
--
-- Author: Galmok, European Stormrage (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : galmok@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

local GUILDADS_NUM_GLOBAL_FACTION_BUTTONS = 19;
local GUILDADS_PLAYER_MAX_LEVEL = 70;

local GUILDADS_FACTION_GROUPS = {
					[1] = 1, [2] = 1, [3] = 1, [4] = 1, [5] = 1, [6] = 2,
					[7] = 2,  [8] = 2, [9] = 1, [10] = 1, [11] = 1, [12] = 1,
					[13] = 1, [14] = 2, [15] = 2, [16] = 2, [17] = 3, [18] = 3,
					[19] = 3, [20] = 3, [21] = 3, [22] = 3, [23] = 3, [24] = 3,
					[25] = 3, [26] = 3, [27] = 4, [28] = 4, [29] = 4, [30] = 4,
					[31] = 4, [32] = 5, [33] = 5, [34] = 5, [35] = 5, [36] = 6,
					[37] = 6, [38] = 6, [39] = 6, [40] = 6, [41] = 6, [42] = 6,
					[43] = 6, [44] = 6, [45] = 6, [46] = 6, [47] = 6, [48] = 6,
					[49] = 6, [50] = 6, [51] = 6, [52] = 6, [53] = 6, [54] = 6
				};
local GUILDADS_FACTION_GROUP_OPTION = {
					[1] = "ShowFaction";
					[2] = "ShowFactionForces";
					[3] = "ShowOutland";
					[4] = "ShowShattrathCity";
					[5] = "ShowSteamwheedleCartel";
					[6] = "ShowOther";
					};

--- Index of the ad currently selected
local g_GlobalAdSelectedId;

GuildAdsFaction = {
	metaInformations = { 
		name = "Reputation",
        guildadsCompatible = 100,
		ui = {
			main = {
				frame = "GuildAdsFactionFrame",
				tab = "GuildAdsFactionTab",
				tooltip = "Faction tab",
				priority = 2
			}
		}
	};
	
	GUILDADS_ADBUTTONSIZEY = 16;
	
	onInit = function()
		if not GuildAdsFaction.getProfileValue(nil, "Filters") then
			GuildAdsFaction.setProfileValue(nil, "Filters",  
				{
					[1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [6] = true,
					[7] = true,  [8] = true, [9] = true, [10] = true, [11] = true, [12] = true,
					[13] = true, [14] = true, [15] = true, [16] = true, [17] = true, [18] = true,
					[19] = true, [20] = true, [21] = true, [22] = true, [23] = true, [24] = true,
					[25] = true, [26] = true, [27] = true, [28] = true, [29] = true, [30] = true,
					[31] = true, [32] = true, [33] = true, [34] = true, [35] = true, [36] = true,
					[37] = true, [38] = true, [39] = true, [40] = true, [41] = true, [42] = true,
					[43] = true, [44] = true, [45] = true, [46] = true, [47] = true, [48] = true,
					[49] = true, [50] = true, [51] = true, [52] = true, [53] = true, [54] = true
				}
			);
		end
		
		if type(GuildAdsFaction.getRawProfileValue(nil, "HideCollapsed"))=="nil" then
			GuildAdsFaction.setProfileValue(nil, "HideCollapsed", true);
		end
		
		if type(GuildAdsFaction.getRawProfileValue(nil, "OnlyLevel70"))=="nil" then
			GuildAdsFaction.setProfileValue(nil, "OnlyLevel70", true);
		end
		-- "Horde", "Horde Forces", "Outland", "Shattrath City", "Steamwheedle Cartel", "Other"
		-- "Faction", "Faction Forces", "Outland", "Shattrath City", "Steamwheedle Cartel", "Other"
		-- 1, 2, 3, 4, 5, 6
		local group, groupname;
		for group, groupname in pairs(GUILDADS_FACTION_GROUP_OPTION) do
			if type(GuildAdsFaction.getRawProfileValue(nil, groupname))=="nil" then
				GuildAdsFaction.setProfileValue(nil, groupname, true); -- initialise all group settings to true (first run)
			end
		end
		
		GuildAdsDB.profile.Faction:registerUpdate(GuildAdsFaction.onDBUpdate);
	end;
	
	onDBUpdate = function(dataType, playerName, id)
		GuildAdsFaction.factionButton.updateAll(true);
	end;
	
	onShow = function()
		GuildAdsFaction.debug("onShow()");
		
		GuildAdsFaction.updateCheckButton(GuildAds_FactionHideCollapsedCheckButton, GuildAdsFaction.getProfileValue(nil, "HideCollapsed"));
		GuildAdsFaction.updateCheckButton(GuildAds_FactionOnlyLevel70CheckButton, GuildAdsFaction.getProfileValue(nil, "OnlyLevel70"));
		
		GuildAdsFaction.updateCheckButton(GuildAds_FactionShowFactionCheckButton, GuildAdsFaction.getProfileValue(nil, "ShowFaction"));
		GuildAdsFaction.updateCheckButton(GuildAds_FactionShowFactionForcesCheckButton, GuildAdsFaction.getProfileValue(nil, "ShowFactionForces"));
		GuildAdsFaction.updateCheckButton(GuildAds_FactionShowOutlandCheckButton, GuildAdsFaction.getProfileValue(nil, "ShowOutland"));
		GuildAdsFaction.updateCheckButton(GuildAds_FactionShowShattrathCityCheckButton, GuildAdsFaction.getProfileValue(nil, "ShowShattrathCity"));
		GuildAdsFaction.updateCheckButton(GuildAds_FactionShowSteamwheedleCartelCheckButton, GuildAdsFaction.getProfileValue(nil, "ShowSteamwheedleCartel"));
		GuildAdsFaction.updateCheckButton(GuildAds_FactionShowOtherCheckButton, GuildAdsFaction.getProfileValue(nil, "ShowOther"));
		
		GuildAdsFaction.factionButton.updateAll(false);
		GuildAdsFactionFrame:Show();
	end;
	
	updateCheckButton = function(button, state)
		if state then
			button:SetChecked(1);
		else
			button:SetChecked(0);
		end
	end;
	
	data = {
	
		cache = nil;
		
		resetCache = function()
			GuildAdsFaction.data.cache = nil;
		end;
		
		get = function(updateData)	
			if not GuildAdsFaction.data.cache or updateData then
				GuildAdsFaction.debug("reset cache");
				local insertHeader;
				
				local workFactions = {}
				for id, name in pairs(GUILDADS_FACTIONS) do
					local group=GUILDADS_FACTION_GROUPS[id];
					if GuildAdsFaction.getProfileValue(nil, GUILDADS_FACTION_GROUP_OPTION[group]) then
						workFactions[id]=name;
					end
				end
				
				GuildAdsFaction.data.cache = {};
				
				local hideCollapsed=false; -- hide collapsed headers unless all headers are collapsed
				if GuildAdsFaction.getProfileValue(nil, "HideCollapsed") then
					for id, name in pairs(workFactions) do
						if GuildAdsFaction.getProfileValue("Filters", id) then
							for playerName, _, data in GuildAdsFactionDataType:iterator(nil, id) do
								if not GuildAdsGuild.getProfileValue(nil, "HideOfflines") or GuildAdsGuild.isOnline(playerName) then
									if not (GuildAdsFaction.getProfileValue(nil, "OnlyLevel70") and ((GuildAdsDB.profile.Main:get(playerName, GuildAdsDB.profile.Main.Level) or 0)<GUILDADS_PLAYER_MAX_LEVEL)) then
										hideCollapsed=true;
									end
								end
							end
						end
					end
				end
				--if hideCollapsed then 
				--	GuildAdsFaction.debug("hideCollapsed=true");
				--else
				--	GuildAdsFaction.debug("hideCollapsed=false");
				--end
				-- for each faction
				for id, name in pairs(workFactions) do
					local factionOpen=GuildAdsFaction.getProfileValue("Filters", id);
					insertHeader = true;
					-- for each player
					for playerName, _, data in GuildAdsFactionDataType:iterator(nil, id) do
						if not GuildAdsGuild.getProfileValue(nil, "HideOfflines") or GuildAdsGuild.isOnline(playerName) then
							if not (GuildAdsFaction.getProfileValue(nil, "OnlyLevel70") and ((GuildAdsDB.profile.Main:get(playerName, GuildAdsDB.profile.Main.Level) or 0)<GUILDADS_PLAYER_MAX_LEVEL)) then
								if insertHeader and (not hideCollapsed or factionOpen) then
									tinsert(GuildAdsFaction.data.cache, {i=id, h=factionOpen } );
									insertHeader = nil;
								end
								if factionOpen then
									tinsert(GuildAdsFaction.data.cache, {i=id, p=playerName, v=data.v, b=data.b, t=data.t, s=data.s });
								end
							end
						end
					end
				end
				
				GuildAdsFaction.sortData.doIt(GuildAdsFaction.data.cache);
			end
			return GuildAdsFaction.data.cache;
		end;
	
	};
	
	sortData = {
		doIt = function(adTable)
 			table.sort(adTable, GuildAdsFaction.sortData.predicate);
		end;
		
		predicate = function(a, b)
			--
			-- nil references are always less than
			--
			if (a == nil) then
				if (b == nil) then
					-- a==nil, b==nil
					return false;
				else
					-- a==nil, b~=nil
					return true;
				end
			elseif (b == nil) then
				-- a~=nil, b==nil
				return false;
			end
			
			if a==false or b==false then
				return false;
			end
		
			if a.i and b.i then
				--
				-- Sort by faction name (ie id)
				--
				local aa = GuildAdsFactionDataType:getNameFromId(a.i);
				local bb = GuildAdsFactionDataType:getNameFromId(b.i);
				--local aa = a.i;
				--local bb = b.i;
				if (aa < bb) then
					return true;
				elseif (aa > bb) then
					return false;
				end
			end
			
			if (a.v and b.v) then
				--
				-- Sort by faction standing
				--		
				if (a.v < b.v) then
					return false;
				elseif (a.v > b.v) then
					return true;
				end
			else
				if not a.v and b.v then
					return true;
				elseif a.v and not b.v then
					return false;
				end
			end
	
			--
			-- Sort by owner next
			--
			aowner = a.p or "";
			bowner = b.p or "";
		
			if (aowner < bowner) then
				return true;
			elseif (aowner > bowner) then
				return false;
			end

			-- These ads are identical
			return false;
		end;
	};

	filters = {
		ExpandFactionHeader = function(factionId)
			GuildAdsFaction.setProfileValue("Filters", factionId, true);
			GuildAdsFaction.factionButton.updateAll(true);
		end;
			
		CollapseFactionHeader = function(factionId)
			GuildAdsFaction.setProfileValue("Filters", factionId, false);
			GuildAdsFaction.factionButton.updateAll(true);
		end;
		
		ExpandAllFactionHeaders = function()
			for i=1, table.getn(GUILDADS_FACTIONS) do
				GuildAdsFaction.setProfileValue("Filters", i, true);
			end;
			GuildAdsFaction.factionButton.updateAll(true);
		end;
		
		CollapseAllFactionHeaders = function()
			for i=1, table.getn(GUILDADS_FACTIONS) do
				GuildAdsFaction.setProfileValue("Filters", i, false);
			end;
			GuildAdsFaction.factionButton.updateAll(true);
		end;
		
		checkButtonSetProfile = function(button,option)
			if ( button:GetChecked() ) then
				PlaySound("igMainMenuOptionCheckBoxOn");
				GuildAdsFaction.setProfileValue(nil, option, true);
			else
				PlaySound("igMainMenuOptionCheckBoxOff");
				GuildAdsFaction.setProfileValue(nil, option, false);
			end
			GuildAdsFaction.factionButton.updateAll(true);
		end;
	};
	
	factionButton = {
		delete = function(button)
			local buttonName = button:GetName();
		
			local ownerField = buttonName.."Owner";
			local skillBar = buttonName.."SkillBar";
	
			getglobal(ownerField):Hide();
			getglobal(skillBar):Hide();
			button:UnlockHighlight();
		end;
		
		update = function(button, selected, info)
			local buttonName= button:GetName();
			local ownerColor = GuildAdsUITools.onlineColor[GuildAdsComm:IsOnLine(info.p)];

			local ownerField = buttonName.."Owner";
			local skillBar = buttonName.."SkillBar";
			local skillName = skillBar.."SkillName";
			local skillRank = skillBar.."SkillRank";
			
			getglobal(ownerField):SetText(info.p);
			getglobal(ownerField):SetTextColor(ownerColor["r"], ownerColor["g"], ownerColor["b"]);
			getglobal(skillName):SetText(GuildAdsSkillDataType:getNameFromId(info.i));
			
			if (info.v) then
					
				if (info.m >= 300 ) then 
					getglobal(skillBar):SetStatusBarColor(TradeSkillTypeColor["optimal"].r,TradeSkillTypeColor["optimal"].g,TradeSkillTypeColor["optimal"].b);
				elseif (info.m >= 225 ) then 
					getglobal(skillBar):SetStatusBarColor(TradeSkillTypeColor["medium"].r,TradeSkillTypeColor["medium"].g,TradeSkillTypeColor["medium"].b);
				elseif (info.m >= 150) then
					getglobal(skillBar):SetStatusBarColor(TradeSkillTypeColor["easy"].r,TradeSkillTypeColor["easy"].g,TradeSkillTypeColor["easy"].b);
				elseif (info.m >= 75) then
					getglobal(skillBar):SetStatusBarColor(TradeSkillTypeColor["trivial"].r,TradeSkillTypeColor["trivial"].g,TradeSkillTypeColor["trivial"].b);
				end
				getglobal(skillBar):SetValue(info.v);
				getglobal(skillRank):SetText(info.v.."/"..info.m);
				
			else
				getglobal(skillBar):SetValue(1);
				getglobal(skillRank):SetText("");
			end
		
			getglobal(ownerField):Show();
			getglobal(skillBar):Show();
		end;
		
		updateAll = function(updateData)
		
			if GuildAdsFactionFrame:IsVisible() then
				local offset = FauxScrollFrame_GetOffset(GuildAdsReputationListScrollFrame);
		
				local linear = GuildAdsFaction.data.get(updateData);
				local linearSize = table.getn(linear);
				
				
				--local gender = UnitSex("player");
				
				-- init
				local i = 1;
				local j = i + offset;
				GuildAdsFaction.debug("GuildAdsFaction.factionButton.updateAll ("..linearSize..") ("..offset..")");
				
				-- for each buttons
				while (i <= GUILDADS_NUM_GLOBAL_FACTION_BUTTONS) do
					--local button = getglobal("GuildAdsReputationBar"..i);
					local factionBar = getglobal("GuildAdsReputationBar"..i);
					local factionHeader = getglobal("GuildAdsReputationHeader"..i);
					--GuildAdsFaction.debug("i="..i.." j="..j);
					if (j <= linearSize) then
						--GuildAdsFaction.debug("linear[j].i="..linear[j].i);
						
						if (linear[j].p) then
							--GuildAdsFaction.debug("Player="..linear[j].p);
							-- update internal data
							factionBar.player = linear[j].p;
							factionBar.id = linear[j].i;
							
							--local factionStanding = GetText("FACTION_STANDING_LABEL"..linear[j].s, gender);
							local factionStanding = getglobal("FACTION_STANDING_LABEL"..linear[j].s);
							getglobal("GuildAdsReputationBar"..i.."FactionStanding"):SetText(factionStanding);
							
							local factionName = getglobal("GuildAdsReputationBar"..i.."FactionName");
							factionName:SetText(linear[j].p); -- playername
							
							local online = GuildAdsGuild.isOnline(linear[j].p);
							local ocolor, lcolor;
							local account = GuildAdsDB.profile.Main:get(linear[j].p, GuildAdsDB.profile.Main.Account);
							if online then
								ocolor = GuildAdsUITools.onlineColor[online];
								lcolor = GuildAdsUITools.white;
							else
								ocolor = GuildAdsUITools.accountOnlineColor[GuildAdsGuild.isAccountOnline(account)];
								lcolor = ocolor;
							end
							factionName:SetTextColor(ocolor.r, ocolor.g, ocolor.b);
							
							-- Normalize values
							local barMax = linear[j].t - linear[j].b;
							local barValue = linear[j].v - linear[j].b;
							local barMin = 0;
				
							--factionBar.id = factionIndex;
							factionBar.standingText = factionStanding;
							factionBar.tooltip = HIGHLIGHT_FONT_COLOR_CODE.." "..barValue.." / "..barMax..FONT_COLOR_CODE_CLOSE;
							factionBar:SetMinMaxValues(0, barMax);
							factionBar:SetValue(barValue);
							color = FACTION_BAR_COLORS[linear[j].s];
							factionBar:SetStatusBarColor(color.r, color.g, color.b);
							--factionBar:SetID(factionIndex);
							factionBar:Show();
							factionHeader:Hide();
							
							factionName:SetWidth(110);
					
							getglobal("GuildAdsReputationBar"..i.."Highlight1"):Hide();
							getglobal("GuildAdsReputationBar"..i.."Highlight2"):Hide();
							
							-- create a ads
							--GuildAdsFaction.factionButton.update(factionBar, g_GlobalAdSelectedId==linear[j].i, linear[j]);
						else
							-- update internal data
							factionHeader.player = nil;
							factionHeader.id = linear[j].i;
							factionHeader.isCollapsed = not linear[j].h;
							
							if ( factionHeader.isCollapsed ) then
								factionHeader:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
							else
								factionHeader:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up"); 
							end
							
							--GuildAdsFaction.debug("Header="..GuildAdsFactionDataType:getNameFromId(linear[j].i));
							-- empty line
							factionHeader:SetText(GuildAdsFactionDataType:getNameFromId(linear[j].i));
							factionBar:Hide();
							factionHeader:Show();
							--GuildAdsFaction.factionButton.delete(button);
						end
						--button:Show();
						j = j+1;
					else
						factionBar:Hide();
						factionHeader:Hide();
					end
		
					i = i+1;
				end
	
				FauxScrollFrame_Update(GuildAdsReputationListScrollFrame, linearSize, GUILDADS_NUM_GLOBAL_FACTION_BUTTONS, GuildAdsFaction.GUILDADS_ADBUTTONSIZEY);
			else
				-- update another tab than the visible one
				if updateData then
					-- but data needs to be reset
					GuildAdsFaction.data.resetCache();
				end
			end
		
		end
		
	}
	
}

---------------------------------------------------------------------------------
--
-- Register plugin
-- 
---------------------------------------------------------------------------------
GuildAdsPlugin.UIregister(GuildAdsFaction);