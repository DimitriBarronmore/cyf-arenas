--[[
	Created by Dimitri Barronmore
	https://github.com/DimitriBarronmore/cyf-arenas
--]]


local function smooth_value(value, value2, speed, div)
	if value < value2 then
		value = math.min(value + (speed*Time.dt/div), value2)
	elseif value > value2 then
		value = math.max(value - (speed*Time.dt/div), value2)
	end
	return value
end

local function TransXY(x,y,rotation)
	local x2 = x*math.cos(rotation) - y*math.sin(rotation)
	local y2 = y*math.cos(rotation) + x*math.sin(rotation)
	return x2, y2
end

local library = {}
local arena_list = {}

function library.update_all_arenas()
	for k in pairs(arena_list) do
		k._update()
	end
end

local function check_collision(arena, px, py)
	--local px, py = Player.absx, Player.absy
	local width, height = arena.currentwidth, arena.currentheight
	local ax, ay = arena.currentx, arena.currenty + 5 + height/2
	local rotation = math.rad(arena.rotation)
	local result

	local r, l, u, d = width/2-8, -width/2+8, height/2-8, -height/2+8

	local apx, apy = px - ax, py - ay
	apx, apy = TransXY(apx, apy, -rotation)

	local intersection_x = apx
	local intersection_y = apy
	if apx >= r then
		intersection_x = r
	elseif apx <= l then
		intersection_x = l
	end
	if apy >= u then
		intersection_y = u
	elseif apy <= d then
		intersection_y = d
	end

	if apx <= r and apx >= l and apy <= u and apy >= d then
		result = false
	else
		result = true
	end

	intersection_x, intersection_y = TransXY(intersection_x, intersection_y, rotation)

	return result, {x = intersection_x + ax, y = intersection_y + ay}
end

bullist = {}

function library.cleanup()
	for k in pairs(arena_list) do
		k.Remove()
		Arena.Show()
	end
end

function library.collide_all_arenas()
	local collisions = {}
	local found_arenas = {}
	local exitearly = false
	for k in pairs(arena_list) do
		res, points = check_collision(k, Player.absx, Player.absy)
		if res == false then -- if any arena contains the player
			--return false, k
			exitearly = true
			found_arenas[#found_arenas+1] = k
		else
			collisions[k] = points
		end
	end

	if exitearly then
		return false, found_arenas
	end

	local closest
	local distance = math.huge
	local is_skip
	for k,v in pairs(collisions) do
		local cdist = math.abs( math.sqrt((v.x - Player.absx)^2 + (v.y - Player.absy)^2) )
		if cdist < distance then
			distance = cdist
			closest = v
		end
	end
	return true, closest
end

local function update_arena(arena, forceupdate, moveplayer)
	arena.isMoving = (arena.currentx ~= arena.x or arena.currenty ~= arena.y)
	arena.isResizing = (arena.currentwidth ~= arena.width or arena.currentheight ~= arena.height)
	arena.isRotating = (arena.currentrotation ~= arena.rotation)
	arena.isModifying = (arena.isMoving or arena.isResizing or arena.isRotating)

	if (not arena.isModifying) and (not forceupdate) then
		return
	end
	local speed = arena.movementspeed

	--if arena.isResizing or forceupdate then
		arena.currentwidth = smooth_value(arena.currentwidth, arena.width, speed, 1)
		arena.currentheight = smooth_value(arena.currentheight, arena.height, speed, 1)
		arena.center.Scale(arena.currentwidth, arena.currentheight)
		arena.walls.Scale(arena.currentwidth + 10, arena.currentheight + 10)
		arena.base.Scale(arena.currentwidth + 10, arena.currentheight + 10)
	--end

	--if arena.isMoving or forceupdate then
		local x1, y1 = arena.currentx, arena.currenty
		arena.currentx = smooth_value(arena.currentx, arena.x, speed, 2)
		arena.currenty = smooth_value(arena.currenty, arena.y, speed, 2)
		arena.base.MoveToAbs(arena.currentx, arena.currenty)
		arena.walls.MoveToAbs(arena.center.absx, arena.center.absy )
		if moveplayer == true and check_collision(arena, Player.absx, Player.absy) == false then
			Player.Move(arena.currentx - x1, arena.currenty - y1, true)
		end
	--end

	--if arena.isRotating or forceupdate then
		arena.currentrotation = smooth_value(arena.currentrotation, arena.rotation, speed, 5)
		arena.walls.rotation = arena.currentrotation
		arena.center.rotation = arena.currentrotation
	--end
end



--remove arena??

local inactive_arena = {
	__index = function(t, k)
		if k == "isactive" then
			return false
		else
			error("attempted to perform operation on removed arena", 2)
		end
	end,
	__newindex = function()
		error("attempted to perform operation on removed arena", 2)
	end
}

CreateLayer("fake_arenas", "BelowArena", false)

function library.create_arena(self, x, y, w, h, r)
	r = r or 0
	local new_arena = {}
	local shell = {}
	arena_list[shell] = true
	shell.__whitelist = {}
	shell.__whitelist["movementspeed"] = true
	shell.__index = function(t, k)
			if k == "currenty" then
				return shell.currenty + 5
			elseif k == "innerColor" then
				return shell.center.color
			elseif k == "innerColor32" then
				return shell.center.color32
			elseif k == "outerColor" then
				return shell.walls.color
			elseif k == "outerColor32" then
				return shell.walls.color32
			else
				return shell[k]
			end
		end
	local function typecheck(val)
		if rawtype(val) ~= "table" then
			error("Arena color must be set to a table.", 3)
		end
	end
	shell.__newindex = function(t, k, v)
		if shell.__whitelist[k] then
			shell[k] = v
		elseif k == "innerColor" then
			typecheck(v)
			shell.center.color = v
		elseif k == "innerColor32" then
			typecheck(v)
			shell.center.color32 = v
		elseif k == "outerColor" then
			typecheck(v)
			shell.walls.color = v
		elseif k == "outerColor32" then
			typecheck(v)
			shell.walls.color32 = v
		else
			if shell[k] then
				error("the arena value " .. k .. " is read-only", 2)
			else
				error("could not find field " .. k .. " of arena", 2)
			end
		end
	end
	setmetatable(new_arena, shell)

	shell.x, shell.currentx = x, x
	shell.y, shell.currenty = y, y
	shell.width, shell.currentwidth = w, w
	shell.height, shell.currentheight = h, h
	shell.rotation, shell.currentrotation = r, r
	shell.isMoving = false
	shell.isResizing = false
	shell.isRotating = false
	shell.isModifying = false
	shell.isactive = true

	local outer = CreateSprite("px", "fake_arenas")
	local inner = CreateSprite("px", "fake_arenas")
	local dummy = CreateSprite("px", "fake_arenas")

	inner.SetParent(dummy)
	inner.color = {0,0,0}
	inner.SetPivot(0.5,0.5)
	inner.SetAnchor(0.5,0.5)
	inner.rotation = r

	--outer.SetParent(dummy)
	outer.SetPivot(0.5,0.5)
	outer.SetAnchor(0.5,0.5)
	outer.SendToBottom()
	outer.rotation = r

	dummy.SetPivot(0.5,0)
	dummy.SetAnchor(0.5,0)
	dummy.alpha = 0

	inner.Scale(shell.width, shell.height)
	outer.Scale(shell.width + 10, shell.height + 10)
	outer.moveTo(inner.absx, inner.absy)
	dummy.Scale(shell.width + 10, shell.height + 10)
	dummy.MoveTo(x, y)


	shell.walls = outer
	shell.center = inner
	shell.base = dummy

	function shell.Hide()
		inner.alpha = 0
		outer.alpha = 0
	end

	function shell.Show()
		inner.alpha = 1
		outer.alpha = 1
	end

	function shell.Remove()
		outer.remove()
		inner.remove()
		dummy.remove()
		local sh, shell = shell, nil
		arena_list[sh] = nil

		setmetatable(new_arena, inactive_arena)
	end


	--movement functions
	local forceupdate = true
	local moveplayer = true
	shell.movementspeed = 1000

	function shell.Move(x, y, mp, imm)
		if mp == false then moveplayer = false else moveplayer = true end
		forceupdate = imm or forceupdate
		shell.x = shell.x + x
		shell.y = shell.y + y
		if imm == true then
			if moveplayer == true and check_collision(shell, Player.absx, Player.absy) == false then
				Player.Move(shell.x - shell.currentx, shell.y - shell.currenty, true)
			end
				shell.currentx = shell.x
			shell.currenty = shell.y
		end
	end

	function shell.MoveTo(x, y, mp, imm)
		if mp == false then moveplayer = false else moveplayer = true end
		forceupdate = imm or forceupdate
		shell.x = x
		shell.y = y
		if imm == true then
			if moveplayer == true and check_collision(shell, Player.absx, Player.absy) == false then
				Player.Move(shell.x - shell.currentx, shell.y - shell.currenty, true)
			end
				shell.currentx = shell.x
			shell.currenty = shell.y
		end
	end

	function shell.Resize(width, height, imm)
		forceupdate = imm or forceupdate
		width = (width >= 16) and width or 16
		height = (height >= 16) and height or 16
		shell.width = width
		shell.height = height
		if imm then
			shell.currentwidth = width
			shell.currentheight = height
		end
	end

	function shell.Rotate(rotation, imm)
		forceupdate = imm or forceupdate
		shell.rotation = shell.rotation + rotation
		if imm then
			shell.currentrotation = shell.currentrotation + rotation
		end
	end

	function shell.RotateTo(rotation, imm)
		forceupdate = imm or forceupdate
		shell.rotation = rotation
		if imm then
			shell.currentrotation = rotation
		end
	end

	function shell.GetRelative(ix, iy)
	--local px, py = Player.absx, Player.absy
	local width, height = shell.currentwidth, shell.currentheight
	local ax, ay = shell.currentx, shell.currenty + 5 + height/2
	local rotation = math.rad(shell.currentrotation)

	local rix = ix*math.cos(rotation) - iy*math.sin(rotation)
	local riy = iy*math.cos(rotation) + ix*math.sin(rotation)

	local apx, apy = ax + rix, ay + riy

	return apx, apy
end

	function shell._update()
		update_arena(shell, forceupdate, moveplayer)
		forceupdate = false
	end

	function shell._check_collision(x, y)
		return check_collision(shell, x, y)
	end

	shell._update()

	return new_arena
end

return setmetatable(library, {__call = library.create_arena})