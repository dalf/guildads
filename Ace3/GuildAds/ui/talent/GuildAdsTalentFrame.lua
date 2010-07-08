----------------------------------------------------------------------------------
--
-- GuildAdsTalentData.lua
--
-- Author: Galmok of European Stormrage (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com, galmok@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

local GLYPHTYPE_MAJOR = 1;
local GLYPHTYPE_MINOR = 2;
local GLYPH_MINOR = { r = 0, g = 0.25, b = 1};
local GLYPH_MAJOR = { r = 1, g = 0.25, b = 0};
local NUM_GLYPH_SLOTS = 6
local GLYPH_SLOTS = {};
-- Empty Texture
GLYPH_SLOTS[0] = { left = 0.78125, right = 0.91015625, top = 0.69921875, bottom = 0.828125 };
-- Major Glyphs
GLYPH_SLOTS[3] = { left = 0.392578125, right = 0.521484375, top = 0.87109375, bottom = 1 };
GLYPH_SLOTS[1] = { left = 0, right = 0.12890625, top = 0.87109375, bottom = 1 };
GLYPH_SLOTS[5] = { left = 0.26171875, right = 0.390625, top = 0.87109375, bottom = 1 };
-- Minor Glyphs
GLYPH_SLOTS[2] = { left = 0.130859375, right = 0.259765625, top = 0.87109375, bottom = 1 };
GLYPH_SLOTS[6] = { left = 0.654296875, right = 0.783203125, top = 0.87109375, bottom = 1 };
GLYPH_SLOTS[4] = { left = 0.5234375, right = 0.65234375, top = 0.87109375, bottom = 1 };

local Base64MatchString, base64chars, base64values, DecodeBase64Char, EncodeBase64Char
do
	Base64MatchString = "[A-Za-z0-9+/]";
	local base64chars = {
		'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
		'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z',
		'0','1','2','3','4','5','6','7','8','9','+','/'
	};
	local base64values = {
		-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
		-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
		-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 62, -1, -1, -1, 63, 
		52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -1, -1, -1, -1, -1, -1,
		-1, 00, 01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 
		15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -1, -1, -1, -1, -1, 
		-1, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
		41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -1, -1, -1, -1, -1}; 

	function DecodeBase64Char(c)
		c = strbyte(c);
		if c < 0 or c > 127 then
			return -1;
		end
		return base64values[c + 1];
	end

	function EncodeBase64Char(val)
		if val < 0 or val > 63 then
			return '-';
		else
			return base64chars[val + 1];
		end
	end
end

local firstShow = true
local talentTabWidthCache = {}

GuildAdsTalentUI = {
	metaInformations = { 
		name = "TalentUI",
		guildadsCompatible = 200,
		ui = {
			inspect = {
				frame = "GuildAdsTalentFrame",
				tab = "GuildAdsTalentTab",
				tooltip = "Talent tab",
				priority = 2
			}
		}
	};
	
	onInit = function()
		PanelTemplates_SetNumTabs(GuildAdsTalentFrame, 4);
		PanelTemplates_SetTab(GuildAdsTalentFrame, 1);
	end;
	
	onFirstShow = function()
		if firstShow then
			firstShow = false
			local self=GuildAdsTalentUI;
			self.TALENT_BRANCH_ARRAY={};
			local loaded, reason = LoadAddOn("Blizzard_TalentUI"); -- need it because it defines many needed constants
		
			for i=1, MAX_NUM_TALENT_TIERS do
				self.TALENT_BRANCH_ARRAY[i] = {};
				for j=1, NUM_TALENT_COLUMNS do
					self.TALENT_BRANCH_ARRAY[i][j] = {id=nil, up=0, left=0, right=0, down=0, leftArrow=0, rightArrow=0, topArrow=0};
				end
			end
			GuildAdsTalentFrameScrollFrameScrollBarScrollDownButton:SetScript("OnClick", self.DownArrow_OnClick);
			--GuildAdsDB.profile.Talent:registerUpdate(GuildAdsTalentUI.onDBUpdate);
			GuildAdsTalentUI.GuildAdsTalentFrameActivateButton_onClick(GuildAdsTalentFrameActivateButton);
			
			-- make sure glyph ui covers all of the talent ui
			local frameLevel = GuildAdsTalentFrame:GetFrameLevel() + 4;
			GuildAdsGlyphFrame:SetFrameLevel(frameLevel);
		end
	end;
	
	onShow = function()
		local self=GuildAdsTalentUI;
		
		self.onFirstShow();
	
		PlaySound("TalentScreenOpen");

		self:Update();

		-- Set flag
		if ( self.TALENT_FRAME_WAS_SHOWN ~= 1 ) then
			self.TALENT_FRAME_WAS_SHOWN = 1;
		end
	end;
	
	talentButtonOnEnter = function(this, id)
		local self=GuildAdsTalentUI;
		local selectedTab = PanelTemplates_GetSelectedTab(GuildAdsTalentFrame);
		local talentName, iconPath, tier, column, currentRank, maxRank = self.GetTalentInfo(selectedTab, id);
		talentName = this.link
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT");
		if GuildAds_ExplodeItemRef(talentName) then
			GameTooltip:SetHyperlink(talentName);
		else
			GameTooltip:SetText(HIGHLIGHT_FONT_COLOR_CODE..talentName..FONT_COLOR_CODE_CLOSE);
		end
		GameTooltip:Show();
	end;
	
	OnHide = function()
		PlaySound("TalentScreenClose");
	end;
	
	onDBUpdate = function(dataType, playerName, talent)
		local self=GuildAdsTalentUI;
		-- only update if visible...
		self:Update();
	end;
	
	LinkSetRank = function(link, rank)
		return link:gsub("(talent:[0-9]+:)(%-?[0-9]+)", "%1"..tostring(rank))
	end;
	
	GetCurrentRankHelper = function(tabIndex, ...)
		return select(tabIndex, ...)
	end;
	
	GetCurrentRank = function(talentString, tabIndex, talentIndex)
		local tabTalentString = GuildAdsTalentUI.GetCurrentRankHelper(tabIndex, string.split(":", talentString))
		local stringIndex = math.floor((talentIndex-1)/2)+1
		local c = tabTalentString:sub(stringIndex, stringIndex)
		local v = DecodeBase64Char(c)
		if math.fmod(talentIndex, 2) == 0 then
			v = bit.rshift(v,3)
		end
		v = bit.band(v, 7)
		return v
	end;
	
	GuildAdsTalentFrameActivateButton_onClick = function(self)
		if GuildAdsTalentUI.shownSpec then
			local prevSpec = GuildAdsTalentUI.shownSpec
			if GuildAdsTalentUI.shownSpec == "1" then
				GuildAdsTalentUI.shownSpec = "2"
			else
				GuildAdsTalentUI.shownSpec = "1"
			end
			if not GuildAdsDB.profile.TalentRank:get(GuildAdsInspectWindow.playerName, GuildAdsTalentUI.shownSpec) then
				GuildAdsTalentUI.shownSpec = prevSpec
			end
		else
			GuildAdsTalentUI.shownSpec = "1"
		end
		GuildAdsTalentUI.onShow();
	end;
	
	GuildAdsTalentFrameActivateButton_onShow = function(self)
		local data = GuildAdsDB.profile.TalentRank:get(GuildAdsInspectWindow.playerName, "A")
		if data then
			self:Show();
			if GuildAdsTalentUI.shownSpec == tostring(data.b) then
				self:SetText(GUILDADS_TALENT_SHOWINACTIVE)
			else
				self:SetText(GUILDADS_TALENT_SHOWACTIVE)
			end
			self:SetWidth(self:GetTextWidth() + 40);
			local data = GuildAdsDB.profile.TalentRank:get(GuildAdsInspectWindow.playerName, "2")
			if data then
				self:Enable();
			else
				self:Disable();
			end
		else
			self:Hide();
		end
	end;
	
	GetTalentGlyphString = function()
		if GuildAdsInspectWindow.playerName then
			local data = GuildAdsDB.profile.TalentRank:get(GuildAdsInspectWindow.playerName, "A"); -- get active talent group
			if data and data.b then
				--local talent = GuildAdsDB.profile.TalentRank:get(GuildAdsInspectWindow.playerName, tostring(data.b)); -- get active talent link
				local talent = GuildAdsDB.profile.TalentRank:get(GuildAdsInspectWindow.playerName, GuildAdsTalentUI.shownSpec); -- get active talent link
				if talent then
					return talent.t, talent.g, talent.b
				end
			end
		end
		return nil, nil, nil
	end;
	
	GetNumTalentTabs = function()
		local talentString = GuildAdsTalentUI.GetTalentGlyphString()
		if talentString then
			return GuildAdsTalentUI.GetCurrentRankHelper("#", string.split(":", talentString))
		end
		return 3 -- default
	end;
	
	GetTalentTabInfo = function(tabIndex)
		if GuildAdsInspectWindow.playerName then
			local GAClass = GuildAdsDB.profile.Main:get(GuildAdsInspectWindow.playerName, GuildAdsDB.profile.Main.Class);
			if GAClass then
				local wowClassId = GuildAdsMainDataType:getWoWClassIdFromClassId(GAClass)
				local virtual = ":"..wowClassId
				local data = GuildAdsDB.profile.Talent:get(virtual, tostring(tabIndex)..":0");
				if not data then
					data = GuildAdsDB.profile.Talent:get(GuildAdsInspectWindow.playerName, tostring(tabIndex)..":0");
				end
				local pointsSpent=0; -- to be calculated
				if data then
					if data and data.n then
						local talentString = GuildAdsTalentUI.GetTalentGlyphString()
						for talentIndex=1, data.nt do
							local cr
							if talentString then
								cr = talentString and GuildAdsTalentUI.GetCurrentRank(talentString, tabIndex, talentIndex);
							else
								local d=GuildAdsDB.profile.Talent:get(GuildAdsInspectWindow.playerName, tostring(tabIndex)..":"..tostring(talentIndex));
								cr = d and d.cr;
							end
							pointsSpent=pointsSpent+(cr or 0);
						end
					end
					return data.n or "", data.t or "", pointsSpent, data.b or "";
				end
			end
		end
		return "","",0,"";
	end;
		
	GetNumTalents = function(tabIndex) -- already good
		if GuildAdsInspectWindow.playerName then
			local GAClass = GuildAdsDB.profile.Main:get(GuildAdsInspectWindow.playerName, GuildAdsDB.profile.Main.Class);
			local wowClassId = GuildAdsMainDataType:getWoWClassIdFromClassId(GAClass)
			local virtual = ":"..wowClassId
			local data = GuildAdsDB.profile.Talent:get(virtual, tostring(tabIndex)..":0");
			if not data then
				data = GuildAdsDB.profile.Talent:get(GuildAdsInspectWindow.playerName, tostring(tabIndex)..":0");
			end
			if data and data.nt then
				return data.nt;
			end
		end
		return 0;
	end;
	
	GetTalentInfo = function(tabIndex, talentIndex)
		if GuildAdsInspectWindow.playerName then
			-- get class data
			local GAClass = GuildAdsDB.profile.Main:get(GuildAdsInspectWindow.playerName, GuildAdsDB.profile.Main.Class);
			local wowClassId = GuildAdsMainDataType:getWoWClassIdFromClassId(GAClass)
			local virtual = ":"..wowClassId
			local data = GuildAdsDB.profile.Talent:get(virtual, tostring(tabIndex)..":"..tostring(talentIndex));
			if not data then
				-- show old data instead of showing nothing
				data = GuildAdsDB.profile.Talent:get(GuildAdsInspectWindow.playerName, tostring(tabIndex)..":"..tostring(talentIndex));
			end
			if data and data.n then
				if not data.t then
					local name, rank, texture = GetSpellInfo(data.n);
					name="|cff71d5ff|Hspell:"..tostring(data.n).."|h["..tostring(name).."]|h|r"
					return name, texture, data.ti, data.co, data.cr, data.mr, 0, data.p;
				else
					local talentString = GuildAdsTalentUI.GetTalentGlyphString()
					local currentrank = talentString and GuildAdsTalentUI.GetCurrentRank(talentString, tabIndex, talentIndex) or data.cr;
					-- modify talent:x:y link in data.n here. Values 0-5 come from currentrank, -1 from ?
					local link = data.n
					link = talentString and GuildAdsTalentUI.LinkSetRank(link, currentrank) or link; -- this only sets 0 to 5. The -1 is tricky!
					return data.n, data.t, data.ti, data.co, currentrank, data.mr, 0, data.p;
				end
			end
		end
		return "", "", 0,0, 0,0,0,0;		
	end;
	-- talent color: ff4e96f7
	
	GetIsLearnable = function(tabIndex, tier, column)
		local GAClass = GuildAdsDB.profile.Main:get(GuildAdsInspectWindow.playerName, GuildAdsDB.profile.Main.Class);
		local wowClassId = GuildAdsMainDataType:getWoWClassIdFromClassId(GAClass)
		local virtual = ":"..wowClassId
		local data = GuildAdsDB.profile.Talent:get(virtual, tostring(tabIndex)..":0");
		if not data then
			data = GuildAdsDB.profile.Talent:get(GuildAdsInspectWindow.playerName, tostring(tabIndex)..":0");
		end
		if data and data.n then
			for talentIndex = 1, data.nt do
				local d = GuildAdsDB.profile.Talent:get(virtual, tostring(tabIndex)..":"..tostring(talentIndex));
				if not d then
					d = GuildAdsDB.profile.Talent:get(GuildAdsInspectWindow.playerName, tostring(tabIndex)..":"..tostring(talentIndex));
				end
				if d and d.ti == tier and d.co == column then
					local talentString = GuildAdsTalentUI.GetTalentGlyphString()
					local currentrank = talentString and GuildAdsTalentUI.GetCurrentRank(talentString, tabIndex, talentIndex) or d.cr;			
					if currentrank == d.mr then
						return "1"
					else
						return
					end
				end
			end
		end
	end;
	
	GetTalentPrereqs = function(tabIndex, talentIndex)
		if GuildAdsInspectWindow.playerName then
			local GAClass = GuildAdsDB.profile.Main:get(GuildAdsInspectWindow.playerName, GuildAdsDB.profile.Main.Class);
			local wowClassId = GuildAdsMainDataType:getWoWClassIdFromClassId(GAClass)
			local virtual = ":"..wowClassId
			local data = GuildAdsDB.profile.Talent:get(virtual, tostring(tabIndex)..":"..tostring(talentIndex));
			if not data then
				data = GuildAdsDB.profile.Talent:get(GuildAdsInspectWindow.playerName, tostring(tabIndex)..":"..tostring(talentIndex));
			end
			if data and data.pt then
				--return data.pt, data.pc, data.pl;
				return data.pt, data.pc, GuildAdsTalentUI.GetIsLearnable(tabIndex, data.ti, data.co);
			end
		end
	end;
	
	Update = function()
		local self=GuildAdsTalentUI;
		local selectedTab = PanelTemplates_GetSelectedTab(GuildAdsTalentFrame);
		self.UpdateTabNames();
		if selectedTab==4 then
			GuildAdsTalentFrameScrollFrame:Hide();
			GuildAdsGlyphFrame:Show();
			GuildAdsTalentFrameActivateButton:Disable();
			self.UpdateGlyphs();
		else
			GuildAdsTalentFrameScrollFrame:Show();
			GuildAdsGlyphFrame:Hide();
			GuildAdsTalentFrameActivateButton:Enable();
			self.UpdateTalents();
		end
	end;
	
	UpdateTabNames = function()
		local self=GuildAdsTalentUI;
		local i, tab, name, iconTexture, pointsSpent;
		local totalTabWidth = 0
		local numTabs = self.GetNumTalentTabs();
		for i=1, MAX_TALENT_TABS do
			tab = getglobal("GuildAdsTalentFrameTab"..i);
			if ( i <= numTabs ) then
				name, iconTexture, pointsSpent = self.GetTalentTabInfo(i);
				tab:SetText(name);
				PanelTemplates_TabResize(tab, 0);
				talentTabWidthCache[i] = PanelTemplates_GetTabWidth(tab);
				totalTabWidth = totalTabWidth + talentTabWidthCache[i];
				tab:Show();
			else
				tab:Hide();
			end
		end
		-- glyph tab width
		talentTabWidthCache[4] = PanelTemplates_GetTabWidth(GuildAdsTalentFrameTab4);
		totalTabWidth = totalTabWidth + talentTabWidthCache[4];

		-- readjust tab sizes to fit
		local maxTotalTabWidth = GuildAdsTalentFrame:GetWidth();
		while ( totalTabWidth >= maxTotalTabWidth ) do
			-- progressively shave 10 pixels off of the largest tab until they all fit within the max width
			local largestTab = 1;
			for i = 2, #talentTabWidthCache do
				if ( talentTabWidthCache[largestTab] < talentTabWidthCache[i] ) then
					largestTab = i;
				end
			end
			-- shave the width
			talentTabWidthCache[largestTab] = talentTabWidthCache[largestTab] - 10;
			-- apply the shaved width
			tab = _G["GuildAdsTalentFrameTab"..largestTab];
			PanelTemplates_TabResize(tab, 0, talentTabWidthCache[largestTab]);
			-- now update the total width
			totalTabWidth = totalTabWidth - 10;
		end
		-- tabs with new shorter text are sometimes still displayed with the previous width (which is too large)
		for i = 1, #talentTabWidthCache do
			tab = _G["GuildAdsTalentFrameTab"..i];
			PanelTemplates_TabResize(tab, 0);
		end
		PanelTemplates_UpdateTabs(GuildAdsTalentFrame);
	end;
	
	UpdateGlyphs = function()
		for i = 1, NUM_GLYPH_SLOTS do
			GuildAdsTalentUI.Glyph_UpdateSlot(_G["GuildAdsGlyphFrameGlyph"..i]);
		end
	end;

	Glyph_OnLoad = function(self)
		local name = self:GetName();
		self:RegisterForClicks("LeftButtonUp", "RightButtonUp");
		self.glyph = _G[name .. "Glyph"];
		self.setting = _G[name .. "Setting"];
		self.highlight = _G[name .. "Highlight"];
		self.background = _G[name .. "Background"];
		self.ring = _G[name .. "Ring"];
		self.shine = _G[name .. "Shine"];
		self.elapsed = 0;
		self.tintElapsed = 0;
		self.glyphType = nil;
	end;

	Glyph_UpdateSlot = function(self)
		local id = self:GetID();
		--local talentGroup = PlayerTalentFrame and PlayerTalentFrame.talentGroup;
		--local enabled, glyphType, glyphSpell, iconFilename = GetGlyphSocketInfo(id, talentGroup);
		local glyph, glyphSpellLink, enabled, glyphType, glyphSpell, iconFilename;
		local talent, glyphs, build = GuildAdsTalentUI.GetTalentGlyphString()

		-- extract the glyph information of interest (which glyph...)
		glyph = (function(...) return select(id,...) end)(string.split(":", glyphs))

		-- extract glyph information (glyph id, major/minor type, texture path)
		glyph, glyphType, iconFilename = string.split(",", glyph)
		glyphType = tonumber(glyphType)
		iconFilename = iconFilename and string.gsub(iconFilename, "\@", "Interface\\Spellbook\\");

		if glyph and glyph~="-" and glyph~="" then
			local spellname = GetSpellInfo(glyph)
			enabled = true;
			glyphSpell = glyph
			glyphSpellLink = "\124cff71d5ff\124Hspell:"..glyph.."\124h["..spellname.."]\124h\124r";
		elseif glyph=="-" then
			-- glyph slot not enabled yet
			enabled, glyphType, glyphSpell, iconFilename = nil, nil, nil, nil;
		elseif glyph=="" then
			-- glyph slot available, but nothing in it
			enabled, glyphSpell, iconFilename = true, nil, nil;
		end
		
		local isMinor = glyphType == 2;
		if ( isMinor ) then
			GuildAdsTalentUI.Glyph_SetGlyphType(self, GLYPHTYPE_MINOR);
		else
			GuildAdsTalentUI.Glyph_SetGlyphType(self, GLYPHTYPE_MAJOR);
		end
	
		if ( not enabled ) then
			self.shine:Hide();
			self.background:Hide();
			self.glyph:Hide();
			self.ring:Hide();
			self.setting:SetTexture("Interface\\Spellbook\\UI-GlyphFrame-Locked");
			self.setting:SetTexCoord(.1, .9, .1, .9);
		elseif ( not glyphSpell ) then
			self.spell = nil;
			self.spellLink = nil;
			self.shine:Show();
			self.background:Show();
			self.background:SetTexCoord(GLYPH_SLOTS[0].left, GLYPH_SLOTS[0].right, GLYPH_SLOTS[0].top, GLYPH_SLOTS[0].bottom);
			self.glyph:Hide();
			self.ring:Show();
		else
			self.spell = glyphSpell;
			self.spellLink = glyphSpellLink;
			self.shine:Show();
			self.background:Show();
			self.background:SetAlpha(1);
			self.background:SetTexCoord(GLYPH_SLOTS[id].left, GLYPH_SLOTS[id].right, GLYPH_SLOTS[id].top, GLYPH_SLOTS[id].bottom);
			self.glyph:Show();
			if ( iconFilename ) then
				self.glyph:SetTexture(iconFilename);
			else
				self.glyph:SetTexture("Interface\\Spellbook\\UI-Glyph-Rune1");
			end
			self.ring:Show();
		end
	end;
	
	Glyph_OnEnter = function(self)
		if ( self.background:IsShown() ) then
			self.highlight:Show();
		end
		if self.spellLink then
			GameTooltip:SetOwner(this, "ANCHOR_RIGHT");
			GameTooltip:SetHyperlink(self.spellLink);
			GameTooltip:Show();
		end
	end;

	Glyph_OnLeave = function(self)
		self.highlight:Hide();
		GameTooltip:Hide();
	end;

	Glyph_OnClick = function(self)
		local id = self:GetID();
		if ( IsModifiedClick("CHATLINK") ) then
			local link = self.spellLink;
			if ( link ) then
				ChatEdit_InsertLink(link);
			end
		end
	end;
	
	UpdateTalents = function()
		local self=GuildAdsTalentUI;
		
		self.onFirstShow();
		GuildAdsTalentUI.GuildAdsTalentFrameActivateButton_onShow(GuildAdsTalentFrameActivateButton);
		-- Initialize talent tables if necessary
		local numTalents = self.GetNumTalents(PanelTemplates_GetSelectedTab(GuildAdsTalentFrame));
		-- Setup Tabs
		local i, tab, name, iconTexture, pointsSpent, button;
		--local numTabs = self.GetNumTalentTabs();
		for i=1, MAX_TALENT_TABS do
			tab = getglobal("GuildAdsTalentFrameTab"..i);
			--if ( i <= numTabs ) then
				--name, iconTexture, pointsSpent = self.GetTalentTabInfo(i);
				if ( i == PanelTemplates_GetSelectedTab(GuildAdsTalentFrame) ) then
					-- If tab is the selected tab set the points spent info
					name, iconTexture, pointsSpent = self.GetTalentTabInfo(i);
					GuildAdsTalentFrameSpentPoints:SetFormattedText(MASTERY_POINTS_SPENT, name, HIGHLIGHT_FONT_COLOR_CODE..pointsSpent..FONT_COLOR_CODE_CLOSE)
					GuildAdsTalentFrame.pointsSpent = pointsSpent;
				end
				--tab:SetText(name);
				--PanelTemplates_TabResize(tab, 10);
				--tab:Show();
			--else
				--tab:Hide();
			--end
		end
		--PanelTemplates_SetNumTabs(GuildAdsTalentFrame, numTabs);
		--PanelTemplates_UpdateTabs(GuildAdsTalentFrame);

		-- Setup Frame
		--SetPortraitTexture(GuildAdsTalentFramePortrait, "none");  --"player"
		GuildAdsTalentFramePortrait:SetTexture("Interface\\FriendsFrame\\FriendsFrameScrollIcon");
		self.UpdateTalentPoints();
		local talentTabName = self.GetTalentTabInfo(PanelTemplates_GetSelectedTab(GuildAdsTalentFrame));
		local base;
		local name, texture, points, fileName = self.GetTalentTabInfo(PanelTemplates_GetSelectedTab(GuildAdsTalentFrame));
		if ( talentTabName ) then
			base = "Interface\\TalentFrame\\"..fileName.."-";
		else
			-- temporary default for classes without talents poor guys
			base = "Interface\\TalentFrame\\MageFire-";
		end
		
		GuildAdsTalentFrameBackgroundTopLeft:SetTexture(base.."TopLeft");
		GuildAdsTalentFrameBackgroundTopRight:SetTexture(base.."TopRight");
		GuildAdsTalentFrameBackgroundBottomLeft:SetTexture(base.."BottomLeft");
		GuildAdsTalentFrameBackgroundBottomRight:SetTexture(base.."BottomRight");
		
		
		-- Just a reminder error if there are more talents than available buttons
		if ( numTalents > MAX_NUM_TALENTS ) then
			message("GuildAds: Too many talents in talent frame!");
		end

		self.ResetBranches();
		local tier, column, rank, maxRank, isExceptional, isLearnable;
		local forceDesaturated, tierUnlocked;
		for i=1, MAX_NUM_TALENTS do
			button = getglobal("GuildAdsTalentFrameTalent"..i);
			if ( i <= numTalents ) then
				-- Set the button info
				name, iconTexture, tier, column, rank, maxRank, isExceptional, meetsPrereq = self.GetTalentInfo(PanelTemplates_GetSelectedTab(GuildAdsTalentFrame), i);
				button.link = name
				getglobal("GuildAdsTalentFrameTalent"..i.."Rank"):SetText(rank);
				self.SetTalentButtonLocation(button, tier, column);
				self.TALENT_BRANCH_ARRAY[tier][column].id = button:GetID();
				
				-- If player has no talent points then show only talents with points in them
				if ( (GuildAdsTalentFrame.talentPoints <= 0 and rank == 0)  ) then
					forceDesaturated = 1;
				else
					forceDesaturated = nil;
				end

				-- If the player has spent at least 5 talent points in the previous tier
				if ( ( (tier - 1) * 5 <= GuildAdsTalentFrame.pointsSpent ) ) then
					tierUnlocked = 1;
				else
					tierUnlocked = nil;
				end
				SetItemButtonTexture(button, iconTexture);
				
				-- Talent must meet prereqs or the player must have no points to spend
				if ( self.SetPrereqs(tier, column, forceDesaturated, tierUnlocked, self.GetTalentPrereqs(PanelTemplates_GetSelectedTab(GuildAdsTalentFrame), i)) and meetsPrereq ) then
					SetItemButtonDesaturated(button, nil);
					
					if ( rank < maxRank ) then
						-- Rank is green if not maxed out
						getglobal("GuildAdsTalentFrameTalent"..i.."Slot"):SetVertexColor(0.1, 1.0, 0.1);
						getglobal("GuildAdsTalentFrameTalent"..i.."Rank"):SetTextColor(GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b);
					else
						getglobal("GuildAdsTalentFrameTalent"..i.."Slot"):SetVertexColor(1.0, 0.82, 0);
						getglobal("GuildAdsTalentFrameTalent"..i.."Rank"):SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
					end
					getglobal("GuildAdsTalentFrameTalent"..i.."RankBorder"):Show();
					getglobal("GuildAdsTalentFrameTalent"..i.."Rank"):Show();
				else
					SetItemButtonDesaturated(button, 1, 0.65, 0.65, 0.65);
					button.link = GuildAdsTalentUI.LinkSetRank(button.link, "-1");
					getglobal("GuildAdsTalentFrameTalent"..i.."Slot"):SetVertexColor(0.5, 0.5, 0.5);
					if ( rank == 0 ) then
						getglobal("GuildAdsTalentFrameTalent"..i.."RankBorder"):Hide();
						getglobal("GuildAdsTalentFrameTalent"..i.."Rank"):Hide();
					else
						getglobal("GuildAdsTalentFrameTalent"..i.."RankBorder"):SetVertexColor(0.5, 0.5, 0.5);
						getglobal("GuildAdsTalentFrameTalent"..i.."Rank"):SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
					end
				end
				
				button:Show();
			else	
				button:Hide();
			end
		end
		
		-- Draw the prerq branches
		local node;
		local textureIndex = 1;
		local xOffset, yOffset;
		local texCoords;
		-- Variable that decides whether or not to ignore drawing pieces
		local ignoreUp;
		local tempNode;
		self.ResetBranchTextureCount();
		self.ResetArrowTextureCount();
		for i=1, MAX_NUM_TALENT_TIERS do
			for j=1, NUM_TALENT_COLUMNS do
				node = self.TALENT_BRANCH_ARRAY[i][j];
				
				-- Setup offsets
				xOffset = ((j - 1) * 63) + INITIAL_TALENT_OFFSET_X + 2;
				yOffset = -((i - 1) * 63) - INITIAL_TALENT_OFFSET_Y - 2;
			
				if ( node.id ) then
					-- Has talent
					if ( node.up ~= 0 ) then
						if ( not ignoreUp ) then
							self.SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["up"][node.up], xOffset, yOffset + TALENT_BUTTON_SIZE);
						else
							ignoreUp = nil;
						end
					end
					if ( node.down ~= 0 ) then
						self.SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["down"][node.down], xOffset, yOffset - TALENT_BUTTON_SIZE + 1);
					end
					if ( node.left ~= 0 ) then
						self.SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["left"][node.left], xOffset - TALENT_BUTTON_SIZE, yOffset);
					end
					if ( node.right ~= 0 ) then
						-- See if any connecting branches are gray and if so color them gray
						tempNode = self.TALENT_BRANCH_ARRAY[i][j+1];	
						if ( tempNode.left ~= 0 and tempNode.down < 0 ) then
							self.SetBranchTexture(i, j-1, TALENT_BRANCH_TEXTURECOORDS["right"][tempNode.down], xOffset + TALENT_BUTTON_SIZE, yOffset);
						else
							self.SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["right"][node.right], xOffset + TALENT_BUTTON_SIZE + 1, yOffset);
						end
						
					end
					-- Draw arrows
					if ( node.rightArrow ~= 0 ) then
						self.SetArrowTexture(i, j, TALENT_ARROW_TEXTURECOORDS["right"][node.rightArrow], xOffset + TALENT_BUTTON_SIZE/2 + 5, yOffset);
					end
					if ( node.leftArrow ~= 0 ) then
						self.SetArrowTexture(i, j, TALENT_ARROW_TEXTURECOORDS["left"][node.leftArrow], xOffset - TALENT_BUTTON_SIZE/2 - 5, yOffset);
					end
					if ( node.topArrow ~= 0 ) then
						self.SetArrowTexture(i, j, TALENT_ARROW_TEXTURECOORDS["top"][node.topArrow], xOffset, yOffset + TALENT_BUTTON_SIZE/2 + 5);
					end
				else
					-- Doesn't have a talent
					if ( node.up ~= 0 and node.left ~= 0 and node.right ~= 0 ) then
						self.SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["tup"][node.up], xOffset , yOffset);
					elseif ( node.down ~= 0 and node.left ~= 0 and node.right ~= 0 ) then
						self.SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["tdown"][node.down], xOffset , yOffset);
					elseif ( node.left ~= 0 and node.down ~= 0 ) then
						self.SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["topright"][node.left], xOffset , yOffset);
						self.SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["down"][node.down], xOffset , yOffset - 32);
					elseif ( node.left ~= 0 and node.up ~= 0 ) then
						self.SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["bottomright"][node.left], xOffset , yOffset);
					elseif ( node.left ~= 0 and node.right ~= 0 ) then
						self.SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["right"][node.right], xOffset + TALENT_BUTTON_SIZE, yOffset);
						self.SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["left"][node.left], xOffset + 1, yOffset);
					elseif ( node.right ~= 0 and node.down ~= 0 ) then
						self.SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["topleft"][node.right], xOffset , yOffset);
						self.SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["down"][node.down], xOffset , yOffset - 32);
					elseif ( node.right ~= 0 and node.up ~= 0 ) then
						self.SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["bottomleft"][node.right], xOffset , yOffset);
					elseif ( node.up ~= 0 and node.down ~= 0 ) then
						self.SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["up"][node.up], xOffset , yOffset);
						self.SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["down"][node.down], xOffset , yOffset - 32);
						ignoreUp = 1;
					end
				end
			end
			GuildAdsTalentFrameScrollFrame:UpdateScrollChildRect();
		end
		-- Hide any unused branch textures
		for i=self.GetBranchTextureCount(), MAX_NUM_BRANCH_TEXTURES do
			getglobal("GuildAdsTalentFrameBranch"..i):Hide();
		end
		-- Hide and unused arrowl textures
		for i=self.GetArrowTextureCount(), MAX_NUM_ARROW_TEXTURES do
			getglobal("GuildAdsTalentFrameArrow"..i):Hide();
		end
	end;

	SetArrowTexture = function(tier, column, texCoords, xOffset, yOffset)
		local self=GuildAdsTalentUI;
		local arrowTexture = self.GetArrowTexture();
		arrowTexture:SetTexCoord(texCoords[1], texCoords[2], texCoords[3], texCoords[4]);
		arrowTexture:SetPoint("TOPLEFT", "GuildAdsTalentFrameArrowFrame", "TOPLEFT", xOffset, yOffset);
	end;

	SetBranchTexture = function(tier, column, texCoords, xOffset, yOffset)
		local self=GuildAdsTalentUI;
		local branchTexture = self.GetBranchTexture();
		branchTexture:SetTexCoord(texCoords[1], texCoords[2], texCoords[3], texCoords[4]);
		branchTexture:SetPoint("TOPLEFT", "GuildAdsTalentFrameScrollChildFrame", "TOPLEFT", xOffset, yOffset);
	end;

	GetArrowTexture = function()
		local arrowTexture = getglobal("GuildAdsTalentFrameArrow"..GuildAdsTalentFrame.arrowIndex);
		GuildAdsTalentFrame.arrowIndex = GuildAdsTalentFrame.arrowIndex + 1;
		if ( not arrowTexture ) then
			message("GuildAds: Not enough arrow textures");
		else
			arrowTexture:Show();
			return arrowTexture;
		end
	end;
	
	GetBranchTexture = function()
		local branchTexture = getglobal("GuildAdsTalentFrameBranch"..GuildAdsTalentFrame.textureIndex);
		GuildAdsTalentFrame.textureIndex = GuildAdsTalentFrame.textureIndex + 1;
		if ( not branchTexture ) then
			--branchTexture = CreateTexture("TalentFrameBranch"..TalentFrame.textureIndex);
			message("GuildAds: Not enough branch textures");
		else
			branchTexture:Show();
			return branchTexture;
		end
	end;
	
	ResetArrowTextureCount= function()
		GuildAdsTalentFrame.arrowIndex = 1;
	end;
	
	ResetBranchTextureCount = function()
		GuildAdsTalentFrame.textureIndex = 1;
	end;
	
	GetArrowTextureCount = function()
		return GuildAdsTalentFrame.arrowIndex;
	end;

	GetBranchTextureCount = function()
		return GuildAdsTalentFrame.textureIndex;
	end;
	
	SetPrereqs = function(buttonTier, buttonColumn, forceDesaturated, tierUnlocked, ...)
		local self=GuildAdsTalentUI;
		local tier, column, isLearnable;
		local requirementsMet;
		if ( tierUnlocked and not forceDesaturated ) then
			requirementsMet = 1;
		else
			requirementsMet = nil;
		end
		for i=1, select("#", ...), 3 do
			tier, column, isLearnable = select(i, ...);
			if ( not isLearnable or forceDesaturated ) then
				requirementsMet = nil;
			end
			self.DrawLines(buttonTier, buttonColumn, tier, column, requirementsMet);
		end
		return requirementsMet;
	end;

	DrawLines = function(buttonTier, buttonColumn, tier, column, requirementsMet)
		local self=GuildAdsTalentUI;
		if ( requirementsMet ) then
			requirementsMet = 1;
		else
			requirementsMet = -1;
		end
		
		-- Check to see if are in the same column
		if ( buttonColumn == column ) then
			-- Check for blocking talents
			if ( (buttonTier - tier) > 1 ) then
				-- If more than one tier difference
				for i=tier + 1, buttonTier - 1 do
					if ( self.TALENT_BRANCH_ARRAY[i][buttonColumn].id ) then
						-- If there's an id, there's a blocker
						message("GuildAds: Error this layout is blocked vertically "..self.TALENT_BRANCH_ARRAY[buttonTier][i].id);
						return;
					end
				end
			end
			
			-- Draw the lines
			for i=tier, buttonTier - 1 do
				self.TALENT_BRANCH_ARRAY[i][buttonColumn].down = requirementsMet;
				if ( (i + 1) <= (buttonTier - 1) ) then
					self.TALENT_BRANCH_ARRAY[i + 1][buttonColumn].up = requirementsMet;
				end
			end
			
			-- Set the arrow
			self.TALENT_BRANCH_ARRAY[buttonTier][buttonColumn].topArrow = requirementsMet;
			return;
		end
		-- Check to see if they're in the same tier
		if ( buttonTier == tier ) then
			local left = min(buttonColumn, column);
			local right = max(buttonColumn, column);
			
			-- See if the distance is greater than one space
			if ( (right - left) > 1 ) then
				-- Check for blocking talents
				for i=left + 1, right - 1 do
					if ( self.TALENT_BRANCH_ARRAY[tier][i].id ) then
						-- If there's an id, there's a blocker
						message("GuildAds: there's a blocker");
						return;
					end
				end
			end
			-- If we get here then we're in the clear
			for i=left, right - 1 do
				self.TALENT_BRANCH_ARRAY[tier][i].right = requirementsMet;
				self.TALENT_BRANCH_ARRAY[tier][i+1].left = requirementsMet;
			end
			-- Determine where the arrow goes
			if ( buttonColumn < column ) then
				self.TALENT_BRANCH_ARRAY[buttonTier][buttonColumn].rightArrow = requirementsMet;
			else
				self.TALENT_BRANCH_ARRAY[buttonTier][buttonColumn].leftArrow = requirementsMet;
			end
			return;
		end
		-- Now we know the prereq is diagonal from us
		local left = min(buttonColumn, column);
		local right = max(buttonColumn, column);
		-- Don't check the location of the current button
		if ( left == column ) then
			left = left + 1;
		else
			right = right - 1;
		end
		-- Check for blocking talents
		local blocked = nil;
		for i=left, right do
			if ( self.TALENT_BRANCH_ARRAY[tier][i].id ) then
				-- If there's an id, there's a blocker
				blocked = 1;
			end
		end
		left = min(buttonColumn, column);
		right = max(buttonColumn, column);
		if ( not blocked ) then
			self.TALENT_BRANCH_ARRAY[tier][buttonColumn].down = requirementsMet;
			self.TALENT_BRANCH_ARRAY[buttonTier][buttonColumn].up = requirementsMet;
			
			for i=tier, buttonTier - 1 do
				self.TALENT_BRANCH_ARRAY[i][buttonColumn].down = requirementsMet;
				self.TALENT_BRANCH_ARRAY[i + 1][buttonColumn].up = requirementsMet;
			end

			for i=left, right - 1 do
				self.TALENT_BRANCH_ARRAY[tier][i].right = requirementsMet;
				self.TALENT_BRANCH_ARRAY[tier][i+1].left = requirementsMet;
			end
			-- Place the arrow
			self.TALENT_BRANCH_ARRAY[buttonTier][buttonColumn].topArrow = requirementsMet;
			return;
		end
		-- If we're here then we were blocked trying to go vertically first so we have to go over first, then up
		if ( left == buttonColumn ) then
			left = left + 1;
		else
			right = right - 1;
		end
		-- Check for blocking talents
		for i=left, right do
			if ( self.TALENT_BRANCH_ARRAY[buttonTier][i].id ) then
				-- If there's an id, then throw an error
				message("GuildAds: Error, this layout is undrawable "..self.TALENT_BRANCH_ARRAY[buttonTier][i].id);
				return;
			end
		end
		-- If we're here we can draw the line
		left = min(buttonColumn, column);
		right = max(buttonColumn, column);
		--TALENT_BRANCH_ARRAY[tier][column].down = requirementsMet;
		--TALENT_BRANCH_ARRAY[buttonTier][column].up = requirementsMet;

		for i=tier, buttonTier-1 do
			self.TALENT_BRANCH_ARRAY[i][column].up = requirementsMet;
			self.TALENT_BRANCH_ARRAY[i+1][column].down = requirementsMet;
		end

		-- Determine where the arrow goes
		if ( buttonColumn < column ) then
			self.TALENT_BRANCH_ARRAY[buttonTier][buttonColumn].rightArrow =  requirementsMet;
		else
			self.TALENT_BRANCH_ARRAY[buttonTier][buttonColumn].leftArrow =  requirementsMet;
		end
	end;
	
	--Tab_OnClick 
	selectTab = function(self)
		--local self=GuildAdsTalentUI;
		PanelTemplates_SetTab(GuildAdsTalentFrame, self:GetID());
		GuildAdsTalentUI.Update();
		for i=1, MAX_TALENT_TABS do
			SetButtonPulse(getglobal("GuildAdsTalentFrameTab"..i), 0, 0);
		end
		PlaySound("igCharacterInfoTab");
	end;
	
	UpdateTalentPoints = function()
		local self=GuildAdsTalentUI;
		--local cp1, cp2 = UnitCharacterPoints("player");
		-- have to calculate it...
		local cp1 = 0; 
		for tabIndex = 1, self.GetNumTalentTabs()  do
			local _, _, pointsSpent = self.GetTalentTabInfo(tabIndex);
			cp1 = cp1 + pointsSpent;
		end
		cp1=(GuildAdsDB.profile.Main:get(GuildAdsInspectWindow.playerName, GuildAdsDB.profile.Main.Level) or 0)-9-cp1;
		if cp1<0 then
			cp1=0;
		end
		GuildAdsTalentFrameTalentPointsText:SetFormattedText(UNSPENT_TALENT_POINTS, HIGHLIGHT_FONT_COLOR_CODE..cp1..FONT_COLOR_CODE_CLOSE);
		--GuildAdsTalentFrameTalentPointsText:SetText(cp1);
		GuildAdsTalentFrame.talentPoints = cp1;
	end;

	SetTalentButtonLocation = function(button, tier, column)
		column = ((column - 1) * 63) + INITIAL_TALENT_OFFSET_X;
		tier = -((tier - 1) * 63) - INITIAL_TALENT_OFFSET_Y;
		button:SetPoint("TOPLEFT", button:GetParent(), "TOPLEFT", column, tier);
	end;

	ResetBranches = function()
		local self=GuildAdsTalentUI;
		for i=1, MAX_NUM_TALENT_TIERS do
			for j=1, NUM_TALENT_COLUMNS do
				self.TALENT_BRANCH_ARRAY[i][j].id = nil;
				self.TALENT_BRANCH_ARRAY[i][j].up = 0;
				self.TALENT_BRANCH_ARRAY[i][j].down = 0;
				self.TALENT_BRANCH_ARRAY[i][j].left = 0;
				self.TALENT_BRANCH_ARRAY[i][j].right = 0;
				self.TALENT_BRANCH_ARRAY[i][j].rightArrow = 0;
				self.TALENT_BRANCH_ARRAY[i][j].leftArrow = 0;
				self.TALENT_BRANCH_ARRAY[i][j].topArrow = 0;
			end
		end
	end;
	
	DownArrow_OnClick = function(self, button)
		local parent = self:GetParent();
		parent:SetValue(parent:GetValue() + (parent:GetHeight() / 2));
		PlaySound("UChatScrollButton");
		--UIFrameFlashStop(GuildAdsTalentScrollButtonOverlay);
	end;
	
	TalentButton_OnClick = function(self, button)
		if ( IsModifiedClick("CHATLINK") ) then
			local link = GuildAdsTalentUI.GetTalentInfo(PanelTemplates_GetSelectedTab(GuildAdsTalentFrame), self:GetID());
			link = self.link
			if ( link ) then
				ChatEdit_InsertLink(link);
			end
		end
	end;

	Glyph_SetGlyphType = function(glyph, glyphType)
		glyph.glyphType = glyphType;
		
		glyph.setting:SetTexture("Interface\\Spellbook\\UI-GlyphFrame");
		if ( glyphType == GLYPHTYPE_MAJOR ) then
			glyph.glyph:SetVertexColor(GLYPH_MAJOR.r, GLYPH_MAJOR.g, GLYPH_MAJOR.b);
			glyph.setting:SetWidth(108);
			glyph.setting:SetHeight(108);
			glyph.setting:SetTexCoord(0.740234375, 0.953125, 0.484375, 0.697265625);
			glyph.highlight:SetWidth(108);
			glyph.highlight:SetHeight(108);
			glyph.highlight:SetTexCoord(0.740234375, 0.953125, 0.484375, 0.697265625);
			glyph.ring:SetWidth(82);
			glyph.ring:SetHeight(82);
			glyph.ring:SetPoint("CENTER", glyph, "CENTER", 0, -1);
			glyph.ring:SetTexCoord(0.767578125, 0.92578125, 0.32421875, 0.482421875);
			glyph.shine:SetTexCoord(0.9609375, 1, 0.9609375, 1);
			glyph.background:SetWidth(70);
			glyph.background:SetHeight(70);
		else
			glyph.glyph:SetVertexColor(GLYPH_MINOR.r, GLYPH_MINOR.g, GLYPH_MINOR.b);
			glyph.setting:SetWidth(86);
			glyph.setting:SetHeight(86);
			glyph.setting:SetTexCoord(0.765625, 0.927734375, 0.15625, 0.31640625);
			glyph.highlight:SetWidth(86);
			glyph.highlight:SetHeight(86);
			glyph.highlight:SetTexCoord(0.765625, 0.927734375, 0.15625, 0.31640625);
			glyph.ring:SetWidth(62);
			glyph.ring:SetHeight(62);
			glyph.ring:SetPoint("CENTER", glyph, "CENTER", 0, 1);
			glyph.ring:SetTexCoord(0.787109375, 0.908203125, 0.033203125, 0.154296875);
			glyph.shine:SetTexCoord(0.9609375, 1, 0.921875, 0.9609375);
			glyph.background:SetWidth(64);
			glyph.background:SetHeight(64);
		end
	end;
}

---------------------------------------------------------------------------------
--
-- Register plugin
-- 
---------------------------------------------------------------------------------
GuildAdsPlugin.UIregister(GuildAdsTalentUI);
