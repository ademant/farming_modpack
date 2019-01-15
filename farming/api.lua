farming.add_soil=function(soil2add)
	table.insert(farming.change_soil,soil2add)
end

function farming.register_on_harvest(spec)
	-- Add function
	if #farming.registered_on_harvest == 0 then
		farming.registered_on_harvest=spec
	else
		table.insert(farming.registered_on_harvest,1,spec)
	end
end

function farming.on_harvest(pos,node,digger)
	for _, func in ipairs(farming.registered_on_harvest) do
		itemstack = func(pos,node,digger) or itemstack
	end
	return itemstack
end
