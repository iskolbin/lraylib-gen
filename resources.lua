local resourcesList = {
	'Image',
	'Texture2D',
	'RenderTexture2D',
	'Shader',
	'Font',
	'AudioStream',
	'Sound',
	'Music',
	'Mesh',
	'Model',
	'Material',
	'Wave',
	'ModelAnimation',
}

local resourcePointersList = {
	'Image *',
	'Texture2D *',
	'Model *',
	'Material *',
	'Wave *',
	'Mesh *',
	'ModelAnimation *',
}

return {
	resourcesList = resourcesList,
	resourcePointersList = resourcePointersList,

	isResource = function( typeName )
		for _, v in pairs( resourcesList ) do if typeName == v then return true end end
		return false
	end,

	isResourcePointer = function( typeName )
		for _, v in pairs( resourcePointersList ) do if typeName == v then return true end end
		return false
	end,
}
