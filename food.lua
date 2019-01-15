
local S = farming_craft.intllib
local modlist=minetest.get_modnames()

--= Sugar

minetest.register_craftitem(":farming:sugar", {
	description = S("Sugar"),
	inventory_image = "farming_sugar.png",
	groups = {food_sugar = 1, flammable = 3},
})

minetest.register_craft({
	type = "cooking",
	cooktime = 3,
	output = "farming:sugar 2",
	recipe = "default:papyrus",
})
minetest.register_craft({
	type = "cooking",
	cooktime = 2,
	output = "farming:sugar 3",
	recipe = "farming:sugarbeet_seed",
})


--= Salt

minetest.register_node(":farming:salt", {
	description = ("Salt"),
	inventory_image = "farming_salt.png",
	wield_image = "farming_salt.png",
	drawtype = "plantlike",
	visual_scale = 0.8,
	paramtype = "light",
	tiles = {"farming_salt.png"},
	groups = {food_salt = 1, vessel = 1, dig_immediate = 3,
			attached_node = 1},
	sounds = default.node_sound_defaults(),
	selection_box = {
		type = "fixed",
		fixed = {-0.25, -0.5, -0.25, 0.25, 0.3, 0.25}
	},
})

minetest.register_craft({
	type = "cooking",
	cooktime = 15,
	output = "farming:salt",
	recipe = "bucket:bucket_water",
	replacements = {{"bucket:bucket_water", "bucket:bucket_empty"}}
})

--= Rose Water

minetest.register_node(":farming:rose_water", {
	description = ("Rose Water"),
	inventory_image = "farming_rose_water.png",
	wield_image = "farming_rose_water.png",
	drawtype = "plantlike",
	visual_scale = 0.8,
	paramtype = "light",
	tiles = {"farming_rose_water.png"},
	groups = {food_rose_water = 1, vessel = 1, dig_immediate = 3,
			attached_node = 1},
	sounds = default.node_sound_defaults(),
	selection_box = {
		type = "fixed",
		fixed = {-0.25, -0.5, -0.25, 0.25, 0.3, 0.25}
	},
})

minetest.register_craft({
	output = "farming:rose_water",
	recipe = {
		{"flowers:rose", "flowers:rose", "flowers:rose"},
		{"flowers:rose", "flowers:rose", "flowers:rose"},
		{"bucket:bucket_water", "group:food_pot", "vessels:glass_bottle"},
	},
	replacements = {
		{"bucket:bucket_water", "bucket:bucket_empty"},
		{"group:food_pot", "farming:pot"},
	}
})

--= Turkish Delight

minetest.register_craftitem(":farming:turkish_delight", {
	description = S("Turkish Delight"),
	inventory_image = "farming_turkish_delight.png",
	groups = {flammable = 3},
	on_use = minetest.item_eat(2),
})

minetest.register_craft({
	output = "farming:turkish_delight 4",
	recipe = {
		{"group:food_gelatin", "group:food_sugar", "group:food_gelatin"},
		{"group:food_sugar", "group:food_rose_water", "group:food_sugar"},
		{"group:food_cornstarch", "group:food_sugar", "dye:pink"},
	},
	replacements = {
		{"group:food_cornstarch", "farming:bowl"},
		{"group:food_rose_water", "vessels:glass_bottle"},
	},
})

--= Garlic Bread

minetest.register_craftitem(":farming:garlic_bread", {
	description = S("Garlic Bread"),
	inventory_image = "farming_garlic_bread.png",
	groups = {flammable = 3},
	on_use = minetest.item_eat(2),
})

minetest.register_craft({
	type = "shapeless",
	output = "farming:garlic_bread",
	recipe = {"group:food_toast", "group:food_garlic_clove", "group:food_garlic_clove"},
})

--= Donuts (thanks to Bockwurst for making the donut images)

minetest.register_craftitem(":farming:donut", {
	description = S("Donut"),
	inventory_image = "farming_donut.png",
	on_use = minetest.item_eat(4),
})

minetest.register_craft({
	output = "farming:donut 3",
	recipe = {
		{"", "group:food_wheat", ""},
		{"group:food_wheat", "group:food_sugar", "group:food_wheat"},
		{"", "group:food_wheat", ""},
	}
})

minetest.register_craftitem(":farming:donut_chocolate", {
	description = S("Chocolate Donut"),
	inventory_image = "farming_donut_chocolate.png",
	on_use = minetest.item_eat(6),
})

minetest.register_craft({
	output = "farming:donut_chocolate",
	recipe = {
		{'group:food_cocoa'},
		{'farming:donut'},
	}
})

minetest.register_craftitem(":farming:donut_apple", {
	description = S("Apple Donut"),
	inventory_image = "farming_donut_apple.png",
	on_use = minetest.item_eat(6),
})

minetest.register_craft({
	output = "farming:donut_apple",
	recipe = {
		{'default:apple'},
		{'farming:donut'},
	}
})

--= Porridge Oats

minetest.register_craftitem(":farming:porridge", {
	description = S("Porridge"),
	inventory_image = "farming_porridge.png",
	on_use = minetest.item_eat(6, "farming:bowl"),
})

minetest.after(0, function()

	local fluid = "bucket:bucket_water"
	local fluid_return = "bucket:bucket_water"

	if minetest.get_modpath("mobs") and mobs and mobs.mod == "redo" then
		fluid = "group:food_milk"
		fluid_return = "mobs:bucket_milk"
	end

	minetest.register_craft({
		type = "shapeless",
		output = "farming:porridge",
		recipe = {
			"group:food_barley", "group:food_barley", "group:food_wheat",
			"group:food_wheat", "group:food_bowl", fluid
		},
		replacements = {{fluid_return, "bucket:bucket_empty"}}
	})
end)


minetest.register_craftitem(":farming:bread", {
	description = "Bread",
	inventory_image = "farming_bread.png",
	on_use = minetest.item_eat(5),
	groups = {food_bread = 1, flammable = 2},
})

minetest.register_craft({
	type = "cooking",
	cooktime = 15,
	output = "farming:bread",
	recipe = "farming:flour"
})


if basic_functions.has_value(modlist,"vessels") and basic_functions.has_value(modlist,"bucket") then
	minetest.register_craft( {
		output = ":farming:grain_coffee_cup 3",
		type = "shapeless",
		recipe = {"vessels:drinking_glass","vessels:drinking_glass","vessels:drinking_glass", "group:food_grain_powder",
			"bucket:bucket_water"},
		replacements = {
			{"bucket:bucket_water", "bucket:bucket_empty"},
		}
	})
	minetest.register_craft( {
		output = ":farming:coffee_cup",
		type = "shapeless",
		recipe = {"vessels:drinking_glass", "group:food_powder",
			"bucket:bucket_water"},
		replacements = {
			{"bucket:bucket_water", "bucket:bucket_empty"},
		}
	})
	minetest.register_craftitem(":farming:grain_coffee_cup", {
		description = "Grain Coffee",
		inventory_image = "farming_coffee_cup.png",
		on_use = minetest.item_eat(2,"vessels:drinking_glass"),
		groups = {coffee = 1, flammable = 1, beverage=1},
	})
	minetest.register_craftitem(":farming:grain_coffee_cup_hot", {
		description = "Grain Coffee hot",
		inventory_image = "farming_coffee_cup_hot.png",
		on_use = minetest.item_eat(4,"vessels:drinking_glass"),
		groups = {coffee = 2, flammable = 1, beverage=2},
	})
	minetest.register_craft({
		type = "cooking",
		cooktime = 2,
		output = "farming:grain_coffee_cup_hot",
		recipe = "farming:grain_coffee_cup"
	})
	minetest.register_craftitem(":farming:grain_milk", {
		description = "Grain Milk",
		inventory_image = "farming_grain_milk.png",
		on_use = minetest.item_eat(5,"vessels:drinking_glass"),
		groups = {flammable = 1, beverage=1},
	})
	minetest.register_craft( {
		output = ":farming:grain_milk 3",
		type = "shapeless",
		recipe = {"vessels:drinking_glass","vessels:drinking_glass","vessels:drinking_glass", "farming:flour",
			"bucket:bucket_water"},
		replacements = {
			{"bucket:bucket_water", "bucket:bucket_empty"},
		}
	})
else
	print("Mod vessels/bucket not available. Seriously? -> no COFFEE!")
end

if basic_functions.has_value(modlist,"wool") then
	minetest.register_craft({
		output="wool:white",
		type="shapeless",
		recipe={"farming:cotton","farming:cotton","farming:cotton","farming:cotton"},
		})
	minetest.register_craft({
		output="wool:dark_green",
		type="shapeless",
		recipe={"farming:nettle_fibre","farming:nettle_fibre","farming:nettle_fibre","farming:nettle_fibre"},
		})
	minetest.register_craft({
		output="wool:dark_green",
		type="shapeless",
		recipe={"farming:hemp_fibre","farming:hemp_fibre","farming:hemp_fibre","farming:hemp_fibre"},
		})
end

--copied from farming_mod
-- sliced bread
minetest.register_craftitem(":farming:bread_slice", {
	description = S("Sliced Bread"),
	inventory_image = "farming_bread_slice.png",
	on_use = minetest.item_eat(1),
	groups = {food_bread_slice = 1, flammable = 2},
})

minetest.register_craft({
	type = "shapeless",
	output = "farming:bread_slice 5",
	recipe = {"farming:bread", "group:food_cutting_board"},
	replacements = {{"group:food_cutting_board", "farming:cutting_board"}},
})

-- toast
minetest.register_craftitem(":farming:toast", {
	description = S("Toast"),
	inventory_image = "farming_toast.png",
	on_use = minetest.item_eat(1),
	groups = {food_toast = 1, flammable = 2},
})

minetest.register_craft({
	type = "cooking",
	cooktime = 3,
	output = "farming:toast",
	recipe = "farming:bread_slice"
})

-- toast sandwich
minetest.register_craftitem(":farming:toast_sandwich", {
	description = S("Toast Sandwich"),
	inventory_image = "farming_toast_sandwich.png",
	on_use = minetest.item_eat(4),
	groups = {flammable = 2},
})

minetest.register_craft({
	output = "farming:toast_sandwich",
	recipe = {
		{"farming:bread_slice"},
		{"farming:toast"},
		{"farming:bread_slice"},
	}
})

minetest.register_craftitem(":farming:smoothie", {
	description = S("Smoothie"),
	inventory_image = "farming_smoothie.png",
	groups = {flammable = 3},
	drink_hp=10,
	on_use = minetest.item_eat(2),
})
minetest.register_craft({
	type = "shapeless",
	output = "farming:smoothie 3",
	recipe = {"vessels:drinking_glass","vessels:drinking_glass","vessels:drinking_glass", "farming:blueberry_seed", 
		"farming:strawberry_seed","farming:raspberry_seed"},
})
