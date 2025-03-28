//the idea is that we will have a bunch of letters on the screen that "attack" player
//he ken destroy them by pressing letter on the keyboard
//and if he will put together a word that is current "combo" we give some sort of bonus
//or super attack. that will then cooldonw

// I shuld have a range, how far i can shoot that can be upgraded.


//mechanicks for building words?

package main

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

SCREEN_WIDTH :: 1024
SCREEN_HEIGHT :: 768

// Some Basic Colors
BASE :: rl.Color{30, 30, 46, 255}
TEXT :: rl.Color{205, 214, 244, 255}
RED :: rl.Color{243, 139, 168, 255}
GREEN :: rl.Color{166, 227, 161, 255}
BLUE :: rl.Color{137, 180, 250, 255}


enemy :: struct {
	id:             int,
	position:       rl.Vector2,
	size:           rl.Vector2,
	animation_size: rl.Vector2,
	color:          rl.Color,
	speed:          int,
	fontSize:       i32,
	textColor:      rl.Color,
	text:           cstring,
	rune:           rune,
	dest:           rl.Vector2,
	active:         bool,
}


new_enemy :: proc(pos: rl.Vector2, text: cstring, rune: rune) -> enemy {
	return enemy {
		position = pos,
		size = {16, 16},
		animation_size = {16, 16},
		color = RED,
		speed = 50,
		fontSize = 14,
		textColor = BASE,
		text = text,
		rune = rune,
		dest = rl.Vector2{SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2},
	}
}

update_enemy :: proc(e: ^enemy) {

	//if we reach destination we return
	if rl.Vector2Equals(e.position, e.dest) {
		return
	}

	//destination vector - postion vector will give us direction vector
	//if we normalize, then we can multiply it by speed and
	//it will give us new position
	direction := rl.Vector2Normalize(e.dest - e.position)
	new_position := e.position + direction * f32(e.speed) * rl.GetFrameTime()

	//if we get close enough we just assighn destonation as a position
	if d := rl.Vector2DistanceSqrt(e.position, e.dest); d < 0.1 {
		new_position = e.dest
	}


	e.position = new_position
}

draw_enemy :: proc(e: enemy) {
	rl.DrawCircleV(e.position, f32(e.size.x), e.color)

	x := i32(e.position.x) - e.fontSize / 2
	y := i32(e.position.y) - e.fontSize / 2
	rl.DrawText(e.text, x, y, e.fontSize, e.textColor)
}


update_enemies :: proc(enemies: ^[33]enemy) {
	for &enemy, i in enemies {
		if enemy.active {
			update_enemy(&enemy)
		}
	}
}

draw_enemies :: proc(enemies: [33]enemy) {
	for enemy in enemies {
		if !enemy.active do continue
		draw_enemy(enemy)
	}
}

//generates random index within the length  of enemies array
//and makes enemies[random_index] active, assining random position
//for now it is static loop that creates 5 enemies
respown_enemies :: proc(enemies: ^[33]enemy) {
	for i in 0 ..< 5 {
		min := i32(0)
		max := i32(len(enemies) - 1)
		rand_index := rl.GetRandomValue(min, max)

		enemies[rand_index].active = true

		x := f32(rl.GetRandomValue(0, SCREEN_WIDTH) - SCREEN_WIDTH / 2)
		y := f32(rl.GetRandomValue(0, SCREEN_HEIGHT) - SCREEN_HEIGHT / 2)
		enemies[rand_index].position = {x, y}
	}
}

//iterates over enemies loop and checks how many entris have
//active == true. returns the number
count_enemies_alive :: proc(enemies: ^[33]enemy) -> int {
	result := 0

	for e in enemies {
		if e.active {
			result += 1
		}
	}

	return result
}

main :: proc() {

	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "For Ales")
	defer rl.CloseWindow()
	defer free_all(context.temp_allocator)

	//creating enemies
	enemies := [33]enemy{}
	for r, i in 'a' ..= 'z' {
		x := f32(rl.GetRandomValue(0, SCREEN_WIDTH) - SCREEN_WIDTH / 2)
		y := f32(rl.GetRandomValue(0, SCREEN_HEIGHT) - SCREEN_HEIGHT / 2)
		enemies[i] = new_enemy({x, y}, fmt.ctprintf("%v", r), r)
	}


	for !rl.WindowShouldClose() { 	// Detect window close button or ESC key

		//process user input
		key_char := rl.GetCharPressed()
		for &enemy in enemies {

			if enemy.rune == key_char {
				enemy.active = false
				//respown_enemies(&enemies)

			}
		}

		//update game state
		enemies_count := count_enemies_alive(&enemies)

		//BUG: ENEMIES LAG ON HIGH NUMBERS
		if enemies_count < 29 {
			respown_enemies(&enemies)

		}

		update_enemies(&enemies)

		//redraw frame
		rl.BeginDrawing()
		rl.ClearBackground(BASE)

		draw_enemies(enemies)

		rl.EndDrawing()
	}
}
