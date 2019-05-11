for k, v in pairs( require( 'raylib' )) do _G[k] = v end

local screenWidth = 800
local screenHeight = 450

SetConfigFlags( FLAG_MSAA_4X_HINT )
InitWindow( screenWidth, screenHeight, 'Gamepad' )
SetTargetFPS( 60 )

function printf( ... )
	print(string.format( ... ))
end
printf("KEYS: %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d\n",
	GAMEPAD_BUTTON_MIDDLE_RIGHT,
	GAMEPAD_BUTTON_MIDDLE_LEFT,
	GAMEPAD_BUTTON_RIGHT_FACE_LEFT,
	GAMEPAD_BUTTON_RIGHT_FACE_DOWN,
	GAMEPAD_BUTTON_RIGHT_FACE_RIGHT,
	GAMEPAD_BUTTON_RIGHT_FACE_UP,
	GAMEPAD_BUTTON_LEFT_FACE_LEFT,
	GAMEPAD_BUTTON_LEFT_FACE_DOWN,
	GAMEPAD_BUTTON_LEFT_FACE_RIGHT,
	GAMEPAD_BUTTON_LEFT_FACE_UP,
	GAMEPAD_BUTTON_LEFT_TRIGGER_1,
	GAMEPAD_BUTTON_RIGHT_TRIGGER_1,
	GAMEPAD_BUTTON_LEFT_TRIGGER_2,
	GAMEPAD_BUTTON_RIGHT_TRIGGER_2,
	GAMEPAD_AXIS_LEFT_X,
	GAMEPAD_AXIS_LEFT_Y,
	GAMEPAD_AXIS_LEFT_TRIGGER,
	GAMEPAD_AXIS_RIGHT_X,
	GAMEPAD_AXIS_RIGHT_Y,
	GAMEPAD_AXIS_RIGHT_TRIGGER
 	);
while not WindowShouldClose() do
	BeginDrawing()
	do
		ClearBackground(RAYWHITE)
		if IsGamepadAvailable(GAMEPAD_PLAYER1) then
			DrawText(("GP1: %s"):format( GetGamepadName(GAMEPAD_PLAYER1)), 10, 10, 10, BLACK);
			if (IsGamepadButtonDown(GAMEPAD_PLAYER1, GAMEPAD_BUTTON_MIDDLE_RIGHT)) then DrawCircle(436, 150, 9, RED) end
			if (IsGamepadButtonDown(GAMEPAD_PLAYER1, GAMEPAD_BUTTON_MIDDLE_LEFT)) then DrawCircle(352, 150, 9, RED) end
			if (IsGamepadButtonDown(GAMEPAD_PLAYER1, GAMEPAD_BUTTON_RIGHT_FACE_LEFT)) then DrawCircle(501, 151, 15, BLUE) end
			if (IsGamepadButtonDown(GAMEPAD_PLAYER1, GAMEPAD_BUTTON_RIGHT_FACE_DOWN)) then DrawCircle(536, 187, 15, LIME) end
			if (IsGamepadButtonDown(GAMEPAD_PLAYER1, GAMEPAD_BUTTON_RIGHT_FACE_RIGHT)) then DrawCircle(572, 151, 15, MAROON) end
			if (IsGamepadButtonDown(GAMEPAD_PLAYER1, GAMEPAD_BUTTON_RIGHT_FACE_UP)) then DrawCircle(536, 115, 15, GOLD) end

			-- Draw buttons: d-pad
			DrawRectangle(317, 202, 19, 71, BLACK);
			DrawRectangle(293, 228, 69, 19, BLACK);
			if (IsGamepadButtonDown(GAMEPAD_PLAYER1, GAMEPAD_BUTTON_LEFT_FACE_UP)) then DrawRectangle(317, 202, 19, 26, RED) end
			if (IsGamepadButtonDown(GAMEPAD_PLAYER1, GAMEPAD_BUTTON_LEFT_FACE_DOWN)) then DrawRectangle(317, 202 + 45, 19, 26, RED) end
			if (IsGamepadButtonDown(GAMEPAD_PLAYER1, GAMEPAD_BUTTON_LEFT_FACE_LEFT)) then DrawRectangle(292, 228, 25, 19, RED) end
			if (IsGamepadButtonDown(GAMEPAD_PLAYER1, GAMEPAD_BUTTON_LEFT_FACE_RIGHT)) then DrawRectangle(292 + 44, 228, 26, 19, RED) end

			-- Draw buttons: left-right back
			if (IsGamepadButtonDown(GAMEPAD_PLAYER1, GAMEPAD_BUTTON_LEFT_TRIGGER_1)) then DrawCircle(259, 61, 20, RED) end
			if (IsGamepadButtonDown(GAMEPAD_PLAYER1, GAMEPAD_BUTTON_RIGHT_TRIGGER_1)) then DrawCircle(536, 61, 20, RED) end

			-- Draw axis: left joystick
			DrawCircle(259, 152, 39, BLACK)
			DrawCircle(259, 152, 34, LIGHTGRAY)
			DrawCircle(259 + (GetGamepadAxisMovement(GAMEPAD_PLAYER1, GAMEPAD_AXIS_LEFT_X)*20), 
			152 - (GetGamepadAxisMovement(GAMEPAD_PLAYER1, GAMEPAD_AXIS_LEFT_Y)*20), 25, BLACK)

			-- Draw axis: right joystick
			DrawCircle(461, 237, 38, BLACK)
			DrawCircle(461, 237, 33, LIGHTGRAY)
			DrawCircle(461 + (GetGamepadAxisMovement(GAMEPAD_PLAYER1, GAMEPAD_AXIS_RIGHT_X)*20), 
			237 - (GetGamepadAxisMovement(GAMEPAD_PLAYER1, GAMEPAD_AXIS_RIGHT_Y)*20), 25, BLACK)

			-- Draw axis: left-right triggers
			DrawRectangle(170, 30, 15, 70, GRAY)
			DrawRectangle(604, 30, 15, 70, GRAY)              
			DrawRectangle(170, 30, 15, (((1.0 + GetGamepadAxisMovement(GAMEPAD_PLAYER1, GAMEPAD_AXIS_LEFT_TRIGGER))/2.0)*70), RED)
			DrawRectangle(604, 30, 15, (((1.0 + GetGamepadAxisMovement(GAMEPAD_PLAYER1, GAMEPAD_AXIS_RIGHT_TRIGGER))/2.0)*70), RED)
			DrawText(("DETECTED AXIS [%i]:"):format( GetGamepadAxisCount(GAMEPAD_PLAYER1)), 10, 50, 10, MAROON); 

			for i = 0, GetGamepadAxisCount(GAMEPAD_PLAYER1)-1 do
				DrawText(("AXIS %i: %.02f"):format( i, GetGamepadAxisMovement(GAMEPAD_PLAYER1, i)), 20, 70 + 20*i, 10, DARKGRAY)
			end
			if (GetGamepadButtonPressed() ~= -1) then
				DrawText(("DETECTED BUTTON: %i"):format( GetGamepadButtonPressed()), 10, 430, 10, RED)
			else
				DrawText("DETECTED BUTTON: NONE", 10, 430, 10, GRAY)
			end
		end
		EndDrawing()
	end
end
CloseWindow()
