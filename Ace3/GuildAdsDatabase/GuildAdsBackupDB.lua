----------------------------------------------------------------------------------
--
-- GuildAdsBackupDB.lua
--
-- Author: Galmok@Stormrage-EU
-- URL : http://guildads.sourceforge.net
-- Email : galmok@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

-- GuildAdsBackupDatabase is meant to hold a copy of the data part of GuildAdsDatabase,
-- either to merge with the current GuildAdsDatabase to speed up synchronizing or 
-- created rom the current GuildAdsDatabase to distribute to other players to help them 
-- get synchronized faster.
--
local function deepcopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        --return setmetatable(new_table, getmetatable(object))
        return new_table
    end
    return _copy(object)
end

-- if GuildAdsBackupDatabase exists, then it means a savedvariables file has been copied to the addon directory.
if GuildAdsBackupDatabase then
	GuildAdsBackupDatabase2 = GuildAdsBackupDatabase 
end

if not GuildAdsBackupDatabase then
	GuildAdsBackupDatabase = {}
end

GuildAdsBackupDB = {

	initialized = false;

	Initialize = function()
		SlashCmdList["GUILDADSDB"] = GuildAdsBackupDB.Command;
		SLASH_GUILDADSDB1 = "/guildadsdb";
		-- listen for ADDON_LOADED
		frame = CreateFrame("Frame", nil, UIParent)
		frame:SetScript("OnEvent", GuildAdsBackupDB.OnEvent)
		frame:RegisterEvent("ADDON_LOADED")
	end;
	
	OnEvent = function(event)
		-- At this time, savedvariables file has been loaded and possibly overwritten the variable from the addon.
		GuildAdsBackupDB.initialized = true
	end;
	
	Command = function(msg)
		if not GuildAdsBackupDB.initialized then
			ChatFrame1:AddMessage("Not initialized yet.")
			return
		end
		if msg=="info" then
			GuildAdsBackupDB.Info();
		elseif msg=="backup" then
			GuildAdsBackupDB.Backup();
		elseif msg=="restore" then
			GuildAdsBackupDB.Restore();
		else
			ChatFrame1:AddMessage("Usage: /guildadsdb [info||backup||restore]");
		end
	end;
	
	isUpdating = function()
		if GuildAdsComm.state == "UPDATING" or
			 GuildAdsComm.state == "WAITING_UPDATE" then
			 	return true
		end
		return false
	end;
	
	Info = function()
		ChatFrame1:AddMessage("Stored GuildAdsDatabase information:");
		ChatFrame1:AddMessage("Requires GuildAds version: "..tostring(GuildAdsBackupDatabase.version));
		ChatFrame1:AddMessage("From realm: "..tostring(GuildAdsBackupDatabase.realmName));
		ChatFrame1:AddMessage("From channel: "..tostring(GuildAdsBackupDatabase.channel));
		ChatFrame1:AddMessage("Created: "..tostring(GuildAdsBackupDatabase.timestamp));
	end;
	
	Backup = function()
		-- make a copy of the active/in-use data of guildads right now
		
		-- check to see if a transaction is happening and wait until it is over
		if GuildAdsBackupDB.isUpdating() then
			ChatFrame1:AddMessage("Transaction in progress. Please try again later.");
			return;
		end
		
		GuildAdsBackupDatabase.complete = false;
		
		-- store revision number this database is from
		GuildAdsBackupDatabase.version = GUILDADS_REVISION_NUMBER
		
		-- store realm name
		GuildAdsBackupDatabase.realmName = GuildAds.realmName
		
		-- store the channel this database is from
		GuildAdsBackupDatabase.channel = GuildAds.channelName.."@"..GuildAds.factionName
		
		-- timestamp
		GuildAdsBackupDatabase.timestamp = date("%Y/%m/%d %H:%M:%S");
		
		-- store channel data
		GuildAdsBackupDatabase["ChannelData"] = deepcopy(GuildAdsDatabase.Data[GuildAds.realmName].channels[GuildAds.channelName.."@"..GuildAds.factionName])
		
		-- clean up channel data (forum[id][author].n = nil)
		for id, authors in pairs(GuildAdsBackupDatabase.ChannelData.forum) do
			if authors then
				for author, data in pairs(authors) do
					if type(data)=="table" then
						data.n = nil
					end
				end
			end
		end
		
		-- store profile data
		GuildAdsBackupDatabase["ProfileData"] = deepcopy(GuildAdsDatabase.Data[GuildAds.realmName].profiles)
		
		-- clean up profile data (.s in craft tables should be nil'ed)
		for author, profile in pairs(GuildAdsBackupDatabase.ProfileData) do
			if profile.craft then
				for id, links in pairs(profile.craft) do
					if type(links)=="table" then
						links.s = nil
					end
				end
			end
		end

		GuildAdsBackupDatabase.complete = true;

		ChatFrame1:AddMessage("GuildAds database is backed up. Restore with /guildadsdb restore");		
	end;
	
	Restore = function()
		-- check to see if a transaction is happening and wait until it is over
		if GuildAdsBackupDB.isUpdating() then
			ChatFrame1:AddMessage("Transaction in progress. Please try again later.");
			return;
		end

		-- check if the stored data fits
		if not GuildAdsBackupDatabase.version then
			ChatFrame1:AddMessage("No data to restore");
			return;
		end

		-- Check if the backup is complete
		if not GuildAdsBackupDatabase.complete then
			ChatFrame1:AddMessage("This backup is not complete. Nothing restored.");
			return;
		end
		
		if GuildAdsBackupDatabase.version ~= GUILDADS_REVISION_NUMBER then
			ChatFrame1:AddMessage(string.format("This data was backed up using revision %s but you are using %s. Revisions must match.", GuildAdsBackupDatabase.version, GUILDADS_REVISION_NUMBER))
			return;
		end
		
		if GuildAdsBackupDatabase.realmName ~= GuildAds.realmName then
			ChatFrame1:AddMessage(string.format("This data is meant for the server %s. Can't restore.", GuildAdsBackupDatabase.realmName))
			return;
		end
		
		if GuildAdsBackupDatabase.channel ~= GuildAds.channelName.."@"..GuildAds.factionName then
			ChatFrame1:AddMessage(string.format("This data is for the channel %s but you are on channel %s. Can't restore.", GuildAdsBackupDatabase.channel, GuildAds.channelName.."@"..GuildAds.factionName))
			return;
		end
		
		-- copy data into database
		ChatFrame1:AddMessage("Restoring channel data")
		GuildAdsDatabase.Data[GuildAds.realmName].channels[GuildAds.channelName.."@"..GuildAds.factionName] = deepcopy(GuildAdsBackupDatabase["ChannelData"])
		
		ChatFrame1:AddMessage("Restoring profile data")
		GuildAdsDatabase.Data[GuildAds.realmName].profiles = deepcopy(GuildAdsBackupDatabase["ProfileData"])
		
		-- update hashtree
		ChatFrame1:AddMessage("Updating hash tree")
		GuildAdsHash.tree = GuildAdsHash:CreateHashTree()
		
		ChatFrame1:AddMessage("GuildAds database has been restored.");
		ChatFrame1:AddMessage("To free addon memory, you should relog now.");
	end;
}

GuildAdsBackupDB.Initialize()

--[[

channelKey = GuildAdsDBchannelMT.getChannelKey()

Copy player-profiles mentioned in this table:
GuildAdsDatabase.Data[GuildAds.realmName].channels[GuildAds.channelName.."@"..GuildAds.factionName].players

Copy the profiles from here:
GuildAdsDatabase.Data[GuildAds.realmName].profiles

Copy the channel data from here:
GuildAdsDatabase.Data[GuildAds.realmName].channels[GuildAds.channelName.."@"..GuildAds.factionName]
]]