if minetest.get_modpath("awards") then

		awards.register_achievement("farming_coffee", {
			title = ("Coffee"),
			description = ("You got your first coffee"),
			icon = "farming_awards_coffee.png",
			trigger = {
				type = "eat",
				item = "group:coffee",
				target = 1
			}
		})
		awards.register_achievement("farming_coffee_silver", {
			title = ("Coffee Silver"),
			description = ("You got your tenth coffee"),
			icon = "farming_awards_coffee_silver.png",
			requires="farming_coffee",
			trigger = {
				type = "eat",
				item = "group:coffee",
				target = 10
			}
		})

		awards.register_achievement("farming_coffee_gold", {
			title = ("Coffee Gold"),
			description = ("You had 30 coffee"),
			icon = "farming_awards_coffee_gold.png",
			requires="farming_coffee_silver",
			trigger = {
				type = "eat",
				item = "group:coffee",
				target = 30
			}
		})

		awards.register_achievement("farming_farmer", {
			title = ("Advanced Farmer"),
			description = ("You are an advanced farmer"),
			icon = "farming_awards_farmer.png",
			trigger = {
				type = "dig",
				item = "groups:for_flour",
				target = 100
			}
		})
		
		awards.register_achievement("farming_miller", {
			title = ("Farming Miller"),
			description = ("You are an advanced miller"),
			icon = "farming_awards_miller.png",
			trigger = {
				type = "craft",
				item = "farming:flour",
				target = 100
			},
			prizes = {"farming:mortar_pestle_highlevel","farming:bread 3"},
		})
		awards.register_achievement("farming_thresher", {
			title = ("Farming Thresher"),
			description = ("You are an advanced thresher"),
			icon = "farming_awards_thresher.png",
			trigger = {
				type = "craft",
				item = "group:for_flour",
				target = 100
			},
			prizes = {"farming:flour 10","farming:bread 5"},
		})

end
