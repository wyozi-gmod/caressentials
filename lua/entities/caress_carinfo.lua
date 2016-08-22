if SERVER then
	AddCSLuaFile()
end

ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.RenderGroup = RENDERGROUP_OPAQUE

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "ActiveLights")
end

function ENT:Initialize()
	if SERVER then
		self:SetModel("models/props_borealis/bluebarrel001.mdl")
		self:PhysicsInit(SOLID_NONE)
	end
end

function ENT:GetVehData()
	if self.vehData then return self.vehData end

	local par = self:GetParent()
	if IsValid(par) then
		local data = caress.getVehicleData(par:GetModel())
		if data then
			self.vehData = data
			return data
		else
			print("ERROR! No vehdata found for ", par:GetModel())
		end
	end
end

if SERVER then
	function ENT:Think()
		local f = caress.lightFlags.Head

		local veh = self:GetParent()
		local driver = veh:GetDriver()
		if IsValid(driver) then
			if driver:KeyDown(IN_BACK) or driver:KeyDown(IN_JUMP) then
				f = f + caress.lightFlags.Brake

				if veh:GetThrottle() == -1 then
					f = f + caress.lightFlags.Reverse
				end
			else
				f = f + caress.lightFlags.BrakePassive
			end

			if math.floor(CurTime() * 2) % 2 == 0 then
				if veh:GetSteering() < 0 then
					f = f + caress.lightFlags.LBlinkers
				end
				if veh:GetSteering() > 0 then
					f = f + caress.lightFlags.RBlinkers
				end
			end
		end

		self:SetActiveLights(f)
	end
end

-- OPTIMIZATIONS LOL

local vlQueue = {}
local vlQueueLength = 0

local cvar_enableCarLights = CreateConVar("ice_carlights", "1", FCVAR_ARCHIVE)
function ENT:Draw()
	if not cvar_enableCarLights:GetBool() then return end

	vlQueueLength = vlQueueLength + 1
	vlQueue[vlQueueLength] = self
end

hook.Add("PostDrawTranslucentRenderables", "Ice_DrawVehicleLightQueue", function()
	for i=1, vlQueueLength do
		local info = vlQueue[i]

		local vehData = info:GetVehData()

		if vehData then
			local veh = info:GetParent()
			caress.drawLights(veh, vehData.lights, info:GetActiveLights())
		end
	end

	vlQueueLength = 0
end)