local list = {
	'UpdateCamera',
	'UpdateVrTracking',
	'GetWindowHandle',
	'UpdateTexture',
	'GetWaveData', -- need output arrays
	'LoadImageEx', -- need input arrays
	'LoadImagePro',
	'GetImageData',
	'GetImageDataNormalized',
	'ImageExtractPalette', -- need output arrays
	'LoadFontData',
	'LoadWaveEx',
	'UpdateSound',
	'SetShaderValue',
	'SetShaderValueV',

	-- Implemented by hand/used internally
	'CloseWindow', 'GetDroppedFiles', 'ClearDroppedFiles', 'GetDirectoryFiles',
	'ClearDroppedFiles', 'CheckCollisionRaySphereEx', 'LoadModelAnimations',
	'QuaternionToAxisAngle', 'Vector3OrthoNormalize', 'DrawPolyEx',
	'DrawPolyExLines', 'TraceLog',

	-- Redundant functions
	'DrawPixelV', 'DrawLineV', 'DrawCircleV', 'DrawCubeWiresV',
	'DrawCubeV', 'DrawRectangleV', 'DrawRectangleRec',
	'TextIsEqual', 'TextLength', 'TextFormat', 'TextSubtext', 'TextReplace',
	'TextInsert', 'TextJoin', 'TextSplit', 'TextAppend', 'TextFindIndex',
	'TextToUpper', 'TextToLower', 'TextToPascal', 'TextToInteger',
}

return {
	list = list,

	isBlacklisted = function( funcName )
		for i = 1, #list do if funcName == list[i] then return true end end
		return false
	end
}
