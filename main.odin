//the idea is that we will have a bunch of letters on the screen that "attack" player
//he ken destroy them by pressing letter on the keyboard
//and if he will put together a word that is current "combo" we give some sort of bonus
//or super attack. that will then cooldonw

// I shuld have a range, how far i can shoot that can be upgraded.

//mechanicks for building words?

package main

import "core:c"
import "core:fmt"
import "core:mem"
import "core:strings"
import rl "vendor:raylib"

SCREEN_WIDTH :: 1024
SCREEN_HEIGHT :: 768

SPAWN_INTERVAL :: 3

// Some Basic Colors
BASE :: rl.Color{30, 30, 46, 255}
TEXT :: rl.Color{205, 214, 244, 255}
RED :: rl.Color{243, 139, 168, 255}
GREEN :: rl.Color{166, 227, 161, 255}
BLUE :: rl.Color{137, 180, 250, 255}

Player :: struct {
	rect:   rl.Rectangle,
	points: int,
	hp:     int,
	color:  rl.Color,
	name:   cstring,
}

new_player :: proc(name: cstring, pos: rl.Vector2, color := GREEN) -> Player {
	return Player{hp = 100, rect = {pos.x - 16, pos.y - 16, 32, 32}, color = color, name = name}
}

draw_player :: proc() {

	p := game.player

	rl.DrawCircleV(
		{p.rect.x + p.rect.width / 2, p.rect.y + p.rect.height / 2},
		p.rect.width / 2,
		p.color,
	)


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
	active:         bool,
}


new_enemy :: proc(pos: rl.Vector2, key: rl.KeyboardKey) -> Enemy {
	return Enemy {
		active = true,
		position = pos,
		size = {16, 16},
		animation_size = {16, 16},
		color = RED,
		speed = 50,
		fontSize = 14,
		textColor = BASE,
		key = key,
		dest = rl.Vector2{SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2},
	}
}

update_enemy :: proc(index: int) {

	e := &game.enemies[index]

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

	if rl.CheckCollisionCircles(e.position, e.size.x, player_center, game.player.rect.width / 2) {
		e.active = false
		game.player.hp -= 10
	}
}

draw_enemy :: proc(e: Enemy) {
	rl.DrawCircleV(e.position, f32(e.size.x), e.color)

	x := i32(e.position.x) - e.fontSize / 2
	y := i32(e.position.y) - e.fontSize / 2
	rl.DrawText(fmt.ctprintf("%v", e.key), x, y, e.fontSize, e.textColor)
}


update_enemies :: proc() {
	for &enemy, i in game.enemies {
		if enemy.active {
			update_enemy(i)
		}
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
Game :: struct {
	player:   Player,
	combos:   []string,
	enemies:  [dynamic]Enemy,
	spawn_in: f32,
}

game := Game {
	combos = {"LOVE", "POWER", "ALES", "SUPER", "BOSS", "HOME", "VOLUME", "ODIN", "DADDY"},
}


main :: proc() {
	//######################################//
	//######## For debuggin perpeses ######//
	//######################################//
	{
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
	}

	rl.SetTargetFPS(60)

	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "For Ales")
	defer rl.CloseWindow()
	defer free_all(context.temp_allocator)

	//init palyer character
	game.player = new_player("ales", {SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2})


	for !rl.WindowShouldClose() { 	// Detect window close button or ESC key

		//process user input
		key := rl.GetKeyPressed()
		for &enemy in game.enemies {
			if enemy.key == key && enemy.active {
				enemy.active = false
				game.player.points += 1
				break
			}
		}

		//--------------***-------------------//
		//-------update game state------------//
		//--------------***-------------------//
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


		//redraw frame
		rl.BeginDrawing()
		rl.ClearBackground(BASE)

		draw_enemies()
		draw_player()
		draw_ui()

		rl.EndDrawing()
		free_all(context.temp_allocator)
	}
}
