
minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
	local def = minetest.registered_nodes[node.name]
	print("pong")
	if def.groups.punchable == nil then
		return
	end
	print("ppong")

	if puncher == nil or puncher:get_player_name() == "" then
		return
	end
	
	print("pppong")
	local punched_fruits=xpfw.player_get_attribute(puncher,"punch_fruits")
	if punched_fruits ~= nil then
		punched_fruits=1+math.floor(math.log(punched_fruits)/farming_xpfw.punch_scale)
		if punched_fruits > 1 then
			if math.random(1,punched_fruits)>1 then
				puncher:get_inventory():add_item('main',def.drop_item)
			end
		end
	end
	
	local tool_def = puncher:get_wielded_item():get_definition()
	print("ppppong")

	-- add one point to punch experience
	xpfw.player_add_attribute(puncher,"punch_fruits",1)
	if tool_def.groups.billhook then
		-- add half point additional, if using billhook
		xpfw.player_add_attribute(puncher,"punch_fruits",0.5)
	end

end)

minetest.register_on_dignode(function(pos, node, digger)
	local def = minetest.registered_nodes[node.name]

	print("ping")
	if def.drop_item == nil then
		return
	end

	print("pping")
	if digger == nil or digger:get_player_name() == "" then
		return
	end
	
	print("ppping")
	local dig_harvest=xpfw.player_get_attribute(puncher,"dig_harvest")
	if dig_harvest ~= nil then
		dig_harvest=1+math.floor(math.log(dig_harvest)/farming_xpfw.dig_scale)
		if dig_harvest > 1 then
			if math.random(1,dig_harvest)>1 then
				digger:get_inventory():add_item('main',def.drop_item)
			end
		end
	end
	
	local tool_def = puncher:get_wielded_item():get_definition()
	print("pppping")

	-- add one point to punch experience
	xpfw.player_add_attribute(puncher,"dig_harvest",1)
	if tool_def.groups.scythe then
		-- add half point additional, if using billhook
		xpfw.player_add_attribute(puncher,"dig_harvest",0.5)
	end

end)
