package main

import "core:math/rand"
import "core:math"
import rl "vendor:raylib"

Audio :: struct {
	move: rl.Sound,
	hit_wall: rl.Sound,
	coin_pickup: rl.Sound,
}

load_audio :: proc( audio: ^Audio ) {
    rl.InitAudioDevice()

    audio.move = rl.LoadSound( "move.wav" )
    audio.hit_wall = rl.LoadSound( "hit_wall.wav" )
    audio.coin_pickup = rl.LoadSound( "coin_pickup.wav" )
}

play_audio_random :: proc( clip: rl.Sound ) {
    rl.SetSoundPitch( clip, rand.float32_range(0.9, 1.2) )
    rl.PlaySound( clip )
}

play_audio_pitch_up_counter :: proc( clip: rl.Sound, counter: i32 ) {
    rl.SetSoundPitch( clip, math.clamp( 1 + ( f32(counter) * 0.05 ), 1, 3 ) )
    rl.PlaySound( clip )
}