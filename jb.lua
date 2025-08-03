local vm = loadstring(game:HttpGet("https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/refs/heads/main/libraries/vm.lua"))()
local run = function(func) func() end
local cloneref = cloneref or function(obj) return obj end
local LazerGodmode = {Enabled = false}
local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local textService = cloneref(game:GetService('TextService'))
local tweenService = cloneref(game:GetService('TweenService'))
local teamsService = cloneref(game:GetService('Teams'))
local collectionService = cloneref(game:GetService('CollectionService'))
local contextService = cloneref(game:GetService('ContextActionService'))
local InfNitro = {Enabled = false}

local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer

local function getVehicle(ent)
	if ent.Player then
		for _, car in collectionService:GetTagged('Vehicle') do
			for _, seat in car:GetChildren() do
				if (seat.Name == 'Seat' or seat.Name == 'Passenger') then
					seat = seat:FindFirstChild('PlayerName')
					if seat and seat.Value == ent.Player.Name then
						return car
					end
				end
			end
		end
	end
end

local function isArrested(name)
	for i, v in jb.CircleAction.Specs do
		if v.Name == 'Arrest' and v.PlayerName == name then
			return not v.ShouldArrest
		end
	end
	return false
end

local function isIllegal(ent)
	if ent.Player and ent.Player.Team == teamsService.Prisoner then
		local items = ent.Player:FindFirstChild('CurrentInventory')
		items = items and items.Value
		if items then
			for i, v in items:GetChildren() do
				if v.Name ~= 'MansionInvite' then
					return true
				end
			end
		end

		return ent.Illegal
	end
	return true
end

run(function()
	local function dumpRemotes(scripts, renamed)
		local returned = {}

		for _, scr in scripts do
			local deserializedcode = vm.luau_deserialize(getscriptbytecode(scr))

			for _, proto in deserializedcode.protoList do
				local stack, top, code = {}, -1, proto.code
				for i, inst in code do
					if inst.opcode == 4 then -- LOADN
						stack[inst.A] = inst.D
					elseif inst.opcode == 5 then -- LOADK
						stack[inst.A] = inst.K
					elseif inst.opcode == 6 then -- MOVE
						stack[inst.A] = stack[inst.B]
					elseif inst.opcode == 12 then -- GETIMPORT
						local count, import = inst.KC, getrenv()[inst.K0]

						if count == 1 then
							stack[inst.A] = import
						elseif count == 2 then
							stack[inst.A] = import[inst.K1]
						elseif count == 3 then
							stack[inst.A] = import[inst.K1][inst.K2]
						end
					elseif inst.opcode == 20 then -- NAMECALL
						local A, B, kv = inst.A, inst.B, inst.K
						stack[A + 1] = stack[B]

						local callInst = code[i + 2]
						local callA, callB, callC = callInst.A, callInst.B, callInst.C
						local params = if callB == 0 then top - callA else callB - 1
						if kv == 'sub' or kv == 'reverse' then
							local arg1, arg2, arg3 = table.unpack(stack, callA + 1, callA + params)
							if kv == 'reverse' and not arg1 then arg1 = 'a' end

							local ret_list = table.pack(string[kv](arg1, arg2, arg3))
							local ret_num = ret_list.n - 1
							if callC == 0 then
								top = callA + ret_num - 1
							else
								ret_num = callC - 1
							end

							table.move(ret_list, 1, ret_num, callA, stack)
						elseif kv == 'FireServer' then
							local name, val = proto.debugname == '(??)' and scr.Name or proto.debugname, stack[callA + 2]
							if name == val then table.insert(returned, val) continue end
							if returned[name] then
								for i = 1, 10 do
									if not returned[name..i] then name ..= i break end
								end
							end

							returned[name] = val
						end
					elseif inst.opcode == 49 then -- CONCAT
						local s = ""
						for i = inst.B, inst.C do
							if type(stack[i]) ~= 'string' then continue end
							s ..= stack[i]
						end
						stack[inst.A] = s
					end
				end
			end
		end

		for i, v in table.clone(returned) do
			if renamed[i] then
				returned[i] = nil
				returned[renamed[i]] = v
			end
		end

		return returned
	end


	local function getCash()
		for i, v in debug.getupvalue(jb.TeamChooseController.Init, 2) do
			if type(v) == 'function' then
				for _, const in debug.getconstants(v) do
					if tostring(const):find('PlusCash') then
						return v, i
					end
				end
			end
		end
	end

	local function toMoney(num)
		local one, two, three = string.match(tostring(num), '^([^%d]*%d)(%d*)(.-)$')
		return one .. (two:reverse():gsub('(%d%d%d)', '%1,'):reverse() .. three)..'$'
	end

	jb = {
		BulletEmitter = require(replicatedStorage.Game.ItemSystem.BulletEmitter),
		CircleAction = require(replicatedStorage.Module.UI).CircleAction,
		CargoController = require(replicatedStorage.Game.Robbery.RobberyPassengerTrain),
		FallingController = require(replicatedStorage.Game.Falling),
		GunController = require(replicatedStorage.Game.Item.Gun),
		HotbarItemSystem = require(replicatedStorage.Hotbar.HotbarItemSystem),
		InventoryItemSystem = require(replicatedStorage.Inventory.InventoryItemSystem),
		ItemSystemController = require(replicatedStorage.Game.ItemSystem.ItemSystem),
		PlayerUtils = require(replicatedStorage.Game.PlayerUtils),
		RagdollController = require(replicatedStorage.Module.AlexRagdoll),
		TaserController = require(replicatedStorage.Game.Item.Taser),
		TeamChooseController = require(replicatedStorage.TeamSelect.TeamChooseUI),
		VehicleController = require(replicatedStorage.Vehicle.VehicleUtils)
	}

	local remotetable = debug.getupvalue(jb.VehicleController.toggleLocalLocked, 2)
	local fireserver, hook = remotetable.FireServer
local remotes
	remotes = dumpRemotes({
		replicatedStorage.Game.TrainSystem.LocomotiveFront,
		replicatedStorage.Game.ItemSystem.ItemSystem,
		replicatedStorage.Game.CashBuyUI,
		replicatedStorage.Game.Item.Taser,
		replicatedStorage.Game.Item.Gun,
		replicatedStorage.Game.Falling,
		lplr.PlayerScripts.LocalScript
	}, {
		Action = 'Pickup',
		Action3 = 'StartRob',
		Action2 = 'EndRob',
		AttemptArrest = 'Arrest',
		attemptPunch = 'Punch',
		AttemptVehicleEject = 'Eject',
		AttemptVehicleEnter = 'GetIn',
		BroadcastInputBegan = 'InputBegan',
		BroadcastInputEnded = 'InputEnded',
		CalculateDelta = 'UseNitro',
		Draw = 'TaseReplicate',
		Gun = 'PopTires',
		LocalScript2 = 'LookAngle',
		LocalScript = 'SelfDamage',
		onPressed = 'FlipVehicle',
		OnJump = 'GetOut',
		OnJump1 = 'GetOut',
		UpdateMousePosition = 'AimPosition'
	})

	local function fireHook(self, id, ...)
		local rem
		for i, v in remotes do
			if v == id then
				rem = i
			end
		end

		if InfNitro.Enabled and rem == 'UseNitro' then return end
		if LazerGodmode.Enabled and rem == 'SelfDamage' then return end
		if rem ~= 'LookAngle' and rem ~= 'AimPosition' then
			local called = getfenv(3)
			called = called and called.script
			if called and (not rem) then print(id, 'called with', called:GetFullName()) end
			print(id, rem or id, ...)
		end

		return hook(self, id, ...)
	end

	hook = hookfunction(fireserver, function(self, id, ...)
		return fireHook(self, id, ...)
	end)

	function jb:FireServer(id, ...)
		if not remotes[id] then
			print("remote not found or failed to fire "..id)
			return
		end
		return hook(remotetable, remotes[id], ...)
	end
end)		
	

local module = {}
local eps = 1e-9
local function isZero(d)
	return (d > -eps and d < eps)
end

local function cuberoot(x)
	return (x > 0) and math.pow(x, (1 / 3)) or -math.pow(math.abs(x), (1 / 3))
end

local function solveQuadric(c0, c1, c2)
	local s0, s1

	local p, q, D

	p = c1 / (2 * c0)
	q = c2 / c0
	D = p * p - q

	if isZero(D) then
		s0 = -p
		return s0
	elseif (D < 0) then
		return
	else -- if (D > 0)
		local sqrt_D = math.sqrt(D)

		s0 = sqrt_D - p
		s1 = -sqrt_D - p
		return s0, s1
	end
end

local function solveCubic(c0, c1, c2, c3)
	local s0, s1, s2

	local num, sub
	local A, B, C
	local sq_A, p, q
	local cb_p, D

	A = c1 / c0
	B = c2 / c0
	C = c3 / c0

	sq_A = A * A
	p = (1 / 3) * (-(1 / 3) * sq_A + B)
	q = 0.5 * ((2 / 27) * A * sq_A - (1 / 3) * A * B + C)

	cb_p = p * p * p
	D = q * q + cb_p

	if isZero(D) then
		if isZero(q) then -- one triple solution
			s0 = 0
			num = 1
		else -- one single and one double solution
			local u = cuberoot(-q)
			s0 = 2 * u
			s1 = -u
			num = 2
		end
	elseif (D < 0) then -- Casus irreducibilis: three real solutions
		local phi = (1 / 3) * math.acos(-q / math.sqrt(-cb_p))
		local t = 2 * math.sqrt(-p)

		s0 = t * math.cos(phi)
		s1 = -t * math.cos(phi + math.pi / 3)
		s2 = -t * math.cos(phi - math.pi / 3)
		num = 3
	else -- one real solution
		local sqrt_D = math.sqrt(D)
		local u = cuberoot(sqrt_D - q)
		local v = -cuberoot(sqrt_D + q)

		s0 = u + v
		num = 1
	end

	sub = (1 / 3) * A

	if (num > 0) then s0 = s0 - sub end
	if (num > 1) then s1 = s1 - sub end
	if (num > 2) then s2 = s2 - sub end

	return s0, s1, s2
end

function module.solveQuartic(c0, c1, c2, c3, c4)
	local s0, s1, s2, s3

	local coeffs = {}
	local z, u, v, sub
	local A, B, C, D
	local sq_A, p, q, r
	local num

	A = c1 / c0
	B = c2 / c0
	C = c3 / c0
	D = c4 / c0

	sq_A = A * A
	p = -0.375 * sq_A + B
	q = 0.125 * sq_A * A - 0.5 * A * B + C
	r = -(3 / 256) * sq_A * sq_A + 0.0625 * sq_A * B - 0.25 * A * C + D

	if isZero(r) then
		coeffs[3] = q
		coeffs[2] = p
		coeffs[1] = 0
		coeffs[0] = 1

		local results = {solveCubic(coeffs[0], coeffs[1], coeffs[2], coeffs[3])}
		num = #results
		s0, s1, s2 = results[1], results[2], results[3]
	else
		coeffs[3] = 0.5 * r * p - 0.125 * q * q
		coeffs[2] = -r
		coeffs[1] = -0.5 * p
		coeffs[0] = 1

		s0, s1, s2 = solveCubic(coeffs[0], coeffs[1], coeffs[2], coeffs[3])
		z = s0

		u = z * z - r
		v = 2 * z - p

		if isZero(u) then
			u = 0
		elseif (u > 0) then
			u = math.sqrt(u)
		else
			return
		end
		if isZero(v) then
			v = 0
		elseif (v > 0) then
			v = math.sqrt(v)
		else
			return
		end

		coeffs[2] = z - u
		coeffs[1] = q < 0 and -v or v
		coeffs[0] = 1

		do
			local results = {solveQuadric(coeffs[0], coeffs[1], coeffs[2])}
			num = #results
			s0, s1 = results[1], results[2]
		end

		coeffs[2] = z + u
		coeffs[1] = q < 0 and v or -v
		coeffs[0] = 1

		if (num == 0) then
			local results = {solveQuadric(coeffs[0], coeffs[1], coeffs[2])}
			num = num + #results
			s0, s1 = results[1], results[2]
		end
		if (num == 1) then
			local results = {solveQuadric(coeffs[0], coeffs[1], coeffs[2])}
			num = num + #results
			s1, s2 = results[1], results[2]
		end
		if (num == 2) then
			local results = {solveQuadric(coeffs[0], coeffs[1], coeffs[2])}
			num = num + #results
			s2, s3 = results[1], results[2]
		end
	end

	sub = 0.25 * A

	if (num > 0) then s0 = s0 - sub end
	if (num > 1) then s1 = s1 - sub end
	if (num > 2) then s2 = s2 - sub end
	if (num > 3) then s3 = s3 - sub end

	return {s3, s2, s1, s0}
end

function module.SolveTrajectory(origin, projectileSpeed, gravity, targetPos, targetVelocity, playerGravity, playerHeight, playerJump, params)
	local disp = targetPos - origin
	local p, q, r = targetVelocity.X, targetVelocity.Y, targetVelocity.Z
	local h, j, k = disp.X, disp.Y, disp.Z
	local l = -.5 * gravity
	if math.abs(q) > 0.01 and playerGravity and playerGravity > 0 then
		local estTime = (disp.Magnitude / projectileSpeed)
		local origq = q
		local origj = j
		for i = 1, 100 do
			q -= (.5 * playerGravity) * estTime
			local velo = targetVelocity * 0.016
			local ray = workspace.Raycast(workspace, Vector3.new(targetPos.X, targetPos.Y, targetPos.Z), Vector3.new(velo.X, (q * estTime) - playerHeight, velo.Z), params)
			if ray then
				local newTarget = ray.Position + Vector3.new(0, playerHeight, 0)
				estTime -= math.sqrt(((targetPos - newTarget).Magnitude * 2) / playerGravity)
				targetPos = newTarget
				j = (targetPos - origin).Y
				q = 0
				break
			else
				break
			end
		end
	end

	local solutions = module.solveQuartic(
		l*l,
		-2*q*l,
		q*q - 2*j*l - projectileSpeed*projectileSpeed + p*p + r*r,
		2*j*q + 2*h*p + 2*k*r,
		j*j + h*h + k*k
	)
	if solutions then
		local posRoots = table.create(2)
		for _, v in solutions do --filter out the negative roots
			if v > 0 then
				table.insert(posRoots, v)
			end
		end
		posRoots[1] = posRoots[1]
		if posRoots[1] then
			local t = posRoots[1]
			local d = (h + p*t)/t
			local e = (j + q*t - l*t*t)/t
			local f = (k + r*t)/t
			return origin + Vector3.new(d, e, f)
		end
	elseif gravity == 0 then
		local t = (disp.Magnitude / projectileSpeed)
		local d = (h + p*t)/t
		local e = (j + q*t - l*t*t)/t
		local f = (k + r*t)/t
		return origin + Vector3.new(d, e, f)
	end
end

local entitylib = {
	isAlive = false,
	character = {},
	List = {},
	Connections = {},
	PlayerConnections = {},
	EntityThreads = {},
	Running = false,
	Events = setmetatable({}, {
		__index = function(self, ind)
			self[ind] = {
				Connections = {},
				Connect = function(rself, func)
					table.insert(rself.Connections, func)
					return {
						Disconnect = function()
							local rind = table.find(rself.Connections, func)
							if rind then
								table.remove(rself.Connections, rind)
							end
						end
					}
				end,
				Fire = function(rself, ...)
					for _, v in rself.Connections do
						task.spawn(v, ...)
					end
				end,
				Destroy = function(rself)
					table.clear(rself.Connections)
					table.clear(rself)
				end
			}

			return self[ind]
		end
	})
}

local function getMousePosition()
	if inputService.TouchEnabled then
		return gameCamera.ViewportSize / 2
	end
	return inputService.GetMouseLocation(inputService)
end

local function loopClean(tbl)
	for i, v in tbl do
		if type(v) == 'table' then
			loopClean(v)
		end
		tbl[i] = nil
	end
end

local function waitForChildOfType(obj, name, timeout, prop)
	local checktick = tick() + timeout
	local returned
	repeat
		returned = prop and obj[name] or obj:FindFirstChildOfClass(name)
		if returned or checktick < tick() then break end
		task.wait()
	until false
	return returned
end

entitylib.targetCheck = function(ent)
	if ent.TeamCheck then
		return ent:TeamCheck()
	end
	if ent.NPC then return true end
	if not lplr.Team then return true end
	if not ent.Player.Team then return true end
	if ent.Player.Team ~= lplr.Team then return true end
	return #ent.Player.Team:GetPlayers() == #playersService:GetPlayers()
end

entitylib.getUpdateConnections = function(ent)
	local hum = ent.Humanoid
	return {
		hum:GetPropertyChangedSignal('Health'),
		hum:GetPropertyChangedSignal('MaxHealth')
	}
end

entitylib.isVulnerable = function(ent)
	return ent.Health > 0 and not ent.Character.FindFirstChildWhichIsA(ent.Character, 'ForceField')
end

entitylib.getEntityColor = function(ent)
	ent = ent.Player
	return ent and tostring(ent.TeamColor) ~= 'White' and ent.TeamColor.Color or nil
end

entitylib.IgnoreObject = RaycastParams.new()
entitylib.IgnoreObject.RespectCanCollide = true
entitylib.Wallcheck = function(origin, position, ignoreobject)
	if typeof(ignoreobject) ~= 'Instance' then
		local ignorelist = {gameCamera, lplr.Character}
		for _, v in entitylib.List do
			if v.Targetable then
				table.insert(ignorelist, v.Character)
			end
		end

		if typeof(ignoreobject) == 'table' then
			for _, v in ignoreobject do
				table.insert(ignorelist, v)
			end
		end

		ignoreobject = entitylib.IgnoreObject
		ignoreobject.FilterDescendantsInstances = ignorelist
	end
	return workspace.Raycast(workspace, origin, (position - origin), ignoreobject)
end

entitylib.EntityMouse = function(entitysettings)
	if entitylib.isAlive then
		local mouseLocation, sortingTable = entitysettings.MouseOrigin or getMousePosition(), {}
		for _, v in entitylib.List do
			if not entitysettings.Players and v.Player then continue end
			if not entitysettings.NPCs and v.NPC then continue end
			if not v.Targetable then continue end
			local position, vis = gameCamera.WorldToViewportPoint(gameCamera, v[entitysettings.Part].Position)
			if not vis then continue end
			local mag = (mouseLocation - Vector2.new(position.x, position.y)).Magnitude
			if mag > entitysettings.Range then continue end
			if entitylib.isVulnerable(v) then
				table.insert(sortingTable, {
					Entity = v,
					Magnitude = v.Target and -1 or mag
				})
			end
		end

		table.sort(sortingTable, entitysettings.Sort or function(a, b)
			return a.Magnitude < b.Magnitude
		end)

		for _, v in sortingTable do
			if entitysettings.Wallcheck then
				if entitylib.Wallcheck(entitysettings.Origin, v.Entity[entitysettings.Part].Position, entitysettings.Wallcheck) then continue end
			end
			table.clear(entitysettings)
			table.clear(sortingTable)
			return v.Entity
		end
		table.clear(sortingTable)
	end
	table.clear(entitysettings)
end

entitylib.EntityPosition = function(entitysettings)
	if entitylib.isAlive then
		local localPosition, sortingTable = entitysettings.Origin or entitylib.character.HumanoidRootPart.Position, {}
		for _, v in entitylib.List do
			if not entitysettings.Players and v.Player then continue end
			if not entitysettings.NPCs and v.NPC then continue end
			if not v.Targetable then continue end
			local mag = (v[entitysettings.Part].Position - localPosition).Magnitude
			if mag > entitysettings.Range then continue end
			if entitylib.isVulnerable(v) then
				table.insert(sortingTable, {
					Entity = v,
					Magnitude = v.Target and -1 or mag
				})
			end
		end

		table.sort(sortingTable, entitysettings.Sort or function(a, b)
			return a.Magnitude < b.Magnitude
		end)

		for _, v in sortingTable do
			if entitysettings.Wallcheck then
				if entitylib.Wallcheck(localPosition, v.Entity[entitysettings.Part].Position, entitysettings.Wallcheck) then continue end
			end
			table.clear(entitysettings)
			table.clear(sortingTable)
			return v.Entity
		end
		table.clear(sortingTable)
	end
	table.clear(entitysettings)
end

entitylib.AllPosition = function(entitysettings)
	local returned = {}
	if entitylib.isAlive then
		local localPosition, sortingTable = entitysettings.Origin or entitylib.character.HumanoidRootPart.Position, {}
		for _, v in entitylib.List do
			if not entitysettings.Players and v.Player then continue end
			if not entitysettings.NPCs and v.NPC then continue end
			if not v.Targetable then continue end
			local mag = (v[entitysettings.Part].Position - localPosition).Magnitude
			if mag > entitysettings.Range then continue end
			if entitylib.isVulnerable(v) then
				table.insert(sortingTable, {Entity = v, Magnitude = v.Target and -1 or mag})
			end
		end

		table.sort(sortingTable, entitysettings.Sort or function(a, b)
			return a.Magnitude < b.Magnitude
		end)

		for _, v in sortingTable do
			if entitysettings.Wallcheck then
				if entitylib.Wallcheck(localPosition, v.Entity[entitysettings.Part].Position, entitysettings.Wallcheck) then continue end
			end
			table.insert(returned, v.Entity)
			if #returned >= (entitysettings.Limit or math.huge) then break end
		end
		table.clear(sortingTable)
	end
	table.clear(entitysettings)
	return returned
end

entitylib.getEntity = function(char)
	for i, v in entitylib.List do
		if v.Player == char or v.Character == char then
			return v, i
		end
	end
end

entitylib.addEntity = function(char, plr, teamfunc)
	if not char then return end
	entitylib.EntityThreads[char] = task.spawn(function()
		local hum = waitForChildOfType(char, 'Humanoid', 10)
		local humrootpart = hum and waitForChildOfType(hum, 'RootPart', workspace.StreamingEnabled and 9e9 or 10, true)
		local head = char:WaitForChild('Head', 10) or humrootpart

		if hum and humrootpart then
			local entity = {
				Connections = {},
				Character = char,
				Health = hum.Health,
				Head = head,
				Humanoid = hum,
				HumanoidRootPart = humrootpart,
				HipHeight = hum.HipHeight + (humrootpart.Size.Y / 2) + (hum.RigType == Enum.HumanoidRigType.R6 and 2 or 0),
				MaxHealth = hum.MaxHealth,
				NPC = plr == nil,
				Player = plr,
				RootPart = humrootpart,
				TeamCheck = teamfunc
			}

			if plr == lplr then
				entitylib.character = entity
				entitylib.isAlive = true
				entitylib.Events.LocalAdded:Fire(entity)
			else
				entity.Targetable = entitylib.targetCheck(entity)

				for _, v in entitylib.getUpdateConnections(entity) do
					table.insert(entity.Connections, v:Connect(function()
						entity.Health = hum.Health
						entity.MaxHealth = hum.MaxHealth
						entitylib.Events.EntityUpdated:Fire(entity)
					end))
				end

				table.insert(entitylib.List, entity)
				entitylib.Events.EntityAdded:Fire(entity)
			end
		end
		entitylib.EntityThreads[char] = nil
	end)
end

entitylib.removeEntity = function(char, localcheck)
	if localcheck then
		if entitylib.isAlive then
			entitylib.isAlive = false
			for _, v in entitylib.character.Connections do
				v:Disconnect()
			end
			table.clear(entitylib.character.Connections)
			entitylib.Events.LocalRemoved:Fire(entitylib.character)
		end
		return
	end

	if char then
		if entitylib.EntityThreads[char] then
			task.cancel(entitylib.EntityThreads[char])
			entitylib.EntityThreads[char] = nil
		end

		local entity, ind = entitylib.getEntity(char)
		if ind then
			for _, v in entity.Connections do
				v:Disconnect()
			end
			table.clear(entity.Connections)
			table.remove(entitylib.List, ind)
			entitylib.Events.EntityRemoved:Fire(entity)
		end
	end
end

entitylib.refreshEntity = function(char, plr)
	entitylib.removeEntity(char)
	entitylib.addEntity(char, plr)
end

entitylib.addPlayer = function(plr)
	if plr.Character then
		entitylib.refreshEntity(plr.Character, plr)
	end
	entitylib.PlayerConnections[plr] = {
		plr.CharacterAdded:Connect(function(char)
			entitylib.refreshEntity(char, plr)
		end),
		plr.CharacterRemoving:Connect(function(char)
			entitylib.removeEntity(char, plr == lplr)
		end),
		plr:GetPropertyChangedSignal('Team'):Connect(function()
			for _, v in entitylib.List do
				if v.Targetable ~= entitylib.targetCheck(v) then
					entitylib.refreshEntity(v.Character, v.Player)
				end
			end

			if plr == lplr then
				entitylib.start()
			else
				entitylib.refreshEntity(plr.Character, plr)
			end
		end)
	}
end

entitylib.removePlayer = function(plr)
	if entitylib.PlayerConnections[plr] then
		for _, v in entitylib.PlayerConnections[plr] do
			v:Disconnect()
		end
		table.clear(entitylib.PlayerConnections[plr])
		entitylib.PlayerConnections[plr] = nil
	end
	entitylib.removeEntity(plr)
end

entitylib.start = function()
	if entitylib.Running then
		entitylib.stop()
	end
	table.insert(entitylib.Connections, playersService.PlayerAdded:Connect(function(v)
		entitylib.addPlayer(v)
	end))
	table.insert(entitylib.Connections, playersService.PlayerRemoving:Connect(function(v)
		entitylib.removePlayer(v)
	end))
	for _, v in playersService:GetPlayers() do
		entitylib.addPlayer(v)
	end
	table.insert(entitylib.Connections, workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(function()
		gameCamera = workspace.CurrentCamera or workspace:FindFirstChildWhichIsA('Camera')
	end))
	entitylib.Running = true
end

entitylib.stop = function()
	for _, v in entitylib.Connections do
		v:Disconnect()
	end
	for _, v in entitylib.PlayerConnections do
		for _, v2 in v do
			v2:Disconnect()
		end
		table.clear(v)
	end
	entitylib.removeEntity(nil, true)
	local cloned = table.clone(entitylib.List)
	for _, v in cloned do
		entitylib.removeEntity(v.Character)
	end
	for _, v in entitylib.EntityThreads do
		task.cancel(v)
	end
	table.clear(entitylib.PlayerConnections)
	table.clear(entitylib.EntityThreads)
	table.clear(entitylib.Connections)
	table.clear(cloned)
	entitylib.Running = false
end

entitylib.kill = function()
	if entitylib.Running then
		entitylib.stop()
	end
	for _, v in entitylib.Events do
		v:Destroy()
	end
	entitylib.IgnoreObject:Destroy()
	loopClean(entitylib)
end

entitylib.refresh = function()
	local cloned = table.clone(entitylib.List)
	for _, v in cloned do
		entitylib.refreshEntity(v.Character, v.Player)
	end
	table.clear(cloned)
end

entitylib.start()
run(function()
	entitylib.getUpdateConnections = function(ent)
		local hum = ent.Humanoid
		return {
			hum:GetPropertyChangedSignal('Health'),
			hum:GetPropertyChangedSignal('MaxHealth'),
			{
				Connect = function()
					ent.Friend = ent.Player and nil
					ent.Target = ent.Player and  nil
					return {Disconnect = function() end}
				end
			},
			{
				Connect = function()
					return hum:GetPropertyChangedSignal('Sit'):Connect(function()
						if getVehicle(ent) then
							ent.Illegal = true
						end
					end)
				end
			}
		}
	end

	entitylib.targetCheck = function(ent)
		if ent.TeamCheck then return ent:TeamCheck() end
		if ent.NPC then return true end
		if lplr.Team == teamsService.Police then
			return ent.Player.Team ~= teamsService.Police
		else
			return ent.Player.Team == teamsService.Police
		end
		return true
	end
end)

local LazerGodmode = {Enabled = false}

-- =================================================================================================
-- GUI LIBRARY
-- =================================================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SapienGUIMain"
screenGui.Parent = game:GetService("CoreGui")
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
screenGui.ResetOnSpawn = false

_G.Main = _G.Main or {}

-- Settings are now for session state only, not saved.
_G.Main.Settings = {
    ButtonStates = {},
    FramePositions = {},
    ModuleStates = {},
    GuiVisible = true,
    SeenIntro = false
}

_G.Main.UIReferences = {
    Buttons = {},
    Frames = {},
    MainGui = nil,
    ToggleButton = nil,
    BlurEffect = nil -- Reference for the blur effect
}

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

-- Animation presets
local ANIMATION_SETTINGS = {
    FrameEntrance = {
        Time = 0.5,
        Easing = Enum.EasingStyle.Quint,
        Offset = UDim2.new(0, 0, 0.1, 0)
    },
    ButtonHover = {
        Time = 0.15,
        Easing = Enum.EasingStyle.Linear
    },
    ButtonPress = {
        Time = 0.1,
        Easing = Enum.EasingStyle.Back
    },
    GuiToggle = {
        Time = 0.3,
        Easing = Enum.EasingStyle.Quad
    },
    Intro = {
        Time = 0.6,
        Easing = Enum.EasingStyle.Quint
    }
}

-- Initialize the GUI system
function _G.Main.Init()
    -- Create main container GUI
    local mainGui = Instance.new("ScreenGui")
    mainGui.Name = "SapienMainGui"
    mainGui.ResetOnSpawn = false
    mainGui.IgnoreGuiInset = true
    mainGui.DisplayOrder = 10
    mainGui.Parent = game:GetService("CoreGui")
    _G.Main.UIReferences.MainGui = mainGui

    -- Create toggle button
    _G.Main.CreateToggleButton(mainGui)

    -- Show intro GUI if first time this session
    if not _G.Main.Settings.SeenIntro then
        _G.Main.ShowIntroGui()
        _G.Main.Settings.SeenIntro = true
    end

    -- Set up hotkeys
    _G.Main.SetupHotkeys()
end

-- Create the GUI toggle button
function _G.Main.CreateToggleButton(parent)
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleGUIButton"
    toggleButton.Size = UDim2.new(0, 120, 0, 36)
    toggleButton.Position = UDim2.new(0, 10, 0, 10)
    toggleButton.AnchorPoint = Vector2.new(0, 0)
    toggleButton.BackgroundColor3 = Color3.fromRGB(0, 102, 204)
    toggleButton.BackgroundTransparency = 0.3
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.Text = _G.Main.Settings.GuiVisible and "Hide GUI" or "Show GUI"
    toggleButton.TextScaled = true
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.BorderSizePixel = 0
    toggleButton.ZIndex = 20
    toggleButton.Parent = parent

    -- Visual styling
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = toggleButton

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(0, 204, 255)
    stroke.Transparency = 0.3
    stroke.Parent = toggleButton

    -- Animation on hover
    toggleButton.MouseEnter:Connect(function()
        TweenService:Create(toggleButton, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.2,
            TextColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
    end)

    toggleButton.MouseLeave:Connect(function()
        TweenService:Create(toggleButton, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.3,
            TextColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
    end)

    -- Click functionality
    toggleButton.MouseButton1Click:Connect(function()
        _G.Main.ToggleGuiVisibility()
    end)
end

-- Toggles GUI visibility and screen blur
function _G.Main.ToggleGuiVisibility()
    -- Toggle the state
    _G.Main.Settings.GuiVisible = not _G.Main.Settings.GuiVisible
    local isVisible = _G.Main.Settings.GuiVisible

    -- Handle the Blur Effect
    if not _G.Main.UIReferences.BlurEffect then
        _G.Main.UIReferences.BlurEffect = Instance.new("BlurEffect")
        _G.Main.UIReferences.BlurEffect.Name = "SapienGuiBlur"
        _G.Main.UIReferences.BlurEffect.Parent = Lighting
    end
    
    _G.Main.UIReferences.BlurEffect.Enabled = isVisible
    _G.Main.UIReferences.BlurEffect.Size = isVisible and 16 or 0

    -- Update the main toggle button's visibility and text
    if _G.Main.UIReferences.ToggleButton then
        _G.Main.UIReferences.ToggleButton.Text = isVisible and "Hide GUI" or "Show GUI"
        _G.Main.UIReferences.ToggleButton.Visible = isVisible
    end
    
    -- Set visibility for all registered frames
    for _, frame in pairs(_G.Main.UIReferences.Frames) do
        frame.Visible = isVisible
    end
end


-- Set up hotkeys
function _G.Main.SetupHotkeys()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
            _G.Main.ToggleGuiVisibility()
        end
    end)
end

function _G.Main.ShowIntroGui()
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")

    -- Create main GUI
    local introGui = Instance.new("ScreenGui")
    introGui.Name = "SapienIntroGui"
    introGui.ResetOnSpawn = false
    introGui.IgnoreGuiInset = true
    introGui.Parent = game:GetService("CoreGui")
    introGui.DisplayOrder = 20

    -- Fullscreen background with animated gradient
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(5, 10, 20)
    bg.BackgroundTransparency = 1 -- Start fully transparent for fade-in
    bg.Parent = introGui

    local gradient = Instance.new("UIGradient")
    gradient.Rotation = 90
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(5, 10, 25)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 25, 50))
    })
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(1, 0.7)
    })
    gradient.Parent = bg

    -- Animated particles background
    local particles = Instance.new("Frame")
    particles.Size = UDim2.new(1, 0, 1, 0)
    particles.BackgroundTransparency = 1
    particles.Parent = bg

    for i = 1, 30 do
        local particle = Instance.new("Frame")
        particle.Size = UDim2.new(0, math.random(2, 5), 0, math.random(2, 5))
        particle.Position = UDim2.new(math.random(), 0, math.random(), 0)
        particle.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
        particle.BackgroundTransparency = 0.7
        particle.BorderSizePixel = 0
        particle.Parent = particles

        task.spawn(function()
            local currentTween
            while particle.Parent do
                local moveTime = math.random(3, 7)
                local targetPosition = UDim2.new(math.random(), 0, math.random(), 0)
                currentTween = TweenService:Create(particle, TweenInfo.new(moveTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Position = targetPosition
                })
                currentTween:Play()
                currentTween.Completed:Wait()
                currentTween:Destroy()
            end
            if currentTween and not currentTween.Completed then
                currentTween:Cancel()
            end
        end)
    end

    local container = Instance.new("Frame")
    container.Size = UDim2.new(0.7, 0, 0.6, 0)
    container.Position = UDim2.new(0.5, 0, 0.5, 0)
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.BackgroundTransparency = 1
    container.Parent = bg

    local shine = Instance.new("Frame")
    shine.Size = UDim2.new(0.8, 0, 0.8, 0)
    shine.Position = UDim2.new(0.5, 0, 0.5, 0)
    shine.AnchorPoint = Vector2.new(0.5, 0.5)
    shine.BackgroundTransparency = 1
    shine.Parent = container

    local shineGradient = Instance.new("UIGradient")
    shineGradient.Rotation = 45
    shineGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 180, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 180, 255))
    })
    shineGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 1),
        NumberSequenceKeypoint.new(1, 1)
    })
    shineGradient.Parent = shine

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.3, 0)
    title.Position = UDim2.new(0.5, 0, 0.2, 0)
    title.AnchorPoint = Vector2.new(0.5, 0.5)
    title.BackgroundTransparency = 1
    title.Text = "" -- Set initially empty for typewriter effect
    title.TextColor3 = Color3.fromRGB(0, 200, 255)
    title.TextTransparency = 1 -- Start transparent
    title.TextScaled = true
    title.Font = Enum.Font.GothamBlack
    title.TextStrokeTransparency = 0.7
    title.TextStrokeColor3 = Color3.fromRGB(0, 80, 150)
    title.ZIndex = 2
    title.Parent = container

    local glow = Instance.new("ImageLabel")
    glow.Size = UDim2.new(1.5, 0, 1.5, 0)
    glow.Position = UDim2.new(0.5, 0, 0.5, 0)
    glow.AnchorPoint = Vector2.new(0.5, 0.5)
    glow.BackgroundTransparency = 1
    glow.Image = "rbxassetid://5028857084"
    glow.ImageColor3 = Color3.fromRGB(0, 120, 255)
    glow.ImageTransparency = 1 -- Start transparent
    glow.ScaleType = Enum.ScaleType.Slice
    glow.SliceCenter = Rect.new(100, 100, 100, 100)
    glow.ZIndex = 1
    glow.Parent = title

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, 0, 0.15, 0)
    subtitle.Position = UDim2.new(0.5, 0, 0.45, 0)
    subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "JOIN OUR DISCORD FOR UPDATES AND OP SCRIPTS"
    subtitle.TextColor3 = Color3.fromRGB(150, 220, 255)
    subtitle.TextTransparency = 1 -- Start transparent
    subtitle.TextScaled = true
    subtitle.Font = Enum.Font.GothamMedium
    subtitle.TextStrokeTransparency = 0.8
    subtitle.TextStrokeColor3 = Color3.fromRGB(0, 50, 100)
    subtitle.ZIndex = 2
    subtitle.Parent = container

    local version = Instance.new("TextLabel")
    version.Size = UDim2.new(1, 0, 0.1, 0)
    version.Position = UDim2.new(0.5, 0, 0.9, 0)
    version.AnchorPoint = Vector2.new(0.5, 0.5)
    version.BackgroundTransparency = 1
    version.Text = "v1.0.0"
    version.TextColor3 = Color3.fromRGB(100, 180, 255)
    version.TextTransparency = 1 -- Start transparent
    version.TextScaled = true
    version.Font = Enum.Font.Gotham
    version.TextStrokeTransparency = 0.9
    version.ZIndex = 2
    version.Parent = container

    -- Fade in background
    TweenService:Create(bg, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {
        BackgroundTransparency = 0
    }):Play()

    -- Animate shine offset
    TweenService:Create(shineGradient, TweenInfo.new(15, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {
        Offset = Vector2.new(1, 1)
    }):Play()

    -- Manual transparency animation for shineGradient
    task.spawn(function()
        local duration = 0.8
        local startTime = tick()
        
        local startKeypoints = {{Time = 0, Value = 1}, {Time = 0.5, Value = 1}, {Time = 1, Value = 1}}
        local targetKeypoints = {{Time = 0, Value = 0.9}, {Time = 0.5, Value = 0.7}, {Time = 1, Value = 0.9}}

        local connection
        connection = RunService.RenderStepped:Connect(function()
            local alpha = math.clamp((tick() - startTime) / duration, 0, 1)
            
            local newKeypoints = {}
            for i, startKp in ipairs(startKeypoints) do
                local targetKp = targetKeypoints[i]
                local currentValue = startKp.Value + (targetKp.Value - startKp.Value) * alpha
                table.insert(newKeypoints, NumberSequenceKeypoint.new(startKp.Time, currentValue))
            end
            
            shineGradient.Transparency = NumberSequence.new(newKeypoints)
            
            if alpha >= 1 then
                connection:Disconnect()
            end
        end)
    end)

    -- Typewriter effect for title
    task.spawn(function()
        local fullText = "SAPIEN"
        for i = 1, #fullText do
            title.Text = string.sub(fullText, 1, i)
            title.TextTransparency = 0
            task.wait(0.08)
        end

        -- Main title glow animation loop
        while title.Parent do
            TweenService:Create(glow, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                ImageTransparency = 0.85,
                Size = UDim2.new(1.6, 0, 1.6, 0)
            }):Play()
            task.wait(1.5)
            TweenService:Create(glow, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                ImageTransparency = 0.7,
                Size = UDim2.new(1.4, 0, 1.4, 0)
            }):Play()
            task.wait(1.5)
        end
    end)

    -- Delayed animations for subtitle and version
    task.delay(0.8, function()
        TweenService:Create(subtitle, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {
            TextTransparency = 0.2
        }):Play()

        TweenService:Create(version, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {
            TextTransparency = 0.3
        }):Play()
    end)

    -- Outro animation
    task.delay(4.5, function()
        -- Animate elements out
        TweenService:Create(title, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {
            TextTransparency = 1,
            Position = UDim2.new(0.5, 0, 0.1, 0),
            TextColor3 = Color3.fromRGB(0, 255, 255)
        }):Play()

        TweenService:Create(subtitle, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {
            TextTransparency = 1,
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }):Play()

        TweenService:Create(version, TweenInfo.new(0.7, Enum.EasingStyle.Quint), { TextTransparency = 1 }):Play()

        TweenService:Create(glow, TweenInfo.new(0.7, Enum.EasingStyle.Quad), {
            ImageTransparency = 1,
            Size = UDim2.new(0, 0, 0, 0),
            ImageColor3 = Color3.fromRGB(0, 255, 255)
        }):Play()

        -- Manual fade out for shineGradient
        task.spawn(function()
            local duration = 0.7
            local startTime = tick()
            local initialTransparency = shineGradient.Transparency
            
            local connection
            connection = RunService.RenderStepped:Connect(function()
                local alpha = math.clamp((tick() - startTime) / duration, 0, 1)
                local newKeypoints = {}
                local currentKeypoints = initialTransparency.Keypoints
                
                for _, kp in ipairs(currentKeypoints) do
                    local interpolatedValue = kp.Value + (1 - kp.Value) * alpha
                    table.insert(newKeypoints, NumberSequenceKeypoint.new(kp.Time, interpolatedValue))
                end
                
                shineGradient.Transparency = NumberSequence.new(newKeypoints)
                
                if alpha >= 1 then
                    connection:Disconnect()
                end
            end)
        end)

        local bgFadeOut = TweenService:Create(bg, TweenInfo.new(1, Enum.EasingStyle.Quint), {
            BackgroundTransparency = 1
        })
        bgFadeOut:Play()

        bgFadeOut.Completed:Connect(function()
            introGui:Destroy()
        end)
    end)
end

function _G.Main.createFrame(parent, position, color, text, name, maxHeight)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.Visible = false
    frame.Name = name or "Frame"
    frame.Size = UDim2.new(0, 150, 0, 50)
    frame.Position = (position or UDim2.new(0.5, -100, 0.5, 0)) + UDim2.new(0, 0, 0.1, 50) -- Start below
    frame.BackgroundColor3 = color or Color3.fromRGB(15, 25, 49)
    frame.BackgroundTransparency = 1 -- Start transparent
    frame.ClipsDescendants = true
    frame.Visible = _G.Main.Settings.GuiVisible
    maxHeight = maxHeight or 270

    if _G.Main.Settings.GuiVisible then
        TweenService:Create(frame, TweenInfo.new(
            ANIMATION_SETTINGS.FrameEntrance.Time,
            ANIMATION_SETTINGS.FrameEntrance.Easing
        ), {
            Position = position or UDim2.new(0.5, -100, 0.5, 0),
            BackgroundTransparency = 0.2
        }):Play()
    else
        frame.BackgroundTransparency = 1
        frame.Position = position or UDim2.new(0.5, -100, 0.5, 0)
    end

    local drag = Instance.new("UIDragDetector", frame)
    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke")
    stroke.Parent = frame
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(0, 153, 255)
    stroke.Transparency = 1 -- Start transparent

    if _G.Main.Settings.GuiVisible then
        TweenService:Create(stroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { Transparency = 0.3 }):Play()
    end

    local title = Instance.new("Frame")
    title.Parent = frame
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = Color3.fromRGB(0, 102, 204)
    title.BackgroundTransparency = 1 -- Start transparent
    title.BorderSizePixel = 0
    
    local titleGradient = Instance.new("UIGradient")
    titleGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 102, 204)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 153, 255))
    })
    titleGradient.Rotation = 90
    titleGradient.Parent = title

    if _G.Main.Settings.GuiVisible then
        TweenService:Create(title, TweenInfo.new(0.4), { BackgroundTransparency = 0 }):Play()
    end

    local titleText = Instance.new("TextLabel")
    titleText.Parent = title
    titleText.Size = UDim2.new(1, 0, 1, 0)
    titleText.BackgroundTransparency = 1
    titleText.Font = Enum.Font.GothamBold
    titleText.Text = "" -- For typing effect
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextScaled = true
    titleText.TextWrapped = true

    if _G.Main.Settings.GuiVisible then
        task.spawn(function()
            local fullText = text or "Frame"
            for i = 1, #fullText do
                titleText.Text = string.sub(fullText, 1, i)
                task.wait(0.03)
            end
        end)
    else
        titleText.Text = text or "Frame"
    end

    local scrollingFrame = Instance.new("ScrollingFrame")
    scrollingFrame.Parent = frame
    scrollingFrame.Size = UDim2.new(1, -10, 1, -45)
    scrollingFrame.Position = UDim2.new(0, 5, 0, 40)
    scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollingFrame.BackgroundTransparency = 1
    scrollingFrame.ScrollBarThickness = 4
    scrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 153, 255)
    scrollingFrame.ClipsDescendants = true
    scrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    scrollingFrame.ScrollBarImageTransparency = 1 -- Start transparent

    if _G.Main.Settings.GuiVisible then
        TweenService:Create(scrollingFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { ScrollBarImageTransparency = 0.3 }):Play()
    end

    local layout = Instance.new("UIListLayout", scrollingFrame)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        local contentHeight = layout.AbsoluteContentSize.Y
        if contentHeight <= maxHeight then
            scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
            frame.Size = UDim2.new(0, frame.Size.X.Offset, 0, contentHeight + 45)
            scrollingFrame.ClipsDescendants = false
        else
            scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
            frame.Size = UDim2.new(0, frame.Size.X.Offset, 0, maxHeight + 45)
            scrollingFrame.ClipsDescendants = true
        end
    end)

    _G.Main.UIReferences.Frames[name] = frame
    return scrollingFrame
end

function _G.Main.createButton(parentFrame, text, onClick, size, color)
    local button = Instance.new("TextButton")
    button.Parent = parentFrame
    button.BackgroundColor3 = color or Color3.fromRGB(30, 60, 120)
    button.BackgroundTransparency = 0.7
    button.Text = text or "Button"
    button.Font = Enum.Font.GothamMedium
    button.TextScaled = true
    button.TextSize = 14
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.AutoButtonColor = false
    button.TextColor3 = Color3.fromRGB(200, 230, 255)

    local originalSize = size or UDim2.new(0, 140, 0, 32)
    button.Size = UDim2.new(0, 0, 0, originalSize.Y.Offset)
    TweenService:Create(button, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Size = originalSize }):Play()

    _G.Main.UIReferences.Buttons[text] = button

    local corner = Instance.new("UICorner", button)
    corner.CornerRadius = UDim.new(0, 6)

    button.MouseEnter:Connect(function()
        if not (_G.Main.Settings.ButtonStates[text] or false) then
            TweenService:Create(button, TweenInfo.new(ANIMATION_SETTINGS.ButtonHover.Time), {
                BackgroundTransparency = 0.4,
                TextColor3 = Color3.fromRGB(255, 255, 255)
            }):Play()
        end
    end)

    button.MouseLeave:Connect(function()
        if not (_G.Main.Settings.ButtonStates[text] or false) then
            TweenService:Create(button, TweenInfo.new(ANIMATION_SETTINGS.ButtonHover.Time), {
                BackgroundTransparency = 0.7,
                TextColor3 = Color3.fromRGB(200, 230, 255)
            }):Play()
        end
    end)

    button.MouseButton1Down:Connect(function()
        TweenService:Create(button, TweenInfo.new(ANIMATION_SETTINGS.ButtonPress.Time, ANIMATION_SETTINGS.ButtonPress.Easing), {
            Size = originalSize - UDim2.new(0, 10, 0, 5)
        }):Play()
    end)

    button.MouseButton1Up:Connect(function()
        TweenService:Create(button, TweenInfo.new(ANIMATION_SETTINGS.ButtonPress.Time * 1.5, ANIMATION_SETTINGS.ButtonPress.Easing), {
            Size = originalSize
        }):Play()
    end)

    button.MouseButton1Click:Connect(function()
        local newIsActive = not (_G.Main.Settings.ButtonStates[text] or false)
        _G.Main.Settings.ButtonStates[text] = newIsActive

        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundTransparency = newIsActive and 0.1 or 0.7,
            TextColor3 = newIsActive and Color3.fromRGB(0, 255, 255) or Color3.fromRGB(200, 230, 255)
        }):Play()

        if newIsActive then
            task.spawn(function()
                TweenService:Create(button, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(0, 180, 255)}):Play()
                task.wait(0.1)
                TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = color or Color3.fromRGB(30, 60, 120)}):Play()
            end)
        end
        
        if onClick then onClick(newIsActive) end
    end)
    
    return button
end

-- Initialize the library
_G.Main.Init()
-- =================================================================================================
-- MAIN SCRIPT LOGIC
-- =================================================================================================

if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Create the main GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SapienGUIMain"
screenGui.Parent = game:GetService("CoreGui")
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
screenGui.ResetOnSpawn = false


-- Create the main combat frame
local combatFrame = _G.Main.createFrame(screenGui, UDim2.new(0.1, 0, 0.1, 0), nil, "Combat", "CombatFrame")
local Visuals = _G.Main.createFrame(screenGui, UDim2.new(0.34, 0, 0.7, 0), nil, "Visuals", "VisualsFrame")

-- Feature state variables
local silentAimEnabled = false
local wallbangEnabled = false

-- Store original functions to restore them later
local originalTransformFunction = jb.GunController.TransformLocalMousePosition
local originalHitPlayerFunction = jb.GunController.BulletEmitterOnLocalHitPlayer
local wallbangHookActive = false

-- Hardcoded "best" settings for Silent Aim
local aimSettings = {
    Range = 1000,
    Mode = 'Position',
    Players = true,
    NPCs = true,
    Walls = false,
    Part = 'RootPart',
    Instant = true
}

-- The new function that will replace TransformLocalMousePosition when Silent Aim is active
local function silentAimHook(self, pos)
    if not silentAimEnabled then
        return originalTransformFunction(self, pos) -- Safeguard
    end

    local ent = entitylib['Entity'..aimSettings.Mode]({
        Range = aimSettings.Range,
        Wallcheck = aimSettings.Walls and true or nil,
        Part = aimSettings.Part,
        Origin = entitylib.isAlive and entitylib.character.RootPart.Position or nil,
        Players = aimSettings.Players,
        NPCs = aimSettings.NPCs
    })

    if ent then
        local item = jb.ItemSystemController:GetLocalEquipped()
        if item and item.Config and item.BulletEmitter then
            local timeToTarget = (self.Tip.CFrame.Position - ent.RootPart.Position).Magnitude / (item.Config.BulletSpeed or 1000)
            if timeToTarget < item.BulletEmitter.LifeSpan then
                local ProjectileRaycast = RaycastParams.new()
                ProjectileRaycast.RespectCanCollide = true
                ProjectileRaycast.FilterDescendantsInstances = {workspace.CurrentCamera, ent.Character, lplr.Character}
                ProjectileRaycast.CollisionGroup = ent.RootPart.CollisionGroup
                
                local calc = module.SolveTrajectory(self.Tip.CFrame.Position, item.Config.BulletSpeed or 1000, math.abs(item.BulletEmitter.GravityVector.Y), ent.RootPart.Position, aimSettings.Instant and Vector3.zero or ent.RootPart.Velocity, workspace.Gravity, ent.HipHeight, nil, ProjectileRaycast)
                if calc then
                    return calc
                end
            end
        end
    end

    return pos
end

-- Loop for hitscan bullets
task.spawn(function()
    while true do
        if silentAimEnabled and aimSettings.Instant then
            local item = jb.ItemSystemController:GetLocalEquipped()
            if item and item.BulletEmitter then
                rawset(item.BulletEmitter, 'LastUpdate', tick() - (item.BulletEmitter.LifeSpan - 0.05))
            end
        end
        task.wait()
    end
end)

-- Loop for wallbang ignore list
task.spawn(function()
    while true do
        if wallbangEnabled then
            local item = jb.ItemSystemController:GetLocalEquipped()
            if item and item.BulletEmitter then
                item.BulletEmitter.IgnoreList = {workspace}
            end
        end
        task.wait(0.1)
    end
end)

-- Create Silent Aim Button
_G.Main.createButton(combatFrame, "Silent Aim", function()
    silentAimEnabled = not silentAimEnabled
    if silentAimEnabled then
        jb.GunController.TransformLocalMousePosition = silentAimHook
    else
        jb.GunController.TransformLocalMousePosition = originalTransformFunction
    end
end)


-- =================================================================================================
-- NEW MODULES & GUI (World & Utility)
-- =================================================================================================

-- Create the World and Utility frames
local worldFrame = _G.Main.createFrame(screenGui, UDim2.new(0.2, 0, 0.1, 0), nil, "World", "WorldFrame")
local utilityFrame = _G.Main.createFrame(screenGui, UDim2.new(0.3, 0, 0.1, 0), nil, "Utility", "UtilityFrame")

local autoArrestEnabled = false
_G.Main.createButton(worldFrame, "Auto Arrest", function()
    autoArrestEnabled = not autoArrestEnabled
end)
task.spawn(function()
    while true do
        if autoArrestEnabled then
            local item = 'Handcuffs'
            if item == 'Handcuffs' then
                local localPosition = entitylib.isAlive and entitylib.character.RootPart.Position or nil
                if localPosition then
                    local plrs = entitylib.AllPosition({ Players = true, Part = 'RootPart', Range = 50 })
                    for _, ent in plrs do
                        if not autoArrestEnabled then break end
                        if ent.Player and isIllegal(ent) then
                            local vehicle = ent.Humanoid.Sit and getVehicle(ent) or nil
                            if vehicle then
                                jb:FireServer('Eject', vehicle)
                            elseif not isArrested(ent.Player.Name) and (localPosition - ent.RootPart.Position).Magnitude < 18.4 then
                                jb:FireServer('Arrest', ent.Player.Name)
                                task.wait(0.6)
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.016)
    end
end)

local autoPopEnabled = false
local autoPopHandCheck = false
local autoPopTeamCheck = true 
local AUTO_POP_RANGE = 600

local function getEntitiesInVehicle(car)
    local entities = {}
    for _, seat in car:GetChildren() do
        if (seat.Name == 'Seat' or seat.Name == 'Passenger') and seat:FindFirstChild('PlayerName') then
            for _, ent in entitylib.List do
                if ent.Player and ent.Player.Name == seat.PlayerName.Value then
                    table.insert(entities, ent)
                end
            end
        end
    end
    return entities
end

_G.Main.createButton(worldFrame, "Auto Pop Tires", function() autoPopEnabled = not autoPopEnabled end)

task.spawn(function()
    while true do
        if autoPopEnabled and entitylib.isAlive then
            local item = jb.ItemSystemController:GetLocalEquipped()
            if (not autoPopHandCheck) or (item and item.BulletEmitter) then
                local localPosition = entitylib.character.RootPart.Position
                for _, car in collectionService:GetTagged('Vehicle') do
                    if not autoPopEnabled then break end
                    if car.PrimaryPart and (car.PrimaryPart.Position - localPosition).Magnitude <= AUTO_POP_RANGE then
                        local entities = getEntitiesInVehicle(car)
                        local check = #entities > 0
                        if autoPopTeamCheck then
                            for _, ent in entities do
                                if not ent.Targetable then
                                    check = false
                                    break
                                end
                            end
                        end
                        if check then
                            jb:FireServer('PopTires', car, 'Sniper')
                            task.wait(0.1)
                        end
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)


-- Auto Punch
local autoPunchEnabled = false
_G.Main.createButton(worldFrame, "Auto Punch", function()
    autoPunchEnabled = not autoPunchEnabled
end)
task.spawn(function()
    while true do
        if autoPunchEnabled and entitylib.isAlive then
            jb:FireServer('Punch')
        end
        task.wait(0.3)
    end
end)

-- Auto Taze
local autoTazeEnabled = false
local autoTazeHandCheck = false
_G.Main.createButton(worldFrame, "Auto Taze", function() autoTazeEnabled = not autoTazeEnabled end)
task.spawn(function()
    while true do
        if autoTazeEnabled then
            local item = jb.ItemSystemController:GetLocalEquipped()
            local hasTaser = item and item.__ClassName == 'Taser'
            if not autoTazeHandCheck or hasTaser then
                local ent = entitylib.EntityPosition({ Players = true, Part = 'RootPart', Range = 50 })
                if ent and isIllegal(ent) and not isArrested(ent.Player.Name) then
                    if hasTaser then
                        jb:FireServer('TaseReplicate', ent.Head.Position)
                    end
                    jb:FireServer('Tase', ent.Humanoid, ent.Head, ent.Head.Position)
                    task.wait(10) 
                end
            end
        end
        task.wait(0.05)
    end
end)



-- Lazer Godmode
_G.Main.createButton(utilityFrame, "Lazer Godmode", function()
    LazerGodmode.Enabled = not LazerGodmode.Enabled
end)

-- No Fall Damage
local noFallEnabled = false
_G.Main.createButton(utilityFrame, "No Fall", function()
    noFallEnabled = not noFallEnabled
    -- This debug constant manipulates the game's fall handling logic.
    debug.setconstant(debug.getupvalue(jb.FallingController.Init, 19), 9, noFallEnabled and 'Archivable' or 'Sit')
end)

-- Infinite Nitro
local oldNitroValue
local nitroTable = debug.getupvalue(jb.VehicleController.NitroShopVisible, 1)
_G.Main.createButton(utilityFrame, "Infinite Nitro", function()
    InfNitro.Enabled = not InfNitro.Enabled
    if InfNitro.Enabled then
        oldNitroValue = nitroTable.Nitro
        jb.VehicleController.updateSpdBarRatio(1)
    else
        nitroTable.Nitro = oldNitroValue
        jb.VehicleController.updateSpdBarRatio(oldNitroValue / 250)
    end
end)
task.spawn(function()
    while true do
        if InfNitro.Enabled then
            nitroTable.Nitro = 250
        end
        task.wait(0.1)
    end
end)

-- Instant Action
local instantActionEnabled = false
_G.Main.createButton(utilityFrame, "Instant Action", function()
    instantActionEnabled = not instantActionEnabled
    -- This debug constant changes a check from "Timed" to something else, skipping the hold timer.
    debug.setconstant(jb.CircleAction.Press, 3, instantActionEnabled and 'Timeda' or 'Timed')
end)

-- Key Spoofer
local keySpooferEnabled = false
    if keySpooferEnabled then
        hookfunction(jb.PlayerUtils.hasKey,function()
        return true
       end)
end
_G.Main.createButton(utilityFrame, "Key Spoofer", function()
    keySpooferEnabled = not keySpooferEnabled
    if keySpooferEnabled then
        hookfunction(jb.PlayerUtils.hasKey,function()
        return true
       end)
     else 
           restorefunction(jb.PlayerUtils.hasKey)
   end
end)
local flying = false
local targetHeight = 10
local speed = 100
local minHeight = 0.5
local heightStep = 4
local holdSpeed = 0.1
local holdUp, holdDown = false, false 

local player = game:GetService("Players").LocalPlayer
local character, root, humanoid
local bv = nil

local function updateCharacter(newCharacter)
    character = newCharacter
    root = character:WaitForChild("HumanoidRootPart")
    humanoid = character:WaitForChild("Humanoid")
    
    if flying then
        toggleFly(true)
    end
end

player.CharacterAdded:Connect(updateCharacter)
if player.Character then
    updateCharacter(player.Character)
end

local FlyGUI = Instance.new("Frame", screenGui)
FlyGUI.Size = UDim2.new(0.1, 0, 0.1, 0)
FlyGUI.Position = UDim2.new(0.85, 0, 0.4, 0)
FlyGUI.BackgroundTransparency = 1
FlyGUI.Visible = false

local UpButton = Instance.new("TextButton", FlyGUI)
UpButton.Size = UDim2.new(1, 0, 0.5, 0)
UpButton.Position = UDim2.new(0, 0, 0, 0)
UpButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
UpButton.Text = "⬆"
UpButton.TextScaled = true
UpButton.Parent = FlyGUI

local DownButton = Instance.new("TextButton", FlyGUI)
DownButton.Size = UDim2.new(1, 0, 0.5, 0)
DownButton.Position = UDim2.new(0, 0, 0.5, 0)
DownButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
DownButton.Text = "⬇"
DownButton.TextScaled = true
DownButton.Parent = FlyGUI

local function getGroundHeight()
    local ray = Ray.new(root.Position, Vector3.new(0, -100, 0)) -- Cast downwards
    local hit, pos = workspace:FindPartOnRayWithIgnoreList(ray, {character})
    return hit and pos.Y or root.Position.Y
end

local function toggleFly(state)
    flying = state or not flying
    FlyGUI.Visible = flying

    if flying then
        if not bv then
            bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            bv.Velocity = Vector3.zero
            bv.Parent = root
        end
        targetHeight = math.max(getGroundHeight() + minHeight, root.Position.Y)
    else
        if bv then bv:Destroy(); bv = nil end
        root.AssemblyLinearVelocity = Vector3.zero
    end
end

game:GetService("RunService").RenderStepped:Connect(function()
    if flying and character and root then
        local moveDirection = humanoid.MoveDirection
        local verticalVelocity = (targetHeight - root.Position.Y) * 5 -- Smooth height adjustment
        bv.Velocity = moveDirection * speed + Vector3.new(0, verticalVelocity, 0)
    end
end)

local function increaseHeight()
    targetHeight = targetHeight + heightStep
end

local function decreaseHeight()
    local groundHeight = getGroundHeight()
    if targetHeight > groundHeight + minHeight then
        targetHeight = targetHeight - heightStep
    end
end

local function startHoldingUp()
    holdUp = true
    while holdUp do
        increaseHeight()
        task.wait(holdSpeed)
    end
end

local function startHoldingDown()
    holdDown = true
    while holdDown do
        decreaseHeight()
        task.wait(holdSpeed)
    end
end

UpButton.MouseButton1Down:Connect(startHoldingUp)
UpButton.MouseButton1Up:Connect(function() holdUp = false end)
UpButton.MouseLeave:Connect(function() holdUp = false end)

DownButton.MouseButton1Down:Connect(startHoldingDown)
DownButton.MouseButton1Up:Connect(function() holdDown = false end)
DownButton.MouseLeave:Connect(function() holdDown = false end)

game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then
        increaseHeight()
    elseif input.KeyCode == Enum.KeyCode.L then
        decreaseHeight()
    end
end)
local flyButton = _G.Main.createButton(utilityFrame, "ToggleFly[F and L]", function() toggleFly() end)

local speedEnabled = false
local ws = 50
local bv = nil

local player = game:GetService("Players").LocalPlayer
local character, root, humanoid
local function updateCharacter(newCharacter)
    character = newCharacter
    root = character:WaitForChild("HumanoidRootPart")
    humanoid = character:WaitForChild("Humanoid")
    if speedEnabled then
        toggleSpeed(true)
    end
end

player.CharacterAdded:Connect(updateCharacter)
if player.Character then
    updateCharacter(player.Character)
end

local function toggleSpeed(state)
    speedEnabled = state or not speedEnabled

    if speedEnabled then
        if not bv then
            bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(1e5, 0, 1e5) -- No Y-axis force (jumps work normally)
            bv.Velocity = Vector3.zero
            bv.Parent = root
        end
    else
        if bv then bv:Destroy(); bv = nil end
        root.AssemblyLinearVelocity = Vector3.zero
    end
end

game:GetService("RunService").RenderStepped:Connect(function()
    if speedEnabled and character and root then
        local moveDirection = humanoid.MoveDirection
        bv.Velocity = Vector3.new(moveDirection.X * ws, root.Velocity.Y, moveDirection.Z * speed)
    end
end)

local speedButton = _G.Main.createButton(utilityFrame, "Toggle Speed", function() toggleSpeed() end)
local function updateFlyAndSpeedButtons(flyButton, speedButton)
    local function toggleFly()
        if speedEnabled then
            toggleSpeed(false) -- Disable Speed before enabling Fly
        end
        toggleFly()
        flyButton.BackgroundColor3 = flying and Color3.fromRGB(0, 0, 255) or Color3.fromRGB(255, 255, 255)
        speedButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Reset Speed button color
    end

    local function toggleSpeed()
        if flying then
            toggleFly(false)
        end
        toggleSpeed()
        speedButton.BackgroundColor3 = speedEnabled and Color3.fromRGB(0, 0, 255) or Color3.fromRGB(255, 255, 255)
        flyButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Reset Fly button color
    end
    
end

updateFlyAndSpeedButtons(FlyButton, SpeedButton)


-- Remove GUI hook (Fly GUI stays regardless of GUI toggle)
-- If previously added, you can remove this hook safely

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local ESP_Boxes = {} 
local ESP_Names = {} 
local ESP_Tracers = {} 

local ESP_Enabled = false
local Names_Enabled = false
local Tracers_Enabled = false

local function createESP(player)
    if player == LocalPlayer then return end  

    local box = Drawing.new("Square")
    box.Thickness = 2
    box.Filled = false
    box.Visible = false

    local nameTag = Drawing.new("Text")
    nameTag.Size = 18
    nameTag.Center = true
    nameTag.Outline = true
    nameTag.Visible = false

    local tracer = Drawing.new("Line")
    tracer.Thickness = 2
    tracer.Visible = false

    ESP_Boxes[player] = box
    ESP_Names[player] = nameTag
    ESP_Tracers[player] = tracer
end

local function updateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        local box = ESP_Boxes[player]
        local nameTag = ESP_Names[player]
        local tracer = ESP_Tracers[player]

        if box and nameTag and tracer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
            local hrp = player.Character.HumanoidRootPart
            local humanoid = player.Character.Humanoid
            local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)

            if onScreen then
                local charHeight = humanoid.HipHeight + 3.5
                local topScreenPos = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, charHeight / 2, 0))
                local bottomScreenPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, charHeight / 2, 0))

                local height = math.abs(topScreenPos.Y - bottomScreenPos.Y) * 1.1
                local width = height * 0.6 

                local color = (player.Team == LocalPlayer.Team) and Color3.new(0, 0, 1) or Color3.new(1, 0, 0)

                if ESP_Enabled then
                    box.Size = Vector2.new(width, height)
                    box.Position = Vector2.new(screenPos.X - (width / 2), screenPos.Y - height * 0.75)
                    box.Color = color
                    box.Visible = true
                else
                    box.Visible = false
                end

                if Names_Enabled then
                    nameTag.Position = Vector2.new(screenPos.X, screenPos.Y - height / 2 - 15)
                    nameTag.Text = player.Name
                    nameTag.Color = color
                    nameTag.Visible = true
                else
                    nameTag.Visible = false
                end

                if Tracers_Enabled then
                    tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y) -- Start from bottom center
                    tracer.To = Vector2.new(screenPos.X, screenPos.Y) -- End at player's position
                    tracer.Color = color
                    tracer.Visible = true
                else
                    tracer.Visible = false
                end
            else
                box.Visible = false
                nameTag.Visible = false
                tracer.Visible = false
            end
        else
            if box then box.Visible = false end
            if nameTag then nameTag.Visible = false end
            if tracer then tracer.Visible = false end
        end
    end
end

local function removeESP(player)
    if ESP_Boxes[player] then
        ESP_Boxes[player]:Remove()
        ESP_Boxes[player] = nil
    end
    if ESP_Names[player] then
        ESP_Names[player]:Remove()
        ESP_Names[player] = nil
    end
    if ESP_Tracers[player] then
        ESP_Tracers[player]:Remove()
        ESP_Tracers[player] = nil
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    createESP(player)
end

Players.PlayerAdded:Connect(function(player)
    createESP(player)
    player.CharacterAdded:Connect(function()
        createESP(player)
    end)
end)

Players.PlayerRemoving:Connect(removeESP)

RunService.RenderStepped:Connect(updateESP)

_G.Main.createButton(Visuals, "Toggle ESP", function()
    ESP_Enabled = not ESP_Enabled
    print("ESP Enabled:", ESP_Enabled)
end)

_G.Main.createButton(Visuals, "Toggle Names", function()
    Names_Enabled = not Names_Enabled
    print("Name Tags Enabled:", Names_Enabled)
end)

_G.Main.createButton(Visuals, "Toggle Tracers", function()
    Tracers_Enabled = not Tracers_Enabled
    print("Tracers Enabled:", Tracers_Enabled)
end)

TextButton2.MouseButton1Click:Connect(function()
       sapien.Enabled = not sapien.Enabled
end)

