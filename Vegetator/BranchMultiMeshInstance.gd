tool
extends MultiMeshInstance

export(String) var starting_rule = ">1"
export(String) var rule_1 = "[2][2][2]"
export(String) var rule_2 = "XYZ>1"
export(String) var rule_3 = ""
export(String) var rule_4 = ""
export(String) var rule_5 = ""
export(int) var rule_generations = 4

export(Color) var branch_color = Color(1, 1, 1, 1)
export(float, 0.1, 10) var branch_start_length = 2
export(float, 0.1, 2) var branch_length_factor = .9
export(float, 0.1, 3) var branch_start_diameter = .5
export(float, 0.1, 2) var branch_diameter_factor = 0.6

export(float, 0, 180) var max_rotation = 40

export(int) var grove_diameter = 20
export(int) var grove_treecount = 20
export(int) var grove_spacing = 5

export(int) var tree_rng_seed = 0
export(int) var grove_rng_seed = 0

export(NodePath) var target_surface
export(NodePath) var placement_manager
export(NodePath) var leaf_manager

export(bool) var reinstance setget reinstance

func _ready():
	instance_multimesh()

func reinstance(_b):
	get_node(placement_manager).remove_placement(self.get_path()) #remove previous positions taken by this node
	get_node(leaf_manager).remove_placements(self.get_path()) #remove previous leaves requested by this node
	instance_multimesh()

#place and transform each branch for each plant position
func instance_multimesh():
	var target_positions = register_target_positions() #set the target positions for each plant and register them with the placement manager.
	var branch_positions = build_tree_mesh(target_positions) #build the series of transformations on each branch to create each unique tree.
	
	#defines the branch mesh and gets the final branch from BranchMultiMesh. By default this is a simple 3-sided cylinder.
	var start_radius = branch_start_diameter/2
	var start_top_radius = start_radius * branch_diameter_factor * 1.1

	var topright_point = Vector3(start_top_radius, branch_start_length/branch_length_factor, start_top_radius) #top right
	var topleft_point = Vector3(-start_top_radius, branch_start_length/branch_length_factor, start_top_radius) #top left
	var topback_point = Vector3(0, branch_start_length/branch_length_factor, -start_top_radius) #top back

	var bottomright_point = Vector3(start_radius, 0, start_radius) #bottom right
	var bottomleft_point = Vector3(-start_radius, 0, start_radius) #bottom left
	var bottomback_point = Vector3(0, 0, -start_radius) #bottom back

	var branch_vertices = [ 
		#front face
		topright_point, bottomright_point, topleft_point,
		bottomright_point, bottomleft_point, topleft_point,
		#backright face
		topright_point, bottomright_point, topback_point,
		bottomback_point, topback_point, bottomright_point,
		#backleft face
		topleft_point, bottomleft_point, topback_point,
		bottomback_point, topback_point, bottomleft_point,
	]
	
	self.multimesh = BranchMultiMesh.new(branch_vertices, branch_color)
	
	#apply the transformations for each branch
	self.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	self.multimesh.instance_count = branch_positions.size()
	
	var i = 0
	for branch in branch_positions:
		var transform = Transform(branch["angle"] * Basis().scaled(Vector3(branch["diameter_factor"],branch["length_factor"],branch["diameter_factor"])), branch["position"])
		self.multimesh.set_instance_transform(i, transform)
		i += 1
	
	get_node(leaf_manager).interpolate_placements(self.get_path()) #request interpolated leaf placements for the trees on this nodes. This greatly increases the density of foliage without requiring a branch for each leaf.
	get_node(leaf_manager).instance_leaves() #place the leaves for these trees in the scene


func register_target_positions():
	#set up the RNG for positioning
	var rng_grove = RandomNumberGenerator.new()
	rng_grove.seed = grove_rng_seed
	
	#get the positioning data from the target mesh. If you have a very low-poly target mesh you could use the interpolation function in LeafMultiMeshInstance to place plants between vertices.
	var parent_mesh = get_node(target_surface).mesh
	var parent_mesh_data = MeshDataTool.new()
	parent_mesh_data.create_from_surface(parent_mesh, 0)
	var available_vertices = range(0,parent_mesh_data.get_vertex_count())
	var grove_origin = self.get_global_transform().origin
	var target_origin = get_node(target_surface).get_global_transform().origin
	var target_positions = []
	
	#find target positions for each plant within the constraints provided by the user
	for i in grove_treecount:
		var placing_tree = true
		while placing_tree and available_vertices.size() > 0:
			#select a random position from the list of possible positions that have not yet been tested
			var random_selection = rng_grove.randi() % available_vertices.size()
			var target_vertex = available_vertices[random_selection]
			var target_position = parent_mesh_data.get_vertex(target_vertex)
			available_vertices.remove(random_selection)
			
			#test the found position with the PlacementManager to see if it is valid
			var position_invalid = false
			position_invalid = get_node(placement_manager).test_placement_invalid(target_position, 2, grove_origin, grove_diameter, grove_spacing, self.get_path())
			if !position_invalid:
				target_positions.append(target_position-grove_origin+target_origin)
				placing_tree = false
 
	return target_positions

#iterate through the L-System and generate the transformations needed for each branch on each tree.
func build_tree_mesh(target_positions):
	var branch_positions = []
	var l_system_string = generate_l_system()

	for i in target_positions.size():
		var rng_tree = RandomNumberGenerator.new()
		rng_tree.seed = tree_rng_seed+i

		var current_position = target_positions[i]
		var current_angle = Basis()
		var current_length = branch_start_length
		var current_length_factor = branch_length_factor
		var current_diameter_factor = branch_diameter_factor
		
		var pushpop_stack = []
		
		for character in l_system_string:
			var target_rotation_free = deg2rad(rng_tree.randf_range(-max_rotation,max_rotation))
			var target_rotation_clamped = deg2rad(rng_tree.randf_range(0,max_rotation))
			match character:
				'X': current_angle = current_angle.rotated(Vector3(1,0,0), target_rotation_free)
				'Y': current_angle = current_angle.rotated(Vector3(0,1,0), target_rotation_free)
				'Z': current_angle = current_angle.rotated(Vector3(0,0,1), target_rotation_free)
				
				'R': current_angle = current_angle.rotated(Vector3.RIGHT, target_rotation_clamped)
				'L': current_angle = current_angle.rotated(Vector3.LEFT, target_rotation_clamped)
				'B': current_angle = current_angle.rotated(Vector3.BACK, target_rotation_clamped)
				'F': current_angle = current_angle.rotated(Vector3.FORWARD, target_rotation_clamped)
				'U': current_angle = current_angle.rotated(Vector3.UP, target_rotation_clamped)
				'D': current_angle = current_angle.rotated(Vector3.DOWN, target_rotation_clamped)
				
				'[':
					pushpop_stack.push_back({"position": current_position, "angle": current_angle, "length": current_length, "length_factor": current_length_factor, "diameter_factor": current_diameter_factor})
				']':
					if pushpop_stack.size() == rule_generations: #if this is the end of a branch, request a leaf
						get_node(leaf_manager).request_placement(current_position, current_angle, i, self.get_path())
					var pop = pushpop_stack.pop_back()
					current_position = pop["position"]
					current_angle = pop["angle"]
					current_length = pop["length"]
					current_length_factor = pop["length_factor"]
					current_diameter_factor = pop["diameter_factor"]
					
				'>':
					var end_point = Transform(current_angle, current_position).translated(Vector3(0,current_length,0))

					branch_positions.push_back({"position": current_position, "angle": current_angle, "length_factor": current_length_factor, "diameter_factor": current_diameter_factor})

					current_position = end_point.origin
					current_length = branch_start_length * current_length_factor
					current_length_factor *= branch_length_factor
					current_diameter_factor *= branch_diameter_factor

	return(branch_positions)

#iterate through the L System string based on the generations requested
func generate_l_system():
	var l_system_string = starting_rule
	for i in (rule_generations):
		l_system_string = l_system_string.replace("1",rule_1)
		l_system_string = l_system_string.replace("2",rule_2)
		l_system_string = l_system_string.replace("3",rule_3)
		l_system_string = l_system_string.replace("4",rule_4)
		l_system_string = l_system_string.replace("5",rule_5)

	#Cleanup the final string. Only useful for making human-readable when debugging
	l_system_string = l_system_string.replace("1","")
	l_system_string = l_system_string.replace("2","")
	l_system_string = l_system_string.replace("3","")
	l_system_string = l_system_string.replace("4","")
	l_system_string = l_system_string.replace("5","")
	return l_system_string
