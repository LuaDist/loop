--------------------------------------------------------------------------------
-- Project: LOOP Extra Utilities for Lua                                      --
-- Version: 1.0 alpha                                                         --
-- Title  : Class of Dynamic Wrapper Objects for Method Invokation            --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
-- Date   : 03/08/2005 16:35                                                  --
--------------------------------------------------------------------------------

local unpack = unpack
local type   = type

local debug = require "debug"
local loop  = require "loop"
local oo    = require "loop.base"

module("loop.extras.Wrapper", loop.define(oo.class()))

local object, method
local function wrappermethod(self, ...)
	return method(object, unpack(arg, 1, arg.n))
end

function __index(wrapper, key)
	local value = wrapper.wrapped[key]
	if type(value) == "function" then
		debug.setupvalue(wrappermethod, 1, value) -- set method
		debug.setupvalue(wrappermethod, 2, wrapper.wrapped) -- set object
		return wrappermethod
	end
	return value
end