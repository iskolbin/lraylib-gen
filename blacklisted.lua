local list = {
	'GetDirectoryFiles',
	'GetDroppedFiles',
	'UpdateCamera',
	'UpdateVrTracking',
	'GetWindowHandle',
	'UpdateTexture',

	'SetTraceLogLevel',
	'SetTraceLogExit',
	'SetTraceLogCallback',
	'TraceLog',

	'GetWaveData', -- need output arrays
	'DrawPolyEx', -- need input arrays
	'DrawPolyExLines', -- need input arrays
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

	'CloseWindow', -- implemented by hand

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
