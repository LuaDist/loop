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
-- Title  : Cache of Objects Created on Demand                               --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                --
-- Date   : 13/12/2004 13:51                                                 --
-------------------------------------------------------------------------------
-- Notes:                                                                    --
--   Storage of keys 'retrieve' and 'default' are not allowed.               --
-------------------------------------------------------------------------------

local rawget = rawget
local rawset = rawset

local loop = require "loop"
local oo   = require "loop.base"

module("loop.collection.ObjectCache", loop.define(oo.class()))

__mode = "k"

function __index(self, key)
	local retrieve = rawget(self, "retrieve")
	if key and retrieve then
		local value = retrieve(self, key)
		rawset(self, key, value)
		return value
	else return rawget(self, "default") end
end