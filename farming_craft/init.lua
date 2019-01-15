-- Global farming namespace

farming_craft = {}
farming_craft.path = minetest.get_modpath("farming_craft")
farming_craft.config = minetest.get_mod_storage()
farming_craft.modname=minetest.get_current_modname()
farming_craft.mod = "redesign"
local S = dofile(farming_craft.path .. "/intllib.lua")
farming_craft.intllib = S


minetest.log("action", "[MOD]"..minetest.get_current_modname().." -- start loading from "..minetest.get_modpath(minetest.get_current_modname()))
-- Load files

-- import settingtypes.txt
basic_functions.import_settingtype(farming_craft.path .. "/settingtypes.txt")

dofile(farming_craft.path .. "/api.lua") -- several foods out of crops
dofile(farming_craft.path .. "/food.lua") -- several foods out of crops
dofile(farming_craft.path .. "/coffee.lua") -- several foods out of crops
dofile(farming_craft.path .. "/utensils.lua") -- several foods out of crops

minetest.log("action", "[MOD]"..minetest.get_current_modname().." -- loaded ")
