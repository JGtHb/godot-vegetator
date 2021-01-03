tool
extends MultiMeshInstance

export(Array, Dictionary) var requested_placements
export(Array) var requested_transforms

export(int, 0, 20) var leaf_interpolation_factor = 3
export(float, 0, 5) var leaf_min_spacing = .3
export(Color) var leaf_color = Color(0, 1, 0, 1)
export(Array) var leaf_vertices = [
	Vector3(0, .25, 0),
	Vector3(.125, 0, .0125),
	Vector3(0, -.125, 0),
	Vector3(-.125, 0, .0125),
	Vector3(0, .025, 0)
]
export(bool) var reset setget reset


func _enter_tree():
	reset(true)


func reset(_b):
	self.multimesh.instance_count = 0
	requested_placements = []
	requested_transforms = []


#place the leaves in the positions requested
func instance_leaves():
	self.multimesh = LeafMultiMesh.new(leaf_vertices, leaf_color)
	self.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	self.multimesh.instance_count = 0
	self.multimesh.instance_count = requested_placements.size()

	for i in self.multimesh.instance_count:
		var offset = Transform(Basis(), get_node(requested_placements[i]["originating_node"]).get_global_transform().origin - self.get_global_transform().origin)
		var placement = Transform(requested_placements[i]["angle"], requested_placements[i]["position"])
		self.multimesh.set_instance_transform(i, offset * placement)


#add additional interpolated leaf placements to increase foliage density without requiring excessive branches
func interpolate_placements(requesting_node):
	#build a filtered array of the requested placements pertinent to the requesting node
	var filtered_requested_placements = []
	for requested_placement in requested_placements:
		if requested_placement["originating_node"] == requesting_node:
			filtered_requested_placements.push_back(requested_placement)

	for requested_placement in filtered_requested_placements:
		#get potential interpolation targets for this leaf that are on the same plant
		var valid_interpolation_targets = []
		for interpolation_target in filtered_requested_placements:
			if interpolation_target["treeid"] == requested_placement["treeid"]:
				valid_interpolation_targets.push_back(interpolation_target)
		
		#loop through the potential interpolation targets looking for one that will meet the requested criteria
		var found_interpolations = 0
		var attempts = 0
		while found_interpolations < leaf_interpolation_factor and attempts < valid_interpolation_targets.size():
			var interpolation_target = valid_interpolation_targets[rand_range(0,valid_interpolation_targets.size())] #pick a random valid target
			
			#if a valid interpolation target is found, add it to the list of placements with a treeid of -1. This prevents interpolations from being performed on top of other interpolations.
			if interpolation_target["position"].distance_to(requested_placement["position"])/2 > leaf_min_spacing:
				var interpolated_requested_placement = (requested_placement["position"] + interpolation_target["position"]) / 2
				var interpolated_requested_angle = (requested_placement["angle"] * interpolation_target["angle"])
				requested_placements.push_back({"position": interpolated_requested_placement, "angle": interpolated_requested_angle, "treeid": -1, "originating_node": requested_placement["originating_node"]})
				found_interpolations += 1
			attempts += 1

#register a leaf origin requested by a branch
func request_placement(position, angle, treeid, originating_node):
	requested_placements.push_back({"position": position, "angle": angle, "treeid": treeid, "originating_node": originating_node})

#remove requested leaf positions, used when reinstancing a plant directly within the Godot editor.
func remove_placements(originating_node):
	var replacement_requested_placements = []
	for requested_placement in requested_placements:
		if requested_placement["originating_node"] != originating_node: #Filter out all used positions that come from the current node. Note that this will break if the node is renamed, not sure how to work around this without a GUID
			replacement_requested_placements.push_back(requested_placement)
	requested_placements = replacement_requested_placements #Replacing the array with a new arary avoids issues with deleting items while iterating through them.
