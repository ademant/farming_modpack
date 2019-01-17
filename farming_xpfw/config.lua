
for i,attr in ipairs({"punch_fruits","dig_harvest"}) do
	xpfw.register_attribute(attr,{min=0,max=math.huge,default=0,hud=1})
end

farming_xpfw.dig_scale =  tonumber(minetest.settings:get("farming_xpfw.dig_scale")) or 50
farming_xpfw.punch_scale =  tonumber(minetest.settings:get("farming_xpfw.punch_scale")) or 50
farming_xpfw.log_dig_scale=math.log(farming_xpfw.dig_scale)
farming_xpfw.log_punch_scale=math.log(farming_xpfw.punch_scale)
