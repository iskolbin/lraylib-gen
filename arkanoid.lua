local rail = require('rail')

rail.conf.window.title = 'Arkanoid'

local bricks = {}
local player = {}
local ball = {}

local PLAYER_MAX_LIFE = 5
local LINES_OF_BRICKS = 5
local BRICKS_PER_LINE = 20

local function reset( ww, wh )
	player = {
		x = ww/2,
		y = wh*7/8,
		w = ww/10,
		h = 20,
		life = PLAYER_MAX_LIFE
	}
	ball = {
		x = ww/2,
		y = wh*7/8 - 30,
		vx = 0,
		vy = 0,
		r = 7,
		active = false
	}
	local brickw, brickh = ww / BRICKS_PER_LINE, 40
	local bricky0 = 50
	for i = 1, LINES_OF_BRICKS do
		bricks[i] = {}
		for j = 1, BRICKS_PER_LINE do
			bricks[i][j] = {
				x = (j-1)*brickw + brickw/2,
				y = (i-1)*brickh + bricky0,
				w = brickw,
				h = brickh,
				active = true
			}
		end
	end
end

function rail.load()
	reset( rail.window.getsize() )
end

function rail.update()
	local ww, wh = rail.window.getsize()
	if not gameover then
		if rail.keyboard.ispressed(string.byte('P')) then
			pause = not pause
		end
		if not pause then
			if rail.keyboard.isdown( rail.KEY_LEFT ) and player.x - 5 >= 0 then
				player.x = x - 5
			end
			if rail.keyboard.isdown( rail.KEY_RIGHT ) and player.x + 5 <= ww then
				player.x = player.x + 5
			end
			if not ball.active then
				if rail.keyboard.ispressed( rail.KEY_SPACE ) then
					ball.active = true
					ball.vx = 0
					ball.vy = -5
				else
					ball.x = player.x
					ball.y = wh*7/8 - 30
				end
			else
				if (ball.x + ball.r + ball.vx <= 0 and ball.vx < 0) or (ball.x + ball.r + ball.vx >= ww and ball.vx > 0) then
					ball.vx = -ball.vx
				end
				if (ball.y + ball.r + ball.vy <= 0 and ball.vy < 0) or (ball.y + ball.r + ball.vy >= wh and ball.vy > 0) then
					ball.vy = -ball.vy
				end
				ball.x = ball.x + ball.vx
				ball.y = ball.y + ball.vy
			end
		end
	end
end

function rail.draw( ctx )
	local ww, wh = rail.window.getsize()
	ctx.clear( rail.RAYWHITE )
	ctx.fillrect( player.x - player.w/2, player.y - player.h/2, player.w, player.h, rail.BLACK )
	for i = 0, player.life - 1 do
		ctx.fillrect( 20 + 40*i, wh-30, 35, 10, rail.LIGHTGRAY )
	end
	ctx.fillcircle( ball.x, ball.y, ball.r, rail.MAROON )
	for i, bs in pairs( bricks ) do
		for j, brick in pairs( bs ) do
			if brick.active then
				ctx.fillrect( brick.x - brick.w/2, brick.y - brick.h/2, brick.w, brick.h, (i+j)%2 == 0 and rail.GRAY or rail.DARKGRAY )
			end
		end
	end
end

rail.run()
