
wesh = {
	name = "wesh",
	temp_foldername = "wesh_temp_obj_files",
	default_max_faces = 8000,
	mod_path = minetest.get_modpath(minetest.get_current_modname()),
	vt_size = 72,
	player_canvas = {},
	forms = {},
	content_ids = {},
}

wesh.models_path = wesh.mod_path .. "/models/"

minetest.register_privilege("wesh_capture", {
	description = "Can use wesh canvases to capture new meshes",
	give_to_singleplayer = true,
})

minetest.register_privilege("wesh_place", {
	description = "Can place nodes created from wesh captures",
	give_to_singleplayer = true,
})

minetest.register_privilege("wesh_delete", {
	description = "Can delete captured meshes",
	give_to_singleplayer = true,
})

minetest.register_privilege("wesh_import", {
	description = "Can import matrix files",
	give_to_singleplayer = true,
})

minetest.register_privilege("wesh_vacuum", {
	description = "Can disintegrate all blocks in the canvas space",
	give_to_singleplayer = true,
})

local smartfs = dofile(wesh.mod_path .. "/smartfs.lua")

local storage = dofile(wesh.mod_path .. "/storage.lua")

wesh.forms.capture = smartfs.create("wesh.forms.capture", function(state)
	state:size(7, 7)
	
	local meshname_field = state:field(0.5, 0.5, 5, 1, "meshname", "Enter the name for your mesh")
	local capture_button = state:button(5, 0.2, 2, 1, "capture", "Capture")
	
	state:checkbox(0.5, 1, "generate_matrix", "Generate backup matrix"):setValue(true)
	
	state:label(0.5, 2, "label_variants", "Select one or more variants:")
	local variants_x = 0.5
	local variants_y = 2.5
	
	local delete_button = state:button(5, 2.2, 2, 0, "delete", "Manage\nMeshes")
	local give_button = state:button(5, 3.2, 2, 0, "give", "Giveme\nMeshes")
	local import_button = state:button(5, 4.2, 2, 0, "import", "Import\nMatrix")
	local vacuum_button = state:button(5, 5.2, 2, 0, "vacuum", "Vacuum\nCanvas")
	
	local max_faces = state:field(0.5, 6.5, 4, 1, "max_faces", "Max # faces, zero disables limit")
	local cancel_button = state:button(5, 6.2, 2, 1, "cancel", "Cancel")

	meshname_field:onKeyEnter(wesh.mesh_capture_confirmed)
	meshname_field:setCloseOnEnter(false)
	capture_button:onClick(wesh.mesh_capture_confirmed)
	
	delete_button:setClose(true)
	give_button:setClose(true)
	import_button:setClose(true)
	vacuum_button:setClose(true)
	cancel_button:setClose(true)
	
	max_faces:setText(wesh.default_max_faces)
	max_faces:setCloseOnEnter(false)
	
	delete_button:onClick(function(_, state)
		if not minetest.get_player_privs(state.player).wesh_delete then
			wesh.notify(state.player, "Insufficient privileges to manage meshes")
			return
		end
		minetest.after(0, function()
			wesh.forms.delete_meshes:show(state.player)
		end)
	end)

	give_button:onClick(function(_, state)
		minetest.after(0, function()
			wesh.forms.giveme_meshes:show(state.player)
		end)
	end)	
	
	import_button:onClick(function(_, state)
		if not minetest.get_player_privs(state.player).wesh_import then
			wesh.notify(state.player, "Insufficient privileges to import matrices")
			return
		end
		minetest.after(0, function()
			wesh.forms.import_matrix:show(state.player)
		end)
	end)
	
	vacuum_button:onClick(function(_, state)
		if not minetest.get_player_privs(state.player).wesh_vacuum then
			wesh.notify(state.player, "Insufficient privileges to vacuum canvas")
			return
		end
		minetest.after(0, function()
			wesh.forms.vacuum_canvas:show(state.player)
		end)
	end)

	local first_variant = nil
	local one_checked = false
	
	local variant_names = {}
	
	for name, _ in pairs(wesh.variants) do table.insert(variant_names, name) end
	
	table.sort(variant_names)
	
	for _, name in ipairs(variant_names) do
		local chk = state:checkbox(variants_x, variants_y, "variant_" .. name, name)
		if name == 'plain' then
			one_checked = true
			chk:setValue(true)
		end
		variants_y = variants_y + 0.5
		if not first_variant then
			first_variant = chk
		end
	end
	
	if not one_checked then
		first_variant:setValue(true)
	end
end)

wesh.forms.delete_meshes = smartfs.create("wesh.forms.delete_meshes", function(state)
	state:size(8, 8)
	
	local all_obj_files_list = state:listbox(0.5, 0.5, 7, 5.5, "all_obj_files_list")
	local label = state:label(0.5, 6.3, "label", "No OBJ selected")
	local action_button = state:button(0.5, 7.2, 5, 1, "action_button", "[disabled]")
	local done_button = state:button(6, 7.2, 2, 1, "done", "Done")
	done_button:setClose(true)
	
	local obj_files = nil
	
	local function update_button(obj)
		if not obj or not obj.type then 
			action_button:setText("[disabled]")	
		elseif obj.type == "stored" then
			action_button:setText("Mark for deletion")	
		elseif obj.type == "pending deletion" then
			action_button:setText("Cancel pending deletion")	
		elseif obj.type == "temporary" then
			action_button:setText("Delete selected temporary NOW!")	
		end
	end
	
	local function fill_list()
		obj_files = wesh.get_all_obj_files()
		all_obj_files_list:clearItems()
		for index, obj in ipairs(obj_files) do
			local item = obj.filename .. (obj.type ~= "" and (" (" .. obj.type .. ")") or "")
			all_obj_files_list:addItem(item)
		end
		all_obj_files_list:setSelected("")
		label:setText("No OBJ selected")
	end
	
	all_obj_files_list:onClick(function(self, state)
		local index = self:getSelected()
		if index then
			label:setText("Selected:\n" .. self:getItem(index))
		else
			label:setText("No OBJ selected")
		end
		update_button(obj_files[index])
	end)

	action_button:onClick(function(_, state)
		local index = all_obj_files_list:getSelected()	
		local obj = obj_files[index]
		if not obj or not obj.type then 
			return
		elseif obj.type == "stored" then
			wesh.mark_obj_for_deletion(obj.filename)
		elseif obj.type == "pending deletion" then
			wesh.unmark_obj_for_deletion(obj.filename)
		elseif obj.type == "temporary" then
			wesh.delete_temp_obj(obj.filename)
		end
		fill_list()	
		update_button()
	end)
	
	fill_list()
	
end)

wesh.forms.giveme_meshes = smartfs.create("wesh.forms.giveme_meshes", function(state)
	state:size(8, 8)
	
	local stored_obj_files = wesh.filter_non_obj(wesh.get_stored_files())

	local stored_variants = state:listbox(0.5, 0.5, 7, 6.5, "stored_variants")	
	for _, obj_filename in pairs(stored_obj_files) do
		local data = wesh.get_obj_filedata(obj_filename)
		if not data.variants then break end
		for variant, _ in pairs(data.variants) do
			stored_variants:addItem(wesh.create_nodename(obj_filename, variant))
		end
	end
	stored_variants:onDoubleClick(wesh.give_mesh_callback)

	local give_button = state:button(0.5, 7.2, 3, 1, "give", "Giveme selected")
	give_button:onClick(wesh.give_mesh_callback)
	
	local done_button = state:button(4, 7.2, 2, 1, "done", "Done")
	done_button:setClose(true)
end)

function wesh.give_mesh_callback(_, state)
	local nodename = state:get("stored_variants"):getSelectedItem()
	if not nodename then return end
	local player_inv = minetest.get_player_by_name(state.player):get_inventory()
	player_inv:add_item("main", {name = nodename, count = 1})
	wesh.notify(state.player, nodename .. " added to inventory")
end

wesh.forms.import_matrix = smartfs.create("wesh.forms.import_matrix", function(state)
	state:size(8, 8)
	
	local stored_matrices = wesh.filter_non_matrix(wesh.get_stored_files())
	local temp_matrices = wesh.filter_non_matrix(wesh.get_temp_files())
	
	local matrices_list = state:listbox(0.5, 0.5, 7, 6.5, "matrices_list")	
	
	for _, matrix_filename in pairs(stored_matrices) do
		matrices_list:addItem(matrix_filename)
	end

	for _, matrix_filename in pairs(temp_matrices) do
		matrices_list:addItem(matrix_filename)
	end

	local import_button = state:button(0.5, 7.2, 3, 1, "import", "Import selected")
	import_button:onClick(function()
		local full_matrix_filename = false
		local selected_matrix_filename = matrices_list:getSelectedItem()
		for _, matrix_filename in pairs(stored_matrices) do
			if matrix_filename == selected_matrix_filename then
				full_matrix_filename = wesh.models_path .. matrix_filename
				break
			end
		end

		for _, matrix_filename in pairs(temp_matrices) do
			if matrix_filename == selected_matrix_filename then
				full_matrix_filename = wesh.temp_path .. matrix_filename
				break
			end
		end
		
		wesh.import_matrix(full_matrix_filename, state.player)
	end)
	import_button:setClose(true)
	
	local done_button = state:button(4, 7.2, 2, 1, "done", "Done")
	done_button:setClose(true)
end)

wesh.forms.vacuum_canvas = smartfs.create("wesh.forms.vacuum_canvas", function(state)
	state:size(4, 3)
	
	local confirm_vacuum = state:button(0.5, -1, 3, 4, "confirm_vacuum", "Yes, delete ALL NODES\nin the canvas range!")
	confirm_vacuum:onClick(function()
		wesh.vacuum_canvas(state.player)
		wesh.notify(state.player, "Canvas vacuumed")
	end)
	confirm_vacuum:setClose(true)
	
	local cancel_button = state:button(0.5, 1, 3, 3, "cancel", "Cancel")
	cancel_button:setClose(true)
end)


-- ========================================================================
-- initialization functions
-- ========================================================================

function wesh._init()
	wesh.temp_path = minetest.get_worldpath() .. "/mod_storage/" .. wesh.temp_foldername .. "/"
	wesh.gen_prefix = "mesh_"

	if not minetest.mkdir(wesh.temp_path) then
		error("[wesh] Unable to create folder " .. wesh.temp_path)
	end
	wesh._init_vertex_textures()
	wesh._init_colors()
	wesh._init_geometry()
	wesh._init_variants()
	wesh._delete_marked_objs()
	wesh._move_temp_files()
	wesh._load_mod_meshes()
	wesh._register_canvas_nodes()
end

function wesh._register_canvas_nodes()

	local function register_canvas(index, size, inner)
		minetest.register_craft({
			output = "wesh:canvas" .. size,
			recipe = {
				{"group:wool", "group:wool", "group:wool"},
				{"group:wool", inner, "group:wool"},
				{"group:wool", "group:wool", "group:wool"},
			}
		})
		minetest.register_node("wesh:canvas" .. size, {
			drawtype = "mesh",
			mesh = "zzz_canvas" .. size .. ".obj",
			inventory_image = "canvas_inventory.png^[verticalframe:6:" .. (index-1) .. ".png",
			tiles = { "canvas.png" },
			paramtype2 = "facedir",
			on_rightclick = wesh.canvas_interaction,
			description = "Woolen Mesh Canvas - Size " .. size,
			walkable = true,
			groups = { snappy = 2, choppy = 2, oddly_breakable_by_hand = 3 },
		})
	end
	
	local canvas_sizes = {
		{"02", "default:steel_ingot"},
		{"04", "default:copper_ingot"},
		{"08", "default:tin_ingot"},
		{"16", "default:bronze_ingot"},
		{"32", "default:gold_ingot"},
		{"64", "default:diamond"},
	}
	
	wesh.valid_canvas_sizes = {}
	
	for index, canvas_data in pairs(canvas_sizes) do
		local size = canvas_data[1]
		local inner = canvas_data[2]
		wesh.valid_canvas_sizes[tonumber(size)] = true
		register_canvas(index, size, inner)
	end
		
	minetest.register_alias("wesh:canvas", "wesh:canvas16")
end

function wesh._init_vertex_textures()
	-- creates a 4x4 grid of UV mappings, each with a margin of one pixel
	-- will be used by the .OBJ file generator
	local vt = {}
	local space = wesh.vt_size / 4
	local tile = space - 2
	local offset = tile / 2
	local start = offset + 1
	local stop = start + 3 * space
	local mult = 1 / wesh.vt_size
	for y = start, stop, space do
		for x = start, stop, space do
			table.insert(vt, "vt " .. ((x + offset) * mult) .. " " .. ((y + offset) * mult) .. "\n") -- top right
			table.insert(vt, "vt " .. ((x + offset) * mult) .. " " .. ((y - offset) * mult) .. "\n") -- bottom right
			table.insert(vt, "vt " .. ((x - offset) * mult) .. " " .. ((y - offset) * mult) .. "\n") -- bottom left
			table.insert(vt, "vt " .. ((x - offset) * mult) .. " " .. ((y + offset) * mult) .. "\n") -- top left
		end
	end
	wesh.vertex_textures = table.concat(vt)
end

function wesh._init_colors()
	wesh.colors = {
		"violet", 
		"white", 
		"yellow", 
		"air", 
		"magenta", 
		"orange", 
		"pink", 
		"red", 
		"dark_green", 
		"dark_grey", 
		"green", 
		"grey", 
		"black",      
		"blue",      
		"brown", 
		"cyan", 
	}
	
	-- The following loop populates the color_vertices table with data like this...
	-- 
	-- wesh.color_vertices = {
	-- 	violet 		= { 1, 2, 3, 4 },
	-- 	white       = { 5, 6, 7, 8 },
	-- 
	-- ...and so forth, in a boring sequence.
	-- 
	-- Such indices will refer to the vt sequence generated by _init_vertex_textures()
	-- The same loop will also fill the nodename_to_color table with default fallbacks for wool

	wesh.nodename_to_color = {}
	wesh.color_vertices = {}
	for i, color in ipairs(wesh.colors) do
		local t = {}
		local j = (i - 1) * 4 + 1
		for k = j, j + 3 do
			table.insert(t, k)
		end
		wesh.color_vertices[color] = t
		if color ~= "air" then
			wesh.nodename_to_color["wool:" .. color] = color
		end
	end
	
	local colors_filename = "nodecolors.conf"
	local default_colors_filename = "default." .. colors_filename
	local full_colors_filename = wesh.mod_path .. "/" .. colors_filename
	local full_default_colors_filename = wesh.mod_path .. "/" .. default_colors_filename
	
	local file = io.open(full_colors_filename, "rb")
	if not file then
		minetest.debug("[wesh] Copying " .. default_colors_filename .. " to " .. colors_filename)
		local success, err = wesh.copy_file(full_default_colors_filename, full_colors_filename)
		if not success then
			minetest.debug("[wesh] " .. err)
			return
		end
		file = io.open(full_colors_filename, "rb")
		if not file then
			minetest.debug("[wesh] Unable to load " .. colors_filename .. " file from mod folder")
			return
		end
	end

	--  The following loop will fill the nodename_to_color table with custom values
	local content = file:read("*all")
	local lines = content:gsub("(\r\n)+", "\r"):gsub("\r+", "\n"):split("\n")
	for _, line in ipairs(lines) do
		local parts = line:gsub("%s+", ""):split("=")
		if #parts == 2 then
			wesh.nodename_to_color[parts[1]] = parts[2]
		end
	end
	file:close()

end

function wesh._init_geometry()

	-- helper table to build the six faces
	wesh.cube_vertices = {
		{ x =  1, y = -1, z = -1 }, -- 1
		{ x = -1, y = -1, z = -1 }, -- 2
		{ x = -1, y = -1, z =  1 }, -- 3
		{ x =  1, y = -1, z =  1 }, -- 4
		{ x =  1, y =  1, z = -1 }, -- 5
		{ x =  1, y =  1, z =  1 }, -- 6
		{ x = -1, y =  1, z =  1 }, -- 7
		{ x = -1, y =  1, z = -1 }, -- 8
	}

	-- vertices refer to the above cube_vertices table
	wesh.face_construction = {
		bottom = { vertices = { 4, 3, 2, 1 }, normal = 1 },
		top    = { vertices = { 8, 7, 6, 5 }, normal = 2 },
		back   = { vertices = { 2, 8, 5, 1 }, normal = 3 },
		front  = { vertices = { 4, 6, 7, 3 }, normal = 4 },
		left   = { vertices = { 6, 4, 1, 5 }, normal = 5 },
		right  = { vertices = { 3, 7, 8, 2 }, normal = 6 },
	}
	
	wesh.face_normals = {
		{x =  0, y = -1, z =  0 },
		{x =  0, y =  1, z =  0 },
		{x =  0, y =  0, z = -1 },
		{x =  0, y =  0, z =  1 },
		{x = -1, y =  0, z =  0 },
		{x =  1, y =  0, z =  0 },
	}
	
	-- helper mapper for transformation functions
	-- only upright canvases supported
	wesh._transfunc = {
		-- facedir 0, +Y, no rotation
		function(p) return p end,
		-- facedir 1, +Y, 90 deg
		function(p) p.x, p.z = p.z, -p.x return p end,
		-- facedir 2, +Y, 180 deg
		function(p) p.x, p.z = -p.x, -p.z return p end,
		-- facedir 3, +Y, 270 deg
		function(p) p.x, p.z = -p.z, p.x return p end,
	}
end

function wesh.transform(facedir, pos)
	return (wesh._transfunc[facedir + 1] or wesh._transfunc[1])(pos)
end

function wesh._reset_geometry(canv_size)
	wesh.matrix = {}
	wesh.vertices = {}
	wesh.vertices_indices = {}
	wesh.faces = {}
	local function reset(p)
		if not wesh.matrix[p.x] then wesh.matrix[p.x] = {} end
		if not wesh.matrix[p.x][p.y] then wesh.matrix[p.x][p.y] = {} end
		wesh.matrix[p.x][p.y][p.z] = "air"	
	end
	wesh.traverse_matrix(reset, canv_size)
end

function wesh._init_variants()
	local variants_filename = "nodevariants.lua"
	local default_variants_filename = "default." .. variants_filename
	local full_variants_filename = wesh.mod_path .. "/" .. variants_filename
	local full_default_variants_filename = wesh.mod_path .. "/" .. default_variants_filename
	
	local file = io.open(full_variants_filename, "rb")
	if not file then
		minetest.debug("[wesh] Copying " .. default_variants_filename .. " to " .. variants_filename)
		local success, err = wesh.copy_file(full_default_variants_filename, full_variants_filename)
		if not success then
			minetest.debug("[wesh] " .. err)
			return
		end
		file = io.open(full_variants_filename, "rb")
		if not file then
			minetest.debug("[wesh] Unable to load " .. variants_filename .. " file from mod folder")
			return
		end
	end

	local custom_variants = minetest.deserialize(file:read("*all"))	
	wesh.variants = {
		plain = "plain-16.png",
	}
	
	-- ensure there is at least one valid variant in the custom variants
	if custom_variants and type(custom_variants) == "table" then
		for name, texture in pairs(custom_variants) do
			if name and type(name) == "string" and texture and type(texture) == "string" then
				wesh.variants = custom_variants
				break
			end
		end
	end
	file:close()
end

-- ========================================================================
-- core functions
-- ========================================================================

function wesh.canvas_interaction(clicked_pos, node, clicker)
	-- called when the player right-clicks on a canvas block
	local canvas = {
		pos = clicked_pos,
		facedir = node.param2,
		node = node,
	}
	
	canvas.size = canvas.node.name:gsub(".*(%d%d)$", "%1")
	canvas.size = tonumber(canvas.size)
	if not wesh.valid_canvas_sizes[canvas.size] then
		canvas.size = 16
	end
	
	local playername = clicker:get_player_name()
	wesh.player_canvas[playername] = canvas
	wesh.forms.capture:show(playername)
end

function wesh.mesh_capture_confirmed(button_or_field, state)
	local meshname = state:get("meshname"):getText()
	local playername = state.player	
	
	if not minetest.get_player_privs(playername).wesh_capture then
		wesh.notify(playername, "Insufficient privileges to capture new meshes")
		return
	end
	
	local canvas = wesh.player_canvas[playername]
	canvas.generate_matrix = state:get("generate_matrix"):getValue()
	canvas.max_faces = tonumber(state:get("max_faces"):getText()) or wesh.default_max_faces
	
	canvas.chosen_variants = {}
	
	local no_variants = true
	for name, texture in pairs(wesh.variants) do
		if state:get("variant_" .. name):getValue() then
			canvas.chosen_variants[name] = texture
			no_variants = false
		end
	end
	
	if no_variants then
		wesh.notify(playername, "Please choose at least one variant")
		return
	end

	canvas.boundary = {}
	if wesh.save_new_mesh(canvas, playername, meshname) then
		minetest.close_formspec(playername, "wesh.forms.capture")
	end
end

function wesh.save_new_mesh(canvas, playername, description)
	local sanitized_meshname = wesh.check_plain(description)
	if sanitized_meshname:len() < 3 then
		wesh.notify(playername, "Mesh name too short, try again (min. 3 chars)")
		return false
	end
	
	local obj_filename = wesh.gen_prefix .. sanitized_meshname .. ".obj"
	for _, entry in ipairs(wesh.get_all_files()) do
		if entry == obj_filename then		
			wesh.notify(playername, "Mesh name '" .. description .. "' already taken, pick a new one")
			return false
		end
	end
	
	-- empty all helper variables
	wesh._reset_geometry(canvas.size)
	
	canvas.voxel_count = 0
	
	-- read all nodes from the canvas space in the world
	-- extract the colors and put them into a helper matrix of color voxels
	-- generate primary boundary
	wesh.traverse_matrix(wesh.node_to_voxel, canvas.size, canvas)
	
	-- generate secondary boundaries
	wesh.generate_secondary_boundaries(canvas)
		
	-- generate faces according to voxels
	local success, err = pcall(function()
		wesh.traverse_matrix(wesh.voxel_to_faces, canvas.size, canvas)
	end)
	
	if not success then
		wesh.notify(playername, err.msg)
		return false
	end
	
	-- this will be the actual content of the .obj file
	local vt_section = wesh.vertex_textures
	local v_section = wesh.vertices_to_string()
	local vn_section = wesh.normals_to_string()
	local f_section = table.concat(wesh.faces, "\n")
	local meshdata = vt_section .. v_section .. vn_section .. f_section
	
	return wesh.save_mesh_to_file(obj_filename, meshdata, description, playername, canvas)
end

-- ========================================================================
-- matrix import helpers
-- ========================================================================

function wesh.import_matrix(full_matrix_filename, playername)
	if not full_matrix_filename then return end
	local file = io.open(full_matrix_filename, "rb")
	if not file then
		wesh.notify(playername, "Unable to open file " .. full_matrix_filename)
		return false
	end
	local matrix = minetest.deserialize(file:read("*all"))
	if not matrix or type(matrix) ~= "table" then
		wesh.notify(playername, "Invalid matrix data inside " .. full_matrix_filename)
		return false
	end
	
	local canvas = wesh.player_canvas[playername]
	
	local function invalid_size(axis, size)
		if size ~= canvas.size then
			wesh.notify(playername, "Trying to import " .. full_matrix_filename)
			wesh.notify(playername, axis .. " == " .. size .. " doesn't match canvas value of " .. canvas.size)
			return true
		end
		return false
	end
	
	if invalid_size("x", #matrix) or invalid_size("y", #matrix[1]) or invalid_size("z", #matrix[1][1]) then
		return false
	end
	
	
	local min_pos = wesh.make_absolute({ x = 1, y = 1, z = 1 }, canvas)
	local max_pos = wesh.make_absolute({ x = canvas.size, y = canvas.size, z = canvas.size }, canvas)
	
	local vm = minetest.get_voxel_manip()
	local emin, emax = vm:read_from_map(min_pos, max_pos)
	local a = VoxelArea:new{
		MinEdge = emin,
		MaxEdge = emax
	}
    
	local data = vm:get_data()
	local air_id = wesh.get_content_id("air")
		
	for x = 1, #matrix do
		for y = 1, #matrix[x] do
			for z = 1, #matrix[x][y] do
				local color = matrix[x][y][z]
				if color ~= "air" then
					local rel_pos = { x = x, y = y, z = z }
					local abs_pos = wesh.make_absolute(rel_pos, canvas)
					local vi = a:index(abs_pos.x, abs_pos.y, abs_pos.z)
					data[vi] = wesh.get_content_id("wool:" .. color)
				end
			end
		end
	end
	
	vm:set_data(data)
	vm:write_to_map(true)
	
	return true
end

function wesh.get_content_id(nodename)
	if not wesh.content_ids[nodename] then
		wesh.content_ids[nodename] = minetest.get_content_id(nodename)
	end
	return wesh.content_ids[nodename]
end

function wesh.vacuum_canvas(playername)
	
	local canvas = wesh.player_canvas[playername]
		
	local min_pos = wesh.make_absolute({ x = 1, y = 1, z = 1 }, canvas)
	local max_pos = wesh.make_absolute({ x = canvas.size, y = canvas.size, z = canvas.size }, canvas)
	
	local vm = minetest.get_voxel_manip()
	local emin, emax = vm:read_from_map(min_pos, max_pos)
	local a = VoxelArea:new{
		MinEdge = emin,
		MaxEdge = emax
	}
    
	local data = vm:get_data()
	local air_id = wesh.get_content_id("air")
	
	local min = wesh.axis_min(min_pos, max_pos)
	local max = wesh.axis_max(min_pos, max_pos)
	
	for x = min.x, max.x do
		for y = min.y, max.y do
			for z = min.z, max.z do
				local vi = a:index(x, y, z)
				data[vi] = air_id
			end
		end
	end
	
	vm:set_data(data)
	vm:write_to_map(true)
	
end

-- ========================================================================
-- mesh management helpers
-- ========================================================================

function wesh.save_mesh_to_file(obj_filename, meshdata, description, playername, canvas)
	
	-- save .obj file
	local full_filename = wesh.temp_path .. "/" .. obj_filename
	local file, errmsg = io.open(full_filename, "wb")
	if not file then
		wesh.notify(playername, "Unable to write to file '" .. obj_filename .. "' from '" .. wesh.temp_path .. "' - error: " .. errmsg)
		return false
	end
	file:write(meshdata)
	file:close()
	
	-- save .dat file
	local data_filename = obj_filename .. ".dat"
	local full_data_filename = wesh.temp_path .. "/" .. data_filename
	local file, errmsg = io.open(full_data_filename, "wb")
	if not file then
		wesh.notify(playername, "Unable to write to file '" .. data_filename .. "' from '" .. wesh.temp_path .. "' - error: " .. errmsg)
		return false
	end
	file:write(wesh.prepare_data_file(description, canvas))
	file:close()
	
	if canvas.generate_matrix then
		-- save .matrix.dat file
		local matrix_data_filename = obj_filename .. ".matrix.dat"
		local full_matrix_data_filename = wesh.temp_path .. "/" .. matrix_data_filename
		local file, errmsg = io.open(full_matrix_data_filename, "wb")
		if not file then
			wesh.notify(playername, "Unable to write to file '" .. matrix_data_filename .. "' from '" .. wesh.temp_path .. "' - error: " .. errmsg)
			return false
		end
		file:write(minetest.serialize(wesh.matrix))
		file:close()
	end
	
	wesh.notify(playername, "Mesh saved to '" .. obj_filename .. "' in '" .. wesh.temp_path .. "'")
	wesh.notify(playername, "Reload the world to move newly created mesh to the mod folder")
	wesh.notify(playername, "Mesh stats: " .. canvas.voxel_count .. " voxels, " .. #wesh.vertices .. " vertices, " .. #wesh.faces .. " faces")
	return true
end

function wesh.prepare_data_file(description, canvas)
	local boxes = {}
	wesh.merge_collision_boxes(canvas)	
	for _, box in ipairs(canvas.boxes) do
		table.insert(boxes, wesh.box_to_collision_box(box, canvas.size))
	end
	
	local data = {
		description = description,
		variants = canvas.chosen_variants,
		collision_box = {
			type = "fixed",
			fixed = boxes,
		}
	}
	return wesh.serialize(data, 2)
end

function wesh.get_temp_files()
	return minetest.get_dir_list(wesh.temp_path, false)
end

function wesh.get_stored_files()
	return minetest.get_dir_list(wesh.models_path, false)
end

function wesh.get_all_files()
	local all = wesh.get_temp_files()
	for _, entry in pairs(wesh.get_stored_files()) do
		table.insert(all, entry)
	end
	return all
end

function wesh.filter_non_obj(filelist)
	local list = {}
	for _, filename in pairs(filelist) do
		if wesh.is_valid_obj_filename(filename) then
			table.insert(list, filename)
		end
	end
	return list
end

function wesh.filter_non_matrix(filelist)
	local list = {}
	for _, filename in pairs(filelist) do
		if wesh.is_valid_matrix_filename(filename) then
			table.insert(list, filename)
		end
	end
	return list
end

function wesh.retrieve_marked_objs()
	local marked_objs = minetest.deserialize(storage:get_string("marked_objs"))
	return type(marked_objs) == "table" and marked_objs or {}
end

function wesh.store_marked_objs(marked_objs)
	storage:set_string("marked_objs", minetest.serialize(marked_objs))
end

function wesh.mark_obj_for_deletion(obj_filename)
	local marked_objs = wesh.retrieve_marked_objs()
	marked_objs[obj_filename] = 1
	wesh.store_marked_objs(marked_objs)
end

function wesh.unmark_obj_for_deletion(obj_filename)
	local marked_objs = wesh.retrieve_marked_objs()
	marked_objs[obj_filename] = nil
	wesh.store_marked_objs(marked_objs)
end

function wesh.delete_temp_obj(obj_filename)
	local full_obj_filename = wesh.temp_path .. "/" .. obj_filename
	wesh._delete_obj_fileset(full_obj_filename)
end

function wesh._delete_obj_fileset(full_obj_filename)
	os.remove(full_obj_filename)
	os.remove(full_obj_filename .. ".dat")
	os.remove(full_obj_filename .. ".matrix.dat")
end

function wesh._delete_marked_objs()
	for obj_filename, _ in pairs(wesh.retrieve_marked_objs()) do
		wesh._delete_obj_fileset(wesh.models_path .. obj_filename)
	end
	storage:set_string("marked_objs", "")
end

function wesh._move_temp_files()
	local meshes = wesh.get_temp_files()
	for _, filename in ipairs(meshes) do
		os.rename(wesh.temp_path .. "/" .. filename, wesh.models_path .. filename)
	end
end

function wesh.is_valid_obj_filename(obj_filename)
	return obj_filename:match("^" .. wesh.gen_prefix .. ".-%.obj$")
end

function wesh.is_valid_matrix_filename(matrix_filename)
	return matrix_filename:match("^" .. wesh.gen_prefix .. ".-%.obj%.matrix%.dat$")
end

function wesh.create_nodename(obj_filename, variant)
	return "wesh:" .. obj_filename:gsub("[^%w]+", "_"):gsub("_obj", "") .. "_" .. variant 
end

function wesh.get_all_obj_files()
	local stored_obj_files = wesh.filter_non_obj(wesh.get_stored_files())
	local temp_obj_files = wesh.filter_non_obj(wesh.get_temp_files())
	local marked_objs = wesh.retrieve_marked_objs()
	local result = {}

	for _, obj_filename in pairs(stored_obj_files) do
		table.insert(result, {
			filename = obj_filename,
			type = marked_objs[obj_filename] and "pending deletion" or "stored",
		})
	end
	
	for _, obj_filename in pairs(temp_obj_files) do
		table.insert(result, {
			filename = obj_filename,
			type = "temporary",
		})
	end

	return result
end

function wesh.get_obj_filedata(obj_filename)
	local full_data_filename = wesh.models_path .. obj_filename .. ".dat"
	
	local file = io.open(full_data_filename, "rb")
	
	local data = {}
	if file then
		data = minetest.deserialize(file:read("*all"))
		data = type(data) == "table" and data or {}
		file:close()
	end
	return data
end

function wesh._load_mod_meshes()
	local meshes = wesh.get_stored_files()
	for _, filename in ipairs(meshes) do
		if wesh.is_valid_obj_filename(filename) then
			wesh._load_mesh(filename)
		end
	end
end

function wesh._load_mesh(obj_filename)
	local data = wesh.get_obj_filedata(obj_filename)
	
	local description = data.description or "Custom Woolen Mesh"
	local variants = data.variants or { plain = "plain-16.png" }
	
	for variant, tile in pairs(variants) do
		local props = {
			drawtype = "mesh",
			mesh = obj_filename,
			paramtype = "light",
			sunlight_propagates = true,
			paramtype2 = "facedir",
			description = description .. " (" .. variant .. ")",
			tiles = { tile },
			walkable = true,
			groups = { snappy = 2, choppy = 2, oddly_breakable_by_hand = 3 },
		}
		for prop, value in pairs(data) do
			if prop ~= "variants" and prop ~= "description" then
				props[prop] = value
			end
		end
		if props.collision_box and not props.selection_box then
			props.selection_box = props.collision_box
		end
		props.on_place = function(itemstack, placer, pointed_thing)
			local playername = placer:get_player_name()
			if not minetest.get_player_privs(playername).wesh_place then
				wesh.notify(playername, "Insufficient privileges to place mesh nodes")
				return
			end
			minetest.item_place(itemstack, placer, pointed_thing)
		end
		local nodename = wesh.create_nodename(obj_filename, variant)
		minetest.register_node(nodename, props)
	end
end

-- ========================================================================
-- collision box computers
-- ========================================================================

function wesh.box_to_collision_box(box, size)
	-- transform integral values of the box to the -0.5 ~ 0.5 range
	-- and return its string representation
	
	local subvoxel = 1 / size
	
	local min = vector.subtract(box.min, 1)
	min = vector.multiply(min, subvoxel)
	min = vector.subtract(min, 0.5)
	
	local max = vector.add(box.max, 0)
	max = vector.multiply(max, subvoxel)
	max = vector.subtract(max, 0.5)
	return { min.x, min.y, min.z, max.x, max.y, max.z }
end

function wesh.generate_secondary_boundaries(canvas)
	-- split_boundary calls itself recursively and splits over the three axes in sequence
	canvas.boundaries = wesh.split_boundary(canvas.boundary, "x")
	
	-- boundaries will get converted to boxes with integral values and shrunk if necessary
	canvas.boxes = {}
	for index, boundary in ipairs(canvas.boundaries) do
		canvas.boxes[index] = {}
		wesh.traverse_matrix(wesh.update_secondary_collision_box, boundary, canvas.boxes[index])
	end
end

function wesh.merge_collision_boxes(canvas)
	-- merge collision boxes back if they fall within a relative treshold

	local unmergeable = {}
	local boxes = {}
	local treshold = math.floor(canvas.size / 4)

	-- remove all empty boxes
	for _, box in ipairs(canvas.boxes) do
		if box.min then
			table.insert(boxes, box)
		end
	end

	-- repeatedly iterate over boxes comparing the first to remaining ones
	while #boxes > 1 do
		local a = boxes[1]
		local merged = false
		for i = 2, #boxes do
			local b = boxes[i]
				-- if appropriate, remove and merge pairs together appending resulting box to the table
			if wesh.mergeable_boxes(a, b, treshold) then
				table.insert(boxes, {
					min = wesh.axis_min(a.min, b.min),
					max = wesh.axis_max(a.max, b.max),
				})
				table.remove(boxes, i)
				table.remove(boxes, 1)
				merged = true;
				break
			end
		end
		if not merged then
			table.insert(unmergeable, boxes[1])
			table.remove(boxes, 1)
		end
	end
	
	for _, v in ipairs(unmergeable) do
		table.insert(boxes, v)
	end
	canvas.boxes = boxes;
end

function wesh.mergeable_boxes(a, b, treshold)
	-- check if boxes are aligned independently on each axis
	local align_x = math.abs(a.min.x - b.min.x) <= treshold and math.abs(a.max.x - b.max.x) <= treshold
	local align_y = math.abs(a.min.y - b.min.y) <= treshold and math.abs(a.max.y - b.max.y) <= treshold
	local align_z = math.abs(a.min.z - b.min.z) <= treshold and math.abs(a.max.z - b.max.z) <= treshold
	
	-- increase treshold by one to arrange for 2x2x2 corner case with treshold set to zero
	treshold = treshold + 1
	
	-- check if spacing between boxes along independent axes is smaller than given treshold
	local close_x = math.abs(a.min.x - b.max.x) <= treshold or  math.abs(b.min.x - a.max.x) <= treshold 
	local close_y = math.abs(a.min.y - b.max.y) <= treshold or  math.abs(b.min.y - a.max.y) <= treshold 
	local close_z = math.abs(a.min.z - b.max.z) <= treshold or  math.abs(b.min.z - a.max.z) <= treshold 
	
	-- return true only if the boxes are aligned on two axes and close together on the third one
	return align_x and align_y and close_z
		or align_y and align_z and close_x
		or align_z and align_x and close_y
end

function wesh.split_boundary(boundary, axis)
	-- split the boundary in half over each axis recursively
	-- this can result in up to 8 secondary boundaries

	local boundaries = {}
	local span = boundary.max[axis] - boundary.min[axis]
	local next_axis = nil
	if axis == "x" then
		next_axis = "y"
	elseif axis == "y" then
		next_axis = "z"
	end
	if span > 0 then
		local limit = math.ceil(span / 2)
		local sub_one = table.copy(boundary)
		sub_one.max[axis] = limit
		local sub_two = table.copy(boundary)
		sub_two.min[axis] = limit + 1
		if next_axis then
			wesh.merge_tables(boundaries, wesh.split_boundary(sub_one, next_axis))		
			wesh.merge_tables(boundaries, wesh.split_boundary(sub_two, next_axis))
		else
			table.insert(boundaries, sub_one)
			table.insert(boundaries, sub_two)
		end
	elseif next_axis then
		wesh.merge_tables(boundaries, wesh.split_boundary(boundary, next_axis))
	else
		table.insert(boundaries, boundary)
	end
	return boundaries
end

function wesh.update_collision_box(rel_pos, box)
	-- shrink box boundaries over the three axes separately
	
	if not box.min then
		box.min = rel_pos
	else
		box.min = wesh.axis_min(box.min, rel_pos)
	end
	if not box.max then
		box.max = rel_pos
	else
		box.max = wesh.axis_max(box.max, rel_pos)
	end
end

function wesh.update_secondary_collision_box(rel_pos, box)
	-- let the box shrink only if the subvoxel isn't empty
	
	if wesh.get_voxel_color(rel_pos) ~= "air" then
		wesh.update_collision_box(rel_pos, box)
	end
end


-- ========================================================================
-- mesh generation helpers
-- ========================================================================

function wesh.construct_face(rel_pos, canvas, texture_vertices, facename, vertices, normal_index)
	local normal = wesh.face_normals[normal_index]
	local hider_pos = vector.add(rel_pos, normal)
	if not wesh.out_of_bounds(hider_pos, canvas.size) and wesh.get_voxel_color(hider_pos) ~= "air" then return end
	local face_line = { "f " }
	for i, vertex in ipairs(vertices) do
		local index = wesh.get_vertex_index(rel_pos, canvas.size, vertex)
		table.insert(face_line, index .. "/" .. texture_vertices[i] .. "/" .. normal_index .. " ")
	end
	table.insert(wesh.faces, table.concat(face_line))
	if canvas.max_faces > 0 and #wesh.faces > canvas.max_faces then
		error({ msg = canvas.max_faces .. " faces limit exceeded"})
	end
end

function wesh.get_node_color(pos)
	local node = minetest.get_node_or_nil(pos)
	if not node then return "air" end
	return wesh.nodename_to_color[node.name] or "air"
end

function wesh.get_texture_vertices(color)
	if not wesh.color_vertices[color] then
		return wesh.color_vertices.air
	end
	return wesh.color_vertices[color]
end

function wesh.get_vertex_index(pos, canv_size, vertex_number)
	-- get integral offset of vertices related to voxel center
	local offset = wesh.cube_vertices[vertex_number]
	
	-- convert integral offset to real offset
	offset = vector.multiply(offset, 1/canv_size/2)
	
	-- scale voxel center from range 1~canv_size to range 1/canv_size ~ 1
	pos = vector.divide(pos, canv_size)
		
	-- center whole mesh around zero and shift it to make room for offsets
	pos = vector.subtract(pos, 1/2 + 1/canv_size/2)
	
	-- not really sure whether this should be done here,
	-- but if I don't do this the resulting mesh will be wrongly mirrored
	pos.x = -pos.x
	
	-- combine voxel center and offset to get final real vertex coordinate
	pos = vector.add(pos, offset)
	
	-- bail out if this vertex already exists
	local lookup = pos.x .. "," .. pos.y .. "," .. pos.z
	if wesh.vertices_indices[lookup] then return wesh.vertices_indices[lookup] end
	
	-- add the vertex to the list of needed ones
	table.insert(wesh.vertices, pos)
	wesh.vertices_indices[lookup] = #wesh.vertices
	
	return #wesh.vertices
end

function wesh.get_voxel_color(pos)
	return wesh.matrix[pos.x][pos.y][pos.z]
end

function wesh.make_absolute(rel_pos, canvas)
	-- relative positions range from (1, 1, 1) to (canvas.size, canvas.size, canvas.size)

	-- shift relative to canvas node within canvas space
	local shifted_pos = {
		x = rel_pos.x - (canvas.size / 2),
		y = rel_pos.y - 1,
		z = rel_pos.z,
	}
	
	-- transform according to canvas facedir
	local transformed_pos = wesh.transform(canvas.facedir, shifted_pos)
		
	-- translate to absolute according to canvas position
	local abs_pos = vector.add(canvas.pos, transformed_pos)
		
	return abs_pos
end

function wesh.set_voxel_color(pos, color)
	if not wesh.color_vertices[color] then color = "air" end
	wesh.matrix[pos.x][pos.y][pos.z] = color
end

function wesh.node_to_voxel(rel_pos, canvas)
	local abs_pos = wesh.make_absolute(rel_pos, canvas)
	local color = wesh.get_node_color(abs_pos)
	if color ~= "air" then
		canvas.voxel_count = canvas.voxel_count + 1
		wesh.update_collision_box(rel_pos, canvas.boundary)
	end
	wesh.set_voxel_color(rel_pos, color)
end

function wesh.normals_to_string()
	local output = {}
	for i, normal in ipairs(wesh.face_normals) do
		table.insert(output, "vn " .. normal.x .. " " .. normal.y .. " " .. normal.z .. "\n")
	end
	return table.concat(output)
end

function wesh.voxel_to_faces(rel_pos, canvas)
	local color = wesh.get_voxel_color(rel_pos)
	if color == "air" then return end
	for facename, facedata in pairs(wesh.face_construction) do
		local texture_vertices = wesh.get_texture_vertices(color)
		wesh.construct_face(rel_pos, canvas, texture_vertices, facename, facedata.vertices, facedata.normal)		
	end
end

function wesh.vertices_to_string()
	local output = {}
	for i, vertex in ipairs(wesh.vertices) do
		table.insert(output, "v " .. vertex.x .. " " .. vertex.y .. " " .. vertex.z .. "\n")
	end
	return table.concat(output)
end

-- ========================================================================
-- generic helpers
-- ========================================================================

function wesh.axis_min(pos1, pos2)
	local result = {}
	for axis, value in pairs(pos1) do
		result[axis] = math.min(value, pos2[axis])
	end
	return result
end

function wesh.axis_max(pos1, pos2)
	local result = {}
	for axis, value in pairs(pos1) do
		result[axis] = math.max(value, pos2[axis])
	end
	return result
end

function wesh.check_plain(text)
	if type(text) ~= "string" then return "" end
	text = text:gsub("^[^%w]*(.-)[^%w]*$", "%1")
	return text:gsub("[^%w]+", "_"):lower()
end

function wesh.copy_file(source, dest)
	local src_file = io.open(source, "rb")
	if not src_file then 
		return false, "copy_file() unable to open source for reading"
	end
	local src_data = src_file:read("*all")
	src_file:close()

	local dest_file = io.open(dest, "wb")
	if not dest_file then 
		return false, "copy_file() unable to open dest for writing"
	end
	dest_file:write(src_data)
	dest_file:close()
	return true, "files copied successfully"
end

function wesh.merge_tables(t1, t2)
	for _, value in pairs(t2) do 
		table.insert(t1, value)
	end
end

function wesh.notify(playername, message)
	minetest.chat_send_player(playername, "[wesh] " .. message)
end

function wesh.out_of_bounds(pos, canv_size)
	return pos.x < 1 or pos.x > canv_size
		or pos.y < 1 or pos.y > canv_size
		or pos.z < 1 or pos.z > canv_size
end

function wesh.serialize(object, max_wrapping)
	local function helper(obj, max_depth, depth, seen)
		if not depth then 
			depth = 0
		end
		if not seen then
			seen = {}
		end
		
		local wrap = max_depth and max_depth > depth or false
		
		local out = ""
		local t = type(obj)
		if t == nil then
			return "nil"
		elseif t == "string"   then
			return string.format("%q", obj)
		elseif t == "boolean" then
			return obj and "true" or "false"
		elseif t == "number" then
			if math.floor(obj) == obj then
				return string.format("%d", obj)
			else
				return tostring(obj)
			end
		elseif t == "table" then
			if seen[tostring(obj)] then
				error("[wesh] serialize(): Cyclic references not supported")
			end
			seen[tostring(obj)] = true;
			
			local output = { "{\n" }
			local post_table = string.rep("\t", depth) .. "}"
			local pre_key = string.rep("\t", depth + 1)
			local post_value = ",\n";
			
			if not wrap then
				output = { "{ " }
				post_table = "}"
				pre_key = ""
				post_value = ", "
			end
			
			for k, v in pairs(obj) do
				local key = k .. " = "
				if type(k) == "number" then
					-- remove numeric indices on purpose
					key = ""
				elseif type(k) ~= "string" or k:match("[^%w_]") then
					error("[wesh] serialize(): Unsupported array key " .. helper(k))
				end
				table.insert(output, pre_key)
				table.insert(output, key)
				table.insert(output, helper(v, max_depth, depth + 1, seen))
				table.insert(output, post_value)
			end
			table.insert(output, post_table)
			return table.concat(output)
		else
			error("[wesh] serialize(): Data type " .. t .. " not supported")
		end
	end
	
	return "return " .. helper(object, max_wrapping)
end

function wesh.traverse_matrix(callback, boundary, ...)
	if type(boundary) == "table" then
		for x = boundary.min.x, boundary.max.x do
			for y = boundary.min.y, boundary.max.y do
				for z = boundary.min.z, boundary.max.z do
					callback({x = x, y = y, z = z}, ...)
				end
			end
		end
	else
		for x = 1, boundary do
			for y = 1, boundary do
				for z = 1, boundary do
					callback({x = x, y = y, z = z}, ...)
				end
			end
		end
	end
end

wesh._init()
