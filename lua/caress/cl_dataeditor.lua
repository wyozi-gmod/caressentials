local function OpenEditor(model, tbl)
	tbl = tbl or { seats = {}, lights = {},  }

	local fr = vgui.Create("DFrame")
	fr:SetTitle("Vehicle Editor")

	local mdlp = fr:Add("DAdjustableModelPanel")
	mdlp:SetModel(model)
	mdlp:Dock(FILL)
	mdlp.LayoutEntity = function()end

	local editingObject = nil

	mdlp._editingObjectModel = ClientsideModel("models/error.mdl")
	mdlp._editingObjectModel:SetNoDraw(true)

	function mdlp:DrawEOModel(mdl)
		self._editingObjectModel:SetModel(mdl)
		self._editingObjectModel:SetRenderOrigin(self.Entity:LocalToWorld(editingObject.ref.pos))
		self._editingObjectModel:SetRenderAngles(editingObject.ref.ang)
		self._editingObjectModel:SetupBones()
		self._editingObjectModel:DrawModel()
	end

	function mdlp:PostDrawModel(e)
		if editingObject then
			if editingObject.type == "seat" then
				self:DrawEOModel("models/nova/airboat_seat.mdl")
				return
			elseif editingObject.type == "cargo" then
				self:DrawEOModel("models/Items/ammoCrate_Rockets.mdl")
				return
			elseif editingObject.type == "light" then
				caress.drawDataLight(e, editingObject.ref, caress.lightFlags[editingObject.cat])

				local opos = self.Entity:LocalToWorld(editingObject.ref.pos)
				render.DrawLine(opos, opos + editingObject.ref.ang:Forward() * 25, Color(255, 0, 0))

				return
			end
		end

		caress.drawLights(e, tbl.lights, 0xFFFFFFFF)
	end

	mdlp:SetLookAng(Angle(30, -60, 0))
	mdlp:SetCamPos(mdlp.Entity:OBBCenter() - mdlp:GetLookAng():Forward() * 300)

	local side = fr:Add("DPanel")
	side:SetWide(200)
	side:Dock(RIGHT)

	local function FormCheck(form, text, bool)
		local c = form:CheckBox(text)
		function c:SetValue(b)
			return self:SetChecked(b)
		end
		function c:OnChange(newval)
			if self.OnValueChanged then self.OnValueChanged(self, newval) end
		end

		c:SetValue(bool)
		return c
	end

	local settings_cargo = side:Add("DForm")
	settings_cargo:SetName("Cargo settings")
	settings_cargo:DoExpansion(false)
	settings_cargo:Dock(BOTTOM)

	local settings_lightspr = side:Add("DForm")
	settings_lightspr:SetName("Light Sprite settings")
	settings_lightspr:DoExpansion(false)
	settings_lightspr:Dock(BOTTOM)

	local settings_light = side:Add("DForm")
	settings_light:SetName("Light settings")
	settings_light:DoExpansion(false)
	settings_light:Dock(BOTTOM)

	local settings = side:Add("DForm")
	settings:SetName("General")
	settings:Dock(BOTTOM)

	local settingComps = { generic = {}, light = {}, cargo = {} }

	local function fetcher(...)
		local args = {...}
		return function(t)
			for _,key in pairs(args) do
				t = t[key]
			end
			return t
		end
	end
	local function setter(...)
		local args = {...}
		local setKey = args[#args]
		args[#args] = nil
		return function(t, val)
			for _,key in pairs(args) do
				t = t[key]
			end
			t[setKey] = val
		end
	end

	settings:Help("Position")
	settingComps.generic.posX = { comp = settings:NumSlider("X", 0, -500, 500), fetch = fetcher("pos", "x"), set = setter("pos", "x") }
	settingComps.generic.posY = { comp = settings:NumSlider("Y", 0, -500, 500), fetch = fetcher("pos", "y"), set = setter("pos", "y") }
	settingComps.generic.posZ = { comp = settings:NumSlider("Z", 0, -500, 500), fetch = fetcher("pos", "z"), set = setter("pos", "z") }
	settings:Help("Rotation")
	settingComps.generic.angP = { comp = settings:NumSlider("P", 0, -180, 180), fetch = fetcher("ang", "p"), set = setter("ang", "p") }
	settingComps.generic.angY = { comp = settings:NumSlider("Y", 0, -180, 180), fetch = fetcher("ang", "y"), set = setter("ang", "y") }
	settingComps.generic.angR = { comp = settings:NumSlider("R", 0, -180, 180), fetch = fetcher("ang", "r"), set = setter("ang", "r") }
	settingComps.generic._node = settings

	settingComps.light.w = { comp = settings_light:NumSlider("Width", nil, 1, 100, 0), fetch = fetcher("w"), set = setter("w") }
	settingComps.light.h = { comp = settings_light:NumSlider("Height", nil, 1, 100, 0), fetch = fetcher("h"), set = setter("h") }
	settingComps.light._node = settings_light

	settings_lightspr:Help("TODO")

	settingComps.cargo.draw = { comp = FormCheck(settings_cargo, "Draw contents", false), fetch = fetcher("draw"), set = setter("draw") }
	settingComps.cargo._node = settings_cargo

	--[[
	local _slc_lbl = vgui.Create("DLabel")
	_slc_lbl:SetText("Color")
	local set_light_clr = vgui.Create("DColorButton")
	set_light_clr:Dock(FILL)
	settings:AddItem(_slc_lbl, set_light_clr)
	]]

	local tree = side:Add("DTree")
	tree:Dock(FILL)


	-- pairs impl that skips underscore names
	local function catPairs(t)
		return function(t, key)
			local nextKey, nextVal = next(t, key)
			if nextKey and nextKey:sub(1, 1) == "_" then
				local nnextKey, nnextVal = nextKey, nextVal
				repeat
					nnextKey, nnextVal = next(t, nnextKey)
					if nnextKey == nextKey then return nil end -- prevent inf loop
				until not nnextKey or nnextKey:sub(1, 1) ~= "_"
				return nnextKey, nnextVal
			end
			return nextKey, nextVal
		end, t, nil
	end

	local function EditObject(type, t, extras)
		editingObject = { type = type, ref = t }
		if extras then table.Merge(editingObject, extras) end

		-- remove old listeners first
		for _,cat in pairs(settingComps) do
			for _,node in catPairs(cat) do
				node.comp.OnValueChanged = function()end
			end
		end

		-- close irrelevant categories
		for name,cat in pairs(settingComps) do
			cat._node:DoExpansion(name == "generic" or type == name)
		end

		-- set generic and cat values
		for _,node in catPairs(settingComps.generic) do
			node.comp:SetValue(node.fetch(t))
		end
		for _,node in catPairs(settingComps[type] or {}) do
			node.comp:SetValue(node.fetch(t))
		end

		-- add new generic and cat listeners
		for _,node in catPairs(settingComps.generic) do
			node.comp.OnValueChanged = function(_, val) node.set(t, val) end
		end
		for _,node in catPairs(settingComps[type] or {}) do
			node.comp.OnValueChanged = function(_, val) node.set(t, val) end
		end
	end

	local function EditLightSprite(tbl)
		settings_lightspr:DoExpansion(true)
	end

	do
		local t_lights = tree:AddNode("Lights")
		local cat_children = {}

		local function AddLight(cat, obj)
			local ctbl = tbl.lights[cat]
			if not ctbl then
				tbl.lights[cat] = {}
				ctbl = tbl.lights[cat]
			end

			if not obj then
				obj = { pos = Vector(0, 0, 50), ang = Angle(0, 0, 0) }
				table.insert(ctbl, obj)
			end

			local light = cat_children[cat]:AddNode("Light #" .. table.KeyFromValue(ctbl, obj))
			light.OnNodeSelected = function()
				EditObject("light", obj, {cat = cat})
			end

			local function AddSprite(t)
				local sprite = light:AddNode("Sprite")

				local sprCustom = t
				if not sprCustom then
					sprCustom = { type = "sphere" }
					obj.custom = obj.custom or {}
					table.insert(obj.custom, sprCustom)
				end

				sprite.OnNodeSelected = function()
					EditLightSprite(sprCustom)
				end
			end

			function light.DoRightClick()
				local menu = DermaMenu()

				menu:AddOption("Add Sprite", function()
					AddSprite()
				end)
				menu:AddOption("Duplicate", function()
					local nobj = AddLight(cat)
					nobj.pos:Set(obj.pos)
					nobj.ang:Set(obj.ang)
					nobj.w = obj.w
					nobj.h = obj.h
				end)
				menu:Open()
			end

			for _,c in pairs(obj.custom or {}) do
				AddSprite(c)
			end

			return obj
		end

		for _, cat in pairs{"Head", "Brake", "Reverse", "LBlinkers", "RBlinkers"} do
			local t_lights_cat = t_lights:AddNode(cat)
			cat_children[cat] = t_lights_cat

			function t_lights_cat.DoRightClick()
				local menu = DermaMenu()
				menu:AddOption("Add new", function()
					AddLight(cat)
				end)
				menu:Open()
			end

			for _,l in pairs(tbl.lights[cat] or {}) do
				AddLight(cat, l)
			end
		end
	end

	do
		local t_seats = tree:AddNode("Seats")

		local function AddSeat(obj)
			if not obj then
				obj = { pos = Vector(0, 0, 50), ang = Angle(0, 0, 0) }
				table.insert(tbl.seats, obj)
			end

			local seat = t_seats:AddNode("Seat #" .. table.KeyFromValue(tbl.seats, obj))
			seat.OnNodeSelected = function()
				EditObject("seat", obj)
			end
			function seat.DoRightClick()
				local menu = DermaMenu()
				menu:AddOption("Duplicate", function()
					local nobj = AddSeat()
					nobj.pos:Set(obj.pos)
					nobj.ang:Set(obj.ang)
				end)
				menu:Open()
			end
			return obj
		end

		function t_seats.DoRightClick()
			local menu = DermaMenu()
			menu:AddOption("Add new", function()
				AddSeat()
			end)
			menu:Open()
		end

		for _,s in pairs(tbl.seats) do
			AddSeat(s)
		end
	end

	do
		local t_cargo = tree:AddNode("Cargo")

		local function AddCargo(obj)
			if not obj then
				obj = { pos = Vector(0, 0, 50), ang = Angle(0, 0, 0) }
				tbl.cargo = tbl.cargo or {}
				table.insert(tbl.cargo, obj)
			end

			local seat = t_cargo:AddNode("Cargo #" .. table.KeyFromValue(tbl.cargo, obj))
			seat.OnNodeSelected = function()
				EditObject("cargo", obj)
			end
		end

		function t_cargo.DoRightClick()
			local menu = DermaMenu()
			menu:AddOption("Add new", function()
				AddCargo()
			end)
			menu:Open()
		end

		for _,c in pairs(tbl.cargo or {}) do
			AddCargo(c)
		end
	end

	local save = fr:Add("DButton")
	save:SetText("Dump")
	save:SetPos(100, 2)
	save:SetSize(50, 20)
	save.DoClick = function()

		local gtable = table
		local gtostring = tostring

		local function tostring(o)
			if type(o) == "Vector" then
				return string.format("Vector(%f, %f, %f)", o.x, o.y, o.z)
			elseif type(o) == "Angle" then
				return string.format("Angle(%f, %f, %f)", o.p, o.y, o.r)
			else
				return gtostring(o)
			end
		end

		local table = setmetatable({}, {__index = gtable}) -- inline table lib, :e
		function table.val_to_str ( v )
		  if "string" == type( v ) then
		    v = string.gsub( v, "\n", "\\n" )
		    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
		      return "'" .. v .. "'"
		    end
		    return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
		  else
		    return "table" == type( v ) and table.tostring( v ) or
		      tostring( v )
		  end
		end

		function table.key_to_str ( k )
		  if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
		    return k
		  else
		    return "[" .. table.val_to_str( k ) .. "]"
		  end
		end

		function table.tostring( tbl )
		  local result, done = {}, {}
		  for k, v in ipairs( tbl ) do
		    table.insert( result, table.val_to_str( v ) )
		    done[ k ] = true
		  end
		  for k, v in pairs( tbl ) do
		    if not done[ k ] then
		      table.insert( result,
		        table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
		    end
		  end
		  return "{" .. table.concat( result, "," ) .. "}"
		end

		print(table.tostring(tbl))
		--print(util.TableToJSON(tbl))
	end

	fr:SetSize(1200, 800)
	fr:Center()
	fr:MakePopup()
end

concommand.Add("caress_editvehicle", function(ply, cmd, args)
	local model = args[1] or "models/tdmcars/bmwm3e92.mdl"

	local data = caress.getVehicleData(model)
	-- TODO deep clone first
	print(data)

	OpenEditor(model, data)
end)