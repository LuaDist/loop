# Copyright (C) 2007-2011 LuaDist.
# Created by Peter Drahoš
# Redistribution and use of this file is allowed according to the terms of the MIT license.
# For details see the COPYRIGHT file distributed with LuaDist.
# Please note that the package source code is licensed under its own license.

project ( loop NONE )
cmake_minimum_required ( VERSION 2.6 )
include ( dist.cmake)

install ( DIRECTORY lua/loop DESTINATION ${INSTALL_LMOD} )  #IMPROVE: use install_lua_module?
install_lua_executable ( precompiler lua/precompiler.lua )
install_lua_executable ( preloader lua/preloader.lua )
install_doc ( doc )
install_data ( LICENSE RELEASE )
