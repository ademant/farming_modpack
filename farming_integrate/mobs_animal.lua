if minetest.get_modpath("mobs_animal") ~= nil then

	if minetest.registered_entities["mobs_animal:cow"] then
		local cow_def=minetest.registered_entities["mobs_animal:cow"]
		table.insert(cow_def.follow,"farming:barley")
		table.insert(cow_def.follow,"farming:spelt")
		table.insert(cow_def.follow,"farming:culturewheat")
		table.insert(cow_def.follow,"farming:wildoat")
		table.insert(cow_def.replace_what,{"group:barley","air",0})
		table.insert(cow_def.replace_what,{"group:wheat","air",0})
		table.insert(cow_def.replace_what,{"group:spelt","air",0})
		table.insert(cow_def.replace_what,{"group:culturewheat","air",0})
		table.insert(cow_def.replace_what,{"group:wildoat","air",0})
		minetest.register_entity(":mobs_animal:cow",cow_def)
--		print(dump2(cow_def))
	end

	if minetest.registered_entities["mobs_animal:sheep"] then
		local cow_def=minetest.registered_entities["mobs_animal:sheep"]
		table.insert(cow_def.follow,"farming:barley")
		table.insert(cow_def.follow,"farming:spelt")
		table.insert(cow_def.follow,"farming:culturewheat")
		table.insert(cow_def.follow,"farming:wildoat")
		table.insert(cow_def.replace_what,{"group:barley","air",0})
		table.insert(cow_def.replace_what,{"group:wheat","air",0})
		table.insert(cow_def.replace_what,{"group:spelt","air",0})
		table.insert(cow_def.replace_what,{"group:culturewheat","air",0})
		table.insert(cow_def.replace_what,{"group:wildoat","air",0})
		minetest.register_entity(":mobs_animal:sheep",cow_def)
--		print(dump2(cow_def))
	end

	if minetest.registered_entities["mobs_animal:chicken"] then
		local cow_def=minetest.registered_entities["mobs_animal:chicken"]
		table.insert(cow_def.follow,"group:farming_seed")
		table.insert(cow_def.replace_what,{"group:farming_seed","air",0})
		minetest.register_entity(":mobs_animal:chicken",cow_def)
	end
	if minetest.registered_entities["mobs_animal:rat"] then
		local cow_def=minetest.registered_entities["mobs_animal:rat"]
		table.insert(cow_def.replace_what,{"group:farming_seed","air",0})
		table.insert(cow_def.replace_what,{"group:beetroot","air",0})
		table.insert(cow_def.replace_what,{"group:sugarbeet","air",0})
		table.insert(cow_def.replace_what,{"group:carrot","air",0})
		table.insert(cow_def.replace_what,{"group:corn","air",0})
		table.insert(cow_def.replace_what,{"group:potato","air",0})
		minetest.register_entity(":mobs_animal:rat",cow_def)
	end
	if minetest.registered_entities["mobs_animal:pumba"] then
		table.insert(cow_def.replace_what,{"group:beetroot","air",0})
		table.insert(cow_def.replace_what,{"group:sugarbeet","air",0})
		table.insert(cow_def.replace_what,{"group:carrot","air",0})
		table.insert(cow_def.replace_what,{"group:corn","air",0})
		table.insert(cow_def.replace_what,{"group:potato","air",0})
		minetest.register_entity(":mobs_animal:pumba",cow_def)
	end
	if minetest.registered_entities["mobs_animal:bunny"] then
		table.insert(cow_def.replace_what,"group:carrot")
		minetest.register_entity(":mobs_animal:pumba",cow_def)
	end
end
