hook.Add("OnEntityCreated", "Caress_AddCarInfo", function(e)
	if e:GetClass() ~= "prop_vehicle_jeep" then return end

	local info = ents.Create("caress_carinfo")
	info:SetPos(e:GetPos())
	info:SetParent(e)
	info:Spawn()

end)