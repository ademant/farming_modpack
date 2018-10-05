local S = farming.intllib

-- helping function for getting biomes
farming.get_biomes = function(biom_def)
--[[
  catch all biomes out of minetest.registered_biomes which fit definition
]]
	local possible_biomes={}
	local count_def=0
	if (biom_def.min_temp ~= nil or biom_def.max_temp ~= nil) then
	  count_def = count_def + 1
	end
	if (biom_def.min_humidity ~= nil or biom_def.max_humidity ~= nil) then
	  count_def = count_def + 1
	end
	if biom_def.spawnon then
		if (biom_def.min_humidity ~= nil or biom_def_max_humidity ~= nil) then
		  count_def = count_def + 1
		end
	end
	
	-- check definition: if not set, choose values, which should fit all biomes
	local mintemp = biom_def.min_temp or -100
	local maxtemp = biom_def.max_temp or 1000
	local minhum = biom_def.min_humidity or -100
	local maxhum = biom_def.max_humidity or 1000
	local minelev = biom_def.spawnon.spawn_min or 0
	local maxelev = biom_def.spawnon.spawn_max or 31000
	for name,def in pairs(minetest.registered_biomes) do
	  local bpossible = 0
	  if def.heat_point >= mintemp and def.heat_point <= maxtemp then
	    bpossible = bpossible + 1
	  end
	  if def.humidity_point >= minhum and def.humidity_point <= maxhum then
	    bpossible = bpossible + 1
	  end
	  if def.y_min <= maxelev and def.y_max >= minelev then
	    bpossible = bpossible + 1
	  end
	  if bpossible == count_def then
	    table.insert(possible_biomes,1,name)
	  end
	end
	return possible_biomes
end

-- function to check definition
-- and set to defaults values
local register_plant_check_def = function(def)
	if not def.description then
		def.description = "Seed"
	end
	if not def.inventory_image then
		def.inventory_image = "unknown_item.png"
	end
	if not def.minlight then
		def.minlight = 1
	end
	if not def.maxlight then
		def.maxlight = 14
	end
	if not def.fertility then
		def.fertility = {}
	end
	if not def.max_harvest then
	  def.max_harvest = 2
	end
	if not def.mean_grow_time then
	  def.mean_grow_time=math.random(170,220)
	end
	if not def.range_grow_time then
	  def.range_grow_time=math.random(15,25)
	end
	if def.range_grow_time > def.mean_grow_time then
	  def.range_grow_time = math.floor(def.mean_grow_time / 2)
	end
	def.min_grow_time=math.floor(def.mean_grow_time-def.range_grow_time)
	def.max_grow_time=math.floor(def.mean_grow_time+def.range_grow_time)
--	if not def.eat_hp then
--	  def.eat_hp = 1
--	end
	if not def.spawnon then
	  def.spawnon = { spawnon = {"default:dirt_with_grass"},
				spawn_min = 0,
				spawn_max = 42,
				spawnby = nil,
				scale = 0.006,
				offset = 0.12,
				spawn_num = -1}
	else
		def.spawnon.spawnon=def.spawnon.spawnon or {"default:dirt_with_grass"}
		def.spawnon.spawn_min = def.spawnon.spawn_min or 0
		def.spawnon.spawn_max = def.spawnon.spawn_max or 42
		def.spawnon.spawnby = def.spawnon.spawn_by or nil
		def.spawnon.scale = def.spawnon.scale or farming.rarety
		def.spawnon.offset = def.spawnon.offset or 0.02
		def.spawnon.spawn_num = def.spawnon.spawn_num or -1
	end
  return def
end


farming.register_harvest=function(hdef)
	local harvest_def={
		description = S(hdef.description:gsub("^%l", string.upper)),
		inventory_image = hdef.harvest_png,
		groups = hdef.groups or {flammable = 2},
	}
	for _,coln in ipairs({"plant_name","seed_name","harvest_name"}) do
	  harvest_def[coln] = hdef[coln]
	end

	if not harvest_def.groups["harvest"] then
	  harvest_def.groups["harvest"] = 1
	end
	--print(dump(harvest_def))
	minetest.register_craftitem(":" .. hdef.harvest_name, harvest_def)
end

farming.register_infect=function(idef)
	local infect_def={
		description = S(idef.description:gsub("^%l", string.upper)),
		inventory_image = idef.mod_name.."_"..idef.plantname.."_ill.png",
		groups = idef.groups or {flammable = 2,ill=2},
	}
	for _,coln in ipairs({"plant_name","seed_name","harvest_name"}) do
	  infect_def[coln] = idef[coln]
	end

	if not infect_def.groups["ill"] then
	  infect_def.groups["ill"] = 2
	end
	minetest.register_craftitem(":" .. idef.harvest_name.."_infected", infect_def)
end


farming.register_seed=function(sdef)
    local seed_def = {
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
		next_plant = sdef.harvest_name .. "_1",
		on_place = farming.seed_on_place,
		on_timer = farming.seed_on_timer,
	}
	for i,colu in ipairs({"inventory_image","minlight","maxlight","place_param2","fertility","description","spawnon","plant_name","seed_name","harvest_name"}) do
	  seed_def[colu] = sdef[colu]
	end
	seed_def.tiles = {sdef.inventory_image}
	seed_def.wield_image = {sdef.inventory_image}
	seed_def.groups = {seed = 1, snappy = 3, attached_node = 1, flammable = 2}
	for k, v in pairs(sdef.fertility) do
		seed_def.groups[v] = 1
	end
	if sdef.groups["on_soil"] then
	  seed_def.groups["on_soil"] = sdef.groups["on_soil"]
	end
	if sdef.eat_hp then
	  seed_def.on_use=minetest.item_eat(sdef.eat_hp)
	end
--	print(dump(seed_def))
	minetest.register_node(":" .. sdef.seed_name, seed_def)
--	farming.register_lbm(sdef.seed_name,sdef)
end


farming.register_steps = function(pname,sdef)
	-- check if plant gives harvest, where seed can be extractet or gives directly seed
    local has_harvest = true
    if sdef.groups["no_harvest"] then 
      has_harvest = false
    end
    -- check if plant give seeds if punched. then drop table is quite simple
    local is_punchable = false
    if sdef.groups["punchable"] then
      is_punchable = true
    end
    -- check if cultured plant exist
    local has_next_plant = false
    if sdef.next_plant then
      has_next_plant = true
    end

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
	for _,colu in ipairs({"paramtype2","place_param2","minlight","maxlight","seed_name","plant_name","harvest_name"}) do
	  if sdef[colu] then
	    node_def[colu] = sdef[colu]
	  end
	end
	local drop_item = sdef.seed_name
	if has_harvest then
	  drop_item = sdef.harvest_name
	end
	local lbm_nodes = {sdef.seed_name}
	for i=1,sdef.steps do
	    local ndef={}
	    for _,colu in ipairs({"minlight","maxlight","sounds","selection_box","drawtype","waving","paramtype","paramtype2","place_param2",
				"walkable","buildable_to","seed_name","plant_name","harvest_name"}) do
			ndef[colu]=node_def[colu]
		end
		ndef.groups = {snappy = 3, flammable = 2, plant = 1, not_in_creative_inventory = 1, attached_node = 1}
		ndef.groups[pname] = i
		ndef.tiles={sdef.mod_name.."_"..sdef.plant_name.."_"..i..".png"}
		if i < sdef.steps then
			ndef.next_plant=sdef.harvest_name .. "_" .. (i + 1)
			lbm_nodes[#lbm_nodes + 1] = sdef.harvest_name .. "_" .. i
			ndef.on_timer = farming.step_on_timer
		end
		local base_rarity = 1
		if sdef.steps ~= 1 then
			base_rarity =  8 - (i - 1) * 7 / (sdef.steps - 1)
		end
		ndef.drop={items={{items={drop_item}}}}

		local base_rarity = 1
		if sdef.steps ~= 1 then
			base_rarity =  sdef.steps - i + 1
		end

		-- with higher grow levels you harvest more
		local step_harvest = math.floor(i*sdef.max_harvest/sdef.steps + 0.05)
		if step_harvest > 1 then
		  for h = 2,step_harvest do
			table.insert(ndef.drop.items,1,{items={drop_item},rarity=base_rarity*h})
		  end
		end
		if i == sdef.steps then
		  ndef.on_dig = farming.harvest_on_dig
		end
		-- at the end stage you can harvest by change a cultured seed (if defined)
		if (i == sdef.steps and sdef.next_plant ~= nil) then
		  sdef.next_plant_rarity = sdef.next_plant_rarity or base_rarity*2
		  table.insert(ndef.drop.items,1,{items={sdef.next_plant},rarity=sdef.next_plant_rarity})
		end
		if i == sdef.steps and is_punchable then
		    ndef.pre_plant = sdef.harvest_name .. "_" .. (i - 1)
			ndef.on_punch = farming.step_on_punch
		end
		minetest.register_node(":" .. sdef.harvest_name .. "_" .. i, ndef)
--		print(sdef.harvest_name.."_"..i)
--		print(dump(node_def))
	end
	farming.register_lbm(lbm_nodes,sdef)
end

farming.register_lbm = function(lbm_nodes,def)
	-- replacement LBM for pre-nodetimer plants
	minetest.register_lbm({
		name = ":" .. def.mod_name .. ":start_nodetimer_" .. def.plant_name,
		nodenames = lbm_nodes,
		action = function(pos, node)
				minetest.get_node_timer(pos):start(math.random(farming.wait_min,farming.wait_max))
		end,
	})
end

farming.register_mapgen = function(mdef)
    -- register mapgen
    if mdef.groups.no_spawn == nil then
		local deco_def={
			deco_type = "simple",
			place_on = mdef.spawnon.spawnon,
			sidelen = 16,
			noise_params = {
				offset = mdef.spawnon.offset,
				scale = mdef.spawnon.scale, -- 0.006,
				spread = {x = 200, y = 200, z = 200},
				seed = 329,
				octaves = 3,
				persist = 0.6
			},
			y_min = mdef.spawnon.spawn_min,
			y_max = mdef.spawnon.spawn_max,
			decoration = mdef.wildname or mdef.harvest_name.."_"..mdef.steps,
			spawn_by = mdef.spawnon.spawnby,
			num_spawn_by = mdef.spawnon.spawn_num,
--			biomes = farming.get_biomes(def)
		}
		minetest.register_decoration(deco_def)
--	  end
	end
end

-- Register plants
farming.register_plant = function(name, def)
	-- Check def table
	if not def.steps then
		return nil
	end
	-- check definition
    def = register_plant_check_def(def)
    
	-- local definitions
	def.mod_name = name:split(":")[1]
	def.plant_name = name:split(":")[2]
	def.harvest_name=def.mod_name..":"..def.plant_name
	local harvest_name_png=def.mod_name.."_"..def.plant_name..".png"
	def.seed_name=def.mod_name..":seed_"..def.plant_name
	local seed_name_png=def.mod_name.."_seed_"..def.plant_name..".png"
	local lbm_nodes = {def.seed_name}

	farming.registered_plants[def.plant_name] = def
	-- check if plant gives harvest, where seed can be extractet or gives directly seed
    local has_harvest = true
    if def.groups["no_harvest"] then 
      has_harvest = false
    end
    -- check if plant give seeds if punched. then drop table is quite simple
    local is_punchable = false
    if def.groups["punchable"] then
      is_punchable = true
    end
    -- check if plant can get ill
    local is_infectable = false
    if def.groups["infectable"] then
      is_infectable = true
    end
    -- check if cultured plant exist
    local has_next_plant = false
    if def.next_plant then
      has_next_plant = true
    end
    
    -- if plant has harvest then registering
    if has_harvest then
      def.harvest_png=harvest_name_png
      farming.register_harvest(def)
    end
    
    farming.register_seed(def)

	farming.register_steps(def.plant_name,def)
	
	farming.register_mapgen(def)
	
    if is_infectable then
      farming.register_infect(def)
    end
end

-- Register new Scythes
farming.register_scythe = function(name, def)
	-- Check for : prefix (register new hoes in your mod's namespace)
	if name:sub(1,1) ~= ":" then
		name = ":" .. name
	end
	-- Check def table
	if def.description == nil then
		def.description = "Scythe"
	end
	if def.inventory_image == nil then
		def.inventory_image = "unknown_item.png"
	end
	if def.max_uses == nil then
		def.max_uses = 30
	end
	if not def.groups["scythe"] then
	  def.groups["scythe"] = 1
	end
	-- Register the tool
	minetest.register_tool(name, {
		description = def.description,
		inventory_image = def.inventory_image,
		groups = def.groups,
		sound = {breaks = "default_tool_breaks"},
	})
	-- Register its recipe
	if def.recipe then
		minetest.register_craft({
			output = name:sub(2),
			recipe = def.recipe
		})
	elseif def.material then
		minetest.register_craft({
			output = name:sub(2),
			recipe = {
				{def.material, def.material, "group:stick"},
				{def.material, "group:stick", ""},
				{"group:stick", "", ""}
			}
		})
	end
end


-- Register new Billhooks
farming.register_billhook = function(name, def)
	-- Check for : prefix (register new hoes in your mod's namespace)
	if name:sub(1,1) ~= ":" then
		name = ":" .. name
	end
	-- Check def table
	if def.description == nil then
		def.description = "Billhook"
	end
	if def.inventory_image == nil then
		def.inventory_image = "unknown_item.png"
	end
	if def.max_uses == nil then
		def.max_uses = 30
	end
	if not def.groups["billhook"] then
	  def.groups["billhook"] = 1
	end
	-- Register the tool
	minetest.register_tool(name, {
		description = def.description,
		inventory_image = def.inventory_image,
		groups = def.groups,
		sound = {breaks = "default_tool_breaks"},
	})
	-- Register its recipe
	if def.recipe then
		minetest.register_craft({
			output = name:sub(2),
			recipe = def.recipe
		})
	elseif def.material then
		minetest.register_craft({
			output = name:sub(2),
			recipe = {
				{"", def.material, def.material},
				{"", "group:stick", ""},
				{"group:stick", "", ""}
			}
		})
	end
end


farming.step_on_punch = function(pos, node, puncher, pointed_thing)
	local node = minetest.get_node(pos)
	local name = node.name
	local def = minetest.registered_nodes[name]
	-- grow
	local pre_node = def.pre_plant
	local placenode = {name = pre_node}
	if def.place_param2 then
		placenode.param2 = def.place_param2
	end
	minetest.swap_node(pos, placenode)
	puncher:get_inventory():add_item('main',def.seed_name)
	if puncher:get_wielded_item() == "farming:billhook_wood" then
  	  puncher:get_inventory():add_item('main',def.seed_name)
	end
	-- new timer needed?
	local pre_def=minetest.registered_nodes[pre_node]
	if pre_def.next_plant then
		minetest.get_node_timer(pos):start(math.random(pre_def.min_grow_time or 100, pre_def.max_grow_time or 200))
	end
end

farming.harvest_on_dig = function(pos, node, digger)
	local node = minetest.get_node(pos)
	local name = node.name
	local def = minetest.registered_nodes[name]
	print(dump(digger))
	if (def.next_plant == nil) and (digger:get_wielded_item() == "farming:scythe_wood") then
	  local plant_def=farming.registered_plants[def.plant_name]
	  local droptable={items={items={def.harvest.." "..(def.max_harvest+1)}}}
	  print("Hello World")
	  minetest.handle_node_drops(pos,droptable,digger)
	else
	  minetest.handle_node_drops(pos,def.drops,digger)
	end
	minetest.remove_node(pos)
end

farming.step_on_timer = function(pos, elapsed)
	local node = minetest.get_node(pos)
	local name = node.name
	local def = minetest.registered_nodes[name]
	print(name)
	print(dump(def))
	-- check if on wet soil and enough light
	local below = minetest.get_node({x = pos.x, y = pos.y - 1, z = pos.z})
	local light = minetest.get_node_light(pos)
	if ((minetest.get_item_group(below.name, "soil") < 3) and (minetest.get_item_group(node,"on_soil") >= 1))or
	 not light or light < def.minlight or light > def.maxlight then
		minetest.get_node_timer(pos):start(math.random(farming.wait_min, farming.wait_max))
		return
	end
	-- grow
	local placenode = {name = def.next_plant}
	if def.place_param2 then
		placenode.param2 = def.place_param2
	end
	minetest.swap_node(pos, placenode)
	-- new timer needed?
	if def.next_plant then
		local def_next=minetest.registered_nodes[def.next_plant]
		minetest.get_node_timer(pos):start(math.random(def_next.min_grow_time or 100, def_next.max_grow_time or 200))
	end
	return
end

-- Seed placement
-- adopted from minetest-game
farming.place_seed = function(itemstack, placer, pointed_thing, plantname)
	local pt = pointed_thing
	-- check if pointing at a node
	if not pt then
		return itemstack
	end
	if pt.type ~= "node" then
		return itemstack
	end

	local under = minetest.get_node(pt.under)
	local above = minetest.get_node(pt.above)
	local udef = minetest.registered_nodes[under.name]
	local pdef = minetest.registered_nodes[plantname]
--	print(plantname)
--	print(dump(pdef))
	local player_name = placer and placer:get_player_name() or ""

	if minetest.is_protected(pt.under, player_name) then
		minetest.record_protection_violation(pt.under, player_name)
		return
	end
	if minetest.is_protected(pt.above, player_name) then
		minetest.record_protection_violation(pt.above, player_name)
		return
	end

	-- return if any of the nodes is not registered
	if not minetest.registered_nodes[under.name] then
		return itemstack
	end
	if not minetest.registered_nodes[above.name] then
		return itemstack
	end

	-- check if pointing at the top of the node
	if pt.above.y ~= pt.under.y+1 then
		return itemstack
	end

	-- check if you can replace the node above the pointed node
	if not minetest.registered_nodes[above.name].buildable_to then
		return itemstack
	end

	-- check if pointing at soil and seed needs soil
	if (minetest.get_item_group(under.name, "soil") < 2) and (minetest.get_item_group(plantname,"on_soil") >= 1) then
		return itemstack
	end
	-- if not neet soil, check for other restrictions
	if (minetest.get_item_group(plantname,"on_soil")<1) then
	  --check for correct height as given in mapgen options
	  if (pt.under.y < pdef.spawnon.spawn_min or pt.under.y > pdef.spawnon.spawn_max) then
  	    return itemstack
	  end
	  -- check if node is in spawning list
	  local is_correct_node = false
	  for _,spawnon in ipairs(pdef.spawnon.spawnon) do
	    if under.name == spawnon then
	      is_correct_node = true
	    end
	  end
	  if not is_correct_node then
	    return itemstack
	  end
	end

	-- add the node and remove 1 item from the itemstack
	minetest.add_node(pt.above, {name = plantname, param2 = 1})
	minetest.get_node_timer(pt.above):start(math.random(farming.wait_min, farming.wait_max))
	if not (creative and creative.is_enabled_for
			and creative.is_enabled_for(player_name)) then
		itemstack:take_item()
	end
	return itemstack
end

farming.seed_on_timer = function(pos, elapsed)
	local node = minetest.get_node(pos)
	local name = node.name
	local def = minetest.registered_nodes[name]
	-- grow seed
	local soil_node = minetest.get_node_or_nil({x = pos.x, y = pos.y - 1, z = pos.z})
	if not soil_node then
		minetest.get_node_timer(pos):start(math.random(farming.wait_min, farming.wait_max))
		return
	end
	local spawnon={}
	for _,v in pairs(def.fertility) do
	  table.insert(spawnon,1,v)
	end
	for _,v in pairs(def.spawnon.spawnon) do
	  table.insert(spawnon,1,v)
	end
--	print(dump(spawnon))
--	print(dump(def))
	-- omitted is a check for light, we assume seeds can germinate in the dark.
--	for _, v in pairs(def.fertility) do
	for _, v in pairs(spawnon) do
		if (minetest.get_item_group(soil_node.name, v) ~= 0) or (soil_node.name == v) then
			local placenode = {name = def.next_plant}
			if def.place_param2 then
				placenode.param2 = def.place_param2
			end
			minetest.swap_node(pos, placenode)
			local def_next=minetest.registered_nodes[def.next_plant]
--			print(soil_node.name)
			print(def.next_plant)
			print(dump(def_next))
			if def.next_plant then
				local node_timer=math.random(def.min_grow_time or 100, def.max_grow_time or 200)
				print(node_timer)
				minetest.get_node_timer(pos):start(node_timer)
				return
			end
		end
	end
end
			
farming.seed_on_place = function(itemstack, placer, pointed_thing)
	local under = pointed_thing.under
	local node = minetest.get_node(under)
	local udef = minetest.registered_nodes[node.name]
	local plantname = itemstack:get_name()
	if udef and udef.on_rightclick and
			not (placer and placer:is_player() and
			placer:get_player_control().sneak) then
		return udef.on_rightclick(under, node, placer, itemstack,
			pointed_thing) or itemstack
	end
	return farming.place_seed(itemstack, placer, pointed_thing, plantname)
end

