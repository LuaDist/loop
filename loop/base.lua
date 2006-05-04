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
-- Name   : Base Class Model                                                 --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                --
-- Version: 2.1 alpha                                                        --
-- Date   : 19/4/2005 11:24                                                  --
-------------------------------------------------------------------------------
-- Exported API:                                                             --
--   class(class)                                                            --
--   new(class, ...)                                                         --
--   classof(object)                                                         --
--   isclass(class)                                                          --
--   instanceof(object, class)                                               --
-------------------------------------------------------------------------------

local type         = type
local setmetatable = setmetatable
local unpack       = unpack
local getmetatable = getmetatable
local rawget       = rawget

module "loop.base"

-------------------------------------------------------------------------------
function rawnew(class, object)
	return setmetatable(object or {}, class)
end
-------------------------------------------------------------------------------
function new(class, ...)
	if type(class.__init) == "function"
		then return rawnew(class, (class:__init(unpack(arg, 1, arg.n))))
		else return rawnew(class)
	end
end
-------------------------------------------------------------------------------
function initclass(class)
	if class == nil then class = {} end
	if rawget(class, "__index") == nil then class.__index = class end
	if class.__init == nil then class.__init = rawnew end
	return class
end
-------------------------------------------------------------------------------
local MetaClass = { __call = new }
function class(class)
	return setmetatable(initclass(class), MetaClass)
end
-------------------------------------------------------------------------------
classof = getmetatable
-------------------------------------------------------------------------------
function isclass(class)
	return classof(class) == MetaClass
end
-------------------------------------------------------------------------------
function instanceof(object, class)
	return classof(object) == class
end
