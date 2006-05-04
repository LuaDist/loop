--------------------------------------------------------------------------------
---------------------- ##       #####    #####   ######  -----------------------
---------------------- ##      ##   ##  ##   ##  ##   ## -----------------------
---------------------- ##      ##   ##  ##   ##  ######  -----------------------
---------------------- ##      ##   ##  ##   ##  ##      -----------------------
---------------------- ######   #####    #####   ##      -----------------------
----------------------                                   -----------------------
----------------------- Lua Object-Oriented Programming ------------------------
--------------------------------------------------------------------------------
-- Project: LOOP Compilation Utilities                                        --
-- Release: 1.0 alpha                                                         --
-- Title  : Conditional Compiler for Code Generation                          --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
-- Date   : 13/12/2004 13:51                                                  --
--------------------------------------------------------------------------------

local type       = type
local assert     = assert
local ipairs     = ipairs
local setfenv    = setfenv
local loadstring = loadstring

local table = require "table"
local debug = require "debug"
local loop  = require "loop"
local oo    = require "loop.base"

module("loop.compiler.Conditional", loop.define(oo.class()))

function add(self, ...)
	table.insert(self, arg)
end

function source(self, includes)
	local func = {}
	for line, strip in ipairs(self) do
		local cond = strip[2]
		if cond then
			cond = assert(loadstring("return "..cond,
				"compiler condition "..line..":"))
			setfenv(cond, includes)
			cond = cond()
		else
			cond = true
		end
		if cond then
			assert(type(strip[1]) == "string",
				"code string is not a string")
			table.insert(func, strip[1])
		end
	end
	return table.concat(func, "\n")
end

function compile(self, includes, upvalues, name)
	func = assert(loadstring(self:source(includes), name))()
	if upvalues then
		local up = 1
		while debug.setupvalue(func, up, upvalues[debug.getupvalue(func, up)]) do
			up = up + 1
		end
	end
	return func
end