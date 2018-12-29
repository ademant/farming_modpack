-- function to drink item on use with fallback to eat if thirsty mod not available
local drink_or_eat = function(hp_change,replace_with_item,itemstack,user,pointed_thing)
	if minetest.get_modpath("thirsty") ~= nil then
		thirsty.drink(user,3*hp_change)
	else
		minetest.do_item_eat(hp_change,replace_with_item,itemstack,user,pointed_thing)
	end
end

