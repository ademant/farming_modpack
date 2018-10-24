local S = farming.intllib
-- function to check definition
-- and set to defaults values
local register_plant_check_def = function(def)
	local default_def={harvest_max=2,place_param2 = 3,mod_name=minetest.get_current_modname()}
	for dn,dv in pairs(default_def) do
		if def[dn] == nil then
			def[dn] = dv
		end
	end
	local default_env={temperature_min=0,temperature_max=100,humidity_min=0,humidity_max=100,
		elevation_min=0,elevation_max=31000,light_min=10,light_max=default.LIGHT_MAX,rarety=10,
		grow_time_mean=120,spread_rate=1e-5,infect_rate_base=1e-5,infect_rate_monoculture=1e-3}
	for dn,dv in pairs(default_env) do
		if def[dn] == nil then
			def[dn] = dv
		end
	end
	if not def.description then
		def.description = "Seed"
		if def.name then
			def.description = def.name
		end
	end
	if not def.fertility then
		def.fertility = {"grassland"}
	end
	if def.groups["seed_grindable"] then
		if def.grind == nil then
			def.grind = minetest.get_current_modname()..":"..def.description.."_grinded"
		end
	end
	if def.groups["seed_roastable"] then
		if def.roast == nil then
			def.roast = minetest.get_current_modname()..":"..def.description.."_roasted"
		end
	end
	-- check if seed_drop is set and check if it is a node name
	if def.seed_drop then
		local mname=def.seed_drop:split(":")[1]
		local sname=def.seed_drop:split(":")[2]
		if mname=="" then
			mname=minetest.get_current_modname()
			def.seed_drop=mname..":"..sname
		end
		def.groups["has_harvest"] = 1
	end
	if def.groups["wiltable"] ~= nil then
		if def.wilt_time == nil then
			def.wilt_time = farming.wilt_time
		end
	end
	def.grow_time_min=math.floor(def.grow_time_mean*0.75)
	def.grow_time_max=math.floor(def.grow_time_mean*1.2)
  return def
end

-- Register plants
farming.register_plant = function(def)
	-- Check def table
	if not def.steps then
		return nil
	end
	-- check definition
    def = register_plant_check_def(def)
	-- local definitions
	def.step_name=def.mod_name..":"..def.name
	def.seed_name=def.mod_name..":seed_"..def.name
	def.plant_name = def.name
    -- if plant has harvest then registering
    if def.groups["has_harvest"] ~= nil then
		-- if plant drops seed of wild crop, set the wild seed as harvest
		if def.seed_drop ~= nil then
			def.harvest_name = def.seed_drop
		else
			def.harvest_name = def.step_name
		end
		farming.register_harvest(def)
    else
		def.harvest_name=def.seed_name
    end
    
    if def.groups["wiltable"] == 2 then
		def.wilt_name=def.mod_name..":wilt_"..def.name
		farming.register_wilt(def)
	end
   	farming.registered_plants[def.name] = def

    farming.register_seed(def)

	farming.register_steps(def)
	
	if (not def.groups["to_culture"]) then
		local edef=def
		local spread_def={name=def.step_name.."_1",
				temp_min=edef.temperature_min,temp_max=edef.temperature_max,
				hum_min=edef.humidity_min,hum_max=edef.humidity_max,
				y_min=edef.elevation_min,y_max=edef.elevation_max,base_rate = def.spread_rate,
				light_min=edef.light_min,light_max=edef.light_max}
		farming.min_light = math.min(farming.min_light,edef.light_min)
		table.insert(farming.spreading_crops,1,spread_def)
	end
	
    if def.groups["infectable"] then
      farming.register_infect(def)
    end
    
    if def.groups["use_flail"] then
		def.straw_name="farming:straw"
		if def.straw then
			def.straw_name=def.straw
		end
		farming.seed_craft(def)
    end
    if def.groups["use_trellis"] then
		farming.trellis_seed(def)
    end
    if def.groups["seed_grindable"] then
		farming.register_grind(def)
    end
    if def.groups["seed_roastable"] then
		farming.register_roast(def)
    end
end

farming.register_harvest=function(hdef)
	-- base definition of harvest
	local harvest_def={
		description = S(hdef.description:gsub("^%l", string.upper)),
		inventory_image = hdef.mod_name.."_"..hdef.plant_name..".png",
		groups = {flammable = 2,farming_harvest=1},
	}
	-- copy fields from plant definition
	for _,coln in ipairs({"plant_name"}) do
	  harvest_def[coln] = hdef[coln]
	end
	-- some existing groups are copied
--	for _,coln in ipairs({"use_flail","use_trellis"}) do
--		if hdef.groups[coln] then
--			harvest_def.groups[coln] = hdef.groups[coln]
--		end
--	end
	minetest.register_craftitem(":" .. hdef.step_name, harvest_def)
end

farming.register_infect=function(idef)
	local infect_def={
		description = S(idef.description:gsub("^%l", string.upper)),
		inventory_image = idef.mod_name.."_"..idef.name.."_ill.png",
		tiles = {idef.mod_name.."_"..idef.name.."_ill.png"},
		wield_image = {idef.mod_name.."_"..idef.name.."_ill.png"},
		drawtype = "plantlike",
		waving = 1,
		paramtype = "light",
		walkable = false,
		buildable_to = true,
		on_dig = farming.plant_cured , -- why digging fails?
		selection_box = {type = "fixed",
			fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5},},
		sounds = default.node_sound_leaves_defaults(),
		on_timer=farming.infect_on_timer,
	}
	for _,coln in ipairs({"name","seed_name","plant_name",
		"place_param2","infect_rate_base","infect_rate_monoculture"}) do
	  infect_def[coln] = idef[coln]
	end

	infect_def.groups = {snappy = 3, attached_node = 1, flammable = 2,farming_infect=2}
--	infect_def.groups["step"] = -1
	infect_def.groups[idef.plant_name] = 0
	minetest.register_node(":" .. idef.name.."_infected", infect_def)
end
farming.register_wilt=function(idef)
	if idef.wilt_name == nil then
		return
	end
	local wilt_def={
		description = S(idef.description:gsub("^%l", string.upper).." wilted"),
		tiles = {idef.mod_name.."_"..idef.name.."_wilt.png"},
		drawtype = "plantlike",
		waving = 1,
		paramtype = "light",
		walkable = false,
		buildable_to = true,
		selection_box = {type = "fixed",
			fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5},},
		sounds = default.node_sound_leaves_defaults(),
		on_timer = farming.wilt_on_timer,
	}
	if idef.straw ~= nil then
		wilt_def.drop={items={{items={idef.straw}}}}
	end
	for _,coln in ipairs({"name","seed_name","plant_name","place_param2","fertility"}) do
	  wilt_def[coln] = idef[coln]
	end

	wilt_def.groups = {snappy = 3, attached_node = 1, flammable = 2,farming_wilt=1}
	wilt_def.groups["step"] = -1
	if idef.groups.wiltable ~= nil then
		wilt_def.groups["wiltable"]=idef.groups.wiltable
	end
	minetest.register_node(":" .. idef.wilt_name, wilt_def)
end


farming.register_seed=function(sdef)
    local seed_def = {
		description=S(sdef.name:gsub("^%l", string.upper).." Seed"),
		drawtype = "signlike",
		paramtype = "light",
		paramtype2 = "wallmounted",
		walkable = false,
		sunlight_propagates = true,
		selection_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5},
		},
		sounds = default.node_sound_dirt_defaults({
			dig = {name = "", gain = 0},
			dug = {name = "default_grass_footstep", gain = 0.2},
			place = {name = "default_place_node", gain = 0.25},
		}),
		next_step = sdef.step_name .. "_1",
		on_place = farming.seed_on_place,
		on_timer = farming.seed_on_timer,
	}
	for i,colu in ipairs({"place_param2","fertility","plant_name","grow_time_min","grow_time_max","light_min"}) do
	  seed_def[colu] = sdef[colu]
	end
	seed_def.inventory_image = sdef.mod_name.."_"..sdef.name.."_seed.png"
	seed_def.tiles = {seed_def.inventory_image}
	seed_def.wield_image = {seed_def.inventory_image}
	seed_def.groups = {farming_seed = 1, snappy = 3, attached_node = 1, flammable = 2}
	seed_def.groups["step"] = 0
	seed_def.groups[sdef.mod_name] = 1
	for k, v in pairs(sdef.fertility) do
		seed_def.groups[v] = 1
	end
	for i,colu in ipairs({"on_soil","for_flour"}) do 
		if sdef.groups[colu] then
		  seed_def.groups[colu] = sdef.groups[colu]
		end
	end
	if sdef.eat_hp then
	  seed_def.on_use=minetest.item_eat(sdef.eat_hp)
	end
	minetest.register_node(":" .. sdef.seed_name, seed_def)
end

farming.register_steps = function(sdef)
	-- check if plant gives harvest, where seed can be extractet or gives directly seed
--    local has_harvest = false
 --   if sdef.groups["has_harvest"] then 
--      has_harvest = true
--    end
    -- check if plant give seeds if punched. then drop table is quite simple
--    local is_punchable = false
--    if sdef.groups["punchable"] then
--      is_punchable = true
--    end
--    local seed_extractable = false
--    if sdef.groups["seed_extractable"] then
--      seed_extractable = true
--    end
    -- check if cultured plant exist
--    local has_next_plant = false
--    if sdef.next_plant then
--      has_next_plant = true
--    end

    -- base configuration of all steps
	local node_def = {
		drawtype = "plantlike",
		waving = 1,
		paramtype = "light",
		walkable = false,
		buildable_to = true,
		selection_box = {type = "fixed",
			fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5},},
		sounds = default.node_sound_leaves_defaults(),
	}
	-- copy some plant definition into definition of this steps
	for _,colu in ipairs({"paramtype2","place_param2","plant_name","grow_time_min","grow_time_max","light_min"}) do
	  if sdef[colu] then
	    node_def[colu] = sdef[colu]
	  end
	end
	-- define drop item: normal drop the seed
	node_def.drop_item = sdef.seed_name
	-- if plant has to be harvested, drop harvest instead
	if sdef.groups["has_harvest"] ~= nil then
		if sdef.seed_drop ~= nil then
			node_def.drop_item = sdef.seed_drop
		else
			node_def.drop_item = sdef.step_name
		end
	end
	for i=1,sdef.steps do
	    local ndef={description=sdef.step_name.."_"..i}
	    for _,colu in ipairs({"sounds","selection_box","drawtype","waving","paramtype","paramtype2","place_param2","grow_time_min","grow_time_max","light_min",
				"walkable","buildable_to","plant_name","drop_item"}) do
			ndef[colu]=node_def[colu]
		end
		ndef.groups = {snappy = 3, flammable = 2,flora=1, plant = 1, not_in_creative_inventory = 1, attached_node = 1}
		for _,colu in ipairs({"infectable","snappy","punchable","damage_per_second","liquid_viscosity","wiltable"}) do
			if sdef.groups[colu] then
			  ndef.groups[colu] = sdef.groups[colu]
			end
		end
		ndef.groups["step"] = i
		ndef.groups[sdef.mod_name]=1
		ndef.groups[sdef.plant_name]=1
		ndef.tiles={sdef.mod_name.."_"..sdef.plant_name.."_"..i..".png"}
		if i < sdef.steps then
			ndef.groups["farming_grows"]=1 -- plant is growing
			ndef.next_step=sdef.step_name .. "_" .. (i + 1)
			ndef.on_timer = farming.step_on_timer
			ndef.grow_time_min=sdef.grow_time_min or 120
			ndef.grow_time_max=sdef.grow_time_max or 180
		end
		ndef.drop={items={{items={ndef.drop_item}}}}
		if sdef.groups["use_trellis"] then
			table.insert(ndef.drop.items,1,{items={"farming:trellis"}})
		end
		-- hurting and viscosity not for first step, which is used for random generation
		if i > 1 then
			-- check if plant hurts while going through
			if ndef.groups["damage_per_second"] then
				-- calculate damage as part of growing: Full damage only for full grown plant
				local step_damage=math.ceil(ndef.groups["damage_per_second"]*i/sdef.steps)
				if step_damage > 0 then
					ndef.damage_per_second = step_damage
				end
			end
			-- for some crops you should walk slowly through like a wheat field
			if ndef.groups["liquid_viscosity"] and farming.config:get_int("viscosity") > 0 then
				local step_viscosity=math.ceil(ndef.groups["liquid_viscosity"]*i/sdef.steps)
				if step_viscosity > 0 then 
					ndef.liquid_viscosity= step_viscosity
					ndef.liquidtype="source"
					ndef.liquid_alternative_source=ndef.description
					ndef.liquid_alternative_flowing=ndef.description
					ndef.liquid_renewable=false
					ndef.liquid_range=0
				end
			end
		end

		-- with higher grow levels you harvest more
		local step_harvest = math.floor(i*sdef.harvest_max/sdef.steps + 0.05)
		if step_harvest > 1 then
		  for h = 2,step_harvest do
			table.insert(ndef.drop.items,1,{items={ndef.drop_item},rarity=(sdef.steps - i + 1)*h})
		  end
		end
		if i == sdef.steps then
			ndef.groups["farming_fullgrown"]=1
			ndef.on_dig = farming.harvest_on_dig
			if sdef.groups.wiltable ~= nil then
				if sdef.groups.wiltable == 2 then
					ndef.next_step=sdef.wilt_name
				end
				if sdef.groups.wiltable == 1 then
					ndef.next_step = sdef.step_name .. "_" .. (i - 1)
				end
				if sdef.groups.wiltable == 3 then
					ndef.pre_step = sdef.step_name .. "_" .. (i - 1)
					ndef.on_timer = farming.wilt_on_timer
					ndef.seed_name=sdef.seed_name
				end
				ndef.on_timer = farming.step_on_timer
				ndef.grow_time_min=sdef.wilt_time or 10
				ndef.grow_time_max=math.ceil(ndef.grow_time_min*1.1)
			end
		end
		-- at the end stage you can harvest by change a cultured seed (if defined)
		if (i == sdef.steps and sdef.next_plant ~= nil) then
		  sdef.next_plant_rarity = (sdef.steps - i + 1)*2
		  table.insert(ndef.drop.items,1,{items={sdef.next_plant},rarity=sdef.next_plant_rarity or 10})
		end
		if i == sdef.steps and sdef.groups["punchable"] and i > 1 then
		    ndef.pre_step = sdef.step_name .. "_" .. (i - 1)
			ndef.on_punch = farming.step_on_punch
		end
		minetest.register_node(":" .. ndef.description, ndef)
	end
end

farming.register_billhook = function(name,def)
  if not def.groups["billhook"] then
	def.groups["billhook"]=1
  end
  if not def.material then
    return
  end
  if def.max_uses == nil then
	def.max_uses = 30
  end
  if def.on_use == nil then
	def.on_use = function(itemstack, user, pointed_thing)
			return farming.billhook_on_use(itemstack, user, pointed_thing, def.max_uses)
		end
  end
  if not def.recipe then
	def.recipe = {
		{"", def.material, def.material},
		{"", "group:stick", ""},
		{"group:stick", "", ""} }
  end
  farming.register_tool(name,def)
end

farming.register_scythe = function(name,def)
  if not def.groups["scythe"] then
	def.groups["scythe"]=1
  end
  if not def.material then
    return
  end
  if not def.recipe then
	def.recipe = {
		{def.material, def.material, "group:stick"},
		{def.material, "group:stick", ""},
		{"group:stick", "", ""} }
  end
  farming.register_tool(name,def)
end

-- Register new Scythes
farming.register_tool = function(name, def)
	-- recipe has to be provided
	if not def.recipe then
		return
	end
	-- Check for : prefix (register new hoes in your mod's namespace)
	if name:sub(1,1) ~= ":" then
		name = ":" .. name
	end
	-- Check def table
	if def.description == nil then
		def.description = "Farming tool"
	end
	if def.inventory_image == nil then
		def.inventory_image = "unknown_item.png"
	end
	if def.max_uses == nil then
		def.max_uses = 30
	end
	def.sound={breaks = "default_tool_breaks"}

	-- Register the tool
	minetest.register_tool(name, def)
	-- Register its recipe
	minetest.register_craft({
		output = name:sub(2),
		recipe = def.recipe
	})
end

farming.plant_infect = function(pos)
	local node = minetest.get_node(pos)
	local def = minetest.registered_nodes[node.name]
	local infect_name=def.plant_name.."_infected"
	if not minetest.registered_nodes[infect_name] then
		return 
	end
	if not def.groups.infectable then
		return
	end
	if not def.groups.step then
		return
	end
	local placenode = {name = infect_name}
	if def.place_param2 then
		placenode.param2 = def.place_param2
	end
	minetest.swap_node(pos, placenode)
	local meta = minetest.get_meta(pos)
	meta:set_int("farming:step",def.groups["step"])
	minetest.get_node_timer(pos):start(math.random(farming.wait_min or 10,farming.wait_max or 20))
end
farming.plant_cured = function(pos)
	local node = minetest.get_node(pos)
	local name = node.name
	local def = minetest.registered_nodes[name]
	local meta = minetest.get_meta(pos)
	local cured_step=meta:get_int("farming:step")
	local cured_name=def.step_name.."_"..cured_step
	if not minetest.registered_nodes[cured_name] then
		return 
	end
	local placenode = {name = cured_name}
	if def.place_param2 then
		placenode.param2 = def.place_param2
	end
	minetest.swap_node(pos, placenode)
end

farming.step_on_punch = function(pos, node, puncher, pointed_thing)
	local node = minetest.get_node(pos)
	local def = minetest.registered_nodes[node.name]
	-- grow
	if def.groups.punchable == nil then
		return
	end
	if def.pre_step == nil then
		return
	end
	local pre_node = def.pre_step
	local placenode = {name = pre_node}
	if pre_node.place_param2 then
		placenode.param2 = pre_node.place_param2
	end
	minetest.swap_node(pos, placenode)
	
	if puncher ~= nil and puncher:get_player_name() ~= "" then
		puncher:get_inventory():add_item('main',def.drop_item)
	-- getting one more when using billhook
		local tool_def = puncher:get_wielded_item():get_definition()
		if tool_def.groups["billhook"] then
		  puncher:get_inventory():add_item('main',def.drop_item)
		end
	end
	-- new timer needed?
	local pre_def=minetest.registered_nodes[pre_node]
	local meta = minetest.get_meta(pos)
	meta:set_int("farming:step",pre_def.groups.step)
	if pre_def.next_step then
		minetest.get_node_timer(pos):start(math.random(pre_def.grow_time_min or 100, pre_def.grow_time_max or 200))
	end
	return 
end

farming.harvest_on_dig = function(pos, node, digger)
	--local node = minetest.get_node(pos)
	local def = minetest.registered_nodes[node.name]
	local tool_def = digger:get_wielded_item():get_definition()
	if (def.next_plant == nil) and (tool_def.groups["scythe"]) and def.drop_item then
   	  digger:get_inventory():add_item('main',def.drop_item)
	end
	minetest.node_dig(pos,node,digger)
end

farming.infect_on_timer = function(pos,elapsed)
	local node = minetest.get_node(pos)
	local def = minetest.registered_nodes[node.name]
	local meta = minetest.get_meta(pos)
--	local actual_step=meta:get_int("farming:step")
	if meta:get_int("farming:step") == nil then
		minetest.swap_node(pos, {name="air"})
		return
	end
	if meta:get_int("farming:step") == 0 then
		print("plant dies")
		minetest.swap_node(pos, {name="air"})
		return
	end
	local infected = 0
	if def.infect_rate_monoculture ~= nil then
		local monoculture=minetest.find_nodes_in_area(vector.subtract(pos,2),vector.add(pos,2),"group:"..def.plant_name)
		if monoculture ~= nil then
			for i = 1,#monoculture do
				if math.random(1,math.max(2,def.infect_rate_monoculture))==1 then
					farming.plant_infect(monoculture[i])
					print("infection spread")
					infected=infected+1
				end
			end
		end
	end
	if infected == 0 then
		if def.infect_rate_base ~= nil then
			local culture=minetest.find_nodes_in_area(vector.subtract(pos,3),vector.add(pos,3),"group:infectable")
			if culture ~= nil then
				for i = 1,#culture do
					if math.random(1,math.max(2,def.infect_rate_base))==1 then
						farming.plant_infect(culture[i])
						print("infection spread")
						infected=infected+1
					end
				end
			end
		end
	end
	meta:set_int("farming:step",meta:get_int("farming:step")-1)
	minetest.get_node_timer(pos):start(math.random(farming.wait_min,farming.wait_max))
end

farming.step_on_timer = function(pos, elapsed)
	local node = minetest.get_node(pos)
--	local name = node.name
	local def = minetest.registered_nodes[node.name]
	-- check for enough light
	local light = minetest.get_node_light(pos)
	if not def.next_step then
		return
	end
	local pdef=farming.registered_plants[def.plant_name]
	if not light or light < pdef.light_min or light > pdef.light_max then
		minetest.get_node_timer(pos):start(math.random(farming.wait_min*2, farming.wait_max*2))
		return
	end
--	local below = minetest.get_node({x = pos.x, y = pos.y - 1, z = pos.z})
	-- grow
	local placenode = {name = def.next_step}
	if def.place_param2 then
		placenode.param2 = def.place_param2
	end
--	minetest.set_node(pos, {name = def.next_step, param2 = 1})
	minetest.swap_node(pos, placenode)
	local meta = minetest.get_meta(pos)
	meta:set_int("farming:step",def.groups.step)
	-- new timer needed?
	if def.next_step then
		-- using light at midday to increase or decrease growing time
--		local local_light_max = minetest.get_node_light(pos,0.5)
		local wait_factor = math.max(0.75,def.light_min/minetest.get_node_light(pos,0.5))
		local wait_min = math.ceil(def.grow_time_min * wait_factor)
		local wait_max = math.ceil(def.grow_time_max * wait_factor)
		if wait_max <= wait_min then wait_max = 2*wait_min end
--		local node_timer=math.random(wait_min, wait_max)
		minetest.get_node_timer(pos):start(math.random(wait_min,wait_max))
	end
	return
end

-- Seed placement
-- adopted from minetest-game
farming.place_seed = function(itemstack, placer, pointed_thing, plantname)
	-- check if pointing at a node
	if not pointed_thing then
		return itemstack
	end
	if pointed_thing.type ~= "node" then
		return itemstack
	end

	-- check if pointing at the top of the node
	if pointed_thing.above.y ~= pointed_thing.under.y+1 then
		return itemstack
	end
	
	local player_name = placer and placer:get_player_name() or ""

	if minetest.is_protected(pointed_thing.under, player_name) then
		minetest.record_protection_violation(pointed_thing.under, player_name)
		return
	end
	if minetest.is_protected(pointed_thing.above, player_name) then
		minetest.record_protection_violation(pointed_thing.above, player_name)
		return
	end

	local under = minetest.get_node(pointed_thing.under)
	local above = minetest.get_node(pointed_thing.above)
	-- return if any of the nodes is not registered
	if not minetest.registered_nodes[under.name] then
		return itemstack
	end
	if not minetest.registered_nodes[above.name] then
		return itemstack
	end

	-- check if you can replace the node above the pointed node
	if not minetest.registered_nodes[above.name].buildable_to then
		return itemstack
	end

	local udef = minetest.registered_nodes[under.name]
	local pdef = minetest.registered_nodes[plantname]
	
	-- check if pointing at soil and seed needs soil
	if minetest.get_item_group(under.name,"soil") < 2 then
		if minetest.get_item_group(plantname,"on_soil") >= 1 then
			return
		else
			-- check if node is correct one
			local plant_def=farming.registered_plants[pdef.plant_name]
			-- check for correct temperature
			if pointed_thing.under.y < plant_def.elevation_min or pointed_thing.under.y > plant_def.elevation_max then
				minetest.chat_send_player(player_name,"Elevation must be between "..plant_def.elevation_min.." and "..plant_def.elevation_max)
				return
			end
			if minetest.get_heat(pointed_thing.under) < plant_def.temperature_min or minetest.get_heat(pointed_thing.under) > plant_def.temperature_max then
				minetest.chat_send_player(player_name,"Temperature "..minetest.get_heat(pt.under).." is out of range for planting.")
				return
			end
			if minetest.get_humidity(pointed_thing.under) < plant_def.humidity_min or minetest.get_humidity(pointed_thing.under) > plant_def.humidity_max then
				minetest.chat_send_player(player_name,"Humidity "..minetest.get_humidity(pt.under).." is out of range for planting.")
				return
			end
		end
	end
	-- add the node and remove 1 item from the itemstack
	minetest.add_node(pointed_thing.above, {name = plantname, param2 = 1})
	local wait_min=farming.wait_min or 120
	local wait_max=farming.wait_max or 240
	if pdef.grow_time_min then
		wait_min=pdef.grow_time_min
	end
	if pdef.grow_time_max then
		wait_max=pdef.grow_time_max
	end
	minetest.get_node_timer(pointed_thing.above):start(math.random(wait_min, wait_max))
	local meta = minetest.get_meta(pointed_thing.above)
	meta:set_int("farming:step",0)
	farming.set_node_metadata(pointed_thing.above)
	if not (creative and creative.is_enabled_for
			and creative.is_enabled_for(player_name)) then
		itemstack:take_item()
	end
	return itemstack
end

farming.seed_on_timer = function(pos, elapsed)
	local node = minetest.get_node(pos)
--	local name = node.name
	local def = minetest.registered_nodes[node.name]
	-- grow seed
	local soil_node = minetest.get_node_or_nil({x = pos.x, y = pos.y - 1, z = pos.z})
	if not soil_node then
		minetest.get_node_timer(pos):start(math.random(farming.wait_min, farming.wait_max))
		return
	end
--	local pdef=farming.registered_plants[def.plant_name]
--	local spawnon={}
--	for _,v in pairs(def.fertility) do
--	  table.insert(spawnon,1,v)
--	end
--	if def.spawnon then
--		for _,v in pairs(pdef.spawnon) do
--		  table.insert(spawnon,1,v)
--		end
--	end
--	local pdef=farming.registered_plants[def.plant_name]
	-- omitted is a check for light, we assume seeds can germinate in the dark.
	local placenode = {name = def.next_step}
	if def.place_param2 then
		placenode.param2 = def.place_param2
	end
	minetest.swap_node(pos, placenode)
	local meta = minetest.get_meta(pos)
	meta:set_int("farming:step",def.groups.step)
	if def.next_step then
		-- using light at midday to increase or decrease growing time
		local local_light_max = minetest.get_node_light(pos,0.5)
		local wait_factor = math.max(0.75,def.light_min/local_light_max)
		local wait_min = math.ceil(def.grow_time_min * wait_factor)
		local wait_max = math.ceil(def.grow_time_max * wait_factor)
		if wait_max <= wait_min then wait_max = 2*wait_min end
		local node_timer=math.random(wait_min, wait_max)
		minetest.get_node_timer(pos):start(node_timer)
		return
	end
end

-- actuall quite easy function to remove wilt plants
farming.wilt_on_timer = function(pos, elapsed)
	local node = minetest.get_node(pos)
--	local name = node.name
	local def = minetest.registered_nodes[node.name]
	if def.groups.wiltable <= 2 then -- normal crop
		minetest.swap_node(pos, {name="air"})
	end
	if def.groups.wiltable == 3 then -- nettle or weed
		-- determine all nearby nodes with soil
--		local pos0=vector.subtract(pos,2)
--		local pos1=vector.add(pos,2)
		local farming_nearby=minetest.find_nodes_in_area(vector.subtract(pos,2),vector.add(pos,2),"group:farming")
		if #farming_nearby <= 4 then
			local neighb=minetest.find_nodes_in_area(vector.subtract(pos,2),vector.add(pos,2),"group:soil")
			if neighb ~= nil then
				local freen={}
				-- get soil nodes with air above
				for j=1,#neighb do
					local jpos=neighb[j]
					if farming.has_value({"air","default:grass_1","default:grass_2","default:grass_3","default:grass_4","default:grass_5"},minetest.get_node({x=jpos.x,y=jpos.y+1,z=jpos.z}).name) then
						table.insert(freen,1,jpos)
					end
				end
				-- randomly pick one and spread
				if #freen >= 1 then
					local jpos=freen[math.random(1,#freen)]
					minetest.add_node({x=jpos.x,y=jpos.y+1,z=jpos.z}, {name = def.seed_name, param2 = 1})
					minetest.get_node_timer({x=jpos.x,y=jpos.y+1,z=jpos.z}):start(def.grow_time_min or 10)
				end
			end
		end
		-- after spreading the source has a one third change to be removed, to go one step back or stay
		local wran=math.random(1,math.max(3,#farming_nearby))
		if wran >= 3 then
			minetest.swap_node(pos, {name="air"})
		end
		if wran == 2 then
			if def.pre_step ~= nil then
				minetest.swap_node(pos, {name=def.pre_step, param2=1})
				minetest.get_node_timer(pos):start(math.random(def.grow_time_min or 10,def.grow_time_max or 20))
			end
		end
		if wran == 1 then
			minetest.get_node_timer(pos):start(math.random(def.grow_time_min or 10,def.grow_time_max or 20))
		end
	end
end
			
farming.seed_on_place = function(itemstack, placer, pointed_thing)
--	local under = pointed_thing.under
	local node = minetest.get_node(pointed_thing.under)
	local udef = minetest.registered_nodes[node.name]
	local plantname = itemstack:get_name()
	if udef and udef.on_rightclick and
			not (placer and placer:is_player() and
			placer:get_player_control().sneak) then
		return udef.on_rightclick(pointed_thing.under, node, placer, itemstack,
			pointed_thing) or itemstack
	end
	return farming.place_seed(itemstack, placer, pointed_thing, plantname)
end

-- using tools
-- adopted from minetest-games
farming.tool_on_dig = function(itemstack, user, pointed_thing, uses)
--	local pt = pointed_thing
	-- check if pointing at a node
	if not pointed_thing then
		return
	end

	local under = minetest.get_node(pointed_thing.under)
	local p = {x=pointed_thing.under.x, y=pointed_thing.under.y+1, z=pointed_thing.under.z}
	local above = minetest.get_node(p)

	-- return if any of the nodes is not registered
	if not minetest.registered_nodes[under.name] then
		return
	end
	if not minetest.registered_nodes[above.name] then
		return
	end

	-- check if the node above the pointed thing is air
	if above.name ~= "air" then
		return
	end

	if minetest.is_protected(pointed_thing.under, user:get_player_name()) then
		minetest.record_protection_violation(pointed_thing.under, user:get_player_name())
		return
	end
	if minetest.is_protected(pointed_thing.above, user:get_player_name()) then
		minetest.record_protection_violation(pointed_thing.above, user:get_player_name())
		return
	end
	if not (creative and creative.is_enabled_for
			and creative.is_enabled_for(user:get_player_name())) then
		-- wear tool
		local wdef = itemstack:get_definition()
		itemstack:add_wear(65535/(wdef.max_uses-1))
		minetest.node_dig(pt.under,under,user)
		-- tool break sound
		if itemstack:get_count() == 0 and wdef.sound and wdef.sound.breaks then
			minetest.sound_play(wdef.sound.breaks, {pos = pointed_thing.above, gain = 0.5})
		end
	end
	return itemstack
end

-- generate "seed" out of harvest and trellis
farming.trellis_seed = function(gdef)
	if gdef.seed_name == nil then
		return
	end
	if gdef.harvest_name == nil then
		return
	end
	
	
	minetest.register_craft({
	type = "shapeless",
	output = gdef.seed_name.." 1",
	recipe = {
		farming.modname..":trellis",gdef.harvest_name
	},
  })
end

-- define seed crafting
function farming.seed_craft(gdef)
	if gdef.seed_name == nil then
		return
	end
	if gdef.harvest_name == nil then
		return
	end
	local straw_name = "farming:straw"
	if gdef.straw_name ~= nil then
		straw_name = gdef.straw_name
	end
	minetest.register_craft({
		type = "shapeless",
		output = gdef.seed_name.." 1",
		recipe = {
			farming.modname..":flail",gdef.harvest_name
		},
		replacements = {{"group:farming_flail", farming.modname..":flail"},
				{gdef.harvest_name,straw_name}},
	})
end

function farming.register_roast(rdef)
	if rdef.seed_name == nil then
		return
	end
	if rdef.step_name == nil then
		return
	end
	local roastitem = rdef.step_name.."_roasted"
	if rdef.roast then
		roastitem = rdef.roast
	end
	local mname = minetest.get_current_modname()
	if rdef.mod_name then
		mname = rdef.mod_name
	end
	local roast_png = roastitem:gsub(":","_")..".png"
	
	local roast_def={
		description = S(rdef.description:gsub("^%l", string.upper).." roasted"),
		inventory_image = roast_png,
		groups = rdef.groups or {flammable = 2},
	}
	for _,coln in ipairs({"plant_name"}) do
	  roast_def[coln] = rdef[coln]
	end
	for _,coln in ipairs({"seed_roastable"}) do
		if rdef.groups[coln] then
			roast_def.groups[coln] = rdef.groups[coln]
		end
	end
	if rdef.eat_hp then
	  roast_def.on_use=minetest.item_eat(rdef.eat_hp*2)
	end
	
	minetest.register_craftitem(":" .. roastitem, roast_def)
	
	local cooktime = 3
	if rdef.roast_time then
		cooktime = rdef.roast_time
	end
	minetest.register_craft({
		type = "cooking",
		cooktime = cooktime or 3,
		output = roastitem,
		recipe = rdef.seed_name
	})
end

function farming.register_grind(rdef)
	if rdef.seed_name == nil then
		return
	end
	if rdef.step_name == nil then
		return
	end
	local grinditem = rdef.step_name.."_flour"
	if rdef.grind then
		grinditem = rdef.grind
	end
	local desc = grinditem:split(":")[2]
	desc = desc:gsub("_"," ")
	local mname = minetest.get_current_modname()
	if rdef.mod_name then
		mname = rdef.mod_name
	end
	local grind_png = grinditem:gsub(":","_")..".png"
	
	local grind_def={
		description = S(desc:gsub("^%l", string.upper).." roasted"),
		inventory_image = grind_png,
		groups = rdef.groups or {flammable = 2},
	}
	for _,coln in ipairs({"plant_name"}) do
	  grind_def[coln] = rdef[coln]
	end
	for _,coln in ipairs({"seed_roastable"}) do
		if rdef.groups[coln] then
			grind_def.groups[coln] = rdef.groups[coln]
		end
	end
	
	if rdef.eat_hp then
	  grind_def.on_use=minetest.item_eat(rdef.eat_hp)
	end
	
	minetest.register_craftitem(":" .. grinditem, grind_def)
	
	local cooktime = 3
	if rdef.roast_time then
		cooktime = rdef.roast_time
	end
	minetest.register_craft({
		type = "shapeless",
		output = grinditem,
		recipe = {rdef.seed_name.." "..rdef.groups["seed_grindable"],
				farming.modname..":mortar_pestle"},
	replacements = {{"group:food_mortar_pestle", farming.modname..":mortar_pestle"}},

	})
end

farming.billhook_on_use = function(itemstack, user, pointed_thing, uses)
--	local pt = pointed_thing
	-- check if pointing at a node
	if not pointed_thing then
		return
	end
	if pointed_thing.type ~= "node" then
		return
	end
	local under = minetest.get_node(pointed_thing.under)
	-- return if any of the nodes is not registered
	if not minetest.registered_nodes[under.name] then
		return
	end

	local pdef=minetest.registered_nodes[under.name]
	-- check if pointing at punchable crop
	if pdef.groups.punchable == nil then
		return
	end
	if minetest.is_protected(pointed_thing.under, user:get_player_name()) then
		minetest.record_protection_violation(pointed_thing.under, user:get_player_name())
		return
	end

	local tdef=itemstack:get_definition()
	if not (creative and creative.is_enabled_for
			and creative.is_enabled_for(user:get_player_name())) then
		-- wear tool
		itemstack:add_wear(65535/(uses-1))
		-- tool break sound
		if itemstack:get_count() == 0 and tdef.sound and tdef.sound.breaks then
			minetest.sound_play(tdef.sound.breaks, {pos = pointed_thing.above, gain = 0.5})
		end
	end
	user:get_inventory():add_item('main',pdef.drop_item)
	if tdef.farming_change ~= nil then
		if math.random(1,tdef.farming_change)==1 then
			user:get_inventory():add_item('main',pdef.drop_item)
		end
	end
--	minetest.node_punch(pt.under, under, user, pointed_thing)
	minetest.punch_node(pointed_thing.under)
	return itemstack
end

farming.set_node_metadata=function(pos)
	local base_rate = 5
	local node = minetest.get_node(pos)
	local def = minetest.registered_nodes[node.name]
	local pdef = farming.registered_plants[def.plant_name]
	local ill_rate=base_rate * (pdef.light_max-minetest.get_node_light(pos,0.5))/(pdef.light_max-pdef.light_min)
	-- calc coeff for temperature
	local ill_temp=(base_rate * math.sqrt(math.min(minetest.get_heat(pos)-pdef.temperature_min,pdef.temperature_max-minetest.get_heat(pos))/(pdef.temperature_max-pdef.temperature_min)))
	-- negative coeff means, it is out of range
	if ill_temp < 0 then
		ill_temp = (ill_temp * (-0.75))
	end
	-- calc coeff for humidity
	local ill_hum=(base_rate * math.sqrt(math.min(minetest.get_humidity(pos)-pdef.humidity_min,pdef.humidity_max-minetest.get_humidity(pos))/(pdef.humidity_max-pdef.humidity_min)))
	-- negative coeff means, it is out of range
	if ill_hum < 0 then
		ill_hum = (ill_hum * (-0.75))
	end
	local infect_rate = 1
	if pdef.groups.infectable then
		infect_rate = pdef.groups.infectable
	end
	ill_rate = math.ceil((ill_rate + ill_temp + ill_hum)/infect_rate)
	local meta = minetest.get_meta(pos)
	meta:set_int("farming:weakness",ill_rate)

	-- calculating 
	local day_start=99999
	local light_amount=0
	for i=50,120 do
		if minetest.get_node_light(pos,(i)/240)>pdef.light_min then
			light_amount=light_amount+minetest.get_node_light(pos,i/240)
			day_start=math.min(day_start,i)
		end
	end
	if day_start > 240 then
		day_start=120
	end
	-- daytime, when light reach light_min
	meta:set_float("farming:daystart",day_start/240)
	-- amount of light the crop gets till midday
	meta:set_int("farming:lightamount",light_amount)
end
