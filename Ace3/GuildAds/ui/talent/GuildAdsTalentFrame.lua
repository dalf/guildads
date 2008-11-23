----------------------------------------------------------------------------------
--
-- GuildAdsTalentData.lua
--
-- Author: Galmok of European Stormrage (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com, galmok@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

local firstShow = true

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
		PanelTemplates_SetNumTabs(GuildAdsTalentFrame, 3);
		PanelTemplates_SetTab(GuildAdsTalentFrame, 1);
	end;
	
	onFirstShow = function()
		if firstShow then
			firstShow = false
			local self=GuildAdsTalentUI;
			self.TALENT_BRANCH_ARRAY={};
			local loaded, reason = LoadAddOn("Blizzard_TalentUI"); -- need it because it defines many needed constants
		
			--this:RegisterEvent("CHARACTER_POINTS_CHANGED");
			--this:RegisterEvent("SPELLS_CHANGED");
			--this:RegisterEvent("UNIT_PORTRAIT_UPDATE");
			for i=1, MAX_NUM_TALENT_TIERS do
				self.TALENT_BRANCH_ARRAY[i] = {};
				for j=1, NUM_TALENT_COLUMNS do
					self.TALENT_BRANCH_ARRAY[i][j] = {id=nil, up=0, left=0, right=0, down=0, leftArrow=0, rightArrow=0, topArrow=0};
				end
			end
			GuildAdsTalentFrameScrollFrameScrollBarScrollDownButton:SetScript("OnClick", self.DownArrow_OnClick);
			--GuildAdsDB.profile.Talent:registerUpdate(GuildAdsTalentUI.onDBUpdate);
		end
	end;
	
	onShow = function()
		local self=GuildAdsTalentUI;
		
		self.onFirstShow();
	
		-- Stop buttons from flashing after skill up
		--SetButtonPulse(TalentMicroButton, 0, 1);

		PlaySound("TalentScreenOpen");
		--UpdateMicroButtons();

		self:Update();

		-- Set flag
		if ( self.TALENT_FRAME_WAS_SHOWN ~= 1 ) then
			self.TALENT_FRAME_WAS_SHOWN = 1;
			--UIFrameFlash(GuildAdsTalentScrollButtonOverlay, 0.5, 0.5, 60);
		end
	end;
	
	isTalentLink = function(link)
		-- "|cff71d5ff|Hspell:14785|h[Silent Resolve]|h|r"
		return nil
	end;
	
	talentButtonOnEnter = function(this, id)
		local self=GuildAdsTalentUI;
		local selectedTab = PanelTemplates_GetSelectedTab(GuildAdsTalentFrame);
		local talentName, iconPath, tier, column, currentRank, maxRank = self.GetTalentInfo(selectedTab, id);
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT");
		if GuildAds_ExplodeItemRef(talentName) then
			GameTooltip:SetHyperlink(talentName);
		else
			GameTooltip:SetText(HIGHLIGHT_FONT_COLOR_CODE..talentName..FONT_COLOR_CODE_CLOSE);
		end
		--[[
		GameTooltip:AddLine(HIGHLIGHT_FONT_COLOR_CODE.."Rank "..tostring(currentRank).."/"..tostring(maxRank)..FONT_COLOR_CODE_CLOSE);
		if GuildAdsTalentFrame.pointsSpent then
			local ptier,pcolumn = self.GetTalentPrereqs(selectedTab, id);
			if ptier then
				local pname, _, _, _, pcurrentRank, pmaxRank = self.GetTalentInfo(selectedTab, self.TALENT_BRANCH_ARRAY[ptier][pcolumn].id);
				if pcurrentRank == 0 then
					local points = " points ";
					if pmaxRank == 1 then
						points = " point ";
					end
					GameTooltip:AddLine(RED_FONT_COLOR_CODE.."Requires "..tostring(pmaxRank)..points.."in "..pname..FONT_COLOR_CODE_CLOSE);
				end
			end
			if GuildAdsTalentFrame.pointsSpent < (tier-1)*5 then
				local name = self.GetTalentTabInfo(PanelTemplates_GetSelectedTab(GuildAdsTalentFrame));
				GameTooltip:AddLine(RED_FONT_COLOR_CODE.."Requires "..tostring((tier-1)*5).." points in "..name.. " Talents"..FONT_COLOR_CODE_CLOSE);
			end
		end
		--]]
		GameTooltip:Show();
	end;
	
	OnHide = function()
		--UpdateMicroButtons();
		PlaySound("TalentScreenClose");
		--UIFrameFlashStop(GuildAdsTalentScrollButtonOverlay);
	end;
	
	onDBUpdate = function(dataType, playerName, talent)
		local self=GuildAdsTalentUI;
		-- only update if visible...
		self:Update();
	end;
	
	GetNumTalentTabs = function()
		return 3;
	end;
	
	GetTalentTabInfo = function(tabIndex)
		if GuildAdsInspectWindow.playerName then
			local data = GuildAdsDB.profile.Talent:get(GuildAdsInspectWindow.playerName, tostring(tabIndex)..":0");
			if data and data.n then
				local pointsSpent=0; -- to be calculated
				for talentIndex=1,data.nt do
					local d=GuildAdsDB.profile.Talent:get(GuildAdsInspectWindow.playerName, tostring(tabIndex)..":"..tostring(talentIndex));
					if d then
						pointsSpent=pointsSpent+(d.cr or 0);
					end
				end
				return data.n or "", data.t or "", pointsSpent, data.b or "";
			end
		end
		return "","",0,"";
	end;
		
	GetNumTalents = function(tabIndex)
		if GuildAdsInspectWindow.playerName then
			local data = GuildAdsDB.profile.Talent:get(GuildAdsInspectWindow.playerName, tostring(tabIndex)..":0");
			if data and data.nt then
				return data.nt;
			end
		end
		return 0;
	end;
	
	GetTalentInfo = function(tabIndex, talentIndex)
		if GuildAdsInspectWindow.playerName then
			local data = GuildAdsDB.profile.Talent:get(GuildAdsInspectWindow.playerName, tostring(tabIndex)..":"..tostring(talentIndex));
			if data and data.n then
				if not data.t then
					local name, rank, texture = GetSpellInfo(data.n);
					name="|cff71d5ff|Hspell:"..tostring(data.n).."|h["..tostring(name).."]|h|r"
					return name, texture, data.ti, data.co, data.cr, data.mr, 0, data.p;
				else
					return data.n, data.t, data.ti, data.co, data.cr, data.mr, 0, data.p;
				end
			end
		end
		return "", "", 0,0, 0,0,0,0;
	end;
	
	GetTalentPrereqs = function(tabIndex , talentIndex )
		if GuildAdsInspectWindow.playerName then
			local data = GuildAdsDB.profile.Talent:get(GuildAdsInspectWindow.playerName, tostring(tabIndex)..":"..tostring(talentIndex));
			if data and data.pt then
				return data.pt, data.pc, data.pl;
			end
		end
	end;
	
	Update = function()
		local self=GuildAdsTalentUI;
		
		self.onFirstShow();
		
		-- Initialize talent tables if necessary
		local numTalents = self.GetNumTalents(PanelTemplates_GetSelectedTab(GuildAdsTalentFrame));
		-- Setup Tabs
		local tab, name, iconTexture, pointsSpent, button;
		local numTabs = self.GetNumTalentTabs();
		for i=1, MAX_TALENT_TABS do
			tab = getglobal("GuildAdsTalentFrameTab"..i);
			if ( i <= numTabs ) then
				name, iconTexture, pointsSpent = self.GetTalentTabInfo(i);
				if ( i == PanelTemplates_GetSelectedTab(GuildAdsTalentFrame) ) then
					-- If tab is the selected tab set the points spent info
					GuildAdsTalentFrameSpentPoints:SetText(format(MASTERY_POINTS_SPENT, name).." "..HIGHLIGHT_FONT_COLOR_CODE..pointsSpent..FONT_COLOR_CODE_CLOSE);
					GuildAdsTalentFrame.pointsSpent = pointsSpent;
				end
				tab:SetText(name);
				PanelTemplates_TabResize(tab, 10);
				tab:Show();
			else
				tab:Hide();
			end
		end
		PanelTemplates_SetNumTabs(GuildAdsTalentFrame, numTabs);
		PanelTemplates_UpdateTabs(GuildAdsTalentFrame);

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
		GuildAdsTalentFrameTalentPointsText:SetText(cp1);
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
			if ( link ) then
				ChatEdit_InsertLink(link);
			end
		end
	end;

}

---------------------------------------------------------------------------------
--
-- Register plugin
-- 
---------------------------------------------------------------------------------
GuildAdsPlugin.UIregister(GuildAdsTalentUI);
