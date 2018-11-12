minetest.log("action", "[MOD]"..minetest.get_current_modname().." -- start loading from "..minetest.get_modpath(minetest.get_current_modname()))
-- Load files
dofile(minetest.get_modpath("farming_awards") .. "/awards.lua") --few helping functions
minetest.log("action", "[MOD]"..minetest.get_current_modname().." -- loaded ")
