
for i,attr in ipairs({"punch_fruits","dig_harvest"}) do
	xpfw.register_attribute(attr,{min=0,max=math.huge,default=0,hud=1})
end
