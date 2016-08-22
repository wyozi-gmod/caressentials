local matGlow = CreateMaterial("IceVehicleGlow" .. os.time(), "UnLitGeneric", {
    ["$basetexture"] = "sprites/glow03",
    ["$nocull"] = 1,
    ["$additive"] = 1,
    ["$translucent"] = 1,
    ["$vertexalpha"] = 1,
    ["$vertexcolor"] = 1,
    ["$ignorez"] = 1
})
local matSprite = CreateMaterial("IceVehicleSprite" .. os.time(), "UnLitGeneric", {
    ["$basetexture"] = "sprites/glow01",
    ["$nocull"] = 1,
    ["$additive"] = 1,
    ["$translucent"] = 1,
    ["$vertexalpha"] = 1,
    ["$vertexcolor"] = 1,
})
local matLightSq = Material("effects/flashlight/square")
local matBeam = Material( "effects/lamp_beam" )

-- this will be set - at some point??
local flags = caress.lightFlags

local band = bit.band

local pixvisIndex = 1
local pool = {}
local function GetPixVis()
	local pv = pool[pixvisIndex]
	if not pv then
		pool[pixvisIndex] = util.GetPixelVisibleHandle()
		pv = pool[pixvisIndex]
	end
	pixvisIndex = pixvisIndex + 1
	return pv
end

hook.Add("PreDrawOpaqueRenderables", "Ice_ClearVehLightPixVis", function()
	pixvisIndex = 1
end)

local defaultColors = {
	[flags.Head] = Color(255, 255, 255),
	[flags.BrakePassive] = Color(255, 0, 0, 70),
	[flags.Brake] = Color(255, 0, 0),
	[flags.LBlinkers] = Color(255, 127, 0),
	[flags.RBlinkers] = Color(255, 127, 0),
}

local redirects = {
	[flags.BrakePassive] = flags.Brake
}

local tmpColor = Color(255, 255, 255, 128)

local function drawDataLight(car, light, flag)
	local wpos = car:LocalToWorld(light.pos)
	local wnorm = car:LocalToWorldAngles(light.ang):Forward()

	local custom = light.custom
	if custom then
		if not not custom.type then
			custom = { custom }
		end

		light.sprites = {}
		for _,c in pairs(custom) do
			if c.type == "sphere" then
				local rad = 2.5
				local segments = 8

				local r, u = light.ang:Right(), light.ang:Up()

				for i=1,segments do
					light.sprites[#light.sprites+1] = r * math.cos(i / segments * math.pi * 2) * rad + u * math.sin(i / segments * math.pi * 2) * rad
				end
			elseif c.type == "line" then
				local start = c.start or vector_origin
				local off = c.off
				local off_e = c.off_e
				local n = c.count

				for i=1,n do
					local add = off * (i - 1)
					if off_e then add.x = add.x ^ off_e.x; add.y = add.y ^ off_e.y; add.z = add.z ^ off_e.z end
					light.sprites[#light.sprites+1] = start + add
				end
			end
		end

		light.custom = nil
	end

	local viewNorm = (wpos - EyePos())
	local distance = viewNorm:Length()
	viewNorm:Normalize()

	local clr = light.clr or defaultColors[flag] or defaultColors[flags.Head]

	local aclr = tmpColor
	aclr.r = clr.r
	aclr.g = clr.g
	aclr.b = clr.b

	local amul = clr.a / 255

	aclr.a = 125 * amul

	local viewDot = viewNorm:Dot(-wnorm)
	local vis = util.PixelVisible(wpos, 4, GetPixVis())
	local sizeMul = (0.5 + math.max(viewDot, 0)) * vis

	render.SetMaterial(matGlow)
	local w, h = light.w or 16, light.h or 16
	local glowMul = (2 + math.Clamp((distance / 128) * viewDot, 0, 10))
	render.DrawSprite(wpos, w * glowMul * sizeMul, h * glowMul * sizeMul, aclr, 0)

	local sprites = light.sprites

	if sprites then
		render.SetMaterial(matSprite)
		aclr.a = 80 * amul

		for i=1,#sprites do
			local sprite = sprites[i]
			render.DrawSprite(car:LocalToWorld(light.pos + sprite), 4, 4, aclr)
		end
	end

	--render.DrawSprite(wpos, w, h, aclr)

	--[[
	render.SetMaterial(matBeam)
	render.StartBeam(3)
		render.AddBeam( wpos, 128, 0.0, Color(255, 255, 255, 64) )
		render.AddBeam( wpos + wnorm * 150, 128, 0.5, Color(255, 255, 255, 50) )
		render.AddBeam( wpos + wnorm * 750, 128, 1, Color(255, 255, 255, 0) )
	render.EndBeam()
	]]
end
caress.drawDataLight = drawDataLight

local function drawDataLights(car, data, flag)
	for _,light in pairs(data) do
		drawDataLight(car, light, flag)
	end
end

function caress.drawLights(car, lightInfo, lightMap)
	local lightInfoBits = {}

	-- TODO do string->bit transformation only once somewhere
	for flag, data in pairs(lightInfo) do
		if type(flag) == "string" then
			lightInfoBits[flags[flag]] = data
		else
			lightInfoBits[flag] = data
		end
	end

	for flag, data in pairs(lightInfoBits) do
		if band(lightMap, flag) == flag then
			drawDataLights(car, data, flag)
		end
	end

	for src,targ in pairs(redirects) do
		if band(lightMap, src) == src then
			local data = lightInfoBits[targ]
			if data then drawDataLights(car, data, src) end
		end
	end
end