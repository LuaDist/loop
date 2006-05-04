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
-- Name   : Packing of Object Classes (Lua 5.1 Package Proposal)             --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                --
-- Version: 2.1 alpha                                                        --
-- Date   : 19/4/2005 11:24                                                  --
-------------------------------------------------------------------------------
-- Exported API:                                                             --
--   <model>class(packagename, ...)                                          --
-------------------------------------------------------------------------------

local getmetatable = getmetatable
local setmetatable = setmetatable
local require      = require
local unpack       = unpack
local rawset       = rawset
local pairs        = pairs
local global       = _G

local string  = require "string"
local package = require "package"

module "loop"

local function setfield (t, f, v)
	for w in string.gmatch(f, "([%w_]+)%.") do
		t[w] = t[w] or {} -- create table if absent
		t = t[w]          -- get the table
	end
	local w = string.gsub(f, "[%w_]+%.", "")   -- get last field name
	t[w] = v            -- do the assignment
end

function define(class)
	return function(module)
		module._CLASS = class
		package.loaded[module._NAME] = class
		setfield(global, module._NAME, class)
		local meta = getmetatable(module)
		if meta then
			meta.__index = meta.__index or class
			meta.__newindex = class
		else
			setmetatable(module, {
				__index = class,
				__newindex = class,
			})
		end
	end
end

function seeapi(model)
	return function(module)
		module._MODEL = model
		for field, value in pairs(model) do
			rawset(module, field, value)
		end
	end
end
