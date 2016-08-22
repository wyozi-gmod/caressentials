local data = {}

function caress.registerVehicle(id, tbl)
	data[id] = tbl
end

function caress.getVehicleData(id)
	return data[id]
end

for _, fil in pairs(file.Find("caress/vehicles/*.lua", "LUA")) do
	if SERVER then AddCSLuaFile("caress/vehicles/" .. fil) end

	include("caress/vehicles/" .. fil)
end