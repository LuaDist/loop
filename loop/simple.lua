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
-- Name   : Simple Inheritance Class Model                                   --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                --
-- Version: 2.1 alpha                                                        --
-- Date   : 19/4/2005 11:24                                                  --
-------------------------------------------------------------------------------
-- Exported API:                                                             --
--   class(class, super)                                                     --
--   new(class, ...)                                                         --
--   classof(object)                                                         --
--   isclass(class)                                                          --
--   superclass(class)                                                       --
--   subclassof(class, super)                                                --
--   instanceof(object, class)                                               --
-------------------------------------------------------------------------------

local require = require
local rawget  = rawget

local table = require "table" require "loop.utils"

module "loop.simple"
-------------------------------------------------------------------------------
local ObjectCache = require "loop.collection.ObjectCache"
local base        = require "loop.base"
-------------------------------------------------------------------------------
table.copy(base, _M)
-------------------------------------------------------------------------------
local DerivedClasses = ObjectCache {
	retrieve = function(self, super)
		return base.class { __index = super, __call = new }
	end,
}
function class(class, super)
	if super
		then return initclass(rawnew(DerivedClasses[super], class or {}))
		else return base.class(class)
	end
end
-------------------------------------------------------------------------------
function isclass(class)
	local metaclass = classof(class)
	if metaclass then
		return metaclass == rawget(DerivedClasses, metaclass.__index) or
		       base.isclass(class)
	end
end
-------------------------------------------------------------------------------
function superclass(class)
	local metaclass = classof(class)
	return ( metaclass and
	         metaclass == rawget(DerivedClasses, metaclass.__index) and
	         metaclass.__index ) or nil
end
-------------------------------------------------------------------------------
function subclassof(class, super)
	while class do
		if class == super then return true end
		class = superclass(class)
	end
	return false
end
-------------------------------------------------------------------------------
function instanceof(object, class)
	return subclassof(classof(object), class)
end