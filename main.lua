local raylib = require( 'raylib' )

raylib.InitWindow( 800, 450, '' )

local textures =  {}
--raylib.GetDirectoryFiles('res/img/')--res/img')
--local items = {raylib.GetDirectoryFiles('res/img')}
--ipairs({raylib.GetDirectoryFiles('res/img')})
for i, path in ipairs{raylib.GetDirectoryFilesEx('../neft/res/img')} do
	--{raylib.GetDirectoryFiles( 'res/img' )} do	
--textures[path] = raylib.LoadTexture( 'res/img/' .. path )
	textures[i] = raylib.LoadTexture( '../neft/res/img/' .. path )
end

for i = 1, 10 do
for i, path in ipairs{raylib.GetDirectoryFilesEx('../neft/res/img')} do
end
end

while not raylib.WindowShouldClose() do
	raylib.BeginDrawing()
	raylib.ClearBackground( raylib.BLACK )
	raylib.EndDrawing()
end

for _, texture in pairs( textures ) do
	raylib.UnloadTexture( texture )
end

raylib.CloseWindow()
