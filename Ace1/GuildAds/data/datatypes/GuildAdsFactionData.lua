----------------------------------------------------------------------------------
--
-- GuildAdsFactionData.lua
--
-- Author: Galmok, European Stormrage (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : galmok@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

GuildAdsFactionDataType = GuildAdsTableDataType:new({
	metaInformations = {
		name = "Faction",
		version = 1,
        guildadsCompatible = 200,
		parent = GuildAdsDataType.PROFILE,
		priority = 700,
		depend = { "Main" }
	};
	schema = {
		id = "Integer", -- faction ID (1-42)
		data = {
			[1] = { key="v",	codec="Integer" }, -- standing
			[2] = { key="b",	codec="Integer" }, -- lower bound
			[3] = { key="t",	codec="Integer" }, -- upper bound
			[4] = { key="s",	codec="Integer" }, -- standing id (FACTION_STANDING_LABEL(x))
		}
	}
});

function GuildAdsFactionDataType:Initialize()
	--[[
		SKILL_LINES_CHANGED event fires when there is change in skills
		CHAT_MSG_SYSTEM event with this text ERR_SPELL_UNLEARNED_S fires when a skill is forget
		CHARACTER_POINTS_CHANGED when player level up or forget/learn a skill
		CHAT_MSG_SKILL event fires when the player progress
	]]
	GuildAdsTask:AddNamedSchedule("GuildAdsFactionDataTypeInit", 8, nil, nil, self.onEvent, self)
	-- UPDATE_FACTION, CHAT_MSG_COMBAT_FACTION_CHANGE, COMBAT_TEXT_UPDATE, UNIT_FACTION, UPDATE_FACTION
	--self:RegisterEvent("CHARACTER_POINTS_CHANGED", "onEvent");
	--self:RegisterEvent("CHAT_MSG_SKILL", "onEvent");
	self:RegisterEvent("PLAYER_LEVEL_UP", "onEvent");
	self:RegisterEvent("UPDATE_FACTION", "onEvent");
end

function GuildAdsFactionDataType:onEvent()
	local playerName = UnitName("player");
	local playerFactionIds = {};
	-- add new factions
	for i = 1, GetNumFactions(), 1 do	
		local factionName, description, standingId, bottomValue, topValue, earnedValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, isWatched = GetFactionInfo(i);
		if (isHeader == nil) then
			local id = self:getIdFromName(factionName);
			if (id > 0) then
				self:set(playerName, id, { v=earnedValue; b=bottomValue; t=topValue; s=standingId });
				playerFactionIds[id] = true;
			end
		end
	end
	-- delete factions (this deletes factions that you chose to hide which is not what we want)
	-- The only way to detect if a faction is to be deleted is to check if all headers are open (not collapsed) as 
	-- that will ensure we have a full faction list. Only then may we delete factions from the list. This is not
	-- implemented yet.
	--for id in pairs(self:getTableForPlayer(playerName)) do
	--	if not playerFactionIds[id] and id~="_u" then
	--		self:set(playerName, id, nil);
	--	end
	--end
end

function GuildAdsFactionDataType:getIdFromName(FactionName)
	for id, name in pairs(GUILDADS_FACTIONS) do
		if (name == FactionName) then
			return id;
		end
	end
	return -1;	
end

function GuildAdsFactionDataType:getNameFromId(FactionId)
	return GUILDADS_FACTIONS[FactionId] or "";
end

function GuildAdsFactionDataType:getTableForPlayer(author)
	return self.profile:getRaw(author).factions;
end

function GuildAdsFactionDataType:get(author, id)
	if not author then
		error("author is nil", 2);
	end
	return self.profile:getRaw(author).factions[id];
end

function GuildAdsFactionDataType:getRevision(author)
	return self.profile:getRaw(author).factions._u or 0;
end

function GuildAdsFactionDataType:setRevision(author, revision)
	self.profile:getRaw(author).factions._u = revision;
end

function GuildAdsFactionDataType:setRaw(author, id, info, revision)
	local factions = self.profile:getRaw(author).factions;
	factions[id] = info;
	if info then
		factions[id]._u = revision;
	end
end

function GuildAdsFactionDataType:set(author, id, info)
	local factions = self.profile:getRaw(author).factions;
	if info then
		if factions[id]==nil or info.v ~= factions[id].v or info.b ~= factions[id].b or info.t ~= factions[id].t or info.s ~= factions[id].s then
			--if factions[id] then
			--	DEFAULT_CHAT_FRAME:AddMessage(""..info.v..":"..factions[id].v.."  "..info.b..":"..factions[id].b.."  "..info.t..":"..factions[id].t.."  "..info.s..":"..factions[id].s);
			--else
			--	DEFAULT_CHAT_FRAME:AddMessage("Faction nil "..id);
			--end
			factions._u = 1 + (factions._u or 0);
			info._u = factions._u;
			factions[id] = info;
			self:triggerUpdate(author, id);
			return info;
		end
	else
		if factions[id] then
			--DEFAULT_CHAT_FRAME:AddMessage("Deleting Faction "..id);
			factions[id] = nil;
			factions._u = 1 + (factions._u or 0);
			self:triggerUpdate(author, id);
		end
	end
end

GuildAdsFactionDataType:register();
