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
-- Name   : Scoped Class Model                                               --
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
--                                                                           --
--   methodfunction(method)                                                  --
--   methodclass(method)                                                     --
--   this(object)                                                            --
--   priv(object, [class])                                                   --
--   prot(object)                                                            --
-------------------------------------------------------------------------------

-- TODO: Solutions to find out...
--	 Enable replace of all members of a scope by ClassProxy[scope] = { ... }
--	 Add static method call.
--	 Define a default __eq metamethod that compares the object references.
--	 Avoid passing in the same class (node) in hierarchy search (see supers and subs)
--	 The best way to relink member with numeric, string and booelan values.
--	 An efficient delegation approach to execute on delegatee state.
--	 Replace conditional compiler by static function constructors.

-------------------------------------------------------------------------------

local type         = type
local pairs        = pairs
local assert       = assert
local ipairs       = ipairs
local setmetatable = setmetatable
local unpack       = unpack
local require      = require
local rawset       = rawset
local getmetatable = getmetatable
local rawget       = rawget

local debug = require "debug"
local table = require "table" require "loop.utils"

module "loop.scoped"                                                            --[[VERBOSE]] local verbose = require "loop.debug.verbose"

-------------------------------------------------------------------------------
local ObjectCache = require "loop.collection.ObjectCache"
local OrderedSet  = require "loop.collection.OrderedSet"
local base        = require "loop.multiple"
-------------------------------------------------------------------------------
table.copy(require "loop.cached", _M)
-------------------------------------------------------------------------------
--- SCOPED DATA CHAIN ---------------------------------------------------------
-------------------------------------------------------------------------------
-- maps private and protected state objects to the object (public) table
local Object = setmetatable({}, { __mode = "kv" })
-------------------------------------------------------------------------------
local function newprotected(self, object)                                       --[[VERBOSE]] verbose.oo_scoped{"new protected state", object = object, meta = self.class}
	local protected = self.class()
	rawset(Object, protected, object)
	return protected
end
local function ProtectedPool(members)                                           --[[VERBOSE]] verbose.oo_scoped{"new protected pool", members = members}
	return ObjectCache {
		class = base.class(members),
		retrieve = newprotected,
	}
end
-------------------------------------------------------------------------------
local function newprivate(self, outter)                                         --[[VERBOSE]] verbose.oo_scoped{"new private state", reference = outter}
	local object = rawget(Object, outter)                                         --[[VERBOSE]] verbose.oo_scoped{"public object found", object = object}
	local private = rawget(self, object)
	if not private then                                                           --[[VERBOSE]] verbose.oo_scoped "no private state found"
		private = self.class()
		if object then
			rawset(Object, private, object)                                           --[[VERBOSE]] verbose.oo_scoped{"registering public object for private state", object = object}
			rawset(self, object, private)                                             --[[VERBOSE]] verbose.oo_scoped{"registering private state for public object", private = private}
		else
			rawset(Object, private, outter)                                           --[[VERBOSE]] verbose.oo_scoped{"registering public object for private state", object = outter, private = private}
		end
	end
	return private
end
local function PrivatePool(members)                                             --[[VERBOSE]] verbose.oo_scoped{"new private pool", members = members}
	return ObjectCache {
		class = base.class(members),
		retrieve = newprivate,
	}
end
-------------------------------------------------------------------------------
local function createmember(class, member)
	if type(member) == "function" then                                            --[[VERBOSE]] verbose.oo_scoped "new method closure"
		local pool
		local method = member
		member = function (self, ...)
			pool = rawget(class, getmetatable(self))                                  --[[VERBOSE]] verbose.oo_scoped{"method closure on object", object = self, is_instance = (pool ~= nil)}
			if pool
				then return method(pool[self], unpack(arg, 1, arg.n))
				else return method(self, unpack(arg, 1, arg.n))
			end
		end
	end
	return member
end
-------------------------------------------------------------------------------
local ConditionalCompiler = require "loop.compiler.Conditional"

local indexer = ConditionalCompiler {
	{[[local meta                                       ]],"not (newindex and public and nilindex)" },
	{[[local result                                     ]],"index and (private or protected)" },
	{[[local Public                                     ]],"private or protected" },
	{[[local Protected, registry                        ]],"private" },
	{[[local member                                     ]],"newindex" },
	{[[local newindex                                   ]],"newindex and not nilindex" },
	{[[local index                                      ]],"index and not nilindex" },
	{[[return function (state, name, value)             ]],"newindex" },
	{[[return function (state, name)                    ]],"index" },
	{[[	result = meta[name]                             ]],"index and (private or protected)" },
	{[[	return   meta[name]                             ]],"index and public" },
	{[[	         or index[name]                         ]],"index and tableindex" },
	{[[	         or index(state, name)                  ]],"index and functionindex" },
	{[[	if result == nil then                           ]],"index and (private or protected)" },
	{[[	if meta[name] == nil then                       ]],"newindex and (private or protected or not nilindex)" },
	{[[		state = Public[state]                         ]],"private or protected" },
	{[[		Protected = registry[getmetatable(state)]     ]],"private" },
	{[[		if Protected then state = Protected[state] end]],"private" },
	{[[		return state[name]                            ]],"index and (private or protected)" },
	{[[		state[name] = member(value)                   ]],"newindex and (private or protected) and nilindex" },
	{[[		newindex[name] = member(value)                ]],"newindex and tableindex" },
	{[[		return newindex(state, name, member(value))   ]],"newindex and functionindex" },
	{[[	else                                            ]],"newindex and (private or protected or not nilindex)" },
	{[[		return rawset(state, name, member(value))     ]],"newindex" },
	{[[	end                                             ]],"private or protected or (newindex and not nilindex)" },
	{[[	return result                                   ]],"index and (private or protected)" },
	{[[end                                              ]]},
}

local function createindexer(class, scope, action)
	local meta = class:getmeta(scope)
	local index = meta["__"..action]
	local indextype = type(index).."index"
	local codename = table.concat({scope,action,index and ("with "..indextype)}," ")

	return indexer:compile({
			[action]    = true,
			[scope]     = true,
			[indextype] = true,
		}, {
			Public   = Object,
			meta     = meta,
			registry = class.registry,
			[action] = index,
			member   = function(value) return createmember(class, value) end,
		},
		codename
	)
end

local function unwrap(meta, tag)
	local indexer
	local key = "__"..tag
	local func = assert(meta[key], "no indexer found in scoped class metatable.")
	local name, value
	local i = 1
	repeat
		name, value = debug.getupvalue(func, i)
		i = i + 1
	until name == nil or name == tag
	return value
end
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function publicproxy_call(_, object)
	return this(object)
end

function protectedproxy_call(_, object)
	return prot(object)
end

function privateproxy_call(_, object, class)
	return priv(object, class)
end
-------------------------------------------------------------------------------
local ScopedClass = base.class({}, CachedClass)

function ScopedClass:getmeta(scope)
	return self[scope] and self[scope].class
	         or
	       (scope == "public") and self.class
	         or
	       nil
end

function ScopedClass:getmembers(scope)
	if self.registry -- if is a scoped class
		then return self.members[scope]
		else return self.members
	end
end

function ScopedClass:__init(class)
	if not class then class = { public = {} } end
	
	-- adjust class definition to use scoped member tables
	if type(class.public) ~= "table" then
		if
			(type(class.protected) == "table")
				or
			(type(class.private) == "table")
		then
			class.public = {}
		else
			local public = table.copy(class)
			table.clear(class)
			class.public = public
		end
	end

	-- initialize scoped cached class
	self = CachedClass.__init(self, class)
	self.registry = { [self.class] = false }

	-- define scoped class proxy for public state
	rawset(self.proxy, "public", setmetatable({}, {
		__call = publicproxy_call,
		__index = self.class,
		__newindex = function(_, field, value)
			self:updatefield(field, value, "public")
		end,
	}))

	return self
end

function ScopedClass:addsubclass(class)
	self.subs[class] = true

	local public = class.class
	for super in supers(self) do
		if super.registry then -- if super is a scoped class
			rawset(super.registry, public, false)
			rawset(super, public, super.private)
		end
	end
end

function ScopedClass:removesubclass(class)
	self.subs[class] = nil

	local public = self.class
	local protected = self:getmeta("protected")
	local private = self:getmeta("private")

	for super in supers(self) do
		local registry = super.registry
		if registry then -- if super is a scoped class
			if public then
				rawset(registry, public, nil)
				rawset(super, public, nil)
			end
			if protected then
				rawset(registry, protected, nil)
				rawset(super, protected, nil)
			end
			if private then
				rawset(registry, private, nil)
				rawset(super, private, nil)
			end
		end
	end
end

local function copymembers(class, source, destiny)
	if source then
		if not destiny then destiny = {} end
		for field, value in pairs(source) do
			destiny[field] = createmember(class, value)
		end
	end
	return destiny
end
function ScopedClass:updatemembers()
	--
	-- metatables to collect with current members
	--
	local public = table.clear(self.class)
	local protected
	local private
	
	--
	-- copy inherited members
	--
	local publicindex, publicnewindex
	local protectedindex, protectednewindex
	local count = table.getn(self.supers)
	for i = count, 1, -1 do
		-- copy members from superclass metatables
		public = table.copy(self.supers[i].class, public)

		if base.instanceof(self.supers[i], ScopedClass) then
			-- copy protected members from superclass metatables
			protected = table.copy(self.supers[i]:getmeta("protected"), protected)

			-- extract the __index and __newindex values
			publicindex    = unwrap(public, "index")    or publicindex
			publicnewindex = unwrap(public, "newindex") or publicnewindex
			if protected then
				protectedindex    = unwrap(protected, "index")    or protectedindex
				protectednewindex = unwrap(protected, "newindex") or protectednewindex
			end
		end
	end
	public.__index    = publicindex
	public.__newindex = publicnewindex
	if protected then
		protected.__index    = protectedindex
		protected.__newindex = protectednewindex
	end

	--
	-- copy members defined in the class
	--
	public    = copymembers(self, self.members.public,    public)
	protected = copymembers(self, self.members.protected, protected)
	private   = copymembers(self, self.members.private,   private)

	--
	-- setup public metatable with proper indexers
	--
	public.__index = createindexer(self, "public", "index")
	public.__newindex = createindexer(self, "public", "newindex")
	
	--
	-- setup proper protected state features: pool, proxies and indexers
	--
	if protected then
		if not self.protected then
			-- create state object pool and class proxy for protected state
			self.protected = ProtectedPool(protected)
			rawset(self.proxy, "protected", setmetatable({}, {
				__call = protectedproxy_call,
				__index = protected,
				__newindex = function(_, field, value)
					self:updatefield(field, value, "protected")
				end,
			}))
			-- registry new pool in superclasses
			local protected_pool = self.protected
			for super in supers(self) do
				local registry = super.registry
				if registry then
					rawset(registry, public, protected_pool)
					rawset(registry, protected, false)
	
					local pool = super.private
					if pool then
						rawset(super, public, pool)
						rawset(super, protected, pool)
					else
						rawset(super, public, protected_pool)
					end
				end
			end
		else
			-- update current metatable with new members
			protected = table.copy(protected, table.clear(self.protected.class))
		end

		-- setup metatable with proper indexers
		protected.__index = createindexer(self, "protected", "index")
		protected.__newindex = createindexer(self, "protected", "newindex")

	elseif self.protected then
		-- remove old pool from registry in superclasses
		local protected_pool = self.protected
		for super in supers(self) do
			local registry = super.registry
			if registry then
				rawset(registry, public, false)
				rawset(registry, protected_pool.class, nil)
	
				rawset(super, public, super.private)
				rawset(super, protected_pool.class, nil)
			end
		end
		-- remove state object pool and class proxy for protected state
		self.protected = nil
		rawset(self.proxy, "protected", nil)
	end
	
	--
	-- setup proper private state features: pool, proxies and indexers
	--
	if private then
		if not self.private then
			-- create state object pool and class proxy for private state
			self.private = PrivatePool(private)
			rawset(self.proxy, "private", setmetatable({}, {
				__call = privateproxy_call,
				__index = private,
				__newindex = function(proxy, field, value)
					self:updatefield(field, value, "private")
				end
			}))
			-- registry new pool in superclasses
			local private_pool = self.private
			local pool = self.protected or Object
			for super in supers(unpack(self.supers)) do
				rawset(super.registry, private, pool)
				rawset(super, private, super.private_pool or pool)
			end
			for meta in pairs(self.registry) do
				rawset(self, meta, private_pool)
			end
		else
			-- update current metatable with new members
			private = table.copy(private, table.clear(self:getmeta("private")))
		end

		-- setup metatable with proper indexers
		private.__index = createindexer(self, "private", "index")
		private.__newindex = createindexer(self, "private", "newindex")

	elseif self.private then
		-- remove old pool from registry in superclasses
		local private_pool = self.private
		for super in supers(unpack(class.supers)) do
			rawset(super.registry, private_pool.class, nil)
			rawset(super, private_pool.class, nil)
		end
		for meta, pool in pairs(self.registry) do
			rawset(self, meta, pool or nil)
		end
		-- remove state object pool and class proxy for private state
		self.private = nil
		rawset(self.proxy, "private", nil)
	end
end

function ScopedClass:updatefield(name, member, scope)                           --[[VERBOSE]] verbose.oo_scoped({"updating field ", name, " on scope ", scope}, true)
	member = createmember(self, member)
	if not scope then
		if
			(
				name == "public"
					or
				name == "protected"
					or
				name == "private"
			)
				and
			type(member) == "table"
		then                                                                        --[[VERBOSE]] verbose.oo_scoped("updating scope field", true)
			self.members[name] = member
			return self:updatemembers()                                               --[[VERBOSE]] , verbose.oo_scoped()
		end
		scope = "public"
	end

	-- Update member list
	local members = self:getmembers(scope)
	members[name] = member

	-- Create new member linkage and get old linkage
	local metatable = self:getmeta(scope)
	local old = metatable[name]
	
	-- Replace old linkage for the new one
	metatable[name] = member
	if scope ~= "private" then
		local queue = OrderedSet()
		for sub in pairs(self.subs) do
			queue:enqueue(sub)
		end
		while queue:head() do
			local current = queue:dequeue()
			metatable = current:getmeta(scope)
			members = current:getmembers(scope)
			if members and (members[name] == nil) then
				for _, super in ipairs(current.supers) do
					local super_meta = super:getmeta(scope)
					if super_meta[name] ~= nil then
						if super_meta[name] ~= metatable[name] then
							metatable[name] = super_meta[name]
							for sub in pairs(current.subs) do
								queue:enqueue(sub)
							end
						end
						break
					end
				end
			end
		end
	end                                                                           --[[VERBOSE]] verbose.oo_scoped()
	return old
end
-------------------------------------------------------------------------------
function class(class, ...)
	class = getclass(class) or ScopedClass(class)
	class:updatehierarchy(arg)
	class:updateinheritance()
	return class.proxy
end
-------------------------------------------------------------------------------
local cached_classof = classof
function classof(object)
	return cached_classof(this(object))
end
-------------------------------------------------------------------------------
function methodfunction(method)
	local name, value = debug.getupvalue(method, 3)
	assert(name == "method", "Oops! Got the wrong upvalue in 'methodfunction'")
	return value
end
-------------------------------------------------------------------------------
function methodclass(method)
	local name, value = debug.getupvalue(method, 2)
	assert(name == "class", "Oops! Got the wrong upvalue in 'methodclass'")
	return value.proxy
end
-------------------------------------------------------------------------------
function this(object)
	return rawget(Object, object) or object
end
-------------------------------------------------------------------------------
function priv(object, class)
	if not class then class = classof(object) end
	class = getclass(class)
	if class and class.private then
		if base.classof(object) == class.private.class
			then return object                 -- private object
			else return class.private[object]  -- protected or public object
		end
	end
end
-------------------------------------------------------------------------------
function prot(object)
	local class = getclass(classof(object))
	if class and class.protected then
		if base.classof(object) == class.protected.class
			then return object                   -- protected object
			else return class.protected[this(object)]  -- private or public object
		end
	end
end