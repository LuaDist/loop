--------------------------------------------------------------------------------
-- Project: Debugging Utilities for Lua                                       --
-- Release: 1.0 alpha                                                         --
-- Title  : Verbose mechanism for layered applications                        --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
-- Date   : 03/08/2005 16:35                                                  --
--------------------------------------------------------------------------------

local type         = type
local setmetatable = setmetatable
local assert       = assert
local ipairs       = ipairs
local tostring     = tostring
local pairs        = pairs
local error        = error
local require      = require

local io     = require "io"
local os     = require "os"
local math   = require "math"
local table  = require "table"
local string = require "string"

module "loop.debug.verbose"

local viewer = require "loop.debug.Viewer"

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Groups = {}
Flags = {}
Details = {}
Pause = {}
Timed = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

Viewer = viewer()
Viewer.identation = "|  "

local Output
function output(value)
	if value
		then Output = value
		else return Output
	end
end

output(io.output())

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local TabCount = 0
local TabBase = "        "
local LargestFlag = 5
function addtab() TabCount = TabCount + 1 end
function removetab() TabCount = math.max(TabCount - 1, 0) end
function settab(count) TabCount = count end
function gettab() return TabCount end
function gettabs()
	if TabCount > 0
		then return TabBase..string.rep(Viewer.identation, TabCount)
		else return TabBase
	end
end

local function write(flag, info)
	local ident = gettabs()	

	Output:write("[", flag, "]")
	Output:write(string.rep(" ", LargestFlag - string.len(flag) + 1))
	
	local time = (type(Timed) == "table") and Timed[flag] or Timed
	if time == true then
		Output:write(os.date(), " - ")
	elseif type(time) == "string" then
		Output:write(os.date(time), " ")
	end
	
	Output:write(string.rep(Viewer.identation, TabCount))

	for i = 1, table.getn(info) do
		Output:write(tostring(info[i]))
	end

	if type(Details) == "table" and Details[flag] or Details == true then
		for name, value in pairs(info) do
			if name ~= "n" and type(name) == "string" then
				Output:write("\n", ident, name, ": ", Viewer:tostring(value, ident))
			end
		end
	end

	if type(Pause) == "table" and Pause[flag] or Pause == true
		then io.read()
		else Output:write("\n")
	end

	Output:flush()
end

local function TaggedPrint(tag)
	return function (msg, start)
		if not msg then
			removetab()
		else
			if type(msg) == "string" then msg = {msg} end
			write(tag, msg)
			if start then addtab() end
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function addgroup(id, ...) Groups[id] = arg end
function insertlevel(id, ...) table.insert(Groups, id, arg) end
function setlevel(level, ...)
	assert(type(level) == "number", "invalid verbose level (number expected)")
	Groups[level] = arg
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function flag(name, value)
	if Groups[name] then
		for _, tag in ipairs(Groups[name]) do
			if value
				then flag(tag, value)
				else if not flag(flag) then return false end
			end
		end
	elseif value ~= nil then
		Flags[name] = value and TaggedPrint(name) or nil
		for name in pairs(Flags) do
			LargestFlag = math.max(LargestFlag, string.len(name))
		end
		TabBase = string.rep(" ", LargestFlag + 3)
	else
		return Flags[name] ~= nil, Details[name], Pause[name]
	end
end

function level(value)
	assert(type(value) == "number", "invalid verbose level (number expected)")
	if value then
		Flags = {}
		for i = 1, value do flag(i, true) end
	else
		for i = 1, table.getn(Groups) do
			if not flag(i) then return i - 1 end
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function valueOf(value, tag)
	if Flags[tag] then return Viewer:tostring(value, gettabs()) end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function foo() end
local meta = {}
setmetatable(_M, {
	__index = function(self, field)
		if field
			then return Flags[field] or foo
			else error("indexing verbose with nil")
		end
	end
})