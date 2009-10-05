-- GuildAdsBackupDatabase is meant to hold a copy of the data part of GuildAdsDatabase,
-- either to merge with the current GuildAdsDatabase to speed up synchronizing or 
-- created rom the current GuildAdsDatabase to distribute to other players to help them 
-- get synchronized faster.
-- The entire logic is (will be) placed in GuildAds itself.

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


if not GuildAdsBackupDatabase then
	GuildAdsBackupDatabase = {}
end

GuildAdsBackupDB = {
	Initialize = function()
		SlashCmdList["GUILDADSDB"] = GuildAdsBackupDB.Command;
		SLASH_GUILDADSDB1 = "/guildadsdb";
	end;
	
	Command = function(msg)
		ChatFrame1:AddMessage("/guildadsdb called with argument "..tostring(msg));
		if msg=="backup" then
			-- make a copy of the active/in-use data of guildads right now
			
			-- check to see if a transaction is happening and wait until it is over
			if GuildAdsBackupDB.isUpdating() then
				ChatFrame1:AddMessage("Transaction in progress. Please try again later.");
				return;
			end
			
			-- store revision number this database is from
			GuildAdsBackupDatabase.version = GUILDADS_REVISION_NUMBER
			
			-- store realm name
			GuildAdsBackupDatabase.realmName = GuildAds.realmName
			
			-- store the channel this database is from
			GuildAdsBackupDatabase.channel = GuildAds.channelName.."@"..GuildAds.factionName
			
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

			ChatFrame1:AddMessage("GuildAds database is backed up. Restore with /guildadsdb restore");
			
		elseif msg=="restore" then

			-- check to see if a transaction is happening and wait until it is over
			if GuildAdsBackupDB.isUpdating() then
				ChatFrame1:AddMessage("Transaction in progress. Please try again later.");
				return;
			end

			-- check if the stored data fits
			if not GuildAdsBackupDatabase.version then
				ChatFrame1:AddMessage("No data to restore");
			end
			
			if GuildAdsBackupDatabase.version ~= GUILDADS_REVISION_NUMBER then
				ChatFrame1:AddMessage(string.format("This data was backed up using revision %s but you are using %s. Revisions must match.", GuildAdsBackupDatabase.version, GUILDADS_REVISION_NUMBER))
			end
			
			if GuildAdsBackupDatabase.realmName ~= GuildAds.realmName then
				ChatFrame1:AddMessage(string.format("This data is meant for the server %s. Can't restore.", GuildAdsBackupDatabase.realmName))
			end
			
			if GuildAdsBackupDatabase.channel ~= GuildAds.channelName.."@"..GuildAds.factionName then
				ChatFrame1:AddMessage(string.format("This data is for the channel %s but you are on channel %s. Can't restore.", GuildAdsBackupDatabase.channel, GuildAds.channelName.."@"..GuildAds.factionName))
			end
			
			-- wait until not receiving a transaction (not sure how)
			
			-- copy data into database
			ChatFrame1:AddMessage("Restoring channel data")
			GuildAdsDatabase.Data[GuildAds.realmName].channels[GuildAds.channelName.."@"..GuildAds.factionName] = deepcopy(GuildAdsBackupDatabase["ChannelData"])
			
			ChatFrame1:AddMessage("Restoring profile data")
			GuildAdsDatabase.Data[GuildAds.realmName].profiles = deepcopy(GuildAdsBackupDatabase["ProfileData"])
			
			-- update hashtree
			ChatFrame1:AddMessage("Updating hash tree")
			GuildAdsHash.tree = GuildAdsHash:CreateHashTree()
			
			ChatFrame1:AddMessage("GuildAds database has been restored.");
		else
			ChatFrame1:AddMessage(string.format("Unsupported argument %s", msg));
		end
	end;
	
	isUpdating = function()
		if GuildAdsComm.state == "UPDATING" or
			 GuildAdsComm.state == "WAITING_UPDATE" then
			 	return true
		end
		return false
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