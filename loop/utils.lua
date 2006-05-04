--------------------------------------------------------------------------------
-- General utilities functions for Lua.

-- These functions are used in many package implementations and may also be
-- usefull in applications.

--------------------------------------------------------------------------------
-- Packs all arguments into a table.

-- All parameters values are stored in a table using numerical indices,
-- including nil values.

-- @return Array-like table containing parameter values.

-- @see unpack.

-- @usage results = pack(SQL.getRecords "select * from Clients")

function pack(...) return arg end

--------------------------------------------------------------------------------
-- Copies all elements stored in a table into another.

-- Each pair of key and value stored in table 'source' will be set into table
-- 'destiny'.
-- If no 'destiny' table is defined, a new empty table is used.

-- @param source Table containing elements to be copied.
-- @param destiny [optional] Table which elements must be copied into.

-- @return Table containing copied elements.

-- @usage copied = table.copy(results)
-- @usage table.copy(results, newcopy)

function table.copy(source, destiny)
	if source then
		if not destiny then destiny = {} end
		for field, value in pairs(source) do
			destiny[field] = value
		end
	end
	return destiny
end

--------------------------------------------------------------------------------
-- Clears all contens of a table.

-- All pairs of key and value stored in table 'source' will be removed by
-- setting nil to each key used to store values in table 'source'.

-- @param tab Table which must be cleared.
-- @usage return table.clear(results)

function table.clear(tab)
	local elem = next(tab)
	while elem do
		tab[elem] = nil
		elem = next(tab)
	end
	return tab
end
