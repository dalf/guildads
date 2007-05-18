----------------------------------------------------------------------------------
--
-- GuildAdsFakeDataType.lua
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

local nilFunction = function() end;

local AceOO = AceLibrary("AceOO-2.0");
GuildAdsFakeDataType = AceOO.Class(GuildAdsDataType);

function GuildAdsFakeDataType.prototype:init(dataTypeName)
	
	self.metaInformations = {
			name = dataTypeName,
			version = 0,
			guildadsCompatible = 200,
			parent = GuildAdsDataType.PROFILE
		};
	self.schema = {};
end

function GuildAdsFakeDataType.prototype:iterator(playerName, id)
	return nilFunction;
end

function GuildAdsFakeDataType.prototype:set(playerName, id, data)
end

function GuildAdsFakeDataType.prototype:clear()
end

function GuildAdsFakeDataType.prototype:getRevision(playerName)
	return 0;
end

function GuildAdsFakeDataType.prototype:setRevision(playerName, revisionNumber)
end

function GuildAdsFakeDataType.prototype:setRaw(playerName, id, data, revisionNumber)
end

function GuildAdsFakeDataType.prototype:delete(playerName, id)
	return 0;
end

--[[ about events ]]
-- nothing will happen

function GuildAdsFakeDataType.prototype:triggerEvent(playerName, id)

end


function GuildAdsFakeDataType.prototype:registerEvent(obj, method)

end


function GuildAdsFakeDataType.prototype:unregisterEvent(obj)

end

--[[ about version ]]
-- herited from GuildAdsDataType

--[[ register the data type ]]
function GuildAdsFakeDataType.prototype:register()
end