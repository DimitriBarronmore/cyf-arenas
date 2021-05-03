--[[
	Created by Dimitri Barronmore
	https://github.com/DimitriBarronmore/cyf-arenas
--]]


local current_folder = (...):gsub('player_movement$', '')
local arenas = require(current_folder .. "arena_creation")

Player.SetControlOverride(true)
real_player = Player

--Player = WrapUserdata(Player)

Player = setmetatable({}, {__index = Player, __newindex = Player})

rawset(Player, "ismoving", false)

local is_frame_based = false
function SetFrameBasedMovement(bool)
	is_frame_based = bool
end

local override = false
rawset(Player, "SetControlOverride", function(bool) override = bool end)

rawset(Player, "Move", function(x, y, ignorewalls)
	ignorewalls = ignorewalls or false
	real_player.Move(x, y, true)
	if ignorewalls == false then
		res, pos = arenas.collide_all_arenas(Player.absx, Player.absy)
		if pos then real_player.MoveToAbs(pos.x, pos.y, true) end
	end
end)

rawset(Player, "MoveToAbs", function(x, y, ignorewalls)
	ignorewalls = ignorewalls or false
	real_player.MoveToAbs(x,y, true)
	if ignorewalls == false then
		res, pos = arenas.collide_all_arenas(Player.absx, Player.absy)
		if res then real_player.MoveToAbs(pos.x, pos.y, true) end
	end
end)

rawset(Player, "MoveTo", function(ix, iy, ignorewalls, arena)
	ignorewalls = ignorewalls or false
	arena = arena or Arena
	--local px, py = Player.absx, Player.absy
	local width, height = arena.currentwidth, arena.currentheight
	local ax, ay = arena.currentx, arena.currenty + 5 + height/2

	rotation = math.rad(arena.currentrotation)

	local rix = ix*math.cos(rotation) - iy*math.sin(rotation)
	local riy = iy*math.cos(rotation) + ix*math.sin(rotation)

	local apx, apy = ax + rix, ay + riy

	real_player.MoveToAbs(apx, apy, true)

	if ignorewalls == false then
		res, pos = arenas.collide_all_arenas(Player.absx, Player.absy)
		if res then real_player.MoveToAbs(pos.x, pos.y, true) end
	end
end
)

local last_px = 0
local last_py = 0
local function handle_movement(speed, ignorewalls)
	if override then return end
	local ignorewalls = ignorewalls or false
	local speed = speed or 2
	if Input.Cancel > 0 then speed = speed / 2 end

	-- Left and right movement.
	local movementX = 0
	local movementY = 0
	movementX = movementX - (Input.Left > 0 and 1 or 0)
	movementX = movementX + (Input.Right > 0 and 1 or 0)
	movementY = movementY + (Input.Up > 0 and 1 or 0)
	movementY = movementY - (Input.Down > 0 and 1 or 0)

	movementX = speed * movementX
	movementY = speed * movementY
	if is_frame_based then
		movementX = movementX * Time.mult
		movementY = movementY * Time.mult
	end

	--DEBUG("mx: " .. movementX .. " my: " .. movementY)

	real_player.Move(movementX, movementY, true)

	if ignorewalls == false then
		res, pos = arenas.collide_all_arenas(Player.absx, Player.absy)
		if res then real_player.MoveToAbs(pos.x, pos.y, true) end
	end

	Player.ismoving = (Player.absx ~= last_px or Player.absy ~= last_py)
	last_px, last_py = Player.absx, Player.absy
end

return handle_movement