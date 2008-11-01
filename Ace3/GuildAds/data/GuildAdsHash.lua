----------------------------------------------------------------------------------
--
-- GuildAdsHash.lua
--
-- Author: Galmok of European Stormrage (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com, galmok@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

local bit_rshift = bit.rshift
local bit_band = bit.band
local bit_lshift = bit.lshift
local bit_bor = bit.bor
local bit_bxor = bit.bxor
local string_sub = string.sub
local table_insert = table.insert
local table_concat = table.concat
local string_format = string.format
local string_byte = string.byte

-- dont make new empty tables all the time (used by ReceiveSearch)
local emptytable = {}

GuildAdsHash={};

function GuildAdsHash:Initialize()
	self.maxRecurse = 3;
	self.hashMask=2^(self.maxRecurse*4)-1;
	self:InitSplitHash();
	self.DT=GuildAdsHash:GetDatatypes();
	self:DeleteAllSearches();

	--[[/* The following copyright notice concerns only the FCS hash algorithm
	---------------------------------------------------------------------------
	Copyright (c) 2003, Dominik Reichl <dominik.reichl@t-online.de>, Germany.
	All rights reserved.
	
	Distributed under the terms of the GNU General Public License v2.
	
	This software is provided 'as is' with no explicit or implied warranties
	in respect of its properties, including, but not limited to, correctness
	and/or fitness for purpose.
	---------------------------------------------------------------------------
	*/]]
	--// FCS-16 algorithm implemented as described in RFC 1331
	self.FCSINIT16 = 65535;
	--// Fast 16 bit FCS lookup table
	self.fcs16tab = { 0, 4489, 8978, 12955, 17956, 22445, 25910, 29887, 35912, 40385, 44890, 48851, 51820, 56293, 59774, 63735, 4225, 264, 13203, 8730, 22181, 18220, 30135, 25662, 40137, 36160, 49115, 44626, 56045, 52068, 63999, 59510, 8450, 12427, 528, 5017, 26406, 30383, 17460, 21949, 44362, 48323, 36440, 40913, 60270, 64231, 51324, 55797, 12675, 8202, 4753, 792, 30631, 26158, 21685, 17724, 48587, 44098, 40665, 36688, 64495, 60006, 55549, 51572, 16900, 21389, 24854, 28831, 1056, 5545, 10034, 14011, 52812, 57285, 60766, 64727, 34920, 39393, 43898, 47859, 21125, 17164, 29079, 24606, 5281, 1320, 14259, 9786, 57037, 53060, 64991, 60502, 39145, 35168, 48123, 43634, 25350, 29327, 16404, 20893, 9506, 13483, 1584, 6073, 61262, 65223, 52316, 56789, 43370, 47331, 35448, 39921, 29575, 25102, 20629, 16668, 13731, 9258, 5809, 1848, 65487, 60998, 56541, 52564, 47595, 43106, 39673, 35696, 33800, 38273, 42778, 46739, 49708, 54181, 57662, 61623, 2112, 6601, 11090, 15067, 20068, 24557, 28022, 31999, 38025, 34048, 47003, 42514, 53933, 49956, 61887, 57398, 6337, 2376, 15315, 10842, 24293, 20332, 32247, 27774, 42250, 46211, 34328, 38801, 58158, 62119, 49212, 53685, 10562, 14539, 2640, 7129, 28518, 32495, 19572, 24061, 46475, 41986, 38553, 34576, 62383, 57894, 53437, 49460, 14787, 10314, 6865, 2904, 32743, 28270, 23797, 19836, 50700, 55173, 58654, 62615, 32808, 37281, 41786, 45747, 19012, 23501, 26966, 30943, 3168, 7657, 12146, 16123, 54925, 50948, 62879, 58390, 37033, 33056, 46011, 41522, 23237, 19276, 31191, 26718, 7393, 3432, 16371, 11898, 59150, 63111, 50204, 54677, 41258, 45219, 33336, 37809, 27462, 31439, 18516, 23005, 11618, 15595, 3696, 8185, 63375, 58886, 54429, 50452, 45483, 40994, 37561, 33584, 31687, 27214, 22741, 18780, 15843, 11370, 7921, 3960 }
end

function GuildAdsHash:fcs16init()
	return self.FCSINIT16;
end

function GuildAdsHash:fcs16update(uFcs16, pBuffer)
	local i
	local l=string.len(pBuffer)
	for i = 1,l do
		uFcs16 = bit_bxor(bit_rshift(uFcs16,8), self.fcs16tab[bit_band(bit_bxor(uFcs16, string_byte(pBuffer,i)), 255)+1])
	end
	return uFcs16
end

function GuildAdsHash:fcs16final(uFcs16)
	return bit_bxor(uFcs16,65535)
end
-- END OF FCS16

function GuildAdsHash:CalculateHash(ID)
	local hashID;
	hashID=self:fcs16init();
	hashID=self:fcs16update(hashID,ID);
	hashID=self:fcs16final(hashID);
	return bit_band(hashID,GuildAdsHash.hashMask);
end

function GuildAdsHash:GetDatatypes()
	local DT;
	DT={}
	for name, profileDT in pairs(GuildAdsDB.profile) do
		DT[name]=profileDT;
	end
	for name, channelDT in pairs(GuildAdsDB.channel[GuildAds.channelName]) do
		if type(channelDT)=="table" and channelDT.metaInformations and name~="db" then
			DT[name]=channelDT;
		end
	end
	return DT
end

function GuildAdsHash:getID(playerName, dataTypeName)
	return playerName.."/"..dataTypeName;
end

function GuildAdsHash:CreateEmptyHashTree(level)
	local i;
	local tree={};
	if level>2 then
		for i=0,15,1 do
			tree[i]=GuildAdsHash:CreateEmptyHashTree(level-1);
		end	
	elseif level>1 then
		for i=0,15,1 do
			tree[i]={};
		end
	end
	return tree;
end

function GuildAdsHash:RemoveNumberPlayers()
	players = GuildAdsDB.channel[GuildAds.channelName]:getPlayers();
	for playerName in pairs(players) do
		if tostring(playerName):match("[0-9]+") then
			GuildAdsDB.channel[GuildAds.channelName]:deletePlayer(playerName);
		end
	end
end

function GuildAdsHash:CreateHashTree()
	local tree, path, hashMask, CheckSums;
	local tmp, numIDs, numHashes, maxShared, maxV;
	
	GuildAdsHash:RemoveNumberPlayers(); -- this is to be removed eventually. Numberplayers "1", "2", etc. were inserted into the database on error. This is the cleanup.
	
	tree={};
	GuildAdsHash:setMetaTable(tree);
	
	players = GuildAdsDB.channel[GuildAds.channelName]:getPlayers();

	tmp = {}
	numIDs=0;
	numHashes=0;
	for playerName in pairs(players) do
		for dataTypeName, dataType in pairs(self.DT) do
			if dataType:getRevision(playerName) > 0 then
				ID=GuildAdsHash:getID(playerName,dataTypeName);
				hashID=GuildAdsHash:CalculateHash(ID);
				--hashID=bit.band(hashID,hashMask);
				if not tmp[hashID] then
					tmp[hashID]={ { hashID=hashID, ID=ID, p=playerName, dt=dataType } };
					numHashes=numHashes+1;
				else
					tinsert(tmp[hashID],{ hashID=hashID, ID=ID, p=playerName, dt=dataType });
					--sort(tmp[hashID],function(a,b) if a.ID<b.ID then return true; else return false; end; end);
				end
				numIDs=numIDs+1;
			end
		end
	end
	GuildAds_ChatDebug(GA_DEBUG_HASH, "Number of IDs: %i",numIDs)
	GuildAds_ChatDebug(GA_DEBUG_HASH, "Number of unique hashes: %i",numHashes) -- #tmp doesn't work for some reason
	
	maxShared=0;
	maxV=nil
	-- sort according to ID
	CheckSums = {}
	for hashID,v in pairs(tmp) do
		sort(v, function(a,b) if a.ID<b.ID then return true; else return false; end; end);
		tinsert(CheckSums,v);
		if #v>maxShared then
			maxShared=#v;
			maxV=v;
		end
	end
	-- following sort is not necessary
	--sort(CheckSums, function(a,b) if a[1].hashID<b[1].hashID then return true; else return false; end; end);
	GuildAds_ChatDebug(GA_DEBUG_HASH, "Max number of IDs on 1 hashID is %i",maxShared);
	for k,v in pairs(maxV) do
		GuildAds_ChatDebug(GA_DEBUG_HASH, "%s", v.ID); --v.p v.dt
	end
	
	-- Calculate leaf checksums
	for _,v in pairs(CheckSums) do
		h=GuildAdsHash:CalculateLeafChecksum(v);
		-- split hashID into 4 bit fields
		path=GuildAdsHash:SplitHash(v[1].hashID);
		tree[path]={ h=h, d=v};
	end
	-- Calculate level 2 and level 1 checksums
	GuildAdsHash:CalculateTreeChecksum(tree);
	return tree;
end

function GuildAdsHash:CheckHashTree()
	self.checkTree=self:CreateHashTree()
	
	-- make leaf comparisons
	local path, a, b, c
	for l1 = 0, 15 do
		for l2 = 0, 15 do
			for l3 = 0, 15 do
				path = l1..","..l2..","..l3
				a=self.tree[path]
				b=self.checkTree[path]
				if (a and not b) or (not a and b) or (a and b and a.h ~= b.h) then
					c=a or b
					ChatFrame1:AddMessage("path "..l1..","..l2..","..l3.." differs");
					for k,v in pairs(c.d) do
						ChatFrame1:AddMessage(v.ID..(a and " missing" or ""));
					end
				end
			end
		end
	end
	
	--self.checkTree=nil
end

function GuildAdsHash:CalculateLeafChecksum(leaf)
	local h;
	h=self:fcs16init();
	for _,hash in pairs(leaf) do
		h=self:fcs16update(h,hash.dt:getRevision(hash.p)); -- maybe ID should be included in the hash calculation?
	end
	return self:fcs16final(h);
end

function GuildAdsHash:InitSplitHash()
	if self.maxRecurse==1 then
		GuildAdsHash.SplitHash=GuildAdsHash.SplitHash1;
	end
	if self.maxRecurse==2 then
		GuildAdsHash.SplitHash=GuildAdsHash.SplitHash2;
	end
	if self.maxRecurse==3 then
		GuildAdsHash.SplitHash=GuildAdsHash.SplitHash3;
	end
	if self.maxRecurse==4 then
		GuildAdsHash.SplitHash=GuildAdsHash.SplitHash4;
	end
end

function GuildAdsHash:SplitHash1(hash)
	local l1;
	l1=bit_band(hash,15); -- lowest 4 bits
	return {l1};
end

function GuildAdsHash:SplitHash2(hash)
	local l1, l2;
	l1=bit_band(hash,15); -- lowest 4 bits
	l2=bit_rshift(bit_band(hash,240),4); -- next 4 bits
	return {l1, l2};
end

function GuildAdsHash:SplitHash3(hash)
	local l1, l2, l3;
	l1=bit_band(hash,15); -- lowest 4 bits
	l2=bit_rshift(bit_band(hash,240),4); -- next 4 bits
	l3=bit_rshift(bit_band(hash,4095),8); -- next 4 bits
	return {l1, l2, l3};
end

function GuildAdsHash:SplitHash4(hash)
	local l1, l2, l3, l4;
	l1=bit_band(hash,15); -- lowest 4 bits
	l2=bit_rshift(bit_band(hash,240),4); -- next 4 bits
	l3=bit_rshift(bit_band(hash,4095),8); -- next 4 bits
	l4=bit_rshift(hash,12); -- highest 4 bits
	return {l1, l2, l3, l4};
end

function GuildAdsHash:CalculateHashFromLevels(l1, l2, l3, l4)
	return bit_bor(l1, bit_bor( bit_bor( bit_lshift(l2,4), bit_lshift(l3,8) ), bit_lshift(l4,12) ));
end

function GuildAdsHash:UpdateTree(tree, playerName, dataTypeName)
	local ID, hashID, path, treepath;
	
	ID=GuildAdsHash:getID(playerName,dataTypeName);
	hashID=GuildAdsHash:CalculateHash(ID);
	
	path=GuildAdsHash:SplitHash(hashID);
	GuildAds_ChatDebug(GA_DEBUG_HASH, "path=%s",table_concat(path,","));
	
	-- is ID in tree?
	treepath=tree[path]; -- just an optimisation
	if treepath and treepath.d then
		for k,v in pairs(treepath.d) do -- small loop, with 12 bit hash (path length = 3), 500 unique ids usually gives no more than 2 loops.
			if v.ID == ID then
				-- hashID exists and contains ID: Just update leaf checksums and recalculate path checksums
				GuildAds_ChatDebug(GA_DEBUG_HASH, "ID found %s",ID);
				GuildAds_ChatDebug(GA_DEBUG_HASH, "checksum=%s (before)",treepath.h);
				treepath.h=GuildAdsHash:CalculateLeafChecksum(treepath.d);
				GuildAds_ChatDebug(GA_DEBUG_HASH, "checksum=%s (after)",treepath.h);
				GuildAdsHash:CalculatePathChecksums(tree,path);
				return; 
			end
		end
		-- hashID exists but ID wasn't there. Add ID to leaf (hashID) and sort them. Then recalculate leaf and path checksum.
		GuildAds_ChatDebug(GA_DEBUG_HASH, "hashID found %s",table_concat(path,","));
		if self.DT[dataTypeName]:getRevision(playerName) > 0 then
			tinsert(treepath.d,{ hashID=hashID, ID=ID, p=playerName, dt=self.DT[dataTypeName] });
			sort(treepath.d, function(a,b) if a.ID<b.ID then return true; else return false; end; end);
			treepath.h=GuildAdsHash:CalculateLeafChecksum(treepath.d);
			GuildAds_ChatDebug(GA_DEBUG_HASH, "checksum=%s (after)",treepath.h);
			GuildAdsHash:CalculatePathChecksums(tree,path);
		end
	else
		-- hashID doesn't exist: Create leaf (hashID) and add ID to it. Then calculate leaf and path checksum.
		GuildAds_ChatDebug(GA_DEBUG_HASH, "hashID not found. Creating %s",table_concat(path,","))
		if self.DT[dataTypeName]:getRevision(playerName) > 0 then
			GuildAds_ChatDebug(GA_DEBUG_HASH, "Path %s is not found.",table_concat(path,","));
			tree[path]={ d={ { hashID=hashID, ID=ID, p=playerName, dt=self.DT[dataTypeName] } } };
			tree[path].h=GuildAdsHash:CalculateLeafChecksum(tree[path].d);
			GuildAdsHash:CalculatePathChecksums(tree,path);
		end
	end
end

-- remove ID from tree, possibly removing the entire hash and therefor also the entire branch (all the way to the root).
function GuildAdsHash:RemoveID(tree,playerName,dataTypeName)
	-- stub so far
	local ID, hashID, path;
	
	ID=GuildAdsHash:getID(playerName, dataTypeName);
	hashID=GuildAdsHash:CalculateHash(ID);
	path=GuildAdsHash:SplitHash(hashID);
	
	if tree then
		treepath=tree[path]; -- just an optimisation
		if treepath and treepath.d then
			for k,v in pairs(treepath.d) do -- small loop, with 12 bit hash (path length = 3), 500 unique ids usually gives no more than 2 loops.
				if v.ID == ID then
					GuildAds_ChatDebug(GA_DEBUG_HASH, "ID found. Deleting %s", ID);
					treepath.d[k]=nil; -- removing an ID does not change the order. No sort necessary.
					if #treepath.d>0 then
						treepath.h=GuildAdsHash:CalculateLeafChecksum(treepath.d); -- update leaf checksum
					else
						tree[path]=nil; -- delete leaf
					end
					GuildAdsHash:CalculatePathChecksums(tree,path);
					return;
				end
			end
		end
	end
end

-- called when DB is updated by player or by transaction
function GuildAdsHash:UpdateHashTree(dataType, playerName, id)
	if GuildAdsHash.tree then
		local hashBefore=GuildAdsHash.tree[""].h
		GuildAds_ChatDebug(GA_DEBUG_HASH, "GuildAdsHash (BEFORE): roothash="..tostring(hashBefore).."   id="..tostring(id));
		
		if id then
			GuildAdsHash:UpdateTree(GuildAdsHash.tree, playerName, dataType.metaInformations.name);
		else
			GuildAdsHash:RemoveID(GuildAdsHash.tree, playerName, dataType.metaInformations.name);
		end
		
		local hashAfter=GuildAdsHash.tree[""].h
		GuildAds_ChatDebug(GA_DEBUG_HASH, "GuildAdsHash (AFTER): roothash="..tostring(hashAfter));
		if hashBefore == hashAfter then
			GuildAds_ChatDebug(GA_DEBUG_HASH, "GuildAdsHash: Hash didn't change! Did the revision change?");
		end
	end
end

-- recalculate path checksum 
function GuildAdsHash:CalculatePathChecksums(tree, path)
	local i,p,t;
	p={ [0]=tree }
	t=tree;
	for k,v in pairs(path) do
		tinsert(p,t[v]);
		t=t[v];
	end
	i=#path;
	if i>self.maxRecurse-1 then
		i=self.maxRecurse-1;
	end
	while i>=0 do
		--GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "Updating path "..i)
		GuildAdsHash:CalculateBranchChecksum(p[i]); -- does not recurse
		i=i-1;
	end
end

-- recalculate checksum for branch t (not recursive)
function GuildAdsHash:CalculateBranchChecksum(t)
	local i,h,k;
	t.h=self:fcs16init();
	k=false;
	for i=0,15,1 do
		if t[i] and t[i].h then
			t.h=self:fcs16update(t.h,t[i].h);
			k=true;
		else
			t.h=self:fcs16update(t.h,"X");
		end
	end
	if k then
		t.h=self:fcs16final(t.h);
	else
		t.h=nil; -- if the sub-branches of this branch are empty, then remove the checksum as well.
	end
end

-- recalculate all branch checksums (does not include leaf checksums)
function GuildAdsHash:CalculateTreeChecksum(tree,level)
	local i;
	level=level or 0;
	if (level+1)<self.maxRecurse then
		for i=0,15,1 do
			if tree[i] then
				GuildAdsHash:CalculateTreeChecksum(tree[i],level+1)
			end
		end
	end
	GuildAdsHash:CalculateBranchChecksum(tree);
end

function GuildAdsHash:GetHexHash(t)
	local i,s;
	s="";
	for i=0,15,1 do
		if t[i] and t[i].h then
			s=string_format("%04x",t[i].h)..s;
		else
			s="XXXX"..s;
		end
	end
	return s;
end

function GuildAdsHash:CompareHexHash(h1,h2)
	local i,r;
	r="";
	for i=1,64,4 do
		if string_sub(h1,i,i+3)==string_sub(h2,i,i+3) then
			r=r.."0";
		else
			r=r.."1";
		end
	end
	return r;
end

function GuildAdsHash:NumToBase64(n)
	local t = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ+*";
	if n<262144 then
		local c0=bit_band(n,63)+1;			-- bit 0-5
		local c1=bit_band(bit_rshift(n,6),63)+1;	-- bit 6-11
		local c2=bit_band(bit_rshift(n,12),63)+1;	-- bit 12-17
		return t:sub(c0,c0)..t:sub(c1,c1)..t:sub(c2,c2);
	end
end

function GuildAdsHash:GetBase64Hash(t)
	s={};
	for i=15,0,-1 do
		if t and t[i] and t[i].h then
			table_insert(s,GuildAdsHash:NumToBase64(t[i].h));
		else
			table_insert(s,"///"); -- no checksum for this leaf. Indicate using invalid base64 chars.
		end
	end
	return table_concat(s);
end

function GuildAdsHash:CompareBase64Hash(h1,h2)
	local i,r;
	r={};
	for i=1,48,3 do
		if string_sub(h1,i,i+2)==string_sub(h2,i,i+2) then
			table_insert(r,"0");
		else
			table_insert(r,"1");
		end
	end
	return table_concat(r);
end

function GuildAdsHash:CompareBase64HashToInteger(h1,h2)
	local i,r;
	r=0;
	for i=1,48,3 do
		if string_sub(h1,i,i+2)==string_sub(h2,i,i+2) then
			r=bit_lshift(r,1);
		else
			r=bit_bor(bit_lshift(r,1),1);
		end
	end
	return r;
end

function GuildAdsHash:IntegerToPathElement(r)
	local path
	local i;
	path={}
	for i=0,15,1 do
		if bit_band(r,1)==1 then
			table_insert(path,i)
		end
		r=bit_rshift(r,1);
	end
	return path;
end


function GuildAdsHash:setMetaTable(t)
	local mt = {
		__index = function (t,k) 
			local i;
			local p;
			if type(k)=="table" then
				i=1;
				p=t;
				while i<=#k do
					if p then
						p=p[tonumber(k[i])];
					else
						return nil;
					end
					i=i+1;
				end
				return p;
			elseif type(k)=="string" then
				return t[GuildAdsHash:stringToPath(k)];
			end;
			return nil;
		end;
		
		__newindex = function(t,k,v)
			local p;
			local i;
			if type(k)=="table" then 
				i=1;
				p=t;
				while i<#k do
					if not p[k[i]] then
						p[k[i]]={};
					end
					p=p[k[i]];
					i=i+1;
				end
				rawset(p,k[i],v); -- p[k[i]]=v;
			else
				rawset(t,k,v); -- t[k]=v;
			end
		end;
		}
	setmetatable(t, mt)
end

function GuildAdsHash:pathToString(path)
	return table_concat(path,",");
end

function GuildAdsHash:stringToPath(str)
	if str=="" then
		return {}
	else
		return {strsplit(",",str)}
	end
end

function GuildAdsHash:SendSearch(path, hashSequence)
	-- send search to everyone
	GuildAdsComm:SendHashSearch(path, hashSequence);
end

function GuildAdsHash:SendHashChanged(path)
	if self.search[path] then
		local result = self.search[path];
		if GuildAdsComm.playerTree[GuildAds.playerName].p then
			-- send result to parent in whisper
			GuildAdsComm:SendHashSearchResultToParent(GuildAdsComm.playerTree[GuildAds.playerName].p, path, result.hashChanged, result.bestPlayerName, result.amount, result.numplayers);
		else
			-- send search result to channel
			GuildAdsComm:SendHashSearchResult(path, result.hashChanged, result.bestPlayerName, result.amount);
		end
	end
end

function GuildAdsHash:ReceiveSearch(path, hashSequence)
	if not self.search[path] then
		GuildAds_ChatDebug(GA_DEBUG_HASH,"GuildAdsHash:ReceiveSearch %s", path);
		self.search[path] = {
			bestPlayerName = GuildAdsComm.playerTree[GuildAds.playerName].i, -- playername as index
			path = self:stringToPath(path);
			hashSequence = hashSequence,
			hashChanged = self:CompareBase64HashToInteger(self:GetBase64Hash(self.tree[path]), hashSequence);
			amount = #((self.tree[path] or emptytable).d or emptytable);  -- number of IDs for this path (or 0).
			numplayers = 1; -- the number of players the bestPlayerName is drawn from (used to calculate probabilities)
		};
	else
		GuildAds_ChatDebug(GA_DEBUG_HASH,"  - Hash search already in progress");
	end
	
	if not (GuildAdsComm.playerTree[GuildAds.playerName].c1 or GuildAdsComm.playerTree[GuildAds.playerName].c2) then
		-- I'm a leaf : don't wait, send my revision information to my parent
		self:SendHashChanged(path);
	end
end

function GuildAdsHash:ReceiveHashSearchToParent(childPlayerName, path, hashChanged, who, amount, numplayers)
	if not self.search[path] then
		return;
	end
	
	numplayers = numplayers or 1; -- temporary fix (until other players upgrade)
	
	local result = self.search[path];
	
	-- merge information
	result.hashChanged = bit_bor(result.hashChanged, hashChanged);
	if amount > result.amount then -- the player with the most ID's for this path is assumed to be the best player. 
		result.bestPlayerName = who;
		result.amount = amount;
		result.numplayers = numplayers;
	elseif amount == result.amount then
		-- probabilities are even for all players having the same highest amount
		if math.random(1,result.numplayers+numplayers)>result.numplayers then
			result.bestPlayerName = who;
		end
		result.numplayers = result.numplayers + numplayers;
	end

	if childPlayerName == GuildAdsComm.playerTree[GuildAds.playerName].c1 then
		result.c1 = true;
	end
	
	if childPlayerName == GuildAdsComm.playerTree[GuildAds.playerName].c2 then
		result.c2 = true;
	end
	
	if (	GuildAdsComm.playerTree[GuildAds.playerName].c1
		and result.c1
		and GuildAdsComm.playerTree[GuildAds.playerName].c2 
		and result.c2)
	   or
	   (	GuildAdsComm.playerTree[GuildAds.playerName].c1
		and result.c1
		and not GuildAdsComm.playerTree[GuildAds.playerName].c2
		and not result.c2
	   )
	then
		self:SendHashChanged(path)
	end
end

function GuildAdsHash:ReceiveHashSearchResult(path, hashChanged, who, amount, DTS)
	if self.search[path] then
		local pathElements, newSearchPath;
		GuildAds_ChatDebug(GA_DEBUG_HASH, "GuildAdsHash:ReceiveHashSearchResult");
		if hashChanged == 0 then
			-- every online client has the same hash for this path (i.e. no change)
		else
			pathElements=self:IntegerToPathElement(hashChanged); 
			GuildAds_ChatDebug(GA_DEBUG_HASH, "ReceiveHashSearchResult: %s + %s", path, table_concat(pathElements,","));
			-- WARNING: REUSE OF PATH TABLE IS WRONG. MAKE A COPY!
			-- problem: 2 hash search results with the same path can be sent due to lag
			newSearchPath=self:stringToPath(path); -- get table form of path
			--tinsert(newSearchPath, pathElements[math.random(1,#pathElements)]); -- pick a random branch (client probably picks different branches, all choices are good)
			if #newSearchPath == self.maxRecurse-1 then
				GuildAds_ChatDebug(GA_DEBUG_HASH, "ReceiveHashSearchResult:Queuing Revision Search ");
				-- full path, search for all IDs at this path
				-- queue revision searches (every client does this)
				for _,branch in pairs(pathElements) do
					newSearchPath=self:stringToPath(path);
					tinsert(newSearchPath,branch);
					if self.tree[newSearchPath] then
						for _,v in pairs(self.tree[newSearchPath].d) do
							--GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "ReceiveHashSearchResult:Queuing Revision Search %s (%s,%s)",v.ID,v.dt.metaInformations.name,v.p);
							GuildAdsComm:QueueSearch(DTS[v.dt.metaInformations.name], v.p);
						end
					end
				end
			else
				GuildAds_ChatDebug(GA_DEBUG_HASH, "ReceiveHashSearchResult:Queuing Hash Search Path(s)");
				for _,branch in pairs(pathElements) do
					newSearchPath=self:stringToPath(path);
					tinsert(newSearchPath,branch);
					--GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "ReceiveHashSearchResult:Queuing Hash Search Path "..self:pathToString(newSearchPath));
					-- queue new hash searches (optimize: queue all hash searches instead of only the randomly selected one)
					GuildAdsComm:QueueHashSearch(self:pathToString(newSearchPath));
				end
			end
		end
		self.search[path]=nil;
	end
end

function GuildAdsHash:DeleteAllSearches()
	GuildAdsHash.search={};
end
