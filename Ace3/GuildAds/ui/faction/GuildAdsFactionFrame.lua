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
local GUILDADS_PLAYER_MAX_LEVEL = 85;

local GUILDADS_FACTION_GROUPS = {
					[1] = 1, [2] = 1, [3] = 1, [4] = 1, [5] = 1, [6] = 2,
					[7] = 2,  [8] = 2, [9] = 1, [10] = 1, [11] = 1, [12] = 1,
					[13] = 1, [14] = 2, [15] = 2, [16] = 2, [17] = 4, [18] = 4,
					[19] = 4, [20] = 4, [21] = 4, [22] = 4, [23] = 4, [24] = 4,
					[25] = 4, [26] = 4, [27] = 5, [28] = 5, [29] = 5, [30] = 5,
					[31] = 5, [32] = 3, [33] = 3, [34] = 3, [35] = 3, [36] = 0,
					[37] = 0, [38] = 0, [39] = 0, [40] = 0, [41] = 0, [42] = 0,
					[43] = 0, [44] = 0, [45] = 0, [46] = 6, [47] = 0, [48] = 0,
					[49] = 6, [50] = 0, [51] = 4, [52] = 4, [53] = 0, [54] = 4,
					[55] = 5, [56] = 7,
					[57] = 7, [58] = 8, [59] = 9, [60] = 8, [61] = 8, [62] = 7,
					[63] = 9, [64] = 7, [65] = 8, [66] = 8, [67] = 8, [68] = 7,
					[69] = 7, [70] = 8, [71] = 8, [72] = 8, [73] = 8, [74] = 7,
					[75] = 1, [76] = 6,
					[77] = 10, [78] = 10, [79] = 10, [80] = 10, [81] = 10, [82] = 10,
					[83] = 2, [84] = 10, [85] = 10
				};
local GUILDADS_FACTION_GROUP_OPTION = {
					[0] = "ShowClassic";
					[1] = "ShowFaction";
					[2] = "ShowFactionForces";
					[3] = "ShowSteamwheedleCartel";
					[4] = "ShowOutland";
					[5] = "ShowShattrathCity";
					[6] = "ShowOther";
					[7] = "ShowNorthrend";
					[8] = "ShowNorthrendForces",
					[9] = "ShowSholazarBasin",
					[10] = "ShowCataclysm"
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
			local filters = {}
			for faction=1, 74 do
					filters[faction] = true;
			end
			GuildAdsFaction.setProfileValue(nil, "Filters",  filters);
		end
		
		if type(GuildAdsFaction.getRawProfileValue(nil, "HideCollapsed"))=="nil" then
			GuildAdsFaction.setProfileValue(nil, "HideCollapsed", true);
		end
		
		if type(GuildAdsFaction.getRawProfileValue(nil, "OnlyLevel"))=="nil" then
			GuildAdsFaction.setProfileValue(nil, "OnlyLevel", true);
		end
		GuildAdsFaction.setProfileValue(nil, "OnlyLevel80", nil); -- remove old profile value
		
		if type(GuildAdsFaction.getRawProfileValue(nil, "ShowOfflines"))=="nil" then
			GuildAdsFaction.setProfileValue(nil, "ShowOfflines", true);
		end
		
		local group, groupname;
		for group, groupname in pairs(GUILDADS_FACTION_GROUP_OPTION) do
			if type(GuildAdsFaction.getRawProfileValue(nil, groupname))=="nil" then
				GuildAdsFaction.setProfileValue(nil, groupname, true); -- initialise all group settings to true (first run)
			end
		end
		
		-- Update faction specific labels
		local faction = UnitFactionGroup("player");
		GuildAds_FactionShowFactionCheckButtonLabel:SetText(string.format(GUILDADS_FACTION_SHOWFACTION, faction));
		GuildAds_FactionShowFactionForcesCheckButtonLabel:SetText(string.format(GUILDADS_FACTION_SHOWFACTIONFORCES, faction));
		if faction=="Horde" then
			GuildAds_FactionShowNorthrendForcesCheckButtonLabel:SetText(GUILDADS_FACTION_SHOWHORDEEXPEDITION);
		else
			GuildAds_FactionShowNorthrendForcesCheckButtonLabel:SetText(GUILDADS_FACTION_SHOWALLIANCEVANGUARD);
		end
		GuildAds_FactionOnlyLevelCheckButtonLabel:SetText(string.format(GUILDADS_FACTION_ONLY_LEVEL, GUILDADS_PLAYER_MAX_LEVEL));
		-- delete old configuration (too be removed in the future)
		GuildAdsFaction.setProfileValue(nil, "ShowDalaran", nil);
		GuildAdsFaction.setProfileValue(nil, "ShowRaid", nil);
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
		GuildAdsFaction.updateCheckButton(GuildAds_FactionOnlyLevelCheckButton, GuildAdsFaction.getProfileValue(nil, "OnlyLevel"));
		GuildAdsFaction.updateCheckButton(GuildAds_FactionShowOfflinesCheckButton, GuildAdsFaction.getProfileValue(nil, "ShowOfflines"));
		
		GuildAdsFaction.updateCheckButton(GuildAds_FactionShowClassicCheckButton, GuildAdsFaction.getProfileValue(nil, "ShowClassic"));
		GuildAdsFaction.updateCheckButton(GuildAds_FactionShowFactionCheckButton, GuildAdsFaction.getProfileValue(nil, "ShowFaction"));
		GuildAdsFaction.updateCheckButton(GuildAds_FactionShowFactionForcesCheckButton, GuildAdsFaction.getProfileValue(nil, "ShowFactionForces"));
		GuildAdsFaction.updateCheckButton(GuildAds_FactionShowSteamwheedleCartelCheckButton, GuildAdsFaction.getProfileValue(nil, "ShowSteamwheedleCartel"));
		GuildAdsFaction.updateCheckButton(GuildAds_FactionShowOutlandCheckButton, GuildAdsFaction.getProfileValue(nil, "ShowOutland"));
		GuildAdsFaction.updateCheckButton(GuildAds_FactionShowShattrathCityCheckButton, GuildAdsFaction.getProfileValue(nil, "ShowShattrathCity"));
		GuildAdsFaction.updateCheckButton(GuildAds_FactionShowNorthrendCheckButton, GuildAdsFaction.getProfileValue(nil, "ShowNorthrend"));
		GuildAdsFaction.updateCheckButton(GuildAds_FactionShowNorthrendForcesCheckButton, GuildAdsFaction.getProfileValue(nil, "ShowNorthrendForces"));
		GuildAdsFaction.updateCheckButton(GuildAds_FactionShowSholazarBasinCheckButton, GuildAdsFaction.getProfileValue(nil, "ShowSholazarBasin"));
		GuildAdsFaction.updateCheckButton(GuildAds_FactionShowCataclysmCheckButton, GuildAdsFaction.getProfileValue(nil, "ShowCataclysmBasin"));
		GuildAdsFaction.updateCheckButton(GuildAds_FactionShowOtherCheckButton, GuildAdsFaction.getProfileValue(nil, "ShowOther"));
		
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
									if not (GuildAdsFaction.getProfileValue(nil, "OnlyLevel") and ((GuildAdsDB.profile.Main:get(playerName, GuildAdsDB.profile.Main.Level) or 0)<GUILDADS_PLAYER_MAX_LEVEL)) then
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
							if not (GuildAdsFaction.getProfileValue(nil, "OnlyLevel") and ((GuildAdsDB.profile.Main:get(playerName, GuildAdsDB.profile.Main.Level) or 0)<GUILDADS_PLAYER_MAX_LEVEL)) then
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