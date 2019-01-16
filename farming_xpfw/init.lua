minetest.log("action", "[MOD]"..minetest.get_current_modname().." -- start loading from "..minetest.get_modpath(minetest.get_current_modname()))

farming_xpfw={}
farming_xpfw.path = minetest.get_modpath("farming")
farming_xpfw.config = minetest.get_mod_storage()
farming_xpfw.modname=minetest.get_current_modname()

basic_functions.import_settingtype(farming_xpfw.path .. "/settingtypes.txt")

dofile(minetest.get_modpath("farming_xpfw") .. "/config.lua") 
dofile(minetest.get_modpath("farming_xpfw") .. "/api.lua") 

minetest.log("action", "[MOD]"..minetest.get_current_modname().." -- loaded ")
