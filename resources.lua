local list = {
	'Image',
	'Texture2D',
	'RenderTexture2D',
	'Shader',
	'Font',
	--'AudioStream',
	'Sound',
	'Music',
	'Mesh',
	'Model',
	'Material',
	'Wave',
	--'TextureCubemap',
}

return {
	list = list,

	isResource = function( typeName )
		for i = 1, #list do if typeName == list[i] then return true end end
		return false
	end
}
