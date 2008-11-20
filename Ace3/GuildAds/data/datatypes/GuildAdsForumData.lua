----------------------------------------------------------------------------------
--
-- GuildAdsForumData.lua
--
-- Author: Galmok of Stormrage (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : galmok@gmail.com, guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

-- codec types: BigInteger, ItemRef, String, Raw, Table, Generic, Integer, Texture, Color

GuildAdsForumDataType = GuildAdsTableDataType:new({
	metaInformations = {
		name = "Forum",
		version = 1,
        	guildadsCompatible = 200,
		parent = GuildAdsDataType.CHANNEL,
		priority = 600,
		depend = {  }
	};
	schema = {
		id = "String",	-- post id
		data = {
			[1] = { key="t",	codec="BigInteger" },	-- Timestamp
			[2] = { key="f",	codec="Integer" },	-- Flags: See below
			[3] = { key="s",	codec="String" },	-- Subject
			[4] = { key="d",	codec="String" },	-- Bodytext
		}
	}
});
--[[ Flags:
	bit 0: Sticky (all sticky posts will be shown at the top)
	bit 1: Locked (It is not possible to reply to this post, but it will be possible to reply to any replies to this post)
		This is difficult to enforce as a player can always unlock his own posts. :-/
	bit 2: only officers can read or see this post (requires players to be able to read officer notes.
							Replying requires ability to write officer note).
							This bit will be automatically set for replies on officer posts.
]]


--[[
A forum consists of a number of threads, each having a number of postings.

Can be seen like this:

A forum has a number of posts at each level, each having a number of replies (than can have replies themself)

forum ----- 1. post ------- 1. reply -- ...
	|		|
	|		|-- 2. reply -- ...
	|
	|-- 2. post ------- 1. reply -- ...
	|		|
	|		|-- 2. reply -- ...
	|
	|-- 3. post --...
	|
	.
	.

All posts have a subject line (can be empty/nil except for the top-level).
All posts must have an id. That id must be unique and contain references to parent id as well 
(in case a post is deleted, the replied to the deleted post should attach themself to the parent id)

Basically, all posts have a pointer to the parent post (i.e. which post is this a reply to)

To make a new post (in any level), find the highest ID and add 1. This number, combined with the playername, 
is the ID for the new post.
e.g. Galmok1

Replies to that post will point to Galmok1 and themself have ID Galmok1:Knok1 (if Knok made the first reply).

A reply to the reply: Galmok1:Knok1:Timble1

If the post Galmok1 is deleted, the "Galmok1:" part is to be completely ignored.
The ID Galmok1 can only happen to be used again if all 

Problems:

ID is somewhat long but the postings are probably much longer.
If top level post is deleted, none of the replies could have a subject line. In that case, show the ID.

ForumUI:

To display the top-level, run through all posts and find all IDs with zero : in.
Sort according to the number value (a number can occur twice or more times) and display.

Select a post should show it and below the post, all immediate replies should be shown.
To find the immediate replies, search for the "<parent ID>:.*[^:]"
To find all replies (regardless of level), search for "<parent ID>:.*"

The will be no quote possibility, i.e. if you want to quote, use copy-paste.
There will also be no styling.
]]


function GuildAdsForumDataType:Initialize()
end

function GuildAdsForumDataType:InitializeChannel()
	if self.db.forum == nil then
		self.db.forum = {};
	end
	if self.db.forumRevision == nil then
		self.db.forumRevision = { };
	end
end

function GuildAdsForumDataType:get(author, id)
	if not author then
		error("author is nil", 2);
	end
	if not id then
		error("id is nil", 2);
	end
	if self.db.forum and self.db.forum[id] then
		return self.db.forum[id][author];
	end
end

function GuildAdsForumDataType:setRevision(author, revision)
	local forumRevision = self.db.forumRevision;
	if not forumRevision[author] then
		forumRevision[author] = {};
	end
	forumRevision[author]._u = revision;
end

function GuildAdsForumDataType:getRevision(author)
	local forumRevision = self.db.forumRevision;
	if forumRevision[author] then
		return forumRevision[author]._u or 0;
	end
	return 0;
end

function GuildAdsForumDataType:setRaw(author, id, info, revision)
	local forum = self.db.forum;
	if info then
		if (self.db.forum[id] == nil) then
			self.db.forum[id] = {};
		end
		self.db.forum[id][author] = info;
		info._u = revision;
	else
		if self.db.forum[id] then
			self.db.forum[id][author] = nil;
		end
	end
end

function GuildAdsForumDataType:set(author, id, info)
	if info then
		if (self.db.forum[id] == nil) then
			self.db.forum[id] = {};
		end
		local forum = self.db.forum[id];
		if forum[author]==nil or info.t~=forum[author].t or info.s~=forum[author].s or info.d~=forum[author].d or info.f~=forum[author].f then
			local revision = self:getRevision(author)+1;
			self:setRevision(author, revision);
			info._u = revision;
			forum[author] = info;
			self:triggerUpdate(author, id);
			return info;
		end
	else
		if self.db.forum[id] and self.db.forum[id][author] then
			self.db.forum[id][author] = nil;
			if not next(self.db.forum[id]) then
				self.db.forum[id]=nil
			end
			self:setRevision(author, self:getRevision(author)+1);
			self:triggerUpdate(author, id);
		end
	end
end

function GuildAdsForumDataType:iterator(author, id)
	if author and not id then
		return self.iteratorId, { self, author} , nil;
	elseif not author and id then
		return self.iteratorAuthor, { self, id }, nil;
	elseif not author and not id then
		return self.iteratorAll, self, {};
	end;
end

GuildAdsForumDataType.iteratorId = function(state, id)
	local t = state[1].db.forum;
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

GuildAdsForumDataType.iteratorAuthor = function(state, author)
	-- state = { self, id }
	local t=state[1].db.forum;
	local id = state[2];
	local data;
	if id and t[id] then
		author, data = next(t[id], author);
	end
	if data then
		return author, id, data, data._u;
	end
end

GuildAdsForumDataType.iteratorAll = function(self, state)
	local id = state[1] or self:nextForumId();
	
	if id then
		local author, data = next(self.db.forum[id], state[2]);
		
		if not author then
			id = self:nextForumId(id);
			if id then
				author, data = next(self.db.forum[id]);
			end
		end
		
		if id and author then
			state[1] = id;
			state[2] = author;
			return state, id, author, data, data._u;
		end
	end
end

function GuildAdsForumDataType:nextForumId(id)
	id = next(self.db.forum, id);
	while id and not (self.db.forum[id] and next(self.db.forum[id]))do
		id = next(self.db.forum, id);  -- skip empty id's
	end
	return id;
end

function GuildAdsForumDataType:iteratorIds()
	return self.nextForumId, self, nil;
end

GuildAdsForumDataType:register();
