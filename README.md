<img src="https://user-images.githubusercontent.com/34289184/116654748-0cf3ab80-a947-11eb-80ac-0307ff25eaf5.gif" width=400>

# Multiple Arenas

This library adds arena rotation to CYF and allows the creation of multiple arenas with merged collision. 

**Setup Instructions:**

**0).** Copy the Arena folder to your Lua/Libraries folder, or wherever else you want it. It should work the same regardless of location if you prefer to structure things a little differently.

**1).** At the top of each wave file you intend to use the library in, run:

```lua
arenas = require "Libraries/Arena/init"
```

**2).** Include the following line at the top of the wave's Update function:

```lua
arenas.update()
```

**3).** Place the following line in the wave's EndingWave function:

```lua
arenas.cleanup()
```


-----------------------

**General Usage Instructions:**
You can create new arenas in the same way as sprites and projectiles using the following function:

```lua
arena = arenas(x, y, width, height, rotation)
```

Multiple arenas which overlap will automatically merge into a single shape. There is no option to disable this.

Arenas behave mostly like the original, with a few notable exceptions:

**1.)** Arena.MoveAndResize and Arena.MoveToAndResize no longer exist. 
This is because you can simply use Arena.Move/Arena.MoveTo and Arena.Resize one after another, and with the addition of rotation following this convention seems impractical.

**2.)** Arena.ResizeImmediate no longer exists. Instead, Arena.Resize takes an optional third true / false argument which tells it whether to resize immediately.

-----------------------

## **Features:**

**`arenas.bind_arena(arena)`**
Causes the real arena to copy the location/scale of the given arena, for purposes of bound monster sprites and the resize back to the UI box at the end of a wave. When the library is initialized this is set to `Arena`.
If 'false' is instead given as an argument, the real arena will no longer move unless directed. If needed it can be accessed via `arenas.real_arena`

**`Arena.Rotate/Arena.RotateTo(angle, immediate = false)`**
`Arena.Rotate` adds or subtracts the given angle from the arena's current rotation, whereas `Arena.RotateTo` sets the arena's rotation directly to the input.

**`x, y = Arena.GetRelative(x, y)`**
`Arena.GetRelative` takes coordinates relative to the arena's center and returns the corresponding absolute coordinates, for use with `Sprite.MoveTo` and `Bullet.MoveToAbs`

**Sprite Components**
The sprite components of an arena can be accessed through `Arena.walls`, `Arena.center`, and `Arena.base` (an invisible sprite used internally). This allows you to do things such as parent sprites to the arena, add shaders and masks, or change the arena's color. Caution and creativity are equally advised.

( **WARNING:** Note that all arena sprites are stored on the layer `fake_arenas` between `BelowArena` and `BelowPlayer`. All `Arena.walls` sprites are placed below everything else, and all `Arena.center` sprites are parented to `Arena.base`. )

**`Arena.movementspeed = 1000`**
This value controls the speed at which an arena moves/resizes/rotates. This may lead to unreliable behavior at high speeds.

**`Arena.Remove()`**
Discards all sprite objects and internal functions for cleanup. Note that any operations on a previously removed arena will result in an error. You can see whether an arena has been removed or not using `Arena.isactive`

---

## The Player:

The Player object should work as normal, including `SetFrameBasedMovement`, `Player.SetControlOverride`, `Player.ismoving`, and all three variations of `Player.Move`.

Because there will be multiple arenas active at once, `Player.MoveTo` now takes a fourth argument: 

```lua
Player.MoveTo(x, y, ignorewalls, arena)
```

Passing in an arena object will cause the player to move to the provided coordinates, relative to the arena, rotation included. This defaults to the current value of `Arena`.

**`handle_movement(speed = 2, ignorewalls = false)`**
This function updates the red soul movement, and as such should only be run once every frame.
Sticking to the default values is recommended.

-----------------------

## Advanced Notice: Extending this Library

Because the default player movement can be disabled using `Player.SetControlOverride(false)` as normal, it's vey possible to create your own movement code and impment alternate soul modes using this library. In fact, movement code which doesn't ignore the arena walls may perform without changes. However, any code which references the Arena's x, y, height, or width will behave erratically with multiple arenas.

The following function can be used to automatically handle collision with multiple arenas:

```lua
status, result = arenas.collide_all_arenas()
```

If the player is inside of any arena, `status` is returned as false and `result` as an array of all arenas the player is currently inside.

If the player is outside of all active arenas and/or colliding with the arena walls, `result` is returned as `true` and `point` as a table `{x = num, y = num}` containing the absolute coordinates of where the player should be placed back within bounds.

Finally, while arena objects are created to be mostly read-only for safety and parity reasons, it is still possible to get to the juicy read/write center using `getmetatable(Arena)`. Prior knowledge of the internal arena code is recommended if you intend to alter existing behavior.
