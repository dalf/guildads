----------------------------------------------------------------------------------
--
-- GuildAdsTalentRankData.lua
--
-- Author: Galmok of European Stormrage (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : galmok@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

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

GuildAdsTalentRankDataType = GuildAdsTableDataType:new({
	metaInformations = {
		name = "TalentRank",
		version = 1,
		guildadsCompatible = 200,
		parent = GuildAdsDataType.PROFILE,
		priority = 600,
		depend = { "Main" }
	};
	schema = {
		id = "String", -- "1" = talent group 1, "2" = talent group 2, "A" = active talent group (number held in 'b')
		data = {
			[1] = { key="t", codec="String" },	-- talent data link			"XXXXXXXXXXXXXXX:YYYYYYYYYYYYYY:ZZZZZZZZZZZZZ"
			[2] = { key="g", codec="String" },	-- glyph data						"<glyph spell id 1>:<glyph spell id 2>:...:<glyph spell id x>"
			[3] = { key="b", codec="Integer" },	-- wow build on which this link is based (stored data in GuildAdsTalentDataType MUST match or talents probably wont be shown correctly)
		}
	}
});

local AceEvent = LibStub("AceEvent-3.0")
AceEvent:Embed(GuildAdsTalentRankDataType)


-- Lots of information needs to be transferred, some of it class relevant (visuals of talent frame) and some of it player relevant (talent points)
--	
--	unspentTalentPoints, learnedProfessions = 							UnitCharacterPoints("player")
--	numTabs = 											GetNumTalentTabs(); -- always 3
--		name, iconTexture, pointsSpent, background = 							GetTalentTabInfo( tabIndex );
--		numTalents = 											GetNumTalents(tabIndex);
--			nameTalent, iconPath, tier, column, currentRank, maxRank, isExceptional, meetsPrereq = 		GetTalentInfo(tabIndex, talentIndex);
--			tier, column, isLearnable = 									GetTalentPrereqs( tabIndex , talentIndex );


-- CLASS relevance:
--	numTabs, name, iconTexture, background,	numTalents, nameTalent, iconPath, tier, column, maxRank
-- PLAYER relevance:
--	pointsSpent, currentRank, meetsPrereq, tier, column, isLearnable, unspentTalentPoints
-- UNUSED:
--	isExceptional, learnedProfessions
-- NOTE:
-- 	pointsSpent can be calculated by summing currenRank inside each tab and therefore doesn't have to be shared.
--

-- Update: Dual talent support requires one more talent tree to be shared. Both trees have much in common:
-- Static/Common: name, nameTalent, iconTexture, iconPath, background, tier, column, maxRank, Prereq:tier, Prereq:column
-- Dynamic/per tree: numTalents(can be calculated from currentRank), currentRank, meetsPrereq(always 1), Prereq:isLearnable(can be discovered from currentRank and static data)
-- This leaves only currentRank to be shared(!!) :-)
-- 
-- Static part is to be shared is if no talent points are spent.
-- Dynamic part only shares what is different from Static part.

function GuildAdsTalentRankDataType:Initialize()
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "enterWorld");
end

function GuildAdsTalentRankDataType:enterWorld()
	self:UnregisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("CHARACTER_POINTS_CHANGED","onEvent");
	self:RegisterEvent("PLAYER_TALENT_UPDATE","onEvent");
	GuildAdsTask:AddNamedSchedule("GuildAdsTalentRankDataTypeInit", 4, nil, nil, self.onEvent, self)
end

function GuildAdsTalentRankDataType:onEvent()
	for talentGroup = 1, GetNumTalentGroups() do
		-- parse complete talent tree now
		local name, iconTexture, pointsSpent, background, numTalents, tabIndex;
		local talentIndex, nameTalent, talentLink, iconPath, tier, column, currentRank, maxRank, isExceptional, meetsPrereq, ptier, pcolumn, isLearnable;
		local talentLinkTable={};
		local sep = "";
		local _, WoWClassId = UnitClass("player")
		-- pack talent info
		local rest
		for tabIndex = 1, GetNumTalentTabs() do
			tinsert(talentLinkTable, sep)
			local q = false;
			for talentIndex = 1, GetNumTalents(tabIndex) do
				_,_,_,_,currentRank = GetTalentInfo(tabIndex, talentIndex, false, false, talentGroup);
				if q then
					tinsert(talentLinkTable, EncodeBase64Char(rest+currentRank*8))
				else
					rest = currentRank;
				end
				q=not q
			end
			if q then
				tinsert(talentLinkTable,EncodeBase64Char(rest))
			end
			sep = ":"
		end
		-- pack glyph info
		local glyphTable = {}
		local sep = "";
		local ng = GetNumGlyphSockets();
		for i = 1, ng do
			tinsert(glyphTable, sep)
			local enabled, glyphType, glyphSpellID, icon = GetGlyphSocketInfo(i, talentGroup);
			if ( enabled ) then
				--local link = GetGlyphLink(i);-- Retrieves the Glyph's link (nil of no glyph in Socket);
				if ( glyphSpellID ) then
					tinsert(glyphTable, glyphSpellID);
					--DEFAULT_CHAT_FRAME:AddMessage("Glyph Socket "..i.." contains "..link);
				else
					tinsert(glyphTable, "");
					--DEFAULT_CHAT_FRAME:AddMessage("Glyph Socket "..i.." is unlocked and empty!");
				end
			else
				tinsert(glyphTable, "-");
				--DEFAULT_CHAT_FRAME:AddMessage("Glyph Socket "..i.." is locked!");
			end
			sep = ":";
		end
		-- store it
		local data = {
			t = table.concat(talentLinkTable,""),
			g = table.concat(glyphTable,""),
			b = (select(2,GetBuildInfo()))
		}
		self:set(GuildAds.playerName, tostring(tabIndex)..":"..tostring(talentIndex), nil);
		self:set(GuildAds.playerName, tostring(talentGroup), data);
	end
	-- store active talent group
	self:set(GuildAds.playerName, "A", { b=GetActiveTalentGroup() });
end

function GuildAdsTalentRankDataType:getTableForPlayer(author)
	if not author then
		error("author is nil", 2);
	end
	return self.profile:getRaw(author).talentrank;
end

function GuildAdsTalentRankDataType:get(author, id)
	if not author then
		error("author is nil", 2);
	end
	return self.profile:getRaw(author).talentrank[id];
end

function GuildAdsTalentRankDataType:getRevision(author)
	return self.profile:getRaw(author).talentrank._u or 0;
end

function GuildAdsTalentRankDataType:setRevision(author, revision)
	self.profile:getRaw(author).talentrank._u = revision;
end

function GuildAdsTalentRankDataType:setRaw(author, id, info, revision)
	local talent = self.profile:getRaw(author).talentrank;
	talent[id] = info;
	if info then
		talent[id]._u = revision;
		return true;
	end
end

function GuildAdsTalentRankDataType:set(author, id, info)
	local keys={ "t", "g", "b" };
	local changed=false;
	local talent = self.profile:getRaw(author).talentrank;
	if info then
		if talent[id]==nil then
			changed=true;
		else
			for _,v in pairs(keys) do
				if info[v] ~= talent[id][v] then
					changed=true;
				end
			end
		end
		if changed then
			talent._u = 1 + (talent._u or 0);
			info._u = talent._u;
			talent[id] = info;
			self:triggerUpdate(author, id);
			return info;
		end
	else
		if talent[id] then
			talent[id] = nil;
			talent._u = 1 + (talent._u or 0);
			self:triggerUpdate(author, id);
		end
	end
end

GuildAdsTalentRankDataType:register();

