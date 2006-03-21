----------------------------------------------------------------------------------
--
-- GuildAdsComm.lua
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

GUILDADS_VERSION_PROTOCOL = "26";

GUILDADS_MSG_PREFIX_NOVERSION = "<GA";
GUILDADS_MSG_REGEX_UNSERIALIZE = "([^\>]*)>";
GUILDADS_MSG_PREFIX1= "<GA"..GUILDADS_VERSION_PROTOCOL;
GUILDADS_MSG_PREFIX = GUILDADS_MSG_PREFIX1..">";
	
GUILDADS_MSG_PREFIX_REGEX_UNSPLIT = GUILDADS_MSG_PREFIX.."([0-9]+)([\.|\:])(.*)";

GUILDADS_MSG_TYPE_ANNONCE = 0;
GUILDADS_MSG_TYPE_REQUEST = 1;
GUILDADS_MSG_TYPE_AVAILABLE = 2;
GUILDADS_MSG_TYPE_SKILL = 3;
GUILDADS_MSG_TYPE_EVENT = 4;
GUILDADS_MSG_TYPE_INVENTORY = 5;
GUILDADS_MSG_TYPE_NOTE = 6;
GUILDADS_MSG_TYPE_EVENT_SUBSCRIPTION = 7;
GUILDADS_MSG_TYPE_IGNORE = "i";

-- "([0-9]+)\." and "([0-9]+)\:" for fragmented messages.
GUILDADS_MSG_ADD = "a";
GUILDADS_MSG_REMOVE = "r";
GUILDADS_MSG_REMOVE_ALL = "R";
GUILDADS_MSG_REQUEST_ADS = "?";
GUILDADS_MSG_REQUEST_INSPECT = "?i";
GUILDADS_MSG_REQUEST_OFFLINES = "?o";
GUILDADS_MSG_SENDING_UPDATE = "U";
GUILDADS_MSG_SENDING_ALL = "S";
GUILDADS_MSG_SENDING_ALL_END = "E";
GUILDADS_MSG_LASTSEEN = "l";
GUILDADS_MSG_LASTSEEN_END = "le";
GUILDADS_MSG_META = "m";
GUILDADS_MSG_CHATFLAG = "chatFlag";

GUILDADS_STATE_UNKNOW       = "unknow";
GUILDADS_STATE_SYNC_ONLINE  = "s_online";
GUILDADS_STATE_SYNC_OFFLINE = "s_offline";
GUILDADS_STATE_OK   	     = "ok";

local playerName = "";
local MonitorAds = {};			-- record updated ads (GUILDADS_MSG_SENDING_ALL)
local MetaPlayers = {};			-- state, onlineSince, version
local MyState = GUILDADS_STATE_UNKNOW;
local LastSeens = {};			-- Players we are listen to give theirs offline players.
local WaitingOfflinesAds = { };	-- Players are we waiting for offlines ads to be GUILDADS_STATE_OK
local StartTime;
-- local OnMessageCommand = { };
local OnMessageAd = {};
local WatingForUpdate = { };

local function GAC_GetGuildChatFrame()
	for i=1,NUM_CHAT_WINDOWS,1 do
		local DefaultMessages = { GetChatWindowMessages(i) };
		for k, channel in DefaultMessages do
			if channel == "GUILD" then
				return getglobal("ChatFrame"..i);
			end
		end
	end
	return DEFAULT_CHAT_FRAME;
end

function GAC_GetMeta(player)
	return MetaPlayers[player];
end

function GAC_GetMetas()
	return MetaPlayers;
end

GAC_GetFlag = SimpleComm_GetFlag;

function GAC_Init(playername, channel, password)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"GAC_Init("..playername..","..channel..")");
	
	playerName = playername;
	if (not StartTime) then
		StartTime = GuildAdsDB:GetCurrentTime();
	end
	
	SimpleComm_Init(channel, password, GAC_GetGuildChatFrame());
	
	local command, alias = GuildAds:GetDefaultChannelAlias();
	SimpleComm_InitAlias(command, alias);
	
	SimpleComm_SetFlagListener(GAC_OnChatFlagChange);
	
	-- Init after the channel is joined (GAC_Synchronize called by SimpleComm)
end

function GAC_Reinit(channel, password)
	-- Reset internal variables
	MonitorAds = {};
	LastSeens = {};
	WaitingOfflinesAds = { };
	WatingForUpdate = { };
	MyState = GUILDADS_STATE_UNKNOW;
	GuildAdsSystem.SynchronizeOfflinesTimer = nil;
	GuildAdsSystem.SynchronizeOfflinesTimerEnd = nil;
	
	-- Reinit GuildAdsComm
	SimpleComm_SetChannel(channel, password);
	
	-- Init after the channel is joined (GAC_Synchronize called by SimpleComm)
end

function GAC_Test()
	for name, profile in GuildAdsDB.profile do
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "  - P:"..name);
	end
	for name, channel in GuilssssdAdsDB.channel[GuildAds.channelName] do
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "  - C:"..name);
	end
end

function GAC_OnChannelLeave()
	GuildAdsPlugin_OnChannelLeave();
end

function GAC_Synchronize()
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"GAC_Synchronize");
	
	-- call plugin init
	GuildAdsPlugin_OnChannelJoin();
	
	-- reset local variables
	MonitorAds = {};
	MetaPlayers = {};
	LastSeens = {};
	WaitingOfflinesAds = {};
	WatingForUpdate = { };
	
	-- Send status
	MyState = GUILDADS_STATE_SYNC_ONLINE;
	GAC_SendMeta(nil);
	
	-- Send chat status : detected by SimpleComm
	GAC_SendChatFlag(playerName);
	
	-- Now, send to all my ads
	GAC_SendAllAdsType(nil, nil, nil);
	
	-- Ask everyone to send me their ads
	GAC_SendRequestAds(nil);

	-- Wait 30 seconds and synchronize offlines
	GuildAdsSystem.SynchronizeOfflinesCount = 0;
	GuildAdsSystem.SynchronizeOfflinesTimer = 30;
	GuildAdsSystem.SynchronizeOfflinesTimerEnd = false;
end

function GAC_SynchronizeOfflines(numberOfTries)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"GAC_SynchronizeOfflines("..numberOfTries..")");
	
	--[[
		moi à player> envois de GUILDADS_MSG_REQUEST_OFFLINES
		player à moi> envois de GUILDADS_MSG_LASTSEEN pour chacun de ses offlines
		moi> pour chaque GUILDADS_MSG_LASTSEEN reçu : 
			si plus ancien -> envois de mes annonces
			si plus récent -> demande les annonces à player
		player à moi> envois de GUILDADS_MSG_LASTSEEN_END
			envois de ses offlines non mis à jour
	]]

	-- Ask offlines to someone who is online
	local oneOnlinePlayer, canTryLater = GAC_GetRandomOnline();
	if (oneOnlinePlayer) then
		-- Il y au moins un autre joueur
		if canTryLater then
			--[[ aucun joueur connecté n'est synchronisé
			attends à nouveau 30 secondes
			sauf s'il y a plus de 40 essais (donc 20 minutes)
			nombre d'essais limité pour éviter le deadlock si 
			deux joueurs se connectent au même moment
			onelinePlayer = true
			]]
			if (numberOfTries<40) then
				GuildAdsSystem.SynchronizeOfflinesCount = numberOfTries+1;
				GuildAdsSystem.SynchronizeOfflinesTimerEnd = false;
				GuildAdsSystem.SynchronizeOfflinesTimer = 30;
			else
				--[[
					il y a un problème : synchro des offlines impossible depuis 20 minutes
				]]
				GuildAds.cmd:msg("|cffff1e00Impossible to synchronize offline ads.|r");
			end
		else
			-- Changement d'état
			MyState = GUILDADS_STATE_SYNC_OFFLINE;
			GAC_SendMeta(nil);
			
			-- Il y a au moins un autre joueur connecté
			GAC_SendRequestOfflines(oneOnlinePlayer);
			
			-- 10 minutes avant d'être déclaré synchronisé
			GuildAdsSystem.SynchronizeOfflinesCount = 0;
			GuildAdsSystem.SynchronizeOfflinesTimerEnd = true;
			GuildAdsSystem.SynchronizeOfflinesTimer = 60*10;
		end
	else
		-- Aucun online
		-- Synchronisation terminée
		MyState = GUILDADS_STATE_OK;
		GAC_SendMeta(nil);
	end
end

function GAC_SynchronizeOfflinesEnd()
	MyState = GUILDADS_STATE_OK;
	GAC_SendMeta(nil);
end

function GAC_OnChatFlagChange(flag, message)
	SimpleComm_SendMessage(
		nil,
		{
			command = GUILDADS_MSG_CHATFLAG;
			flag = flag;
			text = message;
		}
	);
end

--[[
	Retourne le nom d'un joueur connecté et synchronisé.
	Si aucun joueur connecté n'est synchronisé, retourne (nil, true)
	Si aucun joueur n'est connecté, retourne (nil, false)
]]
function GAC_GetRandomOnline()
	local canTryLater = false;
	local ready = {};
	for name, metainfo in MetaPlayers do
		if (name ~= playerName) then
			if (metainfo.state == GUILDADS_STATE_OK) then
				tinsert(ready, name);
			elseif (metainfo.state == GUILDADS_STATE_SYNC_OFFLINE) or (metainfo.state == GUILDADS_STATE_SYNC_ONLINE) then
				canTryLater = true;
			end
		end
	end
	local s = table.getn(ready);
	if (s > 0) then
		return ready[math.random(s)], false;
	else
		return nil, canTryLater;
	end
end

function GAC_SendSkill(who, owner, id, skillRank, skillMaxRank, delay)
	SimpleComm_SendMessage(
		who,
		{
			command = GUILDADS_MSG_ADD;
			adtype = GUILDADS_MSG_TYPE_SKILL;
			id = id;
			skillRank = skillRank;
			skillMaxRank = skillMaxRank;
			creationtime = GuildAdsDB:GetCurrentTime();
			owner = owner;
		},
		delay
	);
end

function GAC_SendInventory(who, slot, texture, color, ref, name, count)
	SimpleComm_SendMessage(
			who,
			{
				command = GUILDADS_MSG_ADD;
				adtype = GUILDADS_MSG_TYPE_INVENTORY;
				id = slot;
				itemRef = ref;
				itemName = name;
				itemColor = color;
				count = count;
				texture = texture;
				creationtime = GuildAdsDB:GetCurrentTime()
			}
		);
end

function GAC_SendInspect(who)
	-- TODO : utiliser le data type
	local buffer = {};
	for slot=1, 19, 1 do
		local link = GetInventoryItemLink("player", slot);
		if (link) then
			-- local title = TEXT(getglobal(strupper(SlotIdText[slot])));
			local texture = GetInventoryItemTexture("player", slot);
			local count = GetInventoryItemCount("player", slot);
			local color, ref, name = GuildAds_ExplodeItemRef(link);	
			tinsert(buffer, {
					slot = slot,
					texture = texture,
					color = color,
					ref = ref,
					name = name,
					count = count
				}
			);
		end
	end
	
	GAC_SendingUpdate(who, table.getn(buffer));
	local index = 1;
	while buffer[index] do
		GAC_SendInventory(who, buffer[index].slot, buffer[index].texture, buffer[index].color, buffer[index].ref, buffer[index].name, buffer[index].count);
		index = index + 1;
	end
end

function GAC_SendRequestInspect(who)
	SimpleComm_SendMessage(
			who,
			{
				command = GUILDADS_MSG_REQUEST_INSPECT
			}
		);
end

function GAC_SendRequestOfflines(who)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"GAC_SendRequestOfflines("..tostring(who)..")");
	LastSeens[who] = {};
	SimpleComm_SendMessage(
			who,
			{
				command = GUILDADS_MSG_REQUEST_OFFLINES
			}
		);
end

function GAC_SendRequestAds(who, owner)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"GAC_SendRequestAds("..tostring(who)..")");
	SimpleComm_SendMessage(
			who,
			{
				command = GUILDADS_MSG_REQUEST_ADS;
				owner = owner
			}
		);
end


function GAC_SendAnnonce(who, owner)
	local name, creationtime;
	
	name = owner or playerName;
	
	if (owner) then
		creationtime = GuildAdsDB.profile.Main:get(name, GuildAdsMainDataType.CreationTime);
	else
		creationtime = GuildAdsDB:GetCurrentTime();
	end
	
	SimpleComm_SendMessage(
			who,
			{
				command = GUILDADS_MSG_ADD;
				adtype = GUILDADS_MSG_TYPE_ANNONCE;
				accountId = GuildAdsDB.profile.Main:get(name, GuildAdsDB.profile.Main.Account);
				class = GuildAdsDB.profile.Main:get(name, GuildAdsDB.profile.Main.Class);
				race = GuildAdsDB.profile.Main:get(name, GuildAdsDB.profile.Main.Race);
				level = GuildAdsDB.profile.Main:get(name, GuildAdsDB.profile.Main.Level);
				guild = GuildAdsDB.profile.Main:get(name, GuildAdsDB.profile.Main.Guild);
				creationtime = creationtime;
				owner = owner
			}
		);
end

function GAC_SendRemove(who, adtype, id)
	SimpleComm_SendMessage(
			who,
			{
				command = GUILDADS_MSG_REMOVE;
				adtype = adtype;
				id = id
			}
		);
end

function GAC_SendRemoveAll(who)
	SimpleComm_SendMessage(
			who,
			{
				command = GUILDADS_MSG_REMOVE_ALL;
			}
		);
end

function GAC_SendingUpdate(who, count, owner, delay)
	SimpleComm_SendMessage(
		who,
		{ 
			command = GUILDADS_MSG_SENDING_UPDATE,
			owner = owner,
			count = count
		},
		delay
	);
end

function GAC_SendingAll(who, owner)
	SimpleComm_SendMessage(
			who,
			{
				command = GUILDADS_MSG_SENDING_ALL;
				owner = owner
			}
		);
end

function GAC_SendingAllEnd(who, owner, delay)
	local creationtime = GAC_ProfileGetUpdatedDate(owner or playerName);
	SimpleComm_SendMessage(
			who,
			{
				command = GUILDADS_MSG_SENDING_ALL_END;
				creationtime = creationtime;
				owner = owner;
			},
			delay
		);
end

function GAC_SendLastSeen(who, owner, time)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"GAC_SendLastSeen("..tostring(who)..")");
	SimpleComm_SendMessage(
			who,
			{
				command = GUILDADS_MSG_LASTSEEN;
				creationtime = time;
				owner = owner
			}
		);
end

function GAC_SendLastSeenEnd(who)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"GAC_SendLastSeenEnd("..tostring(who)..")");
	SimpleComm_SendMessage(
			who,
			{
				command = GUILDADS_MSG_LASTSEEN_END;
			}
		);
end

function GAC_SendTradeDataType(who, owner, adType, dataType, delay)
	for item, playerName, data in dataType:iterator(owner or GuildAds.playerName) do
		local info = GuildAds_ItemInfo[item];
		if info then
			local _, _, _, hex = GetItemQualityColor(info.quality or 2);
			SimpleComm_SendMessage(who, {
				command = GUILDADS_MSG_ADD;
				adtype = adType;
				id = item;					-- compatibility
				text = data.c;
				texture = info.texture;		-- compatibility
				count = data.q;
				itemRef = item;
				itemName = info.name;		-- compatibility
				itemColor = strsub(hex, 2);	-- compatibility
				creationtime = data._t;
				owner = owner
			},
			delay);
		else
			SimpleComm_SendMessage(who, {
				command = GUILDADS_MSG_ADD;
				adtype = adType;
				id = data.text;				-- compatibility
				text = data.c;
				count = data.q;
				itemRef = item;
				creationtime = data._t;
				owner = owner
			},
			delay);
		end
	end	
end

function GAC_SendAllAdsType(who, owner, delay)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"GAC_SendAllAdsType("..tostring(who)..","..tostring(owner)..")");
	
	-- On n'envois pas à who ses annonces
	-- sauf si c'est nous même, ou si c'est à tout le monde
	if (who == owner) and (who ~= playerName) and (who ~= nil) then
		return;
	end
	
	-- Ads->Start
	GAC_SendingAll(who, owner);
	
	-- Guild
	GAC_SendAnnonce(who, owner);
	
	-- Offer
	GAC_SendTradeDataType(who, owner, GUILDADS_MSG_TYPE_AVAILABLE, GuildAdsDB.channel[GuildAds.channelName].TradeOffer, delay);
	
	-- Need
	GAC_SendTradeDataType(who, owner, GUILDADS_MSG_TYPE_REQUEST, GuildAdsDB.channel[GuildAds.channelName].TradeNeed, delay);
	
	-- Events
	for id, _, data in GuildAdsDB.channel[GuildAds.channelName].SimpleEvent:iterator(owner or playerName) do
		SimpleComm_SendMessage(
			who,
			{
				command = GUILDADS_MSG_ADD;
				adtype = GUILDADS_MSG_TYPE_EVENT;
				id = data.id;
				text = id;
				creationtime = data._t;
				owner = owner
		},
		delay
		);
	end
	
	-- Skills
	for id, _, data in GuildAdsDB.profile.Skill:iterator(owner or playerName) do
		GAC_SendSkill(who, owner, id, data.v, data.m, delay)
	end
	
	-- Ads->End
	GAC_SendingAllEnd(who, owner, delay);
end

function GAC_SendMeta(who)
	SimpleComm_SendMessage(
			who,
			{
				command = GUILDADS_MSG_META;
				text = GUILDADS_VERSION;
				creationtime = StartTime;
				id = MyState;
			}
		);
end

function GAC_SendChatFlag(who)
	local flag, message = SimpleComm_GetFlag(playerName);
	SimpleComm_SendMessage(
		nil,
		{
			command = GUILDADS_MSG_CHATFLAG;
			flag = flag;
			text = message;
		}
	);
end


--------------------------------------------------------------------------------
--
-- Temporary function
-- 
---------------------------------------------------------------------------------
function GAC_ProfileSetUpdatedDate(owner, time)
	GuildAdsDB.profile:getRaw(owner).old.updatedDate = time;
end

function GAC_ProfileGetUpdatedDate(owner)
	return GuildAdsDB.profile:getRaw(owner).old.updatedDate;
end

--------------------------------------------------------------------------------
--
-- OnMessage
-- 
---------------------------------------------------------------------------------
local author, owner, message, channelName;

function GAC_OnMessage(a, m, c)

	author = a;
	message = m;
	channelName = c or GuildAds.channelName;
	
	-- Ignore this author ?
	if not GuildAdsDB.channel[channelName]:isPlayerAllowed(author) then
		return;
	end
	
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"[OnMessage,"..author.."]: "..GuildAds_Serialize(message));
	
	-- Set online
	GuildAdsComm:SetOnlineStatus(author, true);
	
	local myTime = GuildAdsDB:GetCurrentTime();
	
	-- Ajuste à l'heure locale
	if (message.creationtime) then
		message.creationtime = message.creationtime + myTime - message.currenttime;
	end
	
	-- Mise à jour du dernier message de author
	GAC_ProfileSetUpdatedDate(author, myTime);
	
	-- A propos de quelle personne : l'auteur du message (author) ou une autre (message.owner)
	if message.owner then
		owner = message.owner;
	else
		owner = author;
	end
	
	-- Process message, if command is known
	if OnMessageCommand[message.command] then
		OnMessageCommand[message.command]()
	else
		-- This message was unknown
		-- GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"Unknown message")
	end
end

OnMessageCommand = {
	[GUILDADS_MSG_ADD] = function()
		-- Accept only if :
		--      this owner isn't ignored
		--   AND ( this owner has sent GUILDADS_MSG_SENDING_ALL which was accepted.
		--         OR this owner has sent a GUILDADS_MSG_SENDING_UPDATE )
		if GuildAdsDB.channel[channelName]:isPlayerAllowed(owner) and (MonitorAds[owner] or WatingForUpdate[owner]) then
			-- 
			local adtype = message.adtype;
			
			-- Use this update
			if WatingForUpdate[owner] then
				WatingForUpdate[owner] = WatingForUpdate[owner] - 1;
				if WatingForUpdate[owner]==0 then
					WatingForUpdate[owner] = nil;
				end
			end
		
			-- Call onMessageAd
			if OnMessageAd[adtype] then
				if not OnMessageAd[adtype](author, message) then
					return;
				end
			end
		
			-- Inventory
			if (adtype == GUILDADS_MSG_TYPE_INVENTORY) then
				GuildAdsDB.profile.Inventory:set(owner, message.id, {i=message.itemRef; q=message.count });
				return;
			end
		
			-- Mise à jour du profile
			if (adtype == GUILDADS_MSG_TYPE_ANNONCE) then
				GuildAdsDB.profile.Main:set(owner, GuildAdsDB.profile.Main.CreationTime, message.creationtime);
				GuildAdsDB.profile.Main:set(owner, GuildAdsDB.profile.Main.Guild, message.guild);
				GuildAdsDB.profile.Main:set(owner, GuildAdsDB.profile.Main.Level, message.level);
				GuildAdsDB.profile.Main:set(owner, GuildAdsDB.profile.Main.Class, message.class);
				GuildAdsDB.profile.Main:set(owner, GuildAdsDB.profile.Main.Race, message.race);
				GuildAdsDB.profile.Main:set(owner, GuildAdsDB.profile.Main.Account, message.accountId);
				GuildAdsDB.channel[channelName]:addPlayer(owner)
				return;
			end
			
			-- Monitor : l'annonce a été mise à jour
			-- cf GUILDADS_MSG_SENDING_ALL et GUILDADS_MSG_SENDING_ALL_END
			if adtype and owner and MonitorAds[owner] and message.id then   -- TODO : message.id sometimes is nil
				if (MonitorAds[owner][adtype] == nil) then
					MonitorAds[owner][adtype] = {};
				end
				MonitorAds[owner][adtype][message.id] = true;
			end
			
			-- Skills
			if (adtype == GUILDADS_MSG_TYPE_SKILL) then
				GuildAdsDB.profile.Skill:set(owner, message.id, {
					v = message.skillRank;
					m = message.skillMaxRank;
					_t = message.creationtime;
				});
				return;
			end
			
			-- Trade offer/need
			if (adtype == GUILDADS_MSG_TYPE_AVAILABLE) or (adtype == GUILDADS_MSG_TYPE_REQUEST) then
				local tmp = {
					q = message.count;
					_t = message.creationtime;
				};
				if (message.text or "")~= "" then
					tmp.c = message.text;
				end
				
				local datatype;
				if adtype == GUILDADS_MSG_TYPE_AVAILABLE then
					datatype = GuildAdsDB.channel[channelName].TradeOffer;
				else
					datatype = GuildAdsDB.channel[channelName].TradeNeed;
				end
				
				if (message.itemRef) then 
					datatype:set(owner, message.itemRef, tmp);
				end
				return;
			end
			
			
			-- Events
			if (adtype == GUILDADS_MSG_TYPE_EVENT) then
				GuildAdsDB.channel[GuildAds.channelName].SimpleEvent:set(owner, message.text, { id=message.id, _t=message.creationtime} );
				return;
			end
			
		end
	end;
	
	[GUILDADS_MSG_REMOVE] = function()
		-- Ignore this owner ?
		if GuildAdsDB.channel[channelName]:isPlayerAllowed(owner) then
			-- A previously placed add is being removed
			if (adtype == GUILDADS_MSG_TYPE_SKILL) then
				GuildAdsDB.profile.Skill:delete(owner, message.id);
			elseif (adtype == GUILDADS_MSG_TYPE_REQUEST) then
				if message.itemRef then
					GuildAdsDB.TradeNeed:delete(owner, message.itemRef);	-- TODO: doesn't work
				end
			elseif (adtype == GUILDADS_MSG_TYPE_AVAILABLE) then
				if message.itemRef then
					GuildAdsDB.TradeOffer:delete(owner, message.itemRef);	-- TODO: doesn't work
				end
			elseif (adtype == GUILDADS_MSG_TYPE_EVENT) then
				GuildAdsDB.channel[GuildAds.channelName].SimpleEvent:delete(owner, message.text); -- TODO: doesn't work
			end
		end
	end;
	
	[GUILDADS_MSG_REQUEST_INSPECT] = function()
		if GuildAdsDB.channel[channelName]:isPlayerAllowed(owner) then
			-- Send inspect to the author
			-- Always my inventory
			GAC_SendInspect(author);
		end
	end;
	
	[GUILDADS_MSG_REQUEST_OFFLINES] = function()
		if GuildAdsDB.channel[channelName]:isPlayerAllowed(owner) then
			GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "Offline sync with "..author);
			-- Pour chaque personne offline
			-- -> envois la date du dernier message
			for player in GuildAdsDB.channel[channelName]:getPlayers() do
				if not GuildAdsComm:IsOnLine(player) and GuildAdsDB.channel[channelName]:isPlayerAllowed(player) then
					GAC_SendLastSeen(author, player, GAC_ProfileGetUpdatedDate(player));
				end
			end
			GAC_SendLastSeenEnd(author);
		end
	end;
	
	[GUILDADS_MSG_LASTSEEN] = function()
		if (owner~=playerName) and LastSeens[author] and GuildAdsDB.channel[channelName]:isPlayerAllowed(owner) then
			LastSeens[author][owner] = true;
			local myUpdate = GAC_ProfileGetUpdatedDate(owner);
			if (message.creationtime ~= myUpdate) then
				if (myUpdate) then
					if (message.creationtime==nil or message.creationtime < myUpdate) then
						GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"LastSeen("..owner..")="..tostring(message.creationtime).."<"..tostring(myUpdate));
						-- on doit faire la mise à jour pour tout le monde
						GAC_SendAllAdsType(nil, owner);
					elseif (message.creationtime > myUpdate) then
						GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"LastSeen("..owner..")="..tostring(message.creationtime)..">"..tostring(myUpdate));
						-- on doit récupérer la mise à jour
						tinsert(WaitingOfflinesAds, owner);
					end
				else
					GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"LastSeen("..owner..")="..tostring(message.creationtime).."/"..tostring(myUpdate));
					-- on doit récupérer la mise à jour
					tinsert(WaitingOfflinesAds, owner);
				end
			end
		end
	end;
	
	[GUILDADS_MSG_LASTSEEN_END] = function()
		if LastSeens[author] and GuildAdsDB.channel[channelName]:isPlayerAllowed(author) then
			-- envois les annonces des joueurs non connus.
			for player in GuildAdsDB.channel[channelName]:getPlayers() do
				-- si ad.owner est offline et non connu par author
				-- alors on envois ses informations à propos de ad.owner
				-- TODO : peut etre extrement long (~15 annonces x 100 x 30 octets -> 1500x30 -> 45000 octets a envoyer
				if (not GuildAdsComm:IsOnLine(player) and LastSeens[author][player]==nil) then
					GAC_SendAllAdsType(nil, player);
				end
			end
			
			-- Dernier message de author à propos des offlines
			-- Donc on n'écoute plus les message de author
			LastSeens[author] = nil;
			
			--
			if (table.getn(WaitingOfflinesAds) > 0) then
				-- demande de mise à jour pour soi.
				for _, owner in WaitingOfflinesAds do
					GAC_SendRequestAds(author, owner);
				end
			else
				-- aucune demande de offlines
				-- on est donc synchro : passage a l'etat OK
				GuildAdsSystem.SynchronizeOfflinesTimer = nil;
				MyState = GUILDADS_STATE_OK;
				GAC_SendMeta(nil);
			end
		end
	end;
	
	[GUILDADS_MSG_REQUEST_ADS] = function()
		-- Someone is requesting ads, probably just arrived in the channel
		-- if message.owner is set : owner's ads
		-- if message.owner is nil : my ads (send my ads in few seconds)
		-- owner is meaningless
		if GuildAdsDB.channel[channelName]:isPlayerAllowed(owner) then
			if (author ~= playerName) then
				if message.owner then
					GAC_SendAllAdsType(author, message.owner);
				else
					GAC_SendMeta(author);
					GAC_SendChatFlag(author);
					GAC_SendAllAdsType(author, nil, math.random(20));
				end
			end
		end
	end;
	
	[GUILDADS_MSG_SENDING_UPDATE] = function()
		WatingForUpdate[owner] = (WatingForUpdate[owner] or 0) + message.count;
	end;
	
	[GUILDADS_MSG_SENDING_ALL] = function()
		if GuildAdsDB.channel[channelName]:isPlayerAllowed(owner) then
			-- Start recording each update ads
			if message.owner then
				-- Accept offline ads from owner we need. (see GUILDADS_MSG_LASTSEEN)
				i = 1;
				while WaitingOfflinesAds[i] and WaitingOfflinesAds[i]~=owner do
					i = i+1;
				end
				if  WaitingOfflinesAds[i] and WaitingOfflinesAds[i]==owner then
					MonitorAds[owner] = {};
				end
				
				-- accept new ads from author who are in GUILDADS_STATE_SYNC_OFFLINE state.
				-- TODO : A verifier : c'est un OR actuellement avec le if precedent, ca devrait être un AND ?
				if MetaPlayers[author] and MetaPlayers[author].state==GUILDADS_STATE_SYNC_OFFLINE then
					MonitorAds[owner] = {};
				end
			else
				-- online synchronization : ok
				MonitorAds[owner] = {};
			end
		end
	end;
	
	[GUILDADS_MSG_SENDING_ALL_END] = function()
		if MonitorAds[owner] and GuildAdsDB.channel[channelName]:isPlayerAllowed(owner) then
		
			-- Update profile date
			if owner then
				GAC_ProfileSetUpdatedDate(owner, message.creationtime);
			end
			
			-- about skills
			if MonitorAds[owner][GUILDADS_MSG_TYPE_SKILL]==nil then
				GuildAdsDB.profile.Skill:delete(owner);
			else
				for _, id in GuildAdsDB.profile.Skill:iterator(owner) do
					if MonitorAds[owner][GUILDADS_MSG_TYPE_SKILL][id] == nil then
						GuildAdsDB.profile.Skill:delete(owner, id);
					end
				end
			end;
			
			-- about trade offer
			if MonitorAds[owner][GUILDADS_MSG_TYPE_AVAILABLE]==nil then
				GuildAdsDB.channel[channelName].TradeOffer:delete(owner);
			else
				for _, id in GuildAdsDB.channel[channelName].TradeOffer:iterator(owner) do
					if MonitorAds[owner][GUILDADS_MSG_TYPE_AVAILABLE][id] == nil then
						GuildAdsDB.channel[channelName].TradeOffer:delete(owner, id);
					end
				end
			end;
			
			-- about trade need
			if MonitorAds[owner][GUILDADS_MSG_TYPE_REQUEST]==nil then
				GuildAdsDB.channel[channelName].TradeNeed:delete(owner);
			else
				for _, id in GuildAdsDB.channel[channelName].TradeNeed:iterator(owner) do
					if MonitorAds[owner][GUILDADS_MSG_TYPE_REQUEST][id] == nil then
						GuildAdsDB.channel[channelName].TradeNeed:delete(owner, id);
					end
				end
			end;
			
			-- about events
			if MonitorAds[owner][GUILDADS_MSG_TYPE_EVENT]==nil then
				GuildAdsDB.channel[channelName].SimpleEvent:delete(owner);
			else
				for _, id in GuildAdsDB.channel[channelName].SimpleEvent:iterator(owner) do
					if MonitorAds[owner][GUILDADS_MSG_TYPE_EVENT][id] == nil then
						GuildAdsDB.channel[channelName].SimpleEvent:delete(owner, id);
					end
				end
			end;
			
			-- stop monitoring
			MonitorAds[owner] = nil;
			
			-- Unstack owner in WatingOfflineAds
			-- if this is the last, we are sync
			-- so set state to GUILDADS_STATE_OK
			i = 1;
			while WaitingOfflinesAds[i] and WaitingOfflinesAds[i]~=owner do
				i = i+1;
			end
			if WaitingOfflinesAds[i] and WaitingOfflinesAds[i]==owner then
				table.remove(WaitingOfflinesAds, i);
				if (table.getn(WaitingOfflinesAds)==0) then
					GuildAdsSystem.SynchronizeOfflinesTimer = nil;
					MyState = GUILDADS_STATE_OK;
					GAC_SendMeta(nil);
				end
			end
			
		end
	end;
	
	[GUILDADS_MSG_REMOVE_ALL] = function()
		if GuildAdsDB.channel[channelName]:isPlayerAllowed(owner) then
			-- Remove all the ads from the owner
			GuildAdsDB.channel[channelName]:deletePlayer(owner);
			GuildAdsDB.channel[channelName].TradeNeed:delete(owner);
			GuildAdsDB.channel[channelName].TradeOffer:delete(owner);
			GuildAdsDB.channel[channelName].SimpleEvent:delete(owner);
		end
	end;
	
	[GUILDADS_MSG_META] = function()
		if GuildAdsDB.channel[channelName]:isPlayerAllowed(author) then
			MetaPlayers[author] = {
				state = message.id;
				onlineSince = message.creationtime;
				version = message.text;
			};
		end
	end;
	
	[GUILDADS_MSG_CHATFLAG] = function()
		if author~=playerName then
			SimpleComm_SetFlag(author, message.flag, message.text);
		end
	end;
	
}

--------------------------------------------------------------------------------
--
-- Register/Unregister new command
-- 
---------------------------------------------------------------------------------
function GAC_RegisterCommand(command, serializeInfo, onMessage)
	if SerializeCommand[command] then
		return false, "command("..command..") already registered";
	else
		if  type(onMessage) == "function" then
			if type(serializeInfo) == "table" then
				for _, spec in serializeInfo do
					if type(spec.key)~="string" or type(spec.fin)~="function" or type(spec.fout)~="function" then
						if type(spec.key)=="string" then
							return false, "serializeInfo["..spec.key.."]="..type(spec.fin)..","..type(spec.fout);
						else
							return false, "serializeInfo[??]="..type(spec.fin)..","..type(spec.fout);
						end
					end
				end
				SerializeCommand[command] = serializeInfo;
				OnMessageCommand[command] = onMessage;
				return true;
			else
				return false, "type(serializeInfo)="..type(serializeInfo);
			end
		else
			return false, "type(onMessage)="..type(onMessage);
		end
	end
end

function GAC_UnregisterCommand(command)
	SerializeCommand[command] = nil;
	OnMessageCommand[command] = nil;
end

function GAC_IsRegisteredCommand(command)
	if SerializeCommand[command] then
		return true, SerializeCommand[command], OnMessageCommand[command];
	else
		return false;
	end
end

--------------------------------------------------------------------------------
--
-- Register/Unregister new ad type
-- 
---------------------------------------------------------------------------------
function GAC_RegisterAdtype(adtype, serializeInfo, onMessage)
	if SerializeAd[adtype] then
		return false, "adtype("..command..") already registered";
	else
		if type(onMessage) == "function" then
			if type(serializeInfo) == "table" then
				for _, spec in serializeInfo do
					if type(spec.key)~="string" or type(spec.fin)~="function" or type(spec.fout)~="function" then
						return false, "serializeInfo["..spec.key.."]="..type(spec.fin)..","..type(spec.fout);
					end
				end
				SerializeAd[adtype] = serializeInfo;
				OnMessageAd[adtype] = onMessage;
				return true;
			else
				return false, "type(serializeInfo)="..type(serializeInfo);
			end
		else
			return false, "type(onMessage)="..type(onMessage);
		end
	end
end

function GAC_UnregisterAdtype(adtype)
	SerializeAd[adtype] = nil;
	OnMessageAd[adtype] = nil;
end

function GAC_IsRegisteredAdtype(adtype)
	if SerializeCommand[adtype] then
		return true, SerializeAd[adtype], OnMessageAd[adtype];
	else
		return false;
	end
end

--------------------------------------------------------------------------------
--
-- Serialize/Unserialize 
-- 
---------------------------------------------------------------------------------
function SerializeId(obj)
	if obj == nil then
		return "";
	else
		return obj
	end
end

function UnserializeId(str)
	return str;
end

function SerializeString(obj)
	if obj == nil then
		return "";
	else
		return obj
	end
end

function UnserializeString(str)
	if str == "" then
		return nil;
	else
		return str
	end
end

function SerializeTexture(obj)
	if obj == nil then
		return "";
	else
		return string.gsub(obj, "Interface\\Icons\\", "\@");
	end
end

function UnserializeTexture(str)
	if str == "" then
		return nil;
	else
		return string.gsub(str, "\@", "Interface\\Icons\\");
	end
end

function SerializeItemRef(obj)
	if obj == nil then
		return "";
	else
		return string.gsub(string.gsub(obj, "item\:", "\@"), ":0:0:0", "\*");
	end
end

function UnserializeItemRef(str)
	if str == "" then
		return nil;
	else
		return string.gsub(string.gsub(str, "\@", "item\:"), "\*", ":0:0:0");
	end
end

local SerializeColorData = {
	["ffa335ee"]="E";
	["ff0070dd"]="R";
	["ff1eff00"]="U";
	["ffffffff"]="C";
	["ff9d9d9d"]="P";
};

local UnserializeColorData = {
	["E"]="ffa335ee";
	["R"]="ff0070dd";
	["U"]="ff1eff00";
	["C"]="ffffffff";
	["P"]="ff9d9d9d";
};

local SerializeColorMetaTable = {
	__index = function(t, i)
		return i;
	end;
};

setmetatable(SerializeColorData, SerializeColorMetaTable);

function SerializeColor(obj)
	if obj==nil then
		return "";
	end
	return SerializeColorData[obj];
end

function UnserializeColor(str)
	if str==nil then
		return nil
	end;
	return UnserializeColorData[str];
end

-- TODO : utiliser base 64 ou base 128
function SerializeInteger(obj)
	if obj == nil then
		return "";
	else
		return obj;
	end
end

function UnserializeInteger(str)
	return tonumber(str);
end

-- TODO : utiliser base 64 ou base 128
function SerializeTime(obj)
	if obj == nil then
		return "";
	else
		if type(obj)=="table" then
			error("table table", 5);
		end
		-- convertion en base 52
		value = "";
		while (obj ~= 0) do
			i = math.floor(obj / 52);
			j = obj - i*52;
			if (j>=26) then
				value = string.char(65+j-26)..value;
			else
				value = string.char(96+j)..value;
			end
			obj = i;
		end
		return value;
	end
end

function UnserializeTime(str)
	if str == "" then
		return nil;
	else
		number = 0;
		for i=1, string.len(str),1  do
			o = string.byte(str, i);
			if (o> 95) then
				j = o-96;
			else
				j = o-65+26;
			end
			number = number*52 + j;
		end
		return number;
	end
end

function SerializeObj(obj)
	if obj == nil then 
		return "";
	elseif ( type(obj) == "string" ) then
		return "s"..string.gsub(string.gsub(string.gsub(obj, ">", "&gt;"), "|([cHhr])", "&%1;"), "|", "&p;");
	elseif ( type(obj) == "number" ) then
		return "n"..obj;
	elseif ( type(obj) == "boolean" ) then
		if  (value) then
			return "1";
		else
			return "0";
		end
	elseif ( type(obj) == "function" ) then
		return ""; -- nil
	elseif ( type(obj) == "table" ) then
		return ""; -- nil
	end
	return "";
end

function UnserializeObj(str)
	if (str == "") then
		return nil;
	else
		typeString = string.sub(str, 0, 1);
		valueString = string.sub(str, 2);
		if (typeString == "s") then
			return string.gsub(string.gsub(string.gsub(valueString, "&gt;", ">"), "&(%w);", "|%1"), "&p;", "|");
		elseif (typeString == "n") then
			return tonumber(valueString);
		elseif (typeString == "1") then
			return true;
		elseif (typeString == "0") then
			return false;
		else
			GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"GuildAds_Unserialize: Type non reconnu:"..str);
			return nil;
		end
	end
end

local t = {};
function SerializeTable(s, o)
	table.setn(t, table.getn(s));
	local l;
	for i, d in ipairs(s) do
		t[i] = d.fout(o[d.key]);
		if t[i] ~= "" then
			l = i;
		end
	end
	if l then
		return table.concat(t, ">", 1, l)..">";
	else
		return "";
	end
end

local serializeResult = { GUILDADS_MSG_PREFIX };
function GuildAds_Serialize(o)
	o.currenttime = GuildAdsDB:GetCurrentTime();
	table.setn(serializeResult, 1);
	table.insert(serializeResult, SerializeTable(SerializeMeta, o));
	if SerializeCommand[o.command] then
		table.insert(serializeResult, SerializeTable(SerializeCommand[o.command], o));
		if o.command == GUILDADS_MSG_ADD then
			table.insert(serializeResult, SerializeTable(SerializeAd[o.adtype], o));
		end
	end
	return table.concat(serializeResult);
end

function GuildAds_Unserialize(text)
	local o;
	
	local j=0;
	local s;
	local i=1;
	local m=1;
	
	for str in string.gfind(text, GUILDADS_MSG_REGEX_UNSERIALIZE) do
		if j>0 then
			o = o or {};
			local d = s[i];
			o[d.key] = d.fin(str);
		else
			if str~=GUILDADS_MSG_PREFIX1 then
				return;
			end
		end
		
		i = i + 1;
		if i>m then
			j=j+1;
			if j==1 then
				s=SerializeMeta;
			elseif j==2 and o.command and SerializeCommand[o.command] then
				s=SerializeCommand[o.command];
			elseif j==3 and o.adtype and SerializeAd[o.adtype] then
				s=SerializeAd[o.adtype];
			else
				break;
			end
			i=1;
			m=table.getn(s);
		end
	end
	
	return o;
end

function GuildAds_SplitSerialize(packetNumber, last, obj)
	if last then
		return GUILDADS_MSG_PREFIX .. packetNumber ..":".. obj;
	else
		return GUILDADS_MSG_PREFIX .. packetNumber ..".".. obj;
	end
end

function GuildAds_UnsplitSerialize(str)
	local iStart, _ , packetNumber, last, packet = string.find(str, GUILDADS_MSG_PREFIX_REGEX_UNSPLIT);
	if iStart then
		return packet, tonumber(packetNumber), last==":";
	end
	return str;
end

function GuildAds_FilterText(text)
	return string.sub(text, 1, string.len(GUILDADS_MSG_PREFIX_NOVERSION)) == GUILDADS_MSG_PREFIX_NOVERSION;
end

--------------------------------------------------------------------------------
--
-- Serialize Spec
-- 
---------------------------------------------------------------------------------
SerializeMeta = {
		[1]  = { ["key"] ="command", 	["fout"]=SerializeId, 		["fin"]=UnserializeId }
	};
	
SerializeCommand = {
		[GUILDADS_MSG_ADD] = {
				[1] = { ["key"]="owner", 			["fout"]=SerializeString,	["fin"]=UnserializeString },
				[2] = { ["key"]="adtype",			["fout"]=SerializeInteger,	["fin"]=UnserializeInteger },
				[3] = { ["key"]="id", 				["fout"]=SerializeObj,		["fin"]=UnserializeObj },
				[4] = { ["key"]="currenttime",		["fout"]=SerializeTime,		["fin"]=UnserializeTime},
				[5] = { ["key"]="creationtime", 	["fout"]=SerializeTime,		["fin"]=UnserializeTime},
			},
		[GUILDADS_MSG_REMOVE] = {
				[1] = { ["key"] ="owner", 			["fout"]=SerializeString,	["fin"]=UnserializeString },
				[2] = { ["key"] ="adtype",			["fout"]=SerializeInteger,	["fin"]=UnserializeInteger },
				[3] = { ["key"] ="id", 				["fout"]=SerializeObj,		["fin"]=UnserializeObj },
			},
		[GUILDADS_MSG_REMOVE_ALL] = {
				[1]  = { ["key"] ="owner", 			["fout"]=SerializeString,	["fin"]=UnserializeString },
			},
		[GUILDADS_MSG_REQUEST_ADS] = {
				[1]  = { ["key"] ="owner", 			["fout"]=SerializeString,	["fin"]=UnserializeString },
			},
		[GUILDADS_MSG_REQUEST_OFFLINES] = {},
		[GUILDADS_MSG_REQUEST_INSPECT] = {},
		[GUILDADS_MSG_SENDING_UPDATE] = {
				[1] = { ["key"] ="owner", 			["fout"]=SerializeString,	["fin"]=UnserializeString },
				[2] = { ["key"] ="count", 			["fout"]=SerializeInteger, 	["fin"]=UnserializeInteger },
			},
		[GUILDADS_MSG_SENDING_ALL] = {
				[1] = { ["key"] ="owner", 			["fout"]=SerializeString,	["fin"]=UnserializeString },
			},
		[GUILDADS_MSG_SENDING_ALL_END] = { -- currenttime, profiletime
				[1] = { ["key"] ="owner", 			["fout"]=SerializeString,	["fin"]=UnserializeString },
				[2] = { ["key"] ="currenttime",		["fout"]=SerializeTime,		["fin"]=UnserializeTime},
				[3] = { ["key"] ="creationtime", 	["fout"]=SerializeTime,		["fin"]=UnserializeTime },
			},
		[GUILDADS_MSG_LASTSEEN] = {  -- currenttime, profiletime
				[1] = { ["key"] ="owner", 			["fout"]=SerializeString,	["fin"]=UnserializeString },
				[2] = { ["key"] ="currenttime",		["fout"]=SerializeTime,		["fin"]=UnserializeTime},
				[3] = { ["key"] ="creationtime",	["fout"]=SerializeTime,		["fin"]=UnserializeTime },
			},
		[GUILDADS_MSG_LASTSEEN_END] = {},
		[GUILDADS_MSG_META] = { -- currenttime, version, starttime, id
				[1] = { ["key"] ="currenttime",		["fout"]=SerializeTime,		["fin"]=UnserializeTime},
				[2] = { ["key"] ="text", 			["fout"]=SerializeString,	["fin"]=UnserializeString },
				[3] = { ["key"] ="creationtime", 	["fout"]=SerializeTime,		["fin"]=UnserializeTime },
				[4] = { ["key"] ="id", 				["fout"]=SerializeId,		["fin"]=UnserializeId },
			},
		[GUILDADS_MSG_CHATFLAG] = { -- flag, text
				[1] = { ["key"] ="flag",		    ["fout"]=SerializeString,   ["fin"]=UnserializeString},
				[2] = { ["key"] ="text", 			["fout"]=SerializeString,	["fin"]=UnserializeString },
			},
	};


SerializeAd = {
		[GUILDADS_MSG_TYPE_ANNONCE] = { -- accountId, class, race, level, guild
				[1]  = { ["key"] ="accountId", 		["fout"]=SerializeObj,		["fin"]=UnserializeObj },
				[2]  = { ["key"] ="class", 			["fout"]=SerializeInteger,	["fin"]=UnserializeInteger },
				[3]  = { ["key"] ="race", 			["fout"]=SerializeInteger,	["fin"]=UnserializeInteger },
				[4]  = { ["key"] ="level",			["fout"]=SerializeInteger,	["fin"]=UnserializeInteger },
				[5]  = { ["key"] ="guild",			["fout"]=SerializeString,	["fin"]=UnserializeString },
			},
		[GUILDADS_MSG_TYPE_INVENTORY] = { -- itemRef, itemName, itemColor, count, texture
				[1] = { ["key"] ="itemColor", 		["fout"]=SerializeColor,	["fin"]=UnserializeColor },
				[2] = { ["key"] ="itemRef", 		["fout"]=SerializeItemRef,	["fin"]=UnserializeItemRef },
				[3] = { ["key"] ="itemName", 		["fout"]=SerializeString,	["fin"]=UnserializeString },
				[4] = { ["key"] ="count", 			["fout"]=SerializeInteger, 	["fin"]=UnserializeInteger },
				[5] = { ["key"] ="texture", 		["fout"]=SerializeTexture, 	["fin"]=UnserializeTexture },				
			},
		[GUILDADS_MSG_TYPE_SKILL] = { -- skillRank , skillMaxRank
				[1] = { ["key"] ="skillRank", 		["fout"]=SerializeInteger, 	["fin"]=UnserializeInteger },
				[2] = { ["key"] ="skillMaxRank", 	["fout"]=SerializeInteger, 	["fin"]=UnserializeInteger },				
			},
		[GUILDADS_MSG_TYPE_REQUEST] = { -- text, itemRef, itemName, itemColor, count, texture
				[1] = { ["key"] ="text", 			["fout"]=SerializeObj,		["fin"]=UnserializeObj },
				[2] = { ["key"] ="itemColor", 		["fout"]=SerializeColor,	["fin"]=UnserializeColor },
				[3] = { ["key"] ="itemRef", 		["fout"]=SerializeItemRef,	["fin"]=UnserializeItemRef },
				[4] = { ["key"] ="itemName", 		["fout"]=SerializeString,	["fin"]=UnserializeString },
				[5] = { ["key"] ="count", 			["fout"]=SerializeInteger, 	["fin"]=UnserializeInteger },
				[6] = { ["key"] ="texture", 		["fout"]=SerializeTexture, 	["fin"]=UnserializeTexture },
			},
		[GUILDADS_MSG_TYPE_AVAILABLE] ={ -- text, itemRef, itemName, itemColor, count, texture
				[1] = { ["key"] ="text", 			["fout"]=SerializeObj,		["fin"]=UnserializeObj },
				[2] = { ["key"] ="itemColor", 		["fout"]=SerializeColor,	["fin"]=UnserializeColor },
				[3] = { ["key"] ="itemRef", 		["fout"]=SerializeItemRef,	["fin"]=UnserializeItemRef },
				[4] = { ["key"] ="itemName", 		["fout"]=SerializeString,	["fin"]=UnserializeString },
				[5] = { ["key"] ="count", 			["fout"]=SerializeInteger, 	["fin"]=UnserializeInteger },
				[6] = { ["key"] ="texture", 		["fout"]=SerializeTexture, 	["fin"]=UnserializeTexture },
			},
		[GUILDADS_MSG_TYPE_EVENT] = { -- text
				[1] = { ["key"] ="text", 			["fout"]=SerializeObj,		["fin"]=UnserializeObj },
				[2] = { ["key"] ="eventtime", 		["fout"]=SerializeTime,		["fin"]=UnserializeTime },
				[3] = { ["key"] ="note", 			["fout"]=SerializeString,	["fin"]=UnserializeString },
				[4] = { ["key"] ="count", 			["fout"]=SerializeInteger,	["fin"]=UnserializeInteger },
				[5] = { ["key"] ="minlevel", 		["fout"]=SerializeInteger,	["fin"]=UnserializeInteger },
				[6] = { ["key"] ="maxlevel", 		["fout"]=SerializeInteger,	["fin"]=UnserializeInteger },
			},
		[GUILDADS_MSG_TYPE_EVENT_SUBSCRIPTION] = {
				[1] = { ["key"] ="eventid", 		["fout"]=SerializeInteger,	["fin"]=UnserializeInteger },
		}
	};

-- export
GAC_SerializeObj = SerializeObj;
GAC_UnserializeObj = UnserializeObj;

GAC_SerializeString = SerializeString;
GAC_UnserializeString = UnserializeString;

GAC_SerializeInteger = SerializeInteger;
GAC_UnserializeInteger = UnserializeInteger;

GAC_SerializeColor = SerializeColor;
GAC_UnserializeColor = UnserializeColor;


------------------------------------
GuildAdsComm = AceModule:new({
	hasJoined = {},
	isOnline = {},
	playerList = {},
	channelName = "",
	channelPassword = ""
});

function GuildAdsComm:Initialize()
	SimpleComm_PreInit(
		GuildAds_FilterText,
		GuildAds_Serialize,
		GuildAds_Unserialize,
		GuildAds_SplitSerialize,
		GuildAds_UnsplitSerialize,
		GAC_Synchronize,
		GAC_OnChannelLeave,
		GAC_OnMessage
	);
	
	self:RegisterEvent("CHAT_MSG_CHANNEL_JOIN");
	self:RegisterEvent("CHAT_MSG_CHANNEL_LEAVE");	
end

function GuildAdsComm:JoinChannel(channel, password)
	self.channelName = string.lower(channel)
	self.channelPassword = password
end

function GuildAdsComm:CHAT_MSG_CHANNEL_JOIN()
	-- TODO : Un joueur vient d'arrive sur le channel
	if self.channelName==string.lower(arg9) then
		self.hasJoined[arg2] = GuildAdsDB:GetCurrentTime()
	end
end
	
function GuildAdsComm:CHAT_MSG_CHANNEL_LEAVE()
	-- Un joueur vient de quitter le channel 
	-- Mise à jour du statut online
	GuildAdsComm:SetOnlineStatus(arg2, false)
	self.hasJoined[arg2] = false
end

--------------------------------------------------------------------------------
--
-- Get online status of a player
-- 
--------------------------------------------------------------------------------
function GuildAdsComm:IsOnLine(playerName)
	if self.isOnline[playerName] then
		return true;
	else
		return false;
	end
end

--------------------------------------------------------------------------------
--
-- Get tree info about a player (parent player, and child players)
-- parent : .p
-- childs : .c1, .c2
-- 
--------------------------------------------------------------------------------
function GuildAdsComm:GetTreeInfo(playerName)
	return self.isOnline[playerName];
end

--------------------------------------------------------------------------------
--
-- Update tree
-- 
--------------------------------------------------------------------------------
function GuildAdsComm:_UpdateTree()
	local p, c;
	table.sort(self.playerList);
	for i, playerName in ipairs(self.playerList) do
		p = i>1 and bit.rshift(i, 1);
		c = bit.lshift(i, 1);
		if type(self.isOnline[playerName]) == "table" then
			self.isOnline[playerName].p = self.playerList[p];
			self.isOnline[playerName].c1 = self.playerList[c];
			self.isOnline[playerName].c2 = self.playerList[c+1];
		else
			self.isOnline[playerName] = { p=self.playerList[p], c1=self.playerList[c], c2=self.playerList[c+1] };
		end
	end
end

--------------------------------------------------------------------------------
--
-- Set online status of a player
-- 
--------------------------------------------------------------------------------
function GuildAdsComm:SetOnlineStatus(playerName, status)
	if status then
		if (not self.isOnline[playerName]) then
			table.insert(self.playerList, playerName);
			self:_UpdateTree();
			if self.hasJoined[playerName] then
				self.hasJoined[playerName] = nil;
				GuildAdsPlugin_OnEvent(GAS_EVENT_CONNECTION, playerName, true);
			end
			GuildAdsPlugin_OnEvent(GAS_EVENT_ONLINE, playerName, true);
		end
	else
		if (self.isOnline[playerName]) then
			self.isOnline[playerName] = nil;
			local f = function(i, p) 
				if p==playerName then 
					return i 
				end
			end;
			table.remove(self.playerList, table.foreach(self.playerList, f));
			self:_UpdateTree();
			GuildAdsPlugin_OnEvent(GAS_EVENT_ONLINE, playerName, false);
			GuildAdsPlugin_OnEvent(GAS_EVENT_CONNECTION, playerName, false);
		end
	end
end

function GuildAdsComm:GetWeight()
	local fps = GetFramerate()
	local _, _, lag = GetNetStats();
	return fps*(1000-lag);
end