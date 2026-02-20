#+feature dynamic-literals
package main

import "core:fmt"
import "core:log"
import rl "vendor:raylib"

v2 :: rl.Vector2
TILE_SIZE :: f32(8.0)
PLAYER_SPEED :: 250
STARS_STRING := "*****"

Tile_Ids :: enum u8 {
	Player = 0,
	Wall,
	Point,
	Star,
	Coin,
	Finish,
	Hidden,
}

Player :: struct {
	pos: v2,
	rot: f32,
	vel: v2,
}

World_Tile :: struct {
	id: Tile_Ids,
	rect: rl.Rectangle,
	world_rect: rl.Rectangle,
}

Game :: struct {
	atlas: rl.Texture,
	map_image: rl.Image,
	camera: rl.Camera2D,
	world: [64][64]World_Tile,

	points: u8,
	coins: u8,
	stars: u8,

	player: Player,

	is_finished: bool,
}

set_player :: proc( x, y: i32 ) {
	if game.player != {} {
		return
	}

	game.player = Player{ 
		{f32(x) * TILE_SIZE, f32(y) * TILE_SIZE},
		0,
		v2(0.0),
	} 
}

get_player_rect :: proc( player: ^Player ) -> rl.Rectangle {
	return rl.Rectangle{
		player.pos.x,
		player.pos.y,
		TILE_SIZE,
		TILE_SIZE
	}
}

player_draw  :: proc( player: ^Player ) {
	if game.player == {} {
		return
	}

	rl.DrawTextureRec( 
		game.atlas, 
		rl.Rectangle{ 0, 0, TILE_SIZE, TILE_SIZE }, 
		player.pos,
		rl.WHITE 
	)
}

map_load :: proc( game: ^Game, path: cstring ) {
	game.map_image = rl.LoadImage( path )
	log.assert( game.map_image != {}, "Map not found!" )

	for y in 0..<game.map_image.height { 	// for( int y = 0; y < image.height; ++y )
		for x in 0..<game.map_image.width {  // for( int x = 0; x < image.height; ++x )
			col := rl.GetImageColor( game.map_image, x, y )

			offset: f32 = -1
			if col == rl.BLACK {
				offset = f32(Tile_Ids.Wall)
			} else if col == {255, 255, 0, 255} {
				offset = f32(Tile_Ids.Point)
			} else if col == {0,0,255,255} {
				offset = f32(Tile_Ids.Star)
			} else if col == {255,0,255,255} {
				offset = f32(Tile_Ids.Coin)
			} else if col == {255,255,255,255} {
				offset = f32(Tile_Ids.Finish)
			} else if col == {0,255,0,255} {
				set_player( x, y )
			}

			if offset != -1 {
				game.world[y][x] = World_Tile{
					Tile_Ids(offset),
					rl.Rectangle{
						offset * TILE_SIZE,
						0,
						TILE_SIZE,
						TILE_SIZE
					},
					rl.Rectangle{
						f32(x) * TILE_SIZE,
						f32(y) * TILE_SIZE,
						TILE_SIZE,
						TILE_SIZE
					}
				}
			}
		}
	}
}

map_draw :: proc( game: ^Game ) {
	for row in game.world {
		for tile in row {
			if tile.id == .Hidden {
				continue
			}

			rl.DrawTextureRec(
				game.atlas,
				tile.rect,
				v2{tile.world_rect.x, tile.world_rect.y},
				rl.WHITE
			)
		}
	}
}

game: ^Game
main :: proc() {
	game = new(Game)

	// setup game window
	rl.InitWindow( 800, 800, "Tomb of the Mask in Odin!" )
	rl.SetTargetFPS( 60 )

	// load sprite atlas
	game.atlas = rl.LoadTexture( "game_atlas.png" )

	// load map
	map_load( game, "totm-map01.png" )

	game.camera = rl.Camera2D {
		v2{ f32(rl.GetScreenWidth()) / 2, f32(rl.GetScreenHeight()) / 2 },
		v2(0.0),
		0,
		// 1.0,
		TILE_SIZE,
	}

	for( !rl.WindowShouldClose() ) {
		using game
		// :update
		dt := rl.GetFrameTime()

		if player != {} && !game.is_finished {
			if player.vel == v2(0.0) {
				if ( rl.IsKeyPressed( .RIGHT ) ) {
					player.vel = v2{1, 0}
				}
				if ( rl.IsKeyPressed( .LEFT ) ) {
					player.vel = v2{-1, 0}
				}
				if ( rl.IsKeyPressed( .UP ) ) {
					player.vel = v2{0, -1}
				}
				if ( rl.IsKeyPressed( .DOWN ) ) {
					player.vel = v2{0, 1}
				}
			}
			player.pos += player.vel * PLAYER_SPEED * dt

			// :Collision logic
			for &row in game.world {
				for &tile in row {
					if rl.CheckCollisionRecs( get_player_rect( &player ), tile.world_rect ) {
						#partial switch tile.id {
						case .Wall: {
							if player.vel.x > 0 {
								player.pos.x = tile.world_rect.x - TILE_SIZE
							} else if player.vel.x < 0 {
								player.pos.x = tile.world_rect.x + TILE_SIZE
							} else if player.vel.y > 0 {
								player.pos.y = tile.world_rect.y - TILE_SIZE
							} else if player.vel.y < 0 {
								player.pos.y = tile.world_rect.y + TILE_SIZE
							}

							player.vel = v2(0.0)
						}
						case .Star: {
							game.stars += 1
							tile.id = .Hidden
						}
						case .Coin: {
							game.coins += 1
							tile.id = .Hidden
						}
						case .Point: {
							game.points += 1
							tile.id = .Hidden
						}
						case .Finish: {
							game.is_finished = true
						}
						}
					}
				}
			}

			camera.target = player.pos + TILE_SIZE / 2
		}
		// :draw
		rl.BeginDrawing()
		rl.ClearBackground( rl.BLACK )
		rl.BeginMode2D( game.camera )
		{
			map_draw( game )
			player_draw( &game.player )
		}
		rl.EndMode2D()

		coin_text := fmt.ctprint( game.points )
		rl.DrawText( coin_text, (rl.GetScreenWidth() - rl.MeasureText( coin_text, 32 )) / 2, rl.GetScreenHeight() - 48, 32, rl.WHITE )

		star_text := fmt.ctprint( STARS_STRING[:game.stars] )
		rl.DrawText( star_text, (rl.GetScreenWidth() - rl.MeasureText( star_text, 32 )) / 2, rl.GetScreenHeight() - 96, 32, rl.WHITE )

		if game.is_finished {
			rl.DrawText( 
				"YOU'VE ESCAPED.", 
				(rl.GetScreenWidth() - rl.MeasureText( "YOU'VE ESCAPED", 50 )) / 2, rl.GetScreenHeight() / 2, 
				50, 
				rl.GREEN 
			)
		}

		rl.EndDrawing()

		free_all( context.temp_allocator )
	}

	rl.UnloadTexture( game.atlas )
	rl.UnloadImage( game.map_image )
	rl.CloseWindow()

	free(game)
}
