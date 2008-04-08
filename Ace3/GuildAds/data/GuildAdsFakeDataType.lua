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

GuildAdsFakeDataType = GuildAdsDataType:new();

function GuildAdsFakeDataType:new(dataTypeName)
	local o = {
		metaInformations = {
			name = dataTypeName,
			version = 0,
			guildadsCompatible = 200,
			parent = GuildAdsDataType.PROFILE
		};
		schema = {
		};
	}
	return GuildAdsDataType.new(self, o);
end

function GuildAdsFakeDataType:iterator(playerName, id)
	return nilFunction;
end

function GuildAdsFakeDataType:set(playerName, id, data)
end

function GuildAdsFakeDataType:clear()
end

function GuildAdsFakeDataType:getRevision(playerName)
	return 0;
end

function GuildAdsFakeDataType:setRevision(playerName, revisionNumber)
end

function GuildAdsFakeDataType:setRaw(playerName, id, data, revisionNumber)
end

function GuildAdsFakeDataType:delete(playerName, id)
	return 0;
end

--[[ about events ]]
-- nothing will happen
function GuildAdsFakeDataType:triggerUpdate(playerName, id)
end

function GuildAdsFakeDataType:registerUpdate(obj, method)
end

function GuildAdsFakeDataType:unregisterUpdate(obj)
end

function GuildAdsFakeDataType:triggerTransactionReceived(playerName, newKeys, deletedKeys)
end

function GuildAdsFakeDataType:registerTransactionReceived(obj, method)
end

function GuildAdsFakeDataType:unregisterTransactionReceived(obj)
end

--[[ about version ]]
-- herited from GuildAdsDataType

--[[ register the data type ]]
function GuildAdsFakeDataType:register()
end