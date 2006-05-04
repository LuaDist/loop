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
-- Title  : Array Optimized for Insertion/Removal that Doesn't Garantee Order--
-- Author : Renato Maia <maia@inf.puc-rio.br>                                --
-- Date   : 13/12/2004 13:51                                                 --
-------------------------------------------------------------------------------

local table = require "table"
local loop  = require "loop"
local oo    = require "loop.base"

module("loop.collection.UnorderedArray", loop.define(oo.class()))

local rawremove = table.remove

size = table.getn
add = table.insert

function remove(self, index)
	local size = size(self)
	if (index > 0) and (index < size) then
		self[index], self[size] = self[size], self[index]
	elseif index ~= size then
		return
	end
	return rawremove(self)
end