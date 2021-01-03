tool
extends Node

export(Array, Dictionary) var used_positions
export(bool) var reset setget reset_array


func reset_array(b):
	used_positions = []


func _enter_tree():
	reset_array(true)

#test if a proposed placement intersects with any other placements from this or other instancing nodes
func test_placement_invalid(target_position, radius, grove_origin, grove_diameter, grove_spacing, originating_node):
	if used_positions.empty() and target_position.distance_to(grove_origin) > grove_diameter:
		record_placement(target_position, radius, originating_node)
		return(false) #this is the first placement and will always be valid
	else:
		for used_position in used_positions:
			if target_position.distance_to(used_position["position"]) < grove_spacing or target_position.distance_to(grove_origin) > grove_diameter:
				return(true) #invalid location

		record_placement(target_position, radius, originating_node)
		return(false)


#records the used placement
func record_placement(position, radius, originating_node):
	used_positions.push_back({"position": position, "radius": radius, "originating_node": originating_node})
	

#removes all used placements of the specified node, used when reinstancing within the Godot editor
func remove_placement(originating_node):
	var replacement_used_positions = []
	for used_position in used_positions:
		if used_position["originating_node"] != originating_node: #this may break if a node is moved or renamed, since Godot does not have node GUIDs. If so, simply use the "reset" button.
			replacement_used_positions.push_back(used_position)
	used_positions = replacement_used_positions #Replacing the array with a new array avoids issues with deleting items while iterating through them.
