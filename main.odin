//the idea is that we will have a bunch of letters on the screen that "attack" player
//he ken destroy them by pressing letter on the keyboard
//and if he will put together a word that is current "combo" we give some sort of bonus
//or super attack. that will then cooldonw

// I shuld have a range, how far i can shoot that can be upgraded.

//mechanicks for building words?

package main

import "core:c"
import "core:fmt"
import "core:math"
import "core:mem"
import "core:strings"
import rl "vendor:raylib"

CELL_WIDTH :: 32
SCREEN_WIDTH :: CELL_WIDTH * 40
SCREEN_HEIGHT :: CELL_WIDTH * 24

SPAWN_INTERVAL :: 3

// Some Basic Colors
BASE :: rl.Color{30, 30, 46, 255}
TEXT :: rl.Color{205, 214, 244, 255}
RED :: rl.Color{243, 139, 168, 255}
GREEN :: rl.Color{166, 227, 161, 255}
BLUE :: rl.Color{137, 180, 250, 255}
ROSEWATER :: rl.Color{244, 219, 214, 255}
FLAMINGO :: rl.Color{240, 198, 198, 255}

enemy_run_down: animation

Player :: struct {
	rect:   rl.Rectangle,
	points: int,
	hp:     int,
	color:  rl.Color,
	name:   cstring,
}

new_player :: proc(name: cstring, pos: rl.Vector2, color := GREEN) -> Player {
	return Player{hp = 100, rect = {pos.x - 16, pos.y - 16, 48, 48}, color = color, name = name}
}

draw_player :: proc() {

	p := game.player

	//rl.DrawCircleV(
	//	{p.rect.x + p.rect.width / 2, p.rect.y + p.rect.height / 2},
	//	p.rect.width / 2,
	//	p.color,
	//)


	font_size := c.int(14)

	//NOTE: I want text in the middle of my cirle(player)
	//I lower it to the middle of the shape, by offsetting
	//vertical position by 1/2 of height, but it is too low
	//Because, "y" is essentially top left corner of the text
	//so we want to bring the text up by the half of it's height.
	vertical_offset := p.rect.height / 2 - f32(font_size / 2)

	//NOTE: Same as vertical offset. We need to move the text to the right,
	// and make sure there is even space on each side. For that we need to
	// figure out how much free space is there after we render the text
	// and them move our original position by half of that
	text_width := rl.MeasureText(p.name, font_size)
	horizontal_offset := p.rect.width - f32(text_width)

	x := c.int(p.rect.x) + c.int(horizontal_offset / 2)
	y := c.int(p.rect.y) + c.int(vertical_offset)
	rl.DrawText(p.name, x, y, font_size, BASE)
}

EnemyState :: enum {
	RUNNING,
	DYING,
}


Enemy :: struct {
	id:             int,
	position:       rl.Vector2,
	size:           rl.Vector2,
	animation_size: rl.Vector2,
	color:          rl.Color,
	speed:          int,
	fontSize:       i32,
	textColor:      rl.Color,
	key:            rl.KeyboardKey,
	dest:           rl.Vector2,
	state:          EnemyState,
	active:         bool,
	animating:      bool,
	animations:     map[EnemyState]animation,
}


new_enemy :: proc(pos: rl.Vector2, key: rl.KeyboardKey) -> Enemy {
	e := Enemy {
		state          = .RUNNING,
		active         = true,
		animating      = true,
		position       = pos,
		size           = {16, 16},
		animation_size = {16, 16},
		color          = RED,
		speed          = 50,
		fontSize       = 14,
		textColor      = BASE,
		key            = key,
		dest           = rl.Vector2{SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2},
		//FIX: Memory leack
		animations     = make(map[EnemyState]animation),
	}

	e.animations[.RUNNING] = {
		position = {0, 0},
		source   = {0, 0, 48, 48},
		frames   = 6,
		interval = 0.1,
		active   = true,
		loop     = true,
		texture  = &game.textures[.ENEMY_RUN_SD],
	}
	e.animations[.DYING] = {
		position = {0, 0},
		source   = {0, 0, 48, 48},
		frames   = 4,
		interval = 0.1,
		active   = true,
		texture  = &game.textures[.ENEMY_DIE_SD],
	}

	return e
}

update_enemy :: proc(index: int) {

	e := &game.enemies[index]

	switch e.state {
	case .RUNNING:
		//if we reach destination we return
		if rl.Vector2Equals(e.position, e.dest) {
			return
		}

		//destination vector - postion vector will give us direction vector
		//if we normalize, then we can multiply it by speed and
		//it will give us new position
		direction := rl.Vector2Normalize(e.dest - e.position)
		new_position := e.position + direction * f32(e.speed) * rl.GetFrameTime()

		////if we get close enough we just assighn destonation as a position

		e.position = new_position
		player_center := rl.Vector2 {
			game.player.rect.x + game.player.rect.width / 2,
			game.player.rect.y + game.player.rect.height / 2,
		}

		if rl.CheckCollisionCircles(
			e.position,
			e.size.x,
			player_center,
			game.player.rect.width / 2,
		) {
			e.active = false
			game.player.hp -= 10
		}
	case .DYING:
		if e.active == false do e.animating = false
	}


	//FIX: Not the best way to do it. because I pretty much need to update position
	//only rest is very static and should be in the separate function
	//also I want to store all animations in the library and then grab the one I
	//need dependig on the state of the enemy
	//update animation
	animation := e.animations[e.state]
	animation.position = e.position
	animation.interval -= rl.GetFrameTime()
	if animation.interval <= 0 {
		animation.interval = 0.1
		animation.cur_frame += 1
		if animation.cur_frame == animation.frames && !animation.loop {
			e.active = false
		}
	}
	animation.source.x = f32(animation.cur_frame) * animation.source.width

	e.animations[e.state] = animation
}

draw_enemy :: proc(e: Enemy) {
	//rl.DrawCircleV(e.position, f32(e.size.x), e.color)

	animation := e.animations[e.state]
	x := i32(e.position.x + animation.source.width / 2)
	y := i32(e.position.y) - e.fontSize / 2
	rl.DrawText(fmt.ctprintf("%v", e.key), x, y, e.fontSize, TEXT)

	rl.DrawTextureRec(animation.texture^, animation.source, animation.position, rl.WHITE)
}


update_enemies :: proc() {
	for &enemy, i in game.enemies {
		if !enemy.active && !enemy.animating {
			delete(game.enemies[i].animations)
			unordered_remove(&game.enemies, i)
			continue
		}
		update_enemy(i)
	}
}

draw_enemies :: proc() {
	for enemy in game.enemies {
		if !enemy.active do continue
		draw_enemy(enemy)
	}
}

//generates random index within the length  of enemies array
//and makes enemies[random_index] active, assining random position
//for now it is static loop that creates 5 enemies
spawn_enemies :: proc() {
	min := i32(0)
	max := i32(len(game.combos) - 1)
	combo_index := rl.GetRandomValue(min, max)

	combo := transmute([]u8)game.combos[combo_index]


	for index in combo {
		pos := get_position_outside_the_screen(SCREEN_WIDTH, SCREEN_HEIGHT)
		enemy := new_enemy(pos, rl.KeyboardKey(index))
		enemy.state = .RUNNING

		append(&game.enemies, enemy)
	}
}

//iterates over enemies loop and checks how many entris have
//active == true. returns the number
count_enemies_alive :: proc() -> int {
	result := 0

	for e in game.enemies {
		if e.active {
			result += 1
		}
	}

	return result
}

get_position_outside_the_screen :: proc(w, h: c.int) -> rl.Vector2 {
	x := rl.GetRandomValue(0, w)
	y := -5

	return rl.Vector2{f32(x), f32(y)}
}

draw_ui :: proc() {
	p := game.player

	offset_x, offset_y: c.int = 10, 10
	w, h := rl.GetScreenWidth(), rl.GetScreenHeight()

	x := 0 + offset_x
	y := 0 + offset_y

	rl.DrawText(fmt.ctprintf("HP: %d", p.hp), x, y, 14, TEXT)
	y += 14
	rl.DrawText(fmt.ctprintf("Score: %d", p.points), x, y, 14, TEXT)
}

Tile :: struct {
	texture: ^rl.Texture2D,
	source:  rl.Rectangle,
	dest:    rl.Rectangle,
}

draw_tiles :: proc() {
	for t in game.world {
		rl.DrawTexturePro(t.texture^, t.source, t.dest, {0, 0}, 0, rl.WHITE)
	}
}

TextureName :: enum {
	ENEMY_RUN_SD,
	ENEMY_DIE_SD,
	EFFECTS_1_1,
	LOCATION_TILESET,
}

Game :: struct {
	player:     Player,
	combos:     []string,
	animations: [dynamic]animation,
	enemies:    [dynamic]Enemy,
	spawn_in:   f32,
	paused:     bool,
	over:       bool,
	textures:   map[TextureName]rl.Texture2D,
	world:      [dynamic]Tile,
}

//global game variable for the ease of use
game := Game {
	combos = {"LOVE", "POWER", "ALES", "SUPER", "BOSS", "HOME", "VOLUME", "ODIN", "DADDY"},
}

update_game :: proc() {

	enemies_count := count_enemies_alive()

	if enemies_count < 1 {
		spawn_enemies()
		game.spawn_in = SPAWN_INTERVAL
	}

	game.spawn_in -= rl.GetFrameTime()

	if game.spawn_in <= 0 {
		game.spawn_in = SPAWN_INTERVAL
		spawn_enemies()
	}

	update_enemies()
	update_animations()
}

animation :: struct {
	position:  rl.Vector2,
	source:    rl.Rectangle,
	dest:      rl.Rectangle,
	rotation:  f32,
	origin:    rl.Vector2,
	//in case our frames have a lot of white space
	frames:    int,
	cur_frame: int,
	interval:  f32,
	active:    bool,
	//true if animation intended to be repeated. Like running or flying etc.
	//false if animation intended to be payed once. Like dying
	loop:      bool,
	texture:   ^rl.Texture2D,
}

update_animations :: proc() {
	for &e in game.animations {
		if !e.active do continue
		e.interval -= rl.GetFrameTime()
		if e.interval <= 0 {
			e.interval = 0.1
			e.cur_frame += 1
			if e.cur_frame == e.frames && !e.loop {
				e.active = false
			}
		}
		e.source.x = f32(e.cur_frame) * e.source.width
	}

}


draw_animations :: proc() {
	for e in game.animations {
		if !e.active do continue

		rl.DrawTexturePro(e.texture^, e.source, e.dest, e.origin, e.rotation, rl.WHITE)
	}
}

main :: proc() {
	//######################################//
	//######## For debuggin perpeses ######//
	//######################################//
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)

	defer {
		if len(track.allocation_map) > 0 {
			fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
			for _, entry in track.allocation_map {
				fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
			}
		}
		mem.tracking_allocator_destroy(&track)
	}

	rl.SetTargetFPS(60)

	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "For Ales")
	defer rl.CloseWindow()
	defer free_all(context.temp_allocator)

	//init palyer character
	game.player = new_player("ales", {CELL_WIDTH * 20, CELL_WIDTH * 12})
	game.textures = make(map[TextureName]rl.Texture2D)
	defer delete(game.textures)

	game.textures[.ENEMY_RUN_SD] = rl.LoadTexture("./enemies/1/RunSD.png")
	game.textures[.ENEMY_DIE_SD] = rl.LoadTexture("./enemies/1/DeathSD.png")
	game.textures[.EFFECTS_1_1] = rl.LoadTexture("./main-character/effects/1_1.png")
	//one tile 32x32
	game.textures[.LOCATION_TILESET] = rl.LoadTexture("./location/tiles/Tileset.png")

	walking := rl.LoadTexture("./location/animated-objects/Altar_Idle.png")
	walk_animation := animation {
		source   = {0, 0, 48, 48},
		dest     = {0, 0, 48, 48},
		frames   = 4,
		interval = 0.1,
		active   = true,
		loop     = true,
		texture  = &walking,
	}
	effects_1_1 := animation {
		source   = {0, 0, 96, 96},
		dest     = {0, 0, 96, 96},
		origin   = {0, 48},
		frames   = 6,
		interval = 0.1,
		active   = true,
		loop     = false,
		texture  = &game.textures[.EFFECTS_1_1],
	}

	walk_animation.dest.x = game.player.rect.x
	walk_animation.dest.y = game.player.rect.y

	effects_1_1.dest.x = game.player.rect.x + game.player.rect.width / 2
	effects_1_1.dest.y = game.player.rect.y + game.player.rect.height / 2

	append(&game.animations, walk_animation)

	tile := Tile {
		texture = &game.textures[.LOCATION_TILESET],
		source  = {0, 0, 32, 32},
	}


	for !rl.WindowShouldClose() { 	// Detect window close button or ESC key

		//temp
		mousePos := rl.GetMousePosition()
		tile.dest = {
			math.round_f32(mousePos.x / 32) * 32,
			math.round_f32(mousePos.y / 32) * 32,
			32,
			32,
		}
		if rl.IsMouseButtonPressed(.LEFT) {
			append(&game.world, tile)
		}

		//process user input
		key := rl.GetKeyPressed()
		#partial switch key {
		case .PAUSE:
			game.paused = !game.paused
		case .DOWN:
			tile.source.y += 32
		case .UP:
			tile.source.y -= 32
		case .RIGHT:
			tile.source.x += 32
		case .LEFT:
			tile.source.x -= 32
		case .KEY_NULL:
		//NOTHING
		case:
			if game.paused do break
			if game.over do break

			key_legit := false
			for &enemy in game.enemies {
				if enemy.key == key && enemy.active && enemy.state != .DYING {
					//add fire animation
					fire_animation := effects_1_1
					deltaX := enemy.position.x - game.player.rect.x
					deltaY := enemy.position.y - game.player.rect.y
					angleRad := math.atan2_f32(deltaY, deltaX)
					fire_animation.rotation = angleRad * rl.RAD2DEG
					append(&game.animations, fire_animation)
					//end

					enemy.state = .DYING
					game.player.points += 1
					key_legit = true
					break
				}
			}
			if !key_legit {
				game.player.hp -= 5
			}
		}

		//--------------***-------------------//
		//-------update game state------------//
		//--------------***-------------------//


		if !game.paused && !game.over do update_game()


		//redraw frame
		rl.BeginDrawing()
		rl.ClearBackground(BASE)
		draw_tiles()

		rl.DrawTexturePro(tile.texture^, tile.source, tile.dest, {0, 0}, 0, rl.WHITE)

		draw_enemies()
		draw_animations()
		draw_player()

		draw_ui()
		//temp
		rl.DrawFPS(SCREEN_WIDTH - 100, 6)

		rl.EndDrawing()
		free_all(context.temp_allocator)
	}

	for &e in game.enemies {
		delete(e.animations)
	}

	delete(game.animations)
	delete(game.enemies)
}
