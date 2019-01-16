farming.add_soil=function(soil2add)
	table.insert(farming.change_soil,soil2add)
end

-- Dummies for counting fruits. Should be overwritten in other mods
function farming.register_on_count_harvest(spec)
	-- Add function
	if #farming.registered_on_count_harvest == 0 then
		farming.registered_on_count_harvest={spec}
	else
		table.insert(farming.registered_on_count_harvest,1,spec)
	end
end

function farming.register_on_count_punching(spec)
	-- Add function
	if #farming.registered_on_count_punching == 0 then
		farming.registered_on_count_punching={spec}
	else
		table.insert(farming.registered_on_count_punching,1,spec)
	end
end

farming.ping_punch=function(playername,item,count)
	for _, func in ipairs(farming.registered_on_count_punching) do
		local bcheck = func(playername,item,count) 
	end
	return 
end

farming.ping_harvest=function(playername,item,count)
	for _, func in ipairs(farming.registered_on_count_harvest) do
		local bcheck = func(playername,item,count)
	end
	return 
end
