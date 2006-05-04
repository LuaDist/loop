-------------------------------------------------------------------------------
---------------------- ##       #####    #####   ######  ----------------------
---------------------- ##      ##   ##  ##   ##  ##   ## ----------------------
---------------------- ##      ##   ##  ##   ##  ######  ----------------------
---------------------- ##      ##   ##  ##   ##  ##      ----------------------
---------------------- ######   #####    #####   ##      ----------------------
----------------------                                   ----------------------
----------------------- Lua Object-Oriented Programming -----------------------
-------------------------------------------------------------------------------
-- Title  : LOOP - Lua Object-Oriented Programming                           --
-- Name   : Cached Class Model                                               --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                --
-- Version: 2.1 alpha                                                        --
-- Date   : 19/4/2005 11:24                                                  --
-------------------------------------------------------------------------------
-- Exported API:                                                             --
--   class(class, super)                                                     --
--   new(class, ...)                                                         --
--   classof(object)                                                         --
--   isclass(class)                                                          --
--   superclass(class)                                                       --
--   subclassof(class, super)                                                --
--   instanceof(object, class)                                               --
-------------------------------------------------------------------------------

local unpack  = unpack
local pairs   = pairs
local rawget  = rawget
local rawset  = rawset
local require = require
local ipairs  = ipairs

local table = require "table" require "loop.utils"

local pack = pack

module "loop.cached"
-------------------------------------------------------------------------------
local ObjectCache = require "loop.collection.ObjectCache"
local OrderedSet  = require "loop.collection.OrderedSet"
local base        = require "loop.multiple"
-------------------------------------------------------------------------------
table.copy(base, _M)
-------------------------------------------------------------------------------
local function supersiterator(stack)
	local next = stack:pop()
	if next then
		for _, def in ipairs(next.supers) do
			stack:push(def)
		end
	end
	return next
end
function supers(...) return supersiterator, OrderedSet(arg) end

local function subsiterator(queue)
	local next = queue:dequeue()
	if next then
		for def in pairs(next.subs) do
			queue:enqueue(def)
		end
	end
	return next
end
function subs(...) return subsiterator, OrderedSet(arg) end
-------------------------------------------------------------------------------
local function proxy_newindex(proxy, field, value)
	local cached = base.classof(proxy)
	return cached:updatefield(field, value)
end
-------------------------------------------------------------------------------
local ClassMap = base.new { __mode = "k" }
-------------------------------------------------------------------------------
CachedClass = base.class()

function getclass(class)
	local cached = base.classof(class)
	if base.instanceof(cached, CachedClass) then
		return cached
	end
end

function CachedClass:__init(class)
	local meta = {}
	self = {
		__call = new,
		__index = meta,
		__newindex = proxy_newindex,
		supers = {},
		subs = {},
		members = class and table.copy(class) or {},
		class = meta,
	}
	self.proxy = base.new(self, class and table.clear(class) or {})
	ClassMap[self.class] = self.proxy
	return self
end

function CachedClass:updatehierarchy(classes)
	-- separate cached from non-cached classes
	local caches = { n=0 }
	local supers = { n=0 }
	for index, super in ipairs(classes) do
		local cached = getclass(super)
		if cached
			then table.insert(caches, cached)
			else table.insert(supers, super)
		end
	end

	-- remove it from its old superclasses
	for _, super in ipairs(self.supers) do
		super:removesubclass(self)
	end
	
	-- update superclasses
	self.uncached = supers
	self.supers = caches

	-- register as subclass in all superclasses
	for _, super in ipairs(self.supers) do
		super:addsubclass(self)
	end
end

function CachedClass:updateinheritance()
	-- relink all affected classes
	for sub in subs(self) do
		sub:updatemembers()
		sub:updatesuperclasses()
	end
end

function CachedClass:addsubclass(class)
	self.subs[class] = true
end

function CachedClass:removesubclass(class)
	self.subs[class] = nil
end

function CachedClass:updatesuperclasses()
	local uncached = { n = 0 }
	-- copy uncached superclasses defined in the class
	for idx, super in ipairs(self.uncached) do
		if not uncached[super] then
			uncached[super] = true
			table.insert(uncached, super)
		end
	end
	-- copy inherited uncached superclasses
	for _, cached in ipairs(self.supers) do
		for idx, super in ipairs{base.superclass(cached.class)} do
			if not uncached[super] then
				uncached[super] = true
				table.insert(uncached, super)
			end
		end
	end
	base.class(self.class, unpack(uncached))
end

function CachedClass:updatemembers()
	local class = table.clear(self.class)
	for i = table.getn(self.supers), 1, -1 do
		local super = self.supers[i].class
		-- copy inherited members
		table.copy(super, class)
		-- do not copy the default __index value
		if rawget(class, "__index") == super then
			rawset(class, "__index", nil)
		end
	end
	-- copy members defined in the class
	table.copy(self.members, class)
	-- set the default __index value
	if rawget(class, "__index") == nil then
		rawset(class, "__index", class)
	end
end

function CachedClass:updatefield(name, member)
	-- update member list
	local members = self.members
	members[name] = member

	-- get old linkage
	local class = self.class
	local old = class[name]
	
	-- replace old linkage for the new one
	class[name] = member
	local queue = OrderedSet()
	for sub in pairs(self.subs) do
		queue:enqueue(sub)
	end
	while queue:head() do
		local current = queue:dequeue()
		class = current.class
		members = current.members
		if members[name] == nil then
			for _, super in ipairs(current.supers) do
				local superclass = super.class
				if superclass[name] ~= nil then
					if superclass[name] ~= class[name] then
						class[name] = superclass[name]
						for sub in pairs(current.subs) do
							queue:enqueue(sub)
						end
					end
					break
				end
			end
		end
	end
	return old
end
-------------------------------------------------------------------------------
function class(class, ...)
	class = getclass(class) or CachedClass(class)
	class:updatehierarchy(arg)
	class:updateinheritance()
	return class.proxy
end
-------------------------------------------------------------------------------
function rawnew(class, object)
	local cached = getclass(class)
	if cached then class = cached.class end
	return base.rawnew(class, object)
end
-------------------------------------------------------------------------------
function new(class, ...)
	local cached = getclass(class)
	if cached then class = cached.class end
	return class(unpack(arg, 1, arg.n))
end
-------------------------------------------------------------------------------
function classof(object)
	local class = base.classof(object)
	return ClassMap[class] or class
end
-------------------------------------------------------------------------------
function isclass(class)
	return getclass(class) ~= nil
end
-------------------------------------------------------------------------------
local function append(tab, ...)
	for _, value in ipairs(arg) do table.insert(tab, value) end
end
function superclass(class)
	local supers = { n=0 }
	local cached = getclass(class)
	if cached then
		for _, cachedsuper in ipairs(cached.supers) do
			table.insert(supers, cachedsuper.proxy)
		end
		class = cached.class
	end
	append(supers, base.superclass(class))
	return unpack(supers)
end
-------------------------------------------------------------------------------
function subclassof(class, super)
	if class == super then
		return true
	else
		local supers = pack(superclass(class))
		for _, superclass in ipairs(supers) do
			if subclassof(superclass, super) then
				return true
			end
		end
	end
end
-------------------------------------------------------------------------------
function instanceof(object, class)
	return subclassof(classof(object), class)
end