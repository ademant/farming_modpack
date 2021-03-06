local S = farming.intllib
	-- fallback default definition, if no defaults given by configuration
local farming_default_env={temperature_min=0,temperature_max=100,humidity_min=0,humidity_max=100,
	elevation_min=0,elevation_max=31000,light_min=10,light_max=default.LIGHT_MAX,rarety=10,
	grow_time_mean=120,spread_rate=1e-5,infect_rate_base=1e-5,infect_rate_monoculture=1e-3,
	harvest_max=2,place_param2 = 3,}

-- function to check definition for a plant
-- and set to defaults values
local register_plant_check_def = function(def) -- time optimised
--	local starttime=os.clock()
	local actmodname=minetest.get_current_modname()
	local base_name=actmodname..":"..def.name
	def.mod_name=actmodname
	def.plant_name=def.name
	def.base_name=base_name
	def.basepng=base_name:gsub(":","_")
	
	-- check if at least default values are set
	for dn,dv in pairs(farming_default_env) do
		if def[dn] == nil then
			def[dn] = dv
		end
	end
	if not def.description then
		def.description = S(def.name:gsub("^%l", string.upper))
	end
	if not def.fertility then
		def.fertility = {"grassland"}
	end
	if def.groups.seed_grindable ~= nil then
		if not def.grind  then
			def.grind = base_name.."_grinded"
		end
	end
	if def.groups.seed_roastable ~= nil then
		if not def.roast then
			def.roast = base_name.."_roasted"
		end
	end
	if def.groups.for_coffee ~= nil then
		if def.roast ~= nil then
			if string.find(def.roast,"roasted")~=nil then
				def.coffeepowder=def.roast:gsub("roasted","powder")
			end
		end
	end
	-- check if seed_drop is set and check if it is a node name
	if def.seed_drop then
		if not string.match(def.seed_drop,":") then
			def.seed_drop=actmodname..":"..def.seed_drop
		end
		def.groups["has_harvest"] = 1
	end
	if def.groups.wiltable then
		if not def.wilt_time then
			def.wilt_time = farming.wilt_time
		end
	end
	if not def.place_param2 then
		def.place_param2 = 3
	end
	def.grow_time_min=math.floor(def.grow_time_mean*0.75)
	def.grow_time_max=math.floor(def.grow_time_mean*1.2)
--	print("time check definition "..1000*(os.clock()-starttime))
  return def
end

-- Register plants
farming.register_plant = function(def)
	-- Check def table
	if not def.steps then
		return nil
	end
	if not def.name then return end
	-- check definition
    def = register_plant_check_def(def)
	-- local definitions
	def.step_name=def.mod_name..":"..def.name
	def.seed_name=def.mod_name..":"..def.name.."_seed"
	def.plant_name = def.name
	local def_groups=def.groups
    -- if plant has harvest then registering
    if def_groups["has_harvest"] ~= nil then
		-- if plant drops seed of wild crop, set the wild seed as harvest
		def.harvest_name = def.step_name
		-- check if seed is dropped instead of harvest
		if def.seed_drop ~= nil then
			def.harvest_name = def.seed_drop
		end
--		print(def.harvest_name)
		farming.register_harvest(def)
    else
		def.harvest_name=def.seed_name
    end
    
    -- if plant should be wiltable, register
    if def_groups["wiltable"] == 2 then
		def.wilt_name=def.mod_name..":wilt_"..def.name
		farming.register_wilt(def)
	end

	-- register seed items, which can be planted
    farming.register_seed(def)

	-- register growing steps
	farming.register_steps(def)
	
	-- crops, which should be cultured, does not randomly appear on the field
	if (not def_groups["to_culture"]) then
		local edef=def
		local spread_def={name=def.step_name.."_1",
				temp_min=edef.temperature_min,temp_max=edef.temperature_max,
				hum_min=edef.humidity_min,hum_max=edef.humidity_max,
				y_min=edef.elevation_min,y_max=edef.elevation_max,base_rate = math.floor((-1)*math.log(def.spread_rate)),
				light_min=edef.light_min,light_max=edef.light_max}
		farming.min_light = math.min(farming.min_light,edef.light_min)
		-- add crop to spreading list, if base rate > 0
		if spread_def.base_rate > 0 then
			table.insert(farming.spreading_crops,1,spread_def)
		end
	end
	
	-- register if plant is infectable
    if def_groups["infectable"] then
      farming.register_infect(def)
    end
    
    -- if defined special roast, grind item or seed to drop,
    -- check if the item already exist. when not than register it.
    for _,it in ipairs({"grind","seed_drop"}) do
		if def[it] ~= nil then
			if minetest.registered_craftitems[def[it]] == nil then
				farming.register_craftitem(def[it])
			end
		end
	end

	-- for normal wheat the crafting of seeds out of harvest can directly registered
    if def_groups["use_flail"] then
		if def.straw == nil then
			def.straw= "farming:straw"
		end
		farming.craft_seed(def)
    end

	-- for plants using a trellis the seed is crafted out of harvest with a trellis
    if def_groups["use_trellis"] then
		farming.trellis_seed(def)
--		print(dump(def))
    end

    if def_groups["seed_grindable"] then
		farming.register_grind(def)
    end

    if def_groups["seed_roastable"] then
--		print(dump2(def))
		farming.register_roast(def)
    end

    if def_groups["for_coffee"] then
		farming.register_coffee(def)
    end

	if def.rarety_grass_drop ~= nil then
		if def.harvest_name ~= nil then
			table.insert(farming.grass_drop.items,1,{items={def.harvest_name},rarity=def.rarety_grass_drop})
		end
	end
	if def.rarety_junglegrass_drop ~= nil then
		if def.harvest_name ~= nil then
			table.insert(farming.junglegrass_drop.items,1,{items={def.harvest_name},rarity=def.rarety_junglegrass_drop})
		end
	end
	if def.rarety_decoration ~= nil then
	-- does not work yet
--		farming.register_deco(def)
	end
   	farming.registered_plants[def.name] = def
end

farming.register_harvest=function(hdef) --time optimised
	-- base definition of harvest
	local harvest_def={
		description = S(hdef.description:gsub("^%l", string.upper)),
		inventory_image = hdef.mod_name.."_"..hdef.plant_name..".png",
		groups = {flammable = 2,farming_harvest=1},
		plant_name=hdef.plant_name,
	}
--	print(hdef.step_name)
	minetest.register_craftitem(":" .. hdef.step_name, harvest_def)
end

farming.register_craftitem = function(itemname)
--	local starttime=os.clock()
	local desc = itemname:split(":")[2]
	local item_def={
		description = S(desc:gsub("^%l", string.upper)),
		inventory_image = itemname:gsub(":","_")..".png",
		groups = {flammable = 2},
	}
	minetest.register_craftitem(":"..itemname,item_def)
--	print("register craftitem "..math.ceil(1000*(os.clock()-starttime)))
end

farming.register_infect=function(idef)
--	local starttime=os.clock()
	local infectpng=idef.mod_name.."_"..idef.plant_name.."_ill.png"
	local infect_def={
		description = S(idef.description:gsub("^%l", string.upper)),
		tiles = {infectpng},
		drawtype = "plantlike",
		waving = 1,
		paramtype = "light",
		walkable = false,
		buildable_to = true,
		on_dig = farming.plant_cured , -- why digging fails?
		selection_box = {type = "fixed",
			fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5},},
		sounds = default.node_sound_leaves_defaults(),
		on_timer=farming.timer_infect,
		place_param2=idef.place_param2,
		groups = {snappy = 3, attached_node = 1, flammable = 2,farming_infect=2},
	}
	
	for _,coln in ipairs({"step_name","name","seed_name","plant_name",
		"infect_rate_base","infect_rate_monoculture"}) do
	  infect_def[coln] = idef[coln]
	end

	infect_def.groups[idef.plant_name] = 0
	minetest.register_node(":" .. idef.name.."_infected", infect_def)
--	print("time register infect "..1000*(os.clock()-starttime))
end

farming.register_wilt=function(idef)
--	local starttime=os.clock()
	if not idef.wilt_name then
		return
	end
	local wilt_def={
		description = S(idef.description:gsub("^%l", string.upper)).." "..S("wilted"),
		tiles = {idef.basepng.."_wilt.png"},
		drawtype = "plantlike",
		waving = 1,
		paramtype = "light",
		walkable = false,
		buildable_to = true,
		selection_box = {type = "fixed",
			fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5},},
		sounds = default.node_sound_leaves_defaults(),
		on_timer = farming.timer_wilt,
		place_param2=idef.place_param2,
		groups = {snappy = 3, attached_node = 1, flammable = 2,farming_wilt=1},
		grow_time_min=farming.wilt_removal_time,
		grow_time_max=math.ceil(1.1*farming.wilt_removal_time),
	}

	if idef.straw then
		wilt_def.drop={items={{items={idef.straw}}}}
	end
	
	for _,coln in ipairs({"name","seed_name","plant_name","fertility"}) do
	  wilt_def[coln] = idef[coln]
	end

	if idef.groups.wiltable then
		wilt_def.groups["wiltable"]=idef.groups.wiltable
	end
	minetest.register_node(":" .. idef.wilt_name, wilt_def)
--	print("time register wilt "..1000*(os.clock()-starttime))
end


farming.register_seed=function(sdef) --time optimised
--	local starttime=os.clock()
	local invimage=sdef.seed_name:gsub(":","_")..".png"
    local seed_def = {
		description=S(sdef.name):gsub("^%l", string.upper).." "..S("Seed"),
		next_step = sdef.step_name .. "_1",
		inventory_image = invimage,
		tiles = {invimage},
		wield_image = {invimage},
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
		on_place = farming.seed_on_place,
		on_timer = farming.timer_seed,
		place_param2=sdef.place_param2,
		groups = {farming_seed = 1, snappy = 3, attached_node = 1, flammable = 2},
	}
	
	for _,colu in ipairs({"fertility","plant_name","grow_time_min","grow_time_max","light_min"}) do
	  seed_def[colu] = sdef[colu]
	end
	seed_def.groups[sdef.mod_name] = 1
	
	
	for _, v in pairs(sdef.fertility) do
		seed_def.groups[v] = 1
	end
	
	for _,colu in ipairs({"on_soil","for_flour"}) do 
		if sdef.groups[colu] then
		  seed_def.groups[colu] = sdef.groups[colu]
		end
	end
	
	if sdef.eat_hp or sdef.drink then
		local eat_hp=0
		if sdef.eat_hp then
			eat_hp=sdef.eat_hp
		end
		if eat_hp>0 then
			seed_def.on_use=minetest.item_eat(eat_hp)
		end
		if sdef.eat_hp then
			seed_def.groups["eatable"]=sdef.eat_hp
		end
		if sdef.drink then
			seed_def.groups["drinkable"]=sdef.drink
		end
	end
	
	minetest.register_node(":" .. sdef.seed_name, seed_def)
--	print("time register seed "..1000*(os.clock()-starttime))
end

farming.register_steps = function(sdef)
--	local starttime=os.clock()
    -- base configuration of all steps
	-- copy some plant definition into definition of this steps
	-- define drop item: normal drop the seed
	local dropitem=sdef.seed_name
	-- if plant has to be harvested, drop harvest instead
	if sdef.groups.has_harvest then
		if sdef.seed_drop then
			dropitem = sdef.seed_drop
		else
			dropitem = sdef.step_name
		end
	end
	
	-- check if plant if hurting player
	local is_hurting=(sdef.groups.damage_per_second~=nil)
	local damage=0
	
	if is_hurting then
		damage=sdef.groups.damage_per_second
	end
	
	-- check if moving through plant is viscos
	local is_viscos=(sdef.groups.liquid_viscosity and farming.config:get_int("viscosity") > 0)
	local viscosity=0
	if is_viscos then
		viscosity=sdef.groups.liquid_viscosity
	end
	
	-- base definition for all steps
	local gdef={
		drawtype = "plantlike",
		waving = 1,
		paramtype = "light",
		walkable = false,
		buildable_to = true,
		selection_box = {type = "fixed",
			fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5},},
		sounds = default.node_sound_leaves_defaults(),
		drop_item=dropitem,
		drop_count=1,
		drop={items={{items={dropitem}},
				{items={dropitem},tools={"farming:scythe"},rarity=10}}}, --one more by digging with scythe
		place_param2=sdef.place_param2,
		groups = {snappy = 3, flammable = 2,flora=1, plant = 1, 
			not_in_creative_inventory = 1, attached_node = 1,
			},
	}
	-- copy other values into plant definition
	for _,colu in ipairs({"grow_time_min","grow_time_max","light_min","plant_name"}) do
		gdef[colu]=sdef[colu]
	end
	-- copy group values
	for _,colu in ipairs({"infectable","snappy","damage_per_second","liquid_viscosity","wiltable"}) do
		if sdef.groups[colu] then
		  gdef.groups[colu] = sdef.groups[colu]
		end
	end
	gdef.groups[sdef.mod_name]=1
	gdef.groups[sdef.plant_name]=1
	
	-- if plant uses trellis, give one back
	if sdef.groups.use_trellis then
		table.insert(gdef.drop.items,1,{items={"farming:trellis"}})
	end
		
	local max_step=sdef.steps
	local stepname=sdef.step_name.."_"
	-- loop for all steps
	for i=1,max_step do
		local reli=i/max_step
		local ndef=table.copy(gdef)
		-- adjust table definition
		ndef.description=S(sdef.step_name):gsub("^%l", string.upper).." "..i
		ndef.tiles={sdef.basepng.."_"..i..".png"}
		ndef.groups.step=i
		
		-- definitions for not full grown plants
		if i < max_step then
			ndef.groups["farming_grows"]=1 -- plant is growing
			ndef.next_step=stepname.. (i + 1) -- pointer to next plant
			ndef.on_timer = farming.timer_step -- setting normal timer function
		end

		-- additional definitions for plant step 2 and greater
		if i > 1 then
			-- check if plant hurts while going through
			if is_hurting then
				-- calculate damage as part of growing: Full damage only for full grown plant
				local step_damage=math.ceil(damage*reli)
				if step_damage > 0 then
					ndef.damage_per_second = step_damage
				end
			end

			-- for some crops you should walk slowly through like a wheat field
			if is_viscos then
				local step_viscosity=math.ceil(viscosity*reli)
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
		local step_harvest = math.floor(reli*sdef.harvest_max + 0.05)
		if step_harvest > 1 then
		  for h = 2,step_harvest do
			table.insert(ndef.drop.items,1,{items={dropitem}})--,rarity=(max_step - i + 1)*h})
		  end
		end

		-- definitions for fullgrown plants
		if i == max_step then
			ndef.groups["farming_fullgrown"]=1
			-- fullgrown plants can be punches to give harvest (if defined)
			for _,colu in ipairs({"punchable","seed_extractable"}) do
				if sdef.groups[colu] then
				  ndef.groups[colu] = sdef.groups[colu]
				end
			end
			
			-- if fullgrown plant can wilt, define wilt
			if sdef.groups.wiltable  then

				local nowilt=sdef.groups.wiltable
				if nowilt == 2 then -- normal wilt
					ndef.next_step=sdef.wilt_name
				elseif nowilt == 1 then -- berries loose their fruit
					ndef.next_step = stepname .. (i - 1)
				elseif nowilt == 3 then
					ndef.pre_step = stepname .. (i - 1)
					ndef.seed_name=sdef.seed_name
				end

				ndef.on_timer = farming.timer_step
				
				-- set wilt time to configured values
				ndef.grow_time_min=sdef.wilt_time or 540
				ndef.grow_time_max=math.ceil(ndef.grow_time_min*1.1)
			end

			-- at the end stage you can harvest by change a cultured seed (if defined)
			if sdef.next_plant then
			  local next_plant_rarity = (max_step - i + 1)*2
			  table.insert(ndef.drop.items,1,{items={sdef.next_plant},tools={"farming:scythe"},rarity=next_plant_rarity})
			end

			-- set pointer to second last step for punchable fruits
			if sdef.groups.punchable and i > 1 then
				ndef.pre_step = stepname.. (i - 1)
			end
			
			if sdef.groups.seed_extractable then
				ndef.seed_name = sdef.seed_name
			end
		end
		-- register node
		minetest.register_node(":" .. sdef.step_name.."_"..i, ndef)
	end
--	print("time register step "..1000*(os.clock()-starttime))
end

-- define seed crafting out of harvest, releasing kind of straw
function farming.craft_seed(gdef)
	if gdef.seed_name == nil then
		return
	end
	if gdef.harvest_name == nil then
		return
	end
	
	local straw_name = "farming:straw"
	if gdef.straw ~= nil then
		straw_name = gdef.straw
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

function farming.register_coffee(cdef)
--	local starttime=os.clock()
	if not cdef.coffeepowder then
		return
	end
	if not cdef.roast then
		return
	end
	
	local powder_png = cdef.coffeepowder:gsub(":","_")..".png"
	
	local powder_def={
		description = S(cdef.description:gsub("^%l", string.upper)).." "..S("powder"),
		inventory_image = powder_png,
		groups = {flammable = 2,food_grain_powder=1},
		plant_name=cdef.plant_name,
	}
	
	if cdef.eat_hp then
	  powder_def.on_use=minetest.item_eat(cdef.eat_hp)
	  powder_def.groups["eatable"]=cdef.eat_hp
	end
	minetest.register_craftitem(":" .. cdef.coffeepowder, powder_def)
	
	minetest.register_craft({
		type = "shapeless",
		output = cdef.coffeepowder,
		recipe = {cdef.roast,
				farming.modname..":coffee_grinder"},
	replacements = {{"group:food_coffee_grinder", farming.modname..":coffee_grinder"}},

	})
--	print("time register coffee "..1000*(os.clock()-starttime))
end

-- registering roast items if needed for plant
function farming.register_roast(rdef)
--	local starttime=os.clock()
	if not rdef.seed_name then
		return
	end
	if not rdef.roast then
		return
	end
	
	local roastitem=rdef.roast
	-- if no roast defined in config, register an own roast item
	if minetest.registered_craftitems[roastitem] == nil then
		local roast_png = roastitem:gsub(":","_")..".png"
		local rn = roastitem:split(":")[2]
		-- check for proper definition of roastitem
		if rn == nil then return end
		rn=rn:gsub("_"," ")
		
		local roast_def={
			description = S(rdef.description:gsub("^%l", string.upper)),
			inventory_image = roast_png,
			groups = {flammable = 2},
			plant_name=rdef.plant_name,
		}
		
		if rdef.groups.seed_roastable then
			roast_def.groups["seed_roastable"] = rdef.groups.seed_roastable
		end
		if rdef.eat_hp then
		  roast_def.on_use=minetest.item_eat(rdef.eat_hp*2)
		  roast_def.groups["eatable"]=rdef.eat_hp*2
		end
		
		minetest.register_craftitem(":" .. roastitem, roast_def)
	end
	
	local cooktime = 3
	if rdef.groups.seed_roastable then
		cooktime = rdef.groups.seed_roastable
	end
	
	local seedname=rdef.seed_name
	if rdef.seed_drop ~= nil then
		seedname=rdef.seed_drop
	end
	
	minetest.register_craft({
		type = "cooking",
		cooktime = cooktime or 3,
		output = roastitem,
		recipe = seedname
	})
--	print("time register roast "..1000*(os.clock()-starttime))
end

-- registering grind items
function farming.register_grind(rdef)
--	local starttime=os.clock()
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
	local grind_png = grinditem:gsub(":","_")..".png"
	
	local grind_def={
		description = S(desc:gsub("^%l", string.upper)).." "..S("roasted"),
		inventory_image = grind_png,
		groups = {flammable = 2},
		plant_name=rdef.plant_name,
	}
	
	if rdef.eat_hp then
	  grind_def.on_use=minetest.item_eat(rdef.eat_hp)
	  grind_def.groups["eatable"]=rdef.eat_hp
	end
	
	minetest.register_craftitem(":" .. grinditem, grind_def)
	
	minetest.register_craft({
		type = "shapeless",
		output = grinditem,
		recipe = {rdef.seed_name.." "..rdef.groups["seed_grindable"],
				farming.modname..":mortar_pestle"},
		replacements = {{"group:food_mortar_pestle", farming.modname..":mortar_pestle"}},

	})
--	print("time register grind "..1000*(os.clock()-starttime))
end

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

--	local starttime=os.clock()
--	print("time define infect "..1000*(os.clock()-starttime))

farming.register_deco = function(ddef)
-- register decoration if defined
	if ddef.rarety_decoration == nil then
		return
	end
	if ddef.seed_name == nil then
		return
	end
	if ddef.step_name == nil then
		return
	end
	local deco_name = ddef.step_name.."_"..ddef.steps
	if minetest.registered_items[deco_name] == nil then
		return
	end
	local spread=math.random(95,105)
	local deco_def={
		deco_type = "simple",
		place_on = table.copy(farming.change_soil),
		sidelen = 16,
		noise_params = {
			offset = 0,
			scale = ddef.rarety_decoration,
			spread = {x = spread, y = spread, z = spread},
			seed = math.random(1,314159),
			octaves = 3,
			persist = 0.6
		},
		y_min = ddef.elevation_min,
		y_max = ddef.elevation_max,
		decoration = {deco_name},
		name=deco_name,
	}
	if ddef.spawn_by then
		if minetest.registered_items[ddef.spawn_by]~= nil then
			deco_def.spawn_by=ddef.spawn_by
			deco_def.num_spawn_by=1
		end
	end
--	print(dump2(deco_def))
--	print(dump2(farming.change_soil))
	minetest.register_decoration(deco_def)
--	print(dump2(minetest.registered_decorations[deco_name]))
end

