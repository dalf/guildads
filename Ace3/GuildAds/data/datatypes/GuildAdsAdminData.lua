----------------------------------------------------------------------------------
--
-- GuildAdsAdminData.lua
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde), Galmok of Stormrage (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

GuildAdsAdminDataType = GuildAdsDataType:new({
	metaInformations = {
		name = "Admin",
		version = 1,
        guildadsCompatible = 200,
		parent = GuildAdsDataType.CHANNEL,
		priority = 400,
		depend = { }
	};
	schema = {
		id = "String",	-- player and/or @guild that is to be blacklisted or whitelisted.
		data = {
			[1] = { key="a",	codec="Generic" },	-- Allowed? (should be Boolean but doesn't exist)
			[2] = { key="c",	codec="String" },	-- Comment
			[3] = { key="t",	codec="BigInteger" },	-- time
		}
	}
});


-- id = player, @guild
-- self.db.Admin[id][author] = { a=allowed, c="comment", t=time, _u=revision }

-- self.db.Admin.revisions[author] = { _u = revision }

function GuildAdsAdminDataType:Initialize()
end

function GuildAdsAdminDataType:InitializeChannel()
	if self.db.Admin == nil then
		self.db.Admin = { };
	end
	if self.db.AdminRevision == nil then
		self.db.AdminRevision = { };
	end
end

function GuildAdsAdminDataType:get(author, id)
	if not author then
		error("author is nil", 2);
	end
	if not id then
		error("id is nil", 2);
	end
	if self.db.Admin and self.db.Admin[id] then
		return self.db.Admin[id][author];
	end
end

function GuildAdsAdminDataType:setRevision(author, revision)
	local AdminRevision = self.db.AdminRevision;
	if not AdminRevision[author] then
		AdminRevision[author] = {};
	end
	AdminRevision[author]._u = revision;
end

function GuildAdsAdminDataType:getRevision(author)
	local AdminRevision = self.db.AdminRevision;
	if AdminRevision[author] then
		return AdminRevision[author]._u or 0;
	end
	return 0;
end

function GuildAdsAdminDataType:getNewestData(pg)
	local newestData;
	for author, id, data in self:iterator(nil,pg) do
		if (not newestData and data.t) or (newestData.t and data.t and data.t>newestData.t) then
			newestData=data;
		end
	end
	return newestData;
end

function GuildAdsAdminDataType:setRaw(author, id, info, revision)
	local Admin = self.db.Admin;
	if info then
		if (self.db.Admin[id] == nil) then
			self.db.Admin[id] = {};
		end
		self.db.Admin[id][author] = info;
		info._u = revision;
	else
		if self.db.Admin[id] then
			self.db.Admin[id][author] = nil;
		end
	end
end

function GuildAdsAdminDataType:set(author, id, info)
	if info then
		if (self.db.Admin[id] == nil) then
			self.db.Admin[id] = {};
		end
		if (self.db.Admin[id] == nil) then
			self.db.Admin[id] = {};
		end
		local Admin = self.db.Admin[id];
		if Admin[author]==nil or info.c~=Admin[author].c then
			local revision = self:getRevision(author)+1;
			self:setRevision(author, revision);
			info._u = revision;
			Admin[author] = info;
			self:triggerUpdate(author, id);
			return info;
		end
	else
		if self.db.Admin[id] and self.db.Admin[id][author] then
			self.db.Admin[id][author] = nil;
			self:setRevision(author, self:getRevision(author)+1);
			self:triggerUpdate(author, id);
		end
	end
end

function GuildAdsAdminDataType:iteratorIds()
	return self.nextAdminId, self, nil;
end

function GuildAdsAdminDataType:nextAdminId(id)
	id = next(self.db.Admin, id);
	while id and not (self.db.Admin[id] and next(self.db.Admin[id]))do
		id = next(self.db.Admin, id);  -- skip empty id's
	end
	return id;
end

function GuildAdsAdminDataType:iterator(author, id)
	if author and not id then
		-- iterateur sur les id d'un même joueur
		return self.iteratorId, { self, author} , nil;
	elseif not author and id then
		-- iterateur sur les joueurs, avec le même id
		return self.iteratorAuthor, { self, id }, nil;
	elseif not author and not id then
		-- iterateur sur toutes les skills de tous les joueurs
		return self.iteratorAll, self, {};
	end;
end

GuildAdsAdminDataType.iteratorAuthor = function(state, author)
	-- state = { self, id }
	local t=state[1].db.Admin;
	local id = state[2];
	local data;
	if id and t[id] then
		author, data = next(t[id], author);
	end
	if data then
		return author, id, data, data._u;
	end
end

GuildAdsAdminDataType.iteratorId = function(state, id)
	local t = state[1].db.Admin;
	local author = state[2];
	local data;
	id, data = next(t, id);
	while id and not(t[id] and t[id][author]) do
		id, data = next(t, id);
	end
	if id then
		return id, author, data[author], data[author]._u
	end
end

GuildAdsAdminDataType.iteratorAll = function(self, state)
	local id = state[1] or self:nextAdminId();
	
	if id then
		local author, data = next(self.db.Admin[id], state[2]);
		
		if not author then
			id = self:nextAdminId(id);
			if id then
				author, data = next(self.db.Admin[id]);
			end
		end
		
		if id and author then
			state[1] = id;
			state[2] = author;
			return state, id, author, data, data._u;
		end
	end
end

GuildAdsAdminDataType:register();
