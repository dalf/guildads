-- from AceDB.lua (Ace1)

TRUE = 1
FALSE = nil
GAAceDatabase = {}

-- 
function GAAceDatabase.CopyTable(into, from)
	for key, val in pairs(from) do
		if( type(val) == "table" ) then
			if( not into[key] ) then into[key] = {} end
			GAAceDatabase.CopyTable(into[key], val)
		else
			into[key] = val
		end
	end
	
	return into
end

-- 
function GAAceDatabase.toggle(val)
	if( val ) then return FALSE end
	return TRUE
end

-- Object constructor
function GAAceDatabase:new(val, seed)
	self.__index = self
	local o = setmetatable({seed=seed}, self)
	
	if( type(val)=="string" ) then
		o.name = val
	else
		o._table = val or {}
		o.initialized = TRUE
	end
	return o
end

function GAAceDatabase:Initialize()
	if( self.initialized ) then return end
	self.initialized = TRUE

	self._table = getglobal(self.name)
	if( self._table ) then return end

	self._table = {}
	setglobal(self.name, self._table)
	if( self.seed ) then
		self.CopyTable(self._table, self.seed)
	end
	self.created = TRUE

	return self.created
end

function GAAceDatabase:_DelvePath(node, path)
	local key, parent
	for _, val in ipairs(path) do
		parent = node
		key    = val
		if( type(val)=="table" ) then
			node, parent, key = self:_DelvePath(node, val)
			if( not node ) then return end
		elseif( not node[val] ) then
			-- If we're not creating the path and the node doesn't exist, we're done.
			if( not self.create ) then return end
			node[val] = {}
			node = node[val]
		else
			node = node[val]
		end
	end
	return node, parent, key
end

function GAAceDatabase:_GetNode(path, create)
	if( not path ) then return self._table end
	self.create = create
	local node, parent, key = self:_DelvePath(self._table, path)
	self.create = FALSE
	return node, parent, key
end

function GAAceDatabase:_GetArgs(arg)
	if( type(arg[1]) == "table" ) then
		return arg[1], arg[2], arg[3], arg[4]
	end
	return nil, arg[1], arg[2], arg[3]
end

function GAAceDatabase:get(...)
    arg = {...}
	if( getn(arg) < 1 ) then return self._table end
	local path, key = self:_GetArgs(arg)
	if (type(self:_GetNode(path) or {}) == "string") then
		error("Bad Path", 2);
	end
	return (self:_GetNode(path) or {})[key]
end

function GAAceDatabase:set(...)
    arg = {...}
	local path, key, val = self:_GetArgs(arg)
	local node = self:_GetNode(path, TRUE)
	if( not key ) then error("No key supplied to AceDatabase:set.", 2) end
	node[key] = val
	return node[key]
end

function GAAceDatabase:toggle(...)
    arg = {...}
	local path, key = self:_GetArgs(arg)
	local node = self:_GetNode(path, TRUE)
	if( not key ) then error("No key supplied to AceDatabase:toggle.", 2) end
	node[key]  = self.toggle(node[key])
	return node[key]
end

function GAAceDatabase:insert(...)
    arg = {...}
	local path, key, val, pos = self:_GetArgs(arg)
	local node = self:_GetNode(path, TRUE)
	if( not key ) then error("No key supplied to AceDatabase:insert.", 2) end
	if( not node[key] ) then node[key] = {} end
	if( pos ) then tinsert(node[key], pos, val)
	else tinsert(node[key], val)
	end
end

function GAAceDatabase:remove(...)
    arg = {...}
	local path, key, pos = self:_GetArgs(arg)
	local node = self:_GetNode(path, TRUE)
	if( not key ) then error("No key supplied to AceDatabase:remove.", 2) end
	return tremove(node[key], pos)
end

function GAAceDatabase:reset(path, seed)
	if( path ) then
		local _, parent, key = self:_GetNode(path)
		if( (not parent) or (not key) ) then return end
		parent[key] = {}
		if( seed ) then self.CopyTable(parent[key], seed) end
		return parent[key]
	else
		self._table = {}
		if( self.name ) then setglobal(self.name, self._table) end
		if( seed or self.seed ) then
			self.CopyTable(self._table, seed or self.seed)
		end
		return self._table
	end
end
