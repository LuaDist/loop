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
-- Title  : Map of Objects that Keeps an Array of Key Values                 --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                --
-- Date   : 13/12/2004 13:51                                                 --
-------------------------------------------------------------------------------
-- Notes:                                                                    --
--   Can only store non-numeric values.                                      --
--   Use of key strings equal to the name of one method prevents its usage.  --
-------------------------------------------------------------------------------

local rawget         = rawget
local loop           = require "loop"
local oo             = require "loop.simple"
local UnorderedArray = require "loop.collection.UnorderedArray"

module("loop.collection.MapWithKeyArray",
	loop.define( oo.class({}, UnorderedArray) )
)

keyat = rawget

function value(self, key, value)
	if value == nil
		then return self[key]
		else self[key] = value
	end
end

function add(self, key, value)
	UnorderedArray.add(self, key)
	self[key] = value or self:size()
end

function remove(self, key)
	for i = 1, size(self) do
		if self[i] == key then
			return removeat(self, i)
		end
	end
end

function removeat(self, index)
	self[UnorderedArray.remove(self, index)] = nil
end

function valueat(self, index, value)
	if value == nil
		then return self[ self[index] ]
		else self[ self[index] ] = value
	end
end
