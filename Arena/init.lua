--[[
	Created by Dimitri Barronmore
	https://github.com/DimitriBarronmore/cyf-arenas
--]]

local current_folder = (...):gsub('init$', '') 

Arena.Hide()

local arenas = require(current_folder.."arena_creation")
local movement = require(current_folder.."player_movement")

Arena = arenas(arenas.real_arena.x, arenas.real_arena.y, arenas.real_arena.width, arenas.real_arena.height)
Arena.innerColor = real_arena.innerColor
Arena.outerColor = real_arena.outerColor

local arinn = getmetatable(Arena)
arinn.currentwidth = real_arena.currentwidth
arinn.currentheight = real_arena.currentheight

local previous_bind
local previous_bind_update
arenas.bind_arena = function(arena)
	if previous_bind then
		previous_bind._update = previous_bind_update
		previous_bind, previous_bind_update = false, false
	end
	if arena == false then
		return
	end
	local inside = getmetatable(arena)
	local ud = inside._update
	inside._update = function()
		ud()
		real_arena.MoveTo(inside.currentx, inside.currenty, false, true)
		real_arena.ResizeImmediate(inside.currentwidth, inside.currentheight)
	end

	previous_bind, previous_bind_update = inside, ud
end

arenas.bind_arena(Arena)

arenas.handle_movement = movement
arenas.update = function()
	arenas.handle_movement()
	arenas.update_all_arenas()
end

local function access_error(str)
	return function()
		error("cannot use function '" .. str .. "' after fake arena cleanup", 2)
	end
end

arenas.cleanup = function()
	for k in pairs(arenas.arena_list) do
		k.Remove()
	end
	Player._unwrap_player()
	arenas.handle_movement = access_error("arenas.handle_movement")
	arenas.bind_arena = access_error("arenas.bind_arena")
	arenas.update = access_error("arenas.update")
	Arena = arenas.real_arena
	if not (previous_bind and previous_bind.center.alpha == 0) then
		Arena.Show()
	end
end

return arenas
-- return arenas, movement
