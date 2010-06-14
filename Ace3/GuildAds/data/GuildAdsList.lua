-- GuildAdsList is a double linked list that has the ability to extract random objects in linear time.
-- Appends and deletes are also handled in linear time.
-- The list however cannot handle 2 (or more) appends of the same object (2. (or later) appens of the same object is ignored).
-- In other words, the list only handles unique objects.
-- Workaround: Convert all objects to tables, e.g. "a" becomes { "a" }.
-- Problem is, you are limited to walk through the list from start to end (random lookups is also possible).
-- You can't reference objects, e.g. GuildAdsList:get({"a"}) as the table {"a"} isn't the same table as previously inserted.
--[[
list=GuildAdsList:new();
print(tostring(list:First()))
list:Append("1,1");
list:Append("1,2");
list:Append("1,3");
list:Append("1,4");

p=list:First();
while p.next do
	print(p.obj);
	p=p.next;
end

p=list:Last();
while p.prev do
	print(p.obj);
	p=p.prev;
end
print("--------")
list:Delete("1,2");
p=list:First();
while p.next do
	print(p.obj);
	p=p.next;
end
print("list... "..#list.list);
print(list:Get(1));
print(list:Get(2));
print(list:Get(3));

print("--")
print(tostring(list:Exists("1,5")))
o=list:GetRandom(); print(o); list:Delete(o);
o=list:GetRandom(); print(o); list:Delete(o);
o=list:GetRandom(); print(o); list:Delete(o);
o=list:GetRandom(); print(o); list:Delete(o);
]]

local new = GuildAds.new
local new_kv = GuildAds.new_kv
local del = GuildAds.del
local deepDel = GuildAds.deepDel

-- The function Insert, Prepend and more can be implemented but haven't been so yet.

GuildAdsList = {};
function GuildAdsList:new(t)
	if (t==nil) then
		t = new();
	end
	if t.head==nil then
		t.first = new_kv('next', new());
		t.idx = new(); -- used to quickly find an object: idx[obj]=list_info
		t.list = new(); -- used to make random access into the list: list[1]=obj, list[2]=obj, ... ([1] is not necessarily the first object in the list)
		t.last = t.first.next;
		t.last.prev = t.first;
	end
	self.__index = self;
	setmetatable(t, self);
	return t;
end

function GuildAdsList:Append(obj,data)
	if not self.idx[obj] then
		local _new;
		_new = new_kv('obj', obj, 'data', data, 'next', self.last, 'prev', self.last.prev);
		self.last.prev.next = _new;
		self.last.prev = _new;
		self.idx[obj] = _new;
		table.insert(self.list,obj);
		_new.idx=#self.list;
	end
end

function GuildAdsList:Delete(obj)
	local t=self.idx[obj];
	if t then
		if t.next then
			t.next.prev = t.prev;
		end
		if t.prev then
			t.prev.next = t.next;
		end
		if #self.list > 1 and t.idx < #self.list then
			self.idx[self.list[#self.list]].idx=t.idx;
			self.list[t.idx]=self.list[#self.list];
		end
		self.list[#self.list]=nil;
		del(self.idx[obj]);
		self.idx[obj]=nil;
	end
end

function GuildAdsList:DeleteAll()
	-- can cause endless loops! (don't know why)
	--local first = self:First()
	--while first do
	--	self:Delete(first);
	--	first = self:First()
	--end
  -- This wont free all tables to the our table pool, but can't loop forever.
	self.first.next = self.last;
	self.last.prev = self.first;
	self.idx = new();
	self.list = new();
end

-- This function takes an index (1,2,3,..) and returns the object at that index.
-- The sequence of objects is NOT the same as iterating from list:first to list:last.
function GuildAdsList:Get(idx)
	return self.list[idx];
end

function GuildAdsList:GetObject(obj)
	local t=self.idx[obj];
	if t then
		return t.obj, t.data;
	end
	return nil,nil;
end

function GuildAdsList:Exists(obj)
	return self.idx[obj] and true or nil;
end

function GuildAdsList:Length()
	return #self.list;
end

function GuildAdsList:First()
	if self.first.next.obj then
		return self.first.next;
	end
	return nil;
end

function GuildAdsList:Last()
	return self.last.prev;
end

function GuildAdsList:GetRandom()
	if #self.list > 0 then
		return self:Get(math.random(1,#self.list))
	end
	return nil;
end
