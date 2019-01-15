local S = farming_craft.intllib
local modlist=minetest.get_modnames()

-- code from tenplus1 farming mod
-- cutting board

minetest.register_craftitem(":farming:cutting_board", {
	description = S("Cutting Board"),
	inventory_image = "farming_cutting_board.png",
	groups = {food_cutting_board = 1, flammable = 2},
})

minetest.register_craft({
	output = "farming:cutting_board",
	recipe = {
		{"default:steel_ingot", "", ""},
		{"", "group:stick", ""},
		{"", "", "group:wood"},
	}
})

-- juicer

minetest.register_craftitem(":farming:juicer", {
	description = S("Juicer"),
	inventory_image = "farming_juicer.png",
	groups = {food_juicer = 1, flammable = 2},
})

minetest.register_craft({
	output = "farming:juicer",
	recipe = {
		{"", "default:stone", ""},
		{"default:stone", "", "default:stone"},
	}
})

-- saucepan

minetest.register_craftitem(":farming:saucepan", {
	description = S("Saucepan"),
	inventory_image = "farming_saucepan.png",
	groups = {food_saucepan = 1, flammable = 2},
})

minetest.register_craft({
	output = "farming:saucepan",
	recipe = {
		{"default:steel_ingot", "", ""},
		{"", "group:stick", ""},
	}
})

-- cooking pot

minetest.register_craftitem(":farming:pot", {
	description = S("Cooking Pot"),
	inventory_image = "farming_pot.png",
	groups = {food_pot = 1, flammable = 2},
})

minetest.register_craft({
	output = "farming:pot",
	recipe = {
		{"group:stick", "default:steel_ingot", "default:steel_ingot"},
		{"", "default:steel_ingot", "default:steel_ingot"},
	}
})
