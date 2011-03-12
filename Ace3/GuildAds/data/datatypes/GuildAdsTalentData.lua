----------------------------------------------------------------------------------
--
-- GuildAdsTalentData.lua
--
-- Author: Galmok of European Stormrage (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com, galmok@gmail.com
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

GuildAdsTalentDataType = GuildAdsTableDataType:new({
	metaInformations = {
		name = "Talent",
		version = 1,
		guildadsCompatible = 200,
		parent = GuildAdsDataType.PROFILE,
		priority = 600,
		depend = { "Main" }
	};
	schema = {
		id = "String", -- (tab number):(talent number), e.g. 1:1, 3:15, 2:22.... 1:0, 2:0 and 3:0 are special; they hold tab specific data.
		data = {
			[1] = { key="n", codec="String" },		-- name | nameTalent
			[2] = { key="t", codec="Texture" },	-- iconTexture | iconPath
			[3] = { key="b", codec="Texture" },	-- background
			[4] = { key="nt", codec="Integer" },	-- numTalents
			[5] = { key="ti", codec="Integer" },	-- tier
			[6] = { key="co", codec="Integer" },	-- column
			[7] = { key="cr", codec="Integer" },	-- currentRank
			[8] = { key="mr", codec="Integer" },	-- maxRank
			[9] = { key="p", codec="Integer" },	-- meetsPrereq -- turns out to be _always_ 1 (no need to share)
			[10] = { key="pt", codec="Integer" },	-- Prereq:tier
			[11] = { key="pc", codec="Integer" },	-- Prereq:column
			[12] = { key="pl", codec="Integer" },	-- Prereq:isLearnable -- is 1 if talent at (Prereq:tier, Prereq:column) is maxed (not really necessary to share)
		}
	}
});

local AceEvent = LibStub("AceEvent-3.0")
AceEvent:Embed(GuildAdsTalentDataType)


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

function GuildAdsTalentDataType:Initialize()
	self:RegisterEvent("CHARACTER_POINTS_CHANGED","onEvent");
	GuildAdsTask:AddNamedSchedule("GuildAdsTalentDataTypeInit", 8, nil, nil, self.onEvent, self)
end

local LinkSetRank = function(link, rank)
		return link:gsub("(talent:[0-9]+:)(%-?[0-9]+)", "%1"..tostring(rank))
end;
	
function GuildAdsTalentDataType:onEvent()
	local _, WoWClassId = UnitClass("player")
	-- parse complete talent tree now
	--local name, iconTexture, pointsSpent, background, 
	local numTalents, tabIndex;
	local talentIndex, nameTalent, talentLink, iconPath, tier, column, currentRank, maxRank, isExceptional, meetsPrereq, ptier, pcolumn, isLearnable;
	for tabIndex=1,GetNumTalentTabs() do
		--name, iconTexture, pointsSpent, background = GetTalentTabInfo( tabIndex );
		local id, name, description, iconTexture, pointsSpent, background, previewPointsSpent, isUnlocked = GetTalentTabInfo( tabIndex );
		numTalents = GetNumTalents(tabIndex);
		self:set(":"..WoWClassId, tostring(tabIndex)..":0", { n=name, t=iconTexture, b=background, nt=numTalents} );
		self:set(GuildAds.playerName, tostring(tabIndex)..":0", nil); -- delete old data
		for talentIndex=1,numTalents do
			nameTalent, iconPath, tier, column, currentRank, maxRank, isExceptional, meetsPrereq = GetTalentInfo(tabIndex, talentIndex);
			ptier, pcolumn, isLearnable = GetTalentPrereqs( tabIndex , talentIndex );
			talentLink=GetTalentLink(tabIndex, talentIndex); -- talent:<talentid>:<currentrank or -1 if not available yet>
			if talentLink then
				nameTalent = LinkSetRank(talentLink, "0");
			end
			currentRank = 0;
			isLearnable = nil; 
			self:set(":"..WoWClassId, tostring(tabIndex)..":"..tostring(talentIndex), { n=nameTalent, 
																t=iconPath,
																ti=tier,
																co=column,
																cr=currentRank,
																mr=maxRank,
																p=1, --meetsPrereq, -- meetsPrereqs seems to be changing for each player and has hence to be ignored for now
																pt=ptier,
																pc=pcolumn,
																pl=isLearnable});
			self:set(GuildAds.playerName, tostring(tabIndex)..":"..tostring(talentIndex), nil);
		end
	end
end

function GuildAdsTalentDataType:getTableForPlayer(author)
	if not author then
		error("author is nil", 2);
	end
	return self.profile:getRaw(author).talent;
end

function GuildAdsTalentDataType:get(author, id)
	if not author then
		error("author is nil", 2);
	end
	return self.profile:getRaw(author).talent[id];
end

function GuildAdsTalentDataType:getRevision(author)
	return self.profile:getRaw(author).talent._u or 0;
end

function GuildAdsTalentDataType:setRevision(author, revision)
	self.profile:getRaw(author).talent._u = revision;
end

function GuildAdsTalentDataType:setRaw(author, id, info, revision)
	local talent = self.profile:getRaw(author).talent;
	talent[id] = info;
	if info then
		talent[id]._u = revision;
		return true;
	end
end

function GuildAdsTalentDataType:set(author, id, info)
	local keys={ "n", "t", "b", "nt", "ti", "co", "cr", "mr", "p", "pt", "pc", "pl" };
	local changed=false;
	local talent = self.profile:getRaw(author).talent;
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

GuildAdsTalentDataType:register();

