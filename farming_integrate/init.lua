minetest.log("action", "[MOD]"..minetest.get_current_modname().." -- start loading from "..minetest.get_modpath(minetest.get_current_modname()))

if minetest.get_modpath("moretrees") ~= nil then
	dofile(minetest.get_modpath("farming_integrate") .. "/moretrees.lua") 
end
if minetest.get_modpath("woodsoil") ~= nil then
	dofile(minetest.get_modpath("farming_integrate") .. "/woodsoil.lua") 
end
if minetest.get_modpath("ethereal") ~= nil then
	dofile(minetest.get_modpath("farming_integrate") .. "/ethereal.lua") 
end

if minetest.get_modpath("mobs_animal") ~= nil then
	dofile(minetest.get_modpath("farming_integrate") .. "/mobs_animal.lua") 
end

if minetest.get_modpath("treasures") ~= nil then
	dofile(minetest.get_modpath("farming_integrate") .. "/treasures.lua") 
end

if minetest.get_modpath("lucky_block") ~= nil then
	dofile(minetest.get_modpath("farming_integrate") .. "/lucky_block.lua") 
end

minetest.log("action", "[MOD]"..minetest.get_current_modname().." -- loaded ")
