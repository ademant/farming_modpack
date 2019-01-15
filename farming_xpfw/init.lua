minetest.log("action", "[MOD]"..minetest.get_current_modname().." -- start loading from "..minetest.get_modpath(minetest.get_current_modname()))

dofile(minetest.get_modpath("farming_xpfw") .. "/config.lua") 
dofile(minetest.get_modpath("farming_xpfw") .. "/api.lua") 

minetest.log("action", "[MOD]"..minetest.get_current_modname().." -- loaded ")
