local MAJOR = "LibTradeLinks-1.0";
local MINOR = "9767";

local LibTradeLinks, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not LibTradeLinks then return end -- no upgrade needed

--------------------------------------------------------------------------------
--      Constant skill line IDs                                               --
--------------------------------------------------------------------------------

LibTradeLinks.SKILL_ALCHEMY        = 171;
LibTradeLinks.SKILL_BLACKSMITHING  = 164;
LibTradeLinks.SKILL_COOKING        = 185;
LibTradeLinks.SKILL_ENCHANTING     = 333;
LibTradeLinks.SKILL_ENGINEERING    = 202;
LibTradeLinks.SKILL_FIRSTAID       = 129;
LibTradeLinks.SKILL_JEWELCRAFTING  = 755;
LibTradeLinks.SKILL_LEATHERWORKING = 165;
LibTradeLinks.SKILL_MINING         = 186;
LibTradeLinks.SKILL_TAILORING      = 197;
LibTradeLinks.SKILL_INSCRIPTION    = 773;

local allSkills = {
		LibTradeLinks.SKILL_ALCHEMY,
		LibTradeLinks.SKILL_BLACKSMITHING,
		LibTradeLinks.SKILL_COOKING,
		LibTradeLinks.SKILL_ENCHANTING,
		LibTradeLinks.SKILL_ENGINEERING,
		LibTradeLinks.SKILL_FIRSTAID,
		LibTradeLinks.SKILL_JEWELCRAFTING,
		LibTradeLinks.SKILL_LEATHERWORKING,
		LibTradeLinks.SKILL_MINING,
		LibTradeLinks.SKILL_TAILORING,
		LibTradeLinks.SKILL_INSCRIPTION,
	};

--------------------------------------------------------------------------------
--                                                                            --
--------------------------------------------------------------------------------

local _G = _G;

-- Lua/bitlib Functions
local next = _G.next;
local max = _G.math.max;
local floor = _G.math.floor;
local strchar = _G.string.char;
local strbyte = _G.string.byte;
local bor = _G.bit.bor;
local blshift = _G.bit.lshift;
local band = _G.bit.band;

-- WoW API Functions
local GetSpellInfo = _G.GetSpellInfo;
local GetSpellLink = _G.GetSpellLink;
local UnitGUID = _G.UnitGUID;

--------------------------------------------------------------------------------
--                                                                            --
--------------------------------------------------------------------------------
local Data = { };
local BlackList = { };
local BoPList = { };

--------------------------------------------------------------------------------
-- Base 64 decode                                                             --
--------------------------------------------------------------------------------
local DecodeBase64Char;
local EncodeBase64Char;
local Base64MatchString;

-- NOTE: Patches after 3.0.3 use a standard Base64 encoding, so
--       check build number to determine which method to use
if tonumber((select(2, GetBuildInfo()))) > 9183 then
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
else
	Base64MatchString = "[<-{]";
	-- This is build <= 9183, use old version, which is a simple offset of 60.
	function DecodeBase64Char(c)
		return strbyte(c) - 60;
	end

	function EncodeBase64Char(val)
		return strchar(60 + val);
	end
	
end

--------------------------------------------------------------------------------
-- Return the build version for which the trade data is valid                 --
--------------------------------------------------------------------------------
function LibTradeLinks:GetBuildVersion()
	return MINOR;
end

--------------------------------------------------------------------------------
-- Set the black list containing non-recipe spellIds                          --
--------------------------------------------------------------------------------
function LibTradeLinks:SetBlackList(blackList)
	BlackList = blackList;
end

--------------------------------------------------------------------------------
-- Set the black list containing non-recipe spellIds                          --
--------------------------------------------------------------------------------
function LibTradeLinks:SetBoPList(bopList)
	BoPList = bopList;
end

--------------------------------------------------------------------------------
-- Add a skill to the list, where professionIdList is a table of spellIds for --
-- the profession to add, and data is a table containing spellId in the order --
-- as they appear in the trade-link bitmask.                                  --
--------------------------------------------------------------------------------
function LibTradeLinks:AddData(skillId, professionIdList, spellIdList)
	local idList = {};
	for _, id in next, professionIdList do idList[id] = id; end
	Data[skillId] = {
		SkillId = skillId,
		ProfessionIdList = idList,
		MainProfessionId = professionIdList[1],
		Label = GetSpellInfo(professionIdList[1]),
		Data = spellIdList,
	};
end

--------------------------------------------------------------------------------
-- Return the table containing spellIds for the specified skill id            --
--------------------------------------------------------------------------------
function LibTradeLinks:GetData(skillId)
	return Data[skillId] and Data[skillId].Data or nil;
end

--------------------------------------------------------------------------------
-- Return a table containing all skillIds                                     --
--------------------------------------------------------------------------------
function LibTradeLinks:GetSkillIds()
	return allSkills;
end

--------------------------------------------------------------------------------
-- Return the name of the specified skillId                                   --
--------------------------------------------------------------------------------
function LibTradeLinks:GetSkillName(skillId)
	if Data[skillId] then
		return Data[skillId].Label;
	end
end
--------------------------------------------------------------------------------
-- Returna s Base64 encoded bitmask, represented by the table t. Function     --
-- func is called for each entry in t, to determine if that bit is 1 or 0.    --
--------------------------------------------------------------------------------
local function Encode64(t, func)
    local str = "";
    local char = 0;
    for index, data in next, t do
        local b = (index - 1) % 6;
        if b == 0 and index ~= 1 then
            str = str .. EncodeBase64Char(char);
            char = 0;
        end
       
        if func(data) then
            char = bor(char, blshift(1, b));
        end
    end
    return str .. EncodeBase64Char(char);
end

--------------------------------------------------------------------------------
-- Encode a trade link for the specified skill and list of spells, return     --
-- a complete chat trade-link as 1st return value, and the trade-link as 2nd. --
--------------------------------------------------------------------------------
function LibTradeLinks:Encode(skillId, spells, skillLevel, skillMax, GUID)
	local data = self:GetData(skillId);
	if not data then return nil, nil; end
	local professionSpellId = Data[skillId].MainProfessionId;
	
	local encoded = ("trade:%d:%d:%d:%s:%s"):format(
		professionSpellId,
		skillLevel or 450,
		skillMax or 450,
		(GUID or UnitGUID("player")):gsub("0x0+", ""),
		Encode64(data, function(id) return spells[id] end)
	);
		
	local link = ("|cffffd000|H%s|h[%s]|h|r"):format(
		encoded,
		GetSpellInfo(professionSpellId)
	);

	return link, encoded;
end

--------------------------------------------------------------------------------
-- Decode a base64 encoded bitmask, looking up bits set to 1 in the table t.  --
-- A table containing the entries set to 1 is returned.                       --
--------------------------------------------------------------------------------
local function Decode64(str, t, out)
	out = out or {};
	local offset = 0;
	str:gsub(".", function(c)
		local v = DecodeBase64Char(c);
		for i = 0, 5 do
			if band(v, blshift(1, i)) ~= 0 then
				out[t[offset * 6 + i + 1]] = 1;
			end
		end
		offset = offset + 1;
	end);
	return out;
end

--------------------------------------------------------------------------------
-- Decode a trade-link and return a table of contained spell Ids              --
-- If purge is specified, black-listed spells are purged from the list        --
--------------------------------------------------------------------------------
function LibTradeLinks:Decode(link, purgeNonRecipe, purgeBoP)
	assert(type(link) == "string", "Error, LibTradeLinks:Decode() requires a string as first argument");

	local profession, guid, skills = link:match("trade:(%d+):%d+:%d+:([0-9a-fA-F]+):(" .. Base64MatchString .. "+)");
	if skills then
		profession = tonumber(profession);
		for skillId, data in next, Data do
			if data.ProfessionIdList[profession] then
				return self:Purge(Decode64(skills, data.Data), purgeNonRecipe, purgeBoP), skillId;
			end
		end
	end
end

--------------------------------------------------------------------------------
-- Decode a trade-link, and write to ChatFrame1 a list of all spells linked.  --
--------------------------------------------------------------------------------
function LibTradeLinks:DecodeOut(link, purgeNonRecipe, purgeBoP)
	local spells = self:Decode(link, purgeNonRecipe, purgeBoP);
	if spells then
		ChatFrame1:AddMessage(link .. " contains:");
		local out = "";
		local count = 0;
		for spellId, _ in next, spells do
			count = count + 1;
			out = out .. GetSpellLink(spellId) .. "; ";
			if count == 5 then
				ChatFrame1:AddMessage(out);
				out = "";
				count = 0;
			end
		end
		if out ~= "" then
			ChatFrame1:AddMessage(out);
		end
	end
end

--------------------------------------------------------------------------------
-- Purge the specified list of spells for non-recipe spells and recipees that --
-- create BoP items.                                                          --
--------------------------------------------------------------------------------
function LibTradeLinks:Purge(spells, purgeNonRecipe, purgeBoP)
	assert(type(spells) == "table", "Error, LibTradeLinks:Purge() requires a table as first argument");
	
	if purgeNonRecipe and BlackList then
		for _, spellId in next, BlackList do
			spells[spellId] = nil;
		end
	end
	
	if purgeBoP and BoPList then
		for _, spellId in next, BoPList do
			spells[spellId] = nil;
		end
	end
	
	return spells;
end
