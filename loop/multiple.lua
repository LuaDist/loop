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
-- Name   : Multiple Inheritance Class Model                                 --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                --
-- Version: 2.1 alpha                                                        --
-- Date   : 19/4/2005 11:24                                                  --
-------------------------------------------------------------------------------
-- Exported API:                                                             --
--   class(class, ...)                                                       --
--   new(class, ...)                                                         --
--   classof(object)                                                         --
--   isclass(class)                                                          --
--   superclass(class)                                                       --
--   subclassof(class, super)                                                --
--   instanceof(object, class)                                               --
-------------------------------------------------------------------------------

local unpack  = unpack
local require = require
local ipairs  = ipairs

local table = require "table" require "loop.utils"

local pack = pack

module "loop.multiple"
-------------------------------------------------------------------------------
local base = require "loop.simple"
-------------------------------------------------------------------------------
table.copy(base, _M)
-------------------------------------------------------------------------------
local MultipleClassBehavior = {
	__call = new,
	__index = function (self, field)
		self = base.classof(self)
		local i = 1
		local super = self[i]
		while super do
			if super[field] ~= nil then
				return super[field]
			else
				i = i + 1
				super = self[i]
			end
		end
	end,
}

function class(class, ...)
	if table.getn(arg) > 1 then
		table.copy(MultipleClassBehavior, arg)
		return initclass(base.rawnew(arg, class))
	else
		return base.class(class, arg[1])
	end
end
-------------------------------------------------------------------------------
function isclass(class)
	local metaclass = base.classof(class)
	if metaclass then
		return metaclass.__index == MultipleClassBehavior.__index or
		       base.isclass(class)
	end
end
-------------------------------------------------------------------------------
function superclass(class)
	local metaclass = classof(class)
	if metaclass and (metaclass.__index == MultipleClassBehavior.__index)
		then return unpack(metaclass)
		else return base.superclass(class)
	end
end
-------------------------------------------------------------------------------
function subclassof(class, super)
	if class == super then
		return true
	else
		local supers = pack(superclass(class))
		for _, superclass in ipairs(supers) do
			if subclassof(superclass, super) then
				return true
			end
		end
	end
	return false
end
-------------------------------------------------------------------------------
function instanceof(object, class)
	return subclassof(classof(object), class)
end