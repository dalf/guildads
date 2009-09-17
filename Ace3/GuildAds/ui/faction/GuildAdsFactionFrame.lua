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
local GUILDADS_PLAYER_MAX_LEVEL = 80;

local GUILDADS_FACTION_GROUPS = {
					[1] = 1, [2] = 1, [3] = 1, [4] = 1, [5] = 1, [6] = 2,
					[7] = 2,  [8] = 2, [9] = 1, [10] = 1, [11] = 1, [12] = 1,
					[13] = 1, [14] = 2, [15] = 2, [16] = 2, [17] = 3, [18] = 3,
					[19] = 3, [20] = 3, [21] = 3, [22] = 3, [23] = 3, [24] = 3,
					[25] = 3, [26] = 9, [27] = 4, [28] = 4, [29] = 4, [30] = 4,
					[31] = 4, [32] = 5, [33] = 5, [34] = 5, [35] = 5, [36] = 6,
					[37] = 6, [38] = 9, [39] = 9, [40] = 6, [41] = 6, [42] = 9,
					[43] = 6, [44] = 6, [45] = 6, [46] = 6, [47] = 6, [48] = 6,
					[49] = 6, [50] = 9, [51] = 6, [52] = 9, [53] = 6, [54] = 6,
					[55] = 4, [56] = 6,
					[57] = 7, [58] = 7, [59] = 7, [60] = 7, [61] = 7, [62] = 7,
					[63] = 7, [64] = 7, [65] = 7, [66] = 7, [67] = 7, [68] = 7,
					[69] = 8, [70] = 8, [71] = 8
				};
local GUILDADS_FACTION_GROUP_OPTION = {
					[1] = "ShowFaction";
					[2] = "ShowFactionForces";
					[3] = "ShowOutland";
					[4] = "ShowShattrathCity";
					[5] = "ShowSteamwheedleCartel";
					[6] = "ShowOther";
					[7] = "ShowNorthrend";
					[8] = "ShowDalaran",
					[9] = "ShowRaid"
					};

--- Index of the ad currently selected
local g_GlobalAdSelectedId;

local new = GuildAds.new
local new_kv = GuildAds.new_kv
local del = GuildAds.del
local deepDel = GuildAds.deepDel

GuildAdsFaction = {
	metaInformations = { 
		name = "Reputation",
        guildadsCompatible = 100,
		ui = {
			main = {
				frame = "GuildAdsFactionFrame",
				tab = "GuildAdsFactionTab",
				tooltip = GUILDADSTOOLTIPS_FACTION,
				tooltiptitle = GUILDADSTOOLTIPS_FACTION_TITLE,
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
					[49] = true, [50] = true, [51] = true, [52] = true, [53] = true, [54] = true,
					[55] = true
				}
			);
		end
		
		if type(GuildAdsFaction.getRawProfileValue(nil, "HideCollapsed"))=="nil" then
			GuildAdsFaction.setProfileValue(nil, "HideCollapsed", true);
		end
		
		if type(GuildAdsFaction.getRawProfileValue(nil, "OnlyLevel80"))=="nil" then
			GuildAdsFaction.setProfileValue(nil, "OnlyLevel80", true);
		end

		if type(GuildAdsFaction.getRawProfileValue(nil, "ShowOfflines"))=="nil" then
			GuildAdsFaction.setProfileValue(nil, "ShowOfflines", true);
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
	end;
	
	onOnline = function(playerName, status)
		GuildAdsFaction.data.resetCache();
		GuildAdsFaction.factionButton.updateAll(nil, true);
	end;
	
	onDBUpdate = function(dataType, playerName, id)
		GuildAdsFaction.factionButton.updateAll(nil, true);
	end;
	
	onReceivedTransaction = function(dataType, playerName, newKeys, deletedKeys)
		GuildAdsFaction.factionButton.updateAll(nil, true);
	end;
	
	onShow = function()
		GuildAdsFaction.debug("onShow()");
		
		GuildAdsFaction.updateCheckButton(GuildAds_FactionHideCollapsedCheckButton, GuildAdsFaction.getProfileValue(nil, "HideCollapsed"));
		GuildAdsFaction.updateCheckButton(GuildAds_FactionOnlyLevel80CheckButton, GuildAdsFaction.getProfileValue(nil, "OnlyLevel80"));
		GuildAdsFaction.updateCheckButton(GuildAds_FactionShowOfflinesCheckButton, GuildAdsFaction.getProfileValue(nil, "ShowOfflines"));
		
		GuildAdsFaction.updateCheckButton(GuildAds_FactionShowFactionCheckButton, GuildAdsFaction.getProfileValue(nil, "ShowFaction"));
		GuildAdsFaction.updateCheckButton(GuildAds_FactionShowFactionForcesCheckButton, GuildAdsFaction.getProfileValue(nil, "ShowFactionForces"));
		GuildAdsFaction.updateCheckButton(GuildAds_FactionShowOutlandCheckButton, GuildAdsFaction.getProfileValue(nil, "ShowOutland"));
		GuildAdsFaction.updateCheckButton(GuildAds_FactionShowShattrathCityCheckButton, GuildAdsFaction.getProfileValue(nil, "ShowShattrathCity"));
		GuildAdsFaction.updateCheckButton(GuildAds_FactionShowSteamwheedleCartelCheckButton, GuildAdsFaction.getProfileValue(nil, "ShowSteamwheedleCartel"));
		GuildAdsFaction.updateCheckButton(GuildAds_FactionShowOtherCheckButton, GuildAdsFaction.getProfileValue(nil, "ShowOther"));
		GuildAdsFaction.updateCheckButton(GuildAds_FactionShowNorthrendCheckButton, GuildAdsFaction.getProfileValue(nil, "ShowNorthrend"));
		GuildAdsFaction.updateCheckButton(GuildAds_FactionShowDalaranCheckButton, GuildAdsFaction.getProfileValue(nil, "ShowDalaran"));
		GuildAdsFaction.updateCheckButton(GuildAds_FactionShowRaidCheckButton, GuildAdsFaction.getProfileValue(nil, "ShowRaid"));
		
		GuildAdsDB.profile.Faction:registerUpdate(GuildAdsFaction.onDBUpdate);
		GuildAdsDB.profile.Faction:registerTransactionReceived(GuildAdsFaction.onReceivedTransaction);
		
		GuildAdsFaction.factionButton.updateAll(nil, true);
		GuildAdsFactionFrame:Show();
	end;

	onHide = function()
		GuildAdsFaction.debug("onHide()");
		GuildAdsDB.profile.Faction:unregisterUpdate(GuildAdsFaction.onDBUpdate);
		GuildAdsDB.profile.Faction:unregisterTransactionReceived(GuildAdsFaction.onReceivedTransaction);
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
			GuildAdsFaction.data.cacheReset = true;
		end;
		
		get = function(updateData)	
			if not GuildAdsFaction.data.cache or updateData or GuildAdsFaction.data.cacheReset then
				GuildAdsFaction.debug("reset cache");
				
				GuildAdsFaction.data.cacheReset = nil
				local insertHeader;
				
				local workFactions = new()
				for id, name in pairs(GUILDADS_FACTIONS) do
					local group=GUILDADS_FACTION_GROUPS[id];
					if GuildAdsFaction.getProfileValue(nil, GUILDADS_FACTION_GROUP_OPTION[group]) then
						workFactions[id]=name;
					end
				end
				
				deepDel(GuildAdsFaction.data.cache);
				GuildAdsFaction.data.cache = new();
				
				local hideCollapsed=false; -- hide collapsed headers unless all headers are collapsed
				if GuildAdsFaction.getProfileValue(nil, "HideCollapsed") then
					for id, name in pairs(workFactions) do
						if GuildAdsFaction.getProfileValue("Filters", id) then
							for playerName, _, data in GuildAdsFactionDataType:iterator(nil, id) do
								if GuildAdsFaction.getProfileValue(nil, "ShowOfflines") or GuildAdsGuild.isOnline(playerName) then
									if not (GuildAdsFaction.getProfileValue(nil, "OnlyLevel80") and ((GuildAdsDB.profile.Main:get(playerName, GuildAdsDB.profile.Main.Level) or 0)<GUILDADS_PLAYER_MAX_LEVEL)) then
										hideCollapsed=true;
									end
								end
							end
						end
					end
				end

				-- for each faction
				for id, name in pairs(workFactions) do
					local factionOpen=GuildAdsFaction.getProfileValue("Filters", id);
					insertHeader = true;
					-- for each player
					for playerName, _, data in GuildAdsFactionDataType:iterator(nil, id) do
						if GuildAdsFaction.getProfileValue(nil, "ShowOfflines") or GuildAdsGuild.isOnline(playerName) then
							if not (GuildAdsFaction.getProfileValue(nil, "OnlyLevel80") and ((GuildAdsDB.profile.Main:get(playerName, GuildAdsDB.profile.Main.Level) or 0)<GUILDADS_PLAYER_MAX_LEVEL)) then
								if insertHeader and (not hideCollapsed or factionOpen) then
									tinsert(GuildAdsFaction.data.cache, new_kv("i", id, "h", factionOpen) );
									insertHeader = nil;
								end
								if factionOpen then
									tinsert(GuildAdsFaction.data.cache, new_kv("i", id, "p", playerName, "v", data.v, "b", data.b, "t", data.t, "s", data.s ));
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
			GuildAdsFaction.factionButton.updateAll(nil, true);
		end;
			
		CollapseFactionHeader = function(factionId)
			GuildAdsFaction.setProfileValue("Filters", factionId, false);
			GuildAdsFaction.factionButton.updateAll(nil, true);
		end;
		
		ExpandAllFactionHeaders = function()
			for i=1, table.getn(GUILDADS_FACTIONS) do
				GuildAdsFaction.setProfileValue("Filters", i, true);
			end;
			GuildAdsFaction.factionButton.updateAll(nil, true);
		end;
		
		CollapseAllFactionHeaders = function()
			for i=1, table.getn(GUILDADS_FACTIONS) do
				GuildAdsFaction.setProfileValue("Filters", i, false);
			end;
			GuildAdsFaction.factionButton.updateAll(nil, true);
		end;
		
		checkButtonSetProfile = function(button,option)
			if ( button:GetChecked() ) then
				PlaySound("igMainMenuOptionCheckBoxOn");
				GuildAdsFaction.setProfileValue(nil, option, true);
			else
				PlaySound("igMainMenuOptionCheckBoxOff");
				GuildAdsFaction.setProfileValue(nil, option, false);
			end
			GuildAdsFaction.factionButton.updateAll(nil, true);
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
		
		updateAll = function(self, updateData)
		
			if GuildAdsFactionFrame:IsVisible() then
				local offset = FauxScrollFrame_GetOffset(GuildAdsReputationListScrollFrame);
		
				local linear = GuildAdsFaction.data.get(updateData);
				local linearSize = table.getn(linear);
				
				
				--local gender = UnitSex("player");
				
				-- init
				local i = 1;
				local j = i + offset;
				--GuildAdsFaction.debug("GuildAdsFaction.factionButton.updateAll ("..linearSize..") ("..offset..")");
				
				-- for each buttons
				while (i <= GUILDADS_NUM_GLOBAL_FACTION_BUTTONS) do
					local factionBar = getglobal("GuildAdsReputationBar"..i);
					local factionHeader = getglobal("GuildAdsReputationHeader"..i);
					local factionHeaderText = getglobal("GuildAdsReputationHeader"..i.."NormalText");
					if (j <= linearSize) then
						
						if (linear[j].p) then
							-- update internal data
							factionBar.player = linear[j].p;
							factionBar.id = linear[j].i;
							
							local barMin, barMax, standingId = GuildAdsFaction.factionButton.getFactionMinMax(linear[j].v)

							--local factionStanding = GetText("FACTION_STANDING_LABEL"..linear[j].s, gender);
							local factionStanding = getglobal("FACTION_STANDING_LABEL"..(linear[j].s or standingId));
							getglobal("GuildAdsReputationBar"..i.."FactionStanding"):SetText(factionStanding);
							
							local factionName = getglobal("GuildAdsReputationBar"..i.."FactionName");
							factionName:SetText(linear[j].p); -- playername
							
							local ocolor = GuildAdsUITools:GetPlayerColor(linear[j].p)
							factionName:SetTextColor(ocolor.r, ocolor.g, ocolor.b);
							
							-- Normalize values
							barMax = (linear[j].t or barMax) - (linear[j].b or barMin)
							barValue = linear[j].v - (linear[j].b or barMin)
							barMin = 0;
				
							--factionBar.id = factionIndex;
							factionBar.standingText = factionStanding;
							factionBar.tooltip = HIGHLIGHT_FONT_COLOR_CODE.." "..barValue.." / "..barMax..FONT_COLOR_CODE_CLOSE;
							factionBar:SetMinMaxValues(0, barMax);
							factionBar:SetValue(barValue);
							color = FACTION_BAR_COLORS[(linear[j].s or standingId)];
							factionBar:SetStatusBarColor(color.r, color.g, color.b);
							factionBar:Show();
							factionHeader:Hide();
							
							factionName:SetWidth(110);
					
							getglobal("GuildAdsReputationBar"..i.."Highlight1"):Hide();
							getglobal("GuildAdsReputationBar"..i.."Highlight2"):Hide();
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
							
							-- empty line
							factionHeaderText:SetText(GuildAdsFactionDataType:getNameFromId(linear[j].i));
							factionBar:Hide();
							factionHeader:Show();
						end
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
		
		end;
		
		getFactionMinMax = function(reputation)
			local barMin, barMax, standingId
			if reputation >= 42000 then
				barMin, barMax, standingId = 42000, 43000, 8
			elseif reputation >= 21000 then
				barMin, barMax, standingId = 21000, 42000, 7
			elseif reputation >= 9000 then
				barMin, barMax, standingId = 9000, 21000, 6
			elseif reputation >= 3000 then
				barMin, barMax, standingId = 3000, 9000, 5
			elseif reputation >= 0 then
				barMin, barMax, standingId = 0, 3000, 4
			elseif reputation >= -3000 then
				barMin, barMax, standingId = -3000, 0, 3
			elseif reputation >= -6000 then
				barMin, barMax, standingId = -6000, -3000, 2
			elseif reputation >= -42000 then
				barMin, barMax, standingId = -42000, -6000, 1
			else
				barMin, barMax, standingId = -42000, 43000, 4
			end
			return barMin, barMax, standingId
		end;
	}
	
}

---------------------------------------------------------------------------------
--
-- Register plugin
-- 
---------------------------------------------------------------------------------
GuildAdsPlugin.UIregister(GuildAdsFaction);