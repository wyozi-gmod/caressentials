local function CreateSeatAtPos(pos, angle)
	local ent = ents.Create("prop_vehicle_prisoner_pod")
	ent:SetModel("models/nova/airboat_seat.mdl")
	ent:SetKeyValue("vehiclescript","scripts/vehicles/prisoner_pod.txt")
	ent:SetPos(pos)
	ent:SetAngles(angle)
	ent:SetNotSolid(true)
	ent:SetNoDraw(true)

	--ent.HandleAnimation = HandleRollercoasterAnimation

	ent:Spawn()
	ent:Activate()

	local phys = ent:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
	end

	ent:SetCollisionGroup( COLLISION_GROUP_DEBRIS_TRIGGER )

	ent.IsCaressVehicleSeat = true

	return ent
end

hook.Add("PlayerUse", "Caress_CarSeat", function(ply, e)
	if ply.LastVehAction and ply.LastVehAction > CurTime() - 0.2 then return false end

	if e:GetClass() ~= "prop_vehicle_jeep" then return end

	-- if no driver, return so that ply is made the driver
	-- TODO allow entering as passenger even when there is a driver?
	if not IsValid(e:GetDriver()) then
		return
	end

	local data = caress.getVehicleData(e:GetModel())
	if not data then return end

	e.CaressSeats = e.CaressSeats or {}

	local bdist, bseat, bseati
	for i,seat in pairs(data.seats) do
		local dist = ply:EyePos():Distance(e:LocalToWorld(seat.pos))
		if not IsValid(e.CaressSeats[i]) and (not bdist or bdist > dist) then
			bdist, bseat, bseati = dist, seat, i
		end
	end

	if not bdist or bdist > 128 then
		return
	end

	local seat = bseat

	local seatEnt = CreateSeatAtPos(e:LocalToWorld(seat.pos), e:LocalToWorldAngles(Angle(0, 0, 0)))
	seatEnt:SetParent(e)

	ply:EnterVehicle(seatEnt)

	e.CaressSeats[bseati] = seatEnt
end)

hook.Add("CanExitVehicle", "CaressExitCar", function(veh, ply)
	if veh.IsCaressVehicleSeat then
		ply:ExitVehicle()
		ply.LastVehAction = CurTime()

		veh:Remove()

		-- TODO set ply pos

		return false
	end
end)