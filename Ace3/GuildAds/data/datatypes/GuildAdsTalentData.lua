----------------------------------------------------------------------------------
--
-- GuildAdsTalentData.lua
--
-- Author: Galmok of European Stormrage (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com, galmok@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

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
			[9] = { key="p", codec="Integer" },	-- meetsPrereq
			[10] = { key="pt", codec="Integer" },	-- Prereq:tier
			[11] = { key="pc", codec="Integer" },	-- Prereq:column
			[12] = { key="pl", codec="Integer" },	-- Prereq:isLearnable
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


function GuildAdsTalentDataType:Initialize()
	self:RegisterEvent("CHARACTER_POINTS_CHANGED","onEvent");
	--self:RegisterEvent("VARIABLES_LOADED","onEvent");
	--GuildAdsTalentDataType:onEvent();
	GuildAdsTask:AddNamedSchedule("GuildAdsTalentDataTypeInit", 8, nil, nil, self.onEvent, self)
end

function GuildAdsTalentDataType:onEvent()
	--if not GetTalentInfo(1,1) then
	--	return
	--end

	-- parse complete talent tree now
	local name, iconTexture, pointsSpent, background, numTalents, tabIndex;
	local talentIndex, nameTalent, talentLink, iconPath, tier, column, currentRank, maxRank, isExceptional, meetsPrereq, ptier, pcolumn, isLearnable;
	for tabIndex=1,GetNumTalentTabs() do
		name, iconTexture, pointsSpent, background = GetTalentTabInfo( tabIndex );
		numTalents = GetNumTalents(tabIndex);
		self:set(GuildAds.playerName, tostring(tabIndex)..":0", { n=name, t=iconTexture, b=background, nt=numTalents} );
		for talentIndex=1,numTalents do
			nameTalent, iconPath, tier, column, currentRank, maxRank, isExceptional, meetsPrereq = GetTalentInfo(tabIndex, talentIndex);
			ptier, pcolumn, isLearnable = GetTalentPrereqs( tabIndex , talentIndex );
			talentLink=GetTalentLink(tabIndex, talentIndex);
			if talentLink then
				nameTalent=talentLink;
				local color, spellId, spellName = GuildAds_ExplodeItemRef(talentLink);
				local start,_,id = string.find(spellId,"spell:(.*)")
				if start then
					nameTalent=id
					iconPath=nil
				end
			end
			self:set(GuildAds.playerName, tostring(tabIndex)..":"..tostring(talentIndex), { n=nameTalent, 
																t=iconPath,
																ti=tier,
																co=column,
																cr=currentRank,
																mr=maxRank,
																p=meetsPrereq,
																pt=ptier,
																pc=pcolumn,
																pl=isLearnable});
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

