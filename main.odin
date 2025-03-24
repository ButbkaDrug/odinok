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
	dest:           rl.Vector2,
}


new_enemy :: proc(pos: rl.Vector2, text: cstring) -> enemy {
	return enemy {
		position = pos,
		size = {16, 16},
		animation_size = {16, 16},
		color = RED,
		speed = 200,
		fontSize = 14,
		textColor = BASE,
		text = text,
		dest = rl.Vector2{SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2},
	}
}

update_enemy :: proc(e: enemy) -> enemy {

	//if we reach destination we return
	if rl.Vector2Equals(e.position, e.dest) {
		return e
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

	new_enemy := e

	new_enemy.position = new_position

	return new_enemy


}

draw_enemy :: proc(e: enemy) {
	rl.DrawCircleV(e.position, f32(e.size.x), e.color)

	x := i32(e.position.x) - e.fontSize / 2
	y := i32(e.position.y) - e.fontSize / 2
	rl.DrawText(e.text, x, y, e.fontSize, e.textColor)
}


update_enemies :: proc(enemies: [dynamic]enemy) -> [dynamic]enemy {
	for enemy, i in enemies {
		e := update_enemy(enemy)
		enemies[i] = e
	}

	return enemies
}

draw_enemies :: proc(enemies: [dynamic]enemy) {
	for enemy in enemies {
		draw_enemy(enemy)
	}
}

game :: struct {}

bullet :: struct {
	position: rl.Vector2,
	size:     rl.Vector2,
	color:    rl.Color,
	speed:    rl.Color,
	valid:    bool,
}


new_bullet :: proc(pos: rl.Vector2, target: rl.Vector2)

main :: proc() {

	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "For Ales")
	defer rl.CloseWindow()

	enemies := [dynamic]enemy{}
	append(&enemies, new_enemy({10, 10}, "F"))
	append(&enemies, new_enemy({SCREEN_WIDTH, SCREEN_HEIGHT}, "G"))

	for !rl.WindowShouldClose() { 	// Detect window close button or ESC key

		enemies = update_enemies(enemies)

		rl.BeginDrawing()
		rl.ClearBackground(BASE)

		draw_enemies(enemies)

		rl.EndDrawing()
	}
}
