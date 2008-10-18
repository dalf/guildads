----------------------------------------------------------------------------------
--
-- GuildAdsSkillFrame.lua
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

GUILDADSSKILL_TAB_PROFESSION = 1;
GUILDADSSKILL_TAB_SKILL = 2;

local GUILDADS_NUM_GLOBAL_AD_BUTTONS = 21;

--- Index of the ad currently selected
local g_currentTab = GUILDADSSKILL_TAB_PROFESSION;
local g_GlobalAdSelectedId;

--- Local copy of TradeSkillTypeColor (available at load without Blizzard addon)
local TradeSkillTypeColor = { };
TradeSkillTypeColor["optimal"]	= { r = 1.00, g = 0.50, b = 0.25 };
TradeSkillTypeColor["medium"]	= { r = 1.00, g = 1.00, b = 0.00 };
TradeSkillTypeColor["easy"]		= { r = 0.25, g = 0.75, b = 0.25 };
TradeSkillTypeColor["trivial"]	= { r = 0.50, g = 0.50, b = 0.50 };
TradeSkillTypeColor["header"]	= { r = 1.00, g = 0.82, b = 0 };

local PROFESSION_ARRAY = {
	[1] = { 
		[1] = {["texture"]="Interface\\Icons\\Trade_Herbalism",["id"]=1},
		[2] = {["texture"]="Interface\\Icons\\Trade_Fishing",["id"]=10},
		[3] = {["texture"]="Interface\\Icons\\INV_Misc_Pelt_Wolf_01",["id"]=3}
		  },
	[2] = {	
		[1] = {["texture"]="Interface\\Icons\\Trade_Alchemy",["id"]=4},
		[2] = {},
		[3] = {["texture"]="Interface\\Icons\\Trade_LeatherWorking",["id"]=7}
		  },
	[3] = {	
		[1] = {},
		[2] = {["texture"]="Interface\\Icons\\INV_Misc_Food_15",["id"]=12},
		[3] = {}
		  },
	[4] = {	
		[1] = {["texture"]="Interface\\Icons\\Trade_Mining",["id"]=2},
		[2] = {["texture"]="Interface\\Icons\\INV_Inscription_MajorGlyph10",["id"]=15},
		[3] = {["texture"]="Interface\\Icons\\Trade_Tailoring",["id"]=8}
		},
	[5] = {	
		[1] = {["texture"]="Interface\\Icons\\Trade_BlackSmithing",["id"]=5},
		[2] = {["texture"]="Interface\\Icons\\Trade_Engineering",["id"]=6},
		[3] = {["texture"]="Interface\\Icons\\INV_Misc_Gem_01",["id"]=14}
		},
	[6] = { 
		[1] = {["texture"]="Interface\\Icons\\Trade_Engraving",["id"]=9},
		[2] = {["texture"]="Interface\\Icons\\Spell_Holy_SealOfSacrifice",["id"]=11},
		[3] = {["texture"]="Interface\\Icons\\INV_Misc_Key_03",["id"]=13}
		}
}
	
local SKILL_ARRAY = {
	[1] = { 
		[1] = {["texture"]="Interface\\Icons\\Trade_Herbalism",["id"]=20},
		[2] = {},
		[3] = {}
		  },
	[2] = {	
		[1] = {["texture"]="Interface\\Icons\\INV_Sword_04",["id"]=22},
		[2] = {["texture"]="Interface\\Icons\\INV_Sword_04",["id"]=23},
		[3] = {["texture"]="Interface\\Icons\\INV_Weapon_Rifle_01",["id"]=31}
		  },
	[3] = {	
		[1] = {["texture"]="Interface\\Icons\\INV_Mace_04",["id"]=24},
		[2] = {["texture"]="Interface\\Icons\\INV_Mace_04",["id"]=25},
		[3] = {["texture"]="Interface\\Icons\\INV_Weapon_Bow_01",["id"]=32}
		  },
	[4] = {	
		[1] = {["texture"]="Interface\\Icons\\INV_Axe_04",["id"]=26},
		[2] = {["texture"]="Interface\\Icons\\INV_Axe_04",["id"]=27},
		[3] = {["texture"]="Interface\\Icons\\INV_Weapon_Crossbow_01",["id"]=33},
	 	  },
	[5] = {	
		[1] = {["texture"]="Interface\\Icons\\INV_Weapon_ShortBlade_01",["id"]=21},
		[2] = {["texture"]="Interface\\Icons\\INV_Weapon_Halbard_01",["id"]=28},
		[3] = {["texture"]="Interface\\Icons\\INV_ThrowingKnife_02",["id"]=30},
		  },
	[6] = { 
		[1] = {},
		[2] = {["texture"]="Interface\\Icons\\INV_Staff_04",["id"]=29},
		[3] = {["texture"]="Interface\\Icons\\INV_Wand_04",["id"]=34}
		  }
}

GuildAdsSkill = {
	metaInformations = { 
		name = "Skill",
        guildadsCompatible = 100,
		ui = {
			main = {
				frame = "GuildAdsSkillFrame",
				tab = "GuildAdsSkillTab",
                tooltiptitle = GUILDADSTOOLTIPS_SKILL_TITLE,
				tooltip = GUILDADSTOOLTIPS_SKILL,--"Skill tab",
				priority = 2
			}
		}
	};
	
	GUILDADS_ADBUTTONSIZEY = 16;
	
	onInit = function()
		if not GuildAdsSkill.getProfileValue(nil, "Filters") then
			GuildAdsSkill.setProfileValue(nil, "Filters",  
				{
					[4] = true, [5] = true, [6] = true, [7] = true,  [8] = true, [9] = true,
					[13] = true, [14] = true, [20] = true, [21] = true, [22] = true, [23] = true, 
					[24] = true, [25] = true, [26] = true, [27] = true, [28] = true, [29] = true, 
					[30] = true, [31] = true, [32] = true, [33] = true, [34] = true
				}
			);
		end
		
		GuildAdsDB.profile.Skill:registerUpdate(GuildAdsSkill.onDBUpdate);
	end;
	
	onDBUpdate = function(dataType, playerName, id)
		GuildAdsSkill.skillButton.updateAll(true);
	end;
	
	onShow = function()
		GuildAdsSkill.filterBySkillButton.initializeTab();
	end;
	
	selectTab = function(tab)
		g_currentTab = tab;
		g_GlobalAdSelected = 0;
		if (tab == GUILDADSSKILL_TAB_PROFESSION) then
			PanelTemplates_SelectTab(GuildAds_MySkillTab1);
			PanelTemplates_DeselectTab(GuildAds_MySkillTab2);
		elseif (tab == GUILDADSSKILL_TAB_SKILL) then 
			PanelTemplates_SelectTab(GuildAds_MySkillTab2);
			PanelTemplates_DeselectTab(GuildAds_MySkillTab1);
		end
		GuildAdsSkill.filterBySkillButton.initializeTab();
		GuildListAdProfessionListFrame:Show();
	end;
	
	data = {
	
		cache = nil;
		
		resetCache = function()
			GuildAdsSkill.data.cache = nil;
		end;
		
		get = function(updateData)	
			if not GuildAdsSkill.data.cache or updateData then
				GuildAdsSkill.debug("reset cache");
				local insertHeader;
				
				GuildAdsSkill.data.cache = {};

				-- for each skill
				for id, name in pairs(GUILDADS_SKILLS) do
					if GuildAdsSkill.filterBySkillButton.order[id] and GuildAdsSkill.getProfileValue("Filters", id) then
						insertHeader = true;
						-- for each player
						for playerName, _, data in GuildAdsSkillDataType:iterator(nil, id) do
							if insertHeader then
								tinsert(GuildAdsSkill.data.cache, {i=id } );
								insertHeader = nil;
							end
							tinsert(GuildAdsSkill.data.cache, {i=id, p=playerName, v=data.v, m=data.m });
						end
					end
				end
				
				GuildAdsSkill.sortData.doIt(GuildAdsSkill.data.cache);
			end
			return GuildAdsSkill.data.cache;
		end;
	
	};
	
	sortData = {
		doIt = function(adTable)
 			table.sort(adTable, GuildAdsSkill.sortData.predicate);
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
				-- Sort by skill name (ie id)
				--
				local aa = GuildAdsSkill.filterBySkillButton.order[a.i];
				local bb = GuildAdsSkill.filterBySkillButton.order[b.i];
				if (aa < bb) then
					return true;
				elseif (aa > bb) then
					return false;
				end
			end
			
			if (a.v and b.v) then
				--
				-- Sort by skill rank
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
	
	filterBySkillButton = {
		_filtersArray = {
			[GUILDADSSKILL_TAB_PROFESSION] = PROFESSION_ARRAY,
			[GUILDADSSKILL_TAB_SKILL] = SKILL_ARRAY
		};
		
		order = {};
		
		set = function(skillId, value, toggle)
			-- value or toggle must be set.
			if not(value~=nil or toggle~=nil) then
				return;
			end
			
			local node, newValue;
			for i =1, 6 do
				for j=1, 3 do
					node = GuildAdsSkill.filterBySkillButton._filtersArray[g_currentTab][i][j];
					if (node.texture) and ((skillId==nil) or (skillId and node.id==skillId)) then
						GuildAdsSkill.debug("set("..i..","..j..") node("..node.id..")="..tostring(GuildAdsSkill.getProfileValue("Filters", node.id)));
						if toggle then
							newValue = not GuildAdsSkill.getProfileValue("Filters", node.id, false);
						else
							newValue = value and true or false;
						end
						GuildAdsSkill.filterBySkillButton.update(i, j, newValue);
					end
				end
			end
			GuildAdsSkill.skillButton.updateAll(true);			
		end;
		
		update = function(i, j, status)
			local node = GuildAdsSkill.filterBySkillButton._filtersArray[g_currentTab][i][j];
			local index = (i-1)*3+j;
			local button = getglobal("GuildAdsProfessionButton"..index);
			local slot = getglobal("GuildAdsProfessionButton"..index.."Slot");
			if status then
				SetItemButtonDesaturated(button, nil);
				slot:SetVertexColor(1.0, 0.82, 0);
			else
				SetItemButtonDesaturated(button, 1, 0.4, 0.4, 0.4);
				slot:SetVertexColor(0.4, 0.4, 0.4);
			end
			if node.id then
				GuildAdsSkill.setProfileValue("Filters", node.id, status and true or nil);
			end
		end;
		
		initialize = function(i, j)
			local node = GuildAdsSkill.filterBySkillButton._filtersArray[g_currentTab][i][j];
			local index = (i-1)*3+j;
			local button = getglobal("GuildAdsProfessionButton"..index);
			local texture = getglobal("GuildAdsProfessionButton"..index.."IconTexture");
			
			if not button then
				return;
			end
			
			local column = ((j - 1) * 63) + 50;
			local tier = -((i - 1) * 63) - 100;
			button:SetPoint("TOPLEFT", "GuildAdsMainWindowFrame", "TOPLEFT", column, tier);
			
			texture:SetTexture(node.texture);
			
			if (node.id) then
				texture:Show();
				GuildAdsSkill.filterBySkillButton.update(i, j, GuildAdsSkill.getProfileValue("Filters", node.id, false));
				button:Show();
				button.skillId = node.id;
				button.i = i;
				button.j = j;
				GuildAdsSkill.filterBySkillButton.order[node.id] = index;
			else
				texture:Hide();
				button:Hide();
				button.skillId = nil;
			end
		end;
		
		initializeTab = function()
			GuildAdsSkill.filterBySkillButton.order = {};
			for i =1, 6 do
				for j=1, 3 do
					GuildAdsSkill.filterBySkillButton.initialize(i, j);
				end
			end
			GuildAdsSkill.skillButton.updateAll(true);		
		end;
		
		onEnter = function()
			GameTooltip:SetOwner(this,"ANCHOR_BOTTOMRIGHT");
			GameTooltip:AddLine(GUILDADS_SKILLS[this.skillId], 1.0, 1.0, 1.0);
			GameTooltip:Show();
		end;
		
		onLeave = function()
			GameTooltip:Hide();
		end;
	};
	
	skillButton = {
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
			local ownerColor = GuildAdsUITools:GetPlayerColor(info.p);

			local ownerField = buttonName.."Owner";
			local skillBar = buttonName.."SkillBar";
			local skillName = skillBar.."SkillName";
			local skillRank = skillBar.."SkillRank";
			
			getglobal(ownerField):SetText(info.p);
			getglobal(ownerField):SetTextColor(ownerColor.r, ownerColor.g, ownerColor.b);
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
		
			if GuildAdsSkillFrame:IsVisible() then
				local offset = FauxScrollFrame_GetOffset(GuildAdsSkillAdScrollFrame);
		
				local linear = GuildAdsSkill.data.get(updateData);
				local linearSize = table.getn(linear);
	
				-- init
				local i = 1;
				local j = i + offset;
				GuildAdsSkill.debug("GuildAdsSkill.skillButton.updateAll");
				
				-- for each buttons
				while (i <= GUILDADS_NUM_GLOBAL_AD_BUTTONS) do
					local button = getglobal("GuildAdsSkillAdButton"..i);
					
					if (j <= linearSize) then
						if (linear[j].p) then
							-- update internal data
							button.player = linear[j].p;
							button.id = linear[j].i;
							
							-- create a ads
							GuildAdsSkill.skillButton.update(button, g_GlobalAdSelectedId==linear[j].i, linear[j]);
						else
							-- update internal data
							button.player = nil;
							button.id = nil;
							
							-- empty line
							GuildAdsSkill.skillButton.delete(button);
						end
						button:Show();
						j = j+1;
					else
						button:Hide();
					end
		
					i = i+1;
				end
	
				FauxScrollFrame_Update(GuildAdsSkillAdScrollFrame, linearSize, GUILDADS_NUM_GLOBAL_AD_BUTTONS, GuildAdsSkill.GUILDADS_ADBUTTONSIZEY);
			else
				-- update another tab than the visible one
				if updateData then
					-- but data needs to be reset
					GuildAdsSkill.data.resetCache();
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
GuildAdsPlugin.UIregister(GuildAdsSkill);