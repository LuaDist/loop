-------------------------------------------------------------------------------
---------------------- ##       #####    #####   ######  ----------------------
---------------------- ##      ##   ##  ##   ##  ##   ## ----------------------
---------------------- ##      ##   ##  ##   ##  ######  ----------------------
---------------------- ##      ##   ##  ##   ##  ##      ----------------------
---------------------- ######   #####    #####   ##      ----------------------
----------------------                                   ----------------------
----------------------- Lua Object-Oriented Programming -----------------------
-------------------------------------------------------------------------------
-- Project: LOOP Collections - Object Collections Implemented in LOOP        --
-- Release: 1.0 alpha                                                        --
-- Title  : Ordered Set Optimized for Insertions and Removals                --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                --
-- Date   : 13/12/2004 13:51                                                 --
-------------------------------------------------------------------------------
-- Notes:                                                                    --
--   Storage of strings equal to the name of one method prevents its usage.  --
-------------------------------------------------------------------------------

local table = require "table"
local loop  = require "loop"
local oo    = require "loop.base"

module("loop.collection.OrderedSet", loop.define(oo.class()), loop.seeapi(oo))

------------------------------------------------------------------------------
-- key constants -------------------------------------------------------------
------------------------------------------------------------------------------

local FIRST = {}
local LAST = {}

------------------------------------------------------------------------------
-- constructor ---------------------------------------------------------------
------------------------------------------------------------------------------

function __init(class, elems)
	local self = {}
	if elems then
		local size = table.getn(elems)
		if size > 0 then
			self[FIRST] = elems[1]
			self[LAST] = elems[1]
			for i = 2, size do
				push_back(self, elems[i])
			end
		end
	end
	return rawnew(class, self)
end

------------------------------------------------------------------------------
-- basic functionality -------------------------------------------------------
------------------------------------------------------------------------------

local function iterator(self, previous)
	return self[previous], previous
end

function sequence(self)
	return iterator, self, FIRST
end

function contains(self, element)
	return (self[element] ~= nil) or (element == self[LAST])
end

function first(self)
	return self[FIRST]
end

function last(self)
	return self[LAST]
end

function empty(self)
	return self[FIRST] == nil
end

function insert(self, element, previous)
	if previous == nil
		then previous = self[LAST] or FIRST
		else if not contains(self, previous) then return end
	end
	if not contains(self, element) then
		if self[previous] == nil
			then self[LAST] = element
			else self[element] = self[previous]
		end
		self[previous] = element
		return element
	end
end

function previous(self, element, start)
	local previous = start or FIRST
	repeat
		if self[previous] == element then
			return previous
		end
		previous = self[previous]
	until previous == nil
end

function remove(self, element, start)
	local prev = previous(self, element, start)
	if prev then
		self[prev] = self[element]
		if self[LAST] == element
			then self[LAST] = prev
			else self[element] = nil
		end
		return element
	end
end

function replace(self, old, new, start)
	local prev = previous(self, old, start)
	if prev then
		self[prev] = new
		self[new] = self[old]
		if old == self[LAST]
			then self[LAST] = new
			else self[old] = nil
		end
		return old
	end
end

function push_front(self, element)
	if not contains(self, element) then
		if self[FIRST] ~= nil
			then self[element] = self[FIRST]
			else self[LAST] = element
		end
		self[FIRST] = element
		return element
	end
end

function pop_front(self)
	local element = self[FIRST]
	self[FIRST] = self[element]
	if self[FIRST] ~= nil
		then self[element] = nil
		else self[LAST] = nil
	end
	return element
end

function push_back(self, element)
	if not contains(self, element) then
		if self[LAST] ~= nil
			then self[ self[LAST] ] = element
			else self[FIRST] = element
		end
		self[LAST] = element
		return element
	end
end

------------------------------------------------------------------------------
-- function aliases ----------------------------------------------------------
------------------------------------------------------------------------------

-- set operations
add = push_back

-- stack operations
push = push_front
pop = pop_front
top = first

-- queue operations
enqueue = push_back
dequeue = pop_front
head = first
tail = last

firstkey = FIRST