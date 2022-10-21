--[[
	Created by Dimitri Barronmore
	https://github.com/DimitriBarronmore/cyf-arenas
--]]

local current_folder = (...):gsub('init$', '') 

Arena.Hide()

local arenas = require(current_folder.."arena_creation")
local movement = require(current_folder.."player_movement")

local real_arena = Arena
arenas.real_arena = Arena

Arena = arenas(real_arena.x, real_arena.y, real_arena.width, real_arena.height)
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
return arenas
-- return arenas, movement
