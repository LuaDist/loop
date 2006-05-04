--------------------------------------------------------------------------------
-- Project: LOOP Debugging Utilities for Lua                                  --
-- Version: 1.0 alpha                                                         --
-- Title  : Visualization of Lua Values                                       --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
-- Date   : 03/08/2005 16:35                                                  --
--------------------------------------------------------------------------------

local require      = require
local type         = type
local pairs        = pairs
local ipairs       = ipairs
local unpack       = unpack
local rawget       = rawget
local rawset       = rawset
local getmetatable = getmetatable
local luatostring  = tostring
local luaprint     = print

local string = require "string"
local table  = require "table"
local io     = require "io"
local loop   = require "loop"
local oo     = require "loop.base"

module("loop.debug.Viewer", loop.define(oo.class()))

maxdepth = false
identation = "  "
output = io.output()

function viewable(value)
	local type_name = type(value)
	return	(type_name ~= "function") and
					(type_name ~= "userdata") and
					(type_name ~= "thread")
end

function rawtostring(value)
	local result
	local meta = getmetatable(value)
	local backup
	if meta then
		backup = rawget(meta, "__tostring")
		if backup ~= nil then rawset(meta, "__tostring", nil) end
	end
	result = luatostring(value)
	if meta and backup ~= nil then
		rawset(meta, "__tostring", backup)
	end
	return result
end

function tostring(self, value, prefix, maxdepth, history)
	if not prefix then prefix = "" end
	if not maxdepth then maxdepth = self.maxdepth end
	if not history then history = {} end
	if viewable(value) then
		if type(value) == "table" then
			if not history[value] then
				history[value] = true
				local serialized = { "{ -- ", rawtostring(value), "\n" }
				local ident = table.concat{ prefix, self.identation }
				if not maxdepth or maxdepth > 0 then
					maxdepth = maxdepth and (maxdepth - 1)
					for key, field in pairs(value) do
						table.insert(serialized, ident)
						table.insert(serialized, "[")
						table.insert(serialized, self:tostring(key, ident, maxdepth, history))
						table.insert(serialized, "] = ")
						table.insert(serialized, self:tostring(field, ident, maxdepth, history))
						table.insert(serialized, ",\n")
					end
				else
					table.insert(serialized, ident)
					table.insert(serialized, "...\n")
				end
				table.insert(serialized, prefix)
				table.insert(serialized, "}")
				return table.concat(serialized)
			end
		elseif type(value) == "string" then
			return string.format("%q", value)
		else
			return rawtostring(value)
		end
	end
	return "(" .. rawtostring(value) .. ")"
end

function print(self, ...)
	for index, value in ipairs(arg) do
		arg[index] = self:tostring(value)
	end
	luaprint(unpack(arg, 1, arg.n))
end

function write(self, ...)
	for index = 1, arg.n do
		arg[index] = self:tostring(arg[index])
	end
	local output = self.output
	output:write(unpack(arg, 1, arg.n))
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function equivalent(value, other, history)
	if not history then history = {} end
	if value == other then
		return true
	elseif type(value) == type(other) then
		if history[value] == other then
			return true
		elseif not history[value] and type(value) == "table" then
			history[value] = other
			local keysfound = {}
			for key, field in pairs(value) do
				local otherfield = other[key]
				if otherfield == nil then
					local success = false
					for otherkey, otherfield in pairs(other) do
						if
							equals(key, otherkey, history) and
							equals(field, otherfield, history)
						then
							keysfound[otherkey] = true
							success = true
							break
						end
					end
					if not success then
						return false
					end
				elseif equals(field, otherfield, history) then
					keysfound[key] = true
				else
					return false
				end
			end
			for otherkey, otherfield in pairs(other) do
				if not keysfound[otherkey] then
					return false
				end
			end
			return true
		end
	end
	return false
end
