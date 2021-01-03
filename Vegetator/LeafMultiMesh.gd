tool
class_name LeafMultiMesh
extends MultiMesh

var normal = Vector3(0,0,-1)

# build the leaf mesh for use by the instancer. By default this is a simple 2-polygon mesh.
func _init(vertices, color):
	var surface_tool = SurfaceTool.new();
	var material  = SpatialMaterial.new()
	
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLE_FAN);
	
	for i in vertices:
		surface_tool.add_normal(normal)
		surface_tool.add_vertex(i)

	# apply a simple colored material. This can be replaced depending on your visual style.
	material.albedo_color = color
	material.params_cull_mode = SpatialMaterial.CULL_DISABLED
	surface_tool.set_material(material)
	
	self.mesh = surface_tool.commit();
