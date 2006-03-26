----------------------------------------------------------------------------------
--
-- GuildAdsTableDataType.lua
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

GuildAdsTableDataType = GuildAdsDataType:new();

--[[
	convention :
	index : current id (may be a table in other plugin)
	author : 
	id :
	data : (value, max, spe, subspe)
	_u : revision
]]
GuildAdsTableDataType.iteratorId = function(state, id)
	local id, data = next(state[1], id);
	if id=="_u" then
		id, data = next(state[1], id);
	end
	if id then
		if type(data)=="table" then
			return id, state[2], data, data._u;
		else
			return id, state[2], data;
		end
	end
end
	
GuildAdsTableDataType.iteratorAll = function(state, current)
	error("GuildAdsTableDataType.iteratorAll not impletemented", 2);
end

function GuildAdsTableDataType:getTableForPlayer(author)
	error("GuildAdsTableDataType:getTableForPlayer not impletemented", 2);
end

function GuildAdsTableDataType:iterator(author, id)
	if author and not id then
		-- iterateur sur les id d'un même joueur
		return self.iteratorId, { self:getTableForPlayer(author), author} , nil;
	elseif not author and id then
		-- iterateur sur les joueurs, avec le même id
		return self.iteratorAuthor, { self, id }, nil;
	elseif not author and not id then
		-- iterateur sur toutes les skills de tous les joueurs
		return self.iteratorAll, self, {};
	end;
end