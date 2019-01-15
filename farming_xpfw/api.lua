
farming.register_on_count_punching(function(playername,item,count) 
	local player=minetest.get_player_by_name(playername)
	if count==nil then count=0 end
	xpfw.player_add_attribute(player,"punch_fruits",count)
end)

farming.register_on_count_harvest(function(playername,item,count) 
	local player=minetest.get_player_by_name(playername)
	if count==nil then count=0 end
	xpfw.player_add_attribute(player,"dig_harvest",count)
end)
