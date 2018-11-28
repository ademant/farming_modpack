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

		awards.register_achievement("farming_cultured_wheat", {
			title = ("Cultured Wheat"),
			description = ("You got your first cultured wheat"),
			icon = "farming_awards_cultured_wheat.png",
			trigger = {
				type = "dig",
				item = "farming:culturedwheat",
				target = 1
			}
		})

		awards.register_achievement("farming_miller", {
			title = ("Farming Miller"),
			description = ("You are advanced miller"),
			icon = "farming_awards_miller.png",
			trigger = {
				type = "craft",
				item = "farming:flour",
				target = 100
			}
		})

end
