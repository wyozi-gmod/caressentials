caress = {}

for _, fil in pairs(file.Find("caress/sh_*.lua", "LUA")) do
	if SERVER then AddCSLuaFile("caress/" .. fil) end
	include("caress/" .. fil)
end
for _, fil in pairs(file.Find("caress/sv_*.lua", "LUA")) do
	if SERVER then include("caress/" .. fil) end
end
for _, fil in pairs(file.Find("caress/cl_*.lua", "LUA")) do
	if SERVER then AddCSLuaFile("caress/" .. fil) end
	if CLIENT then include("caress/" .. fil) end
end