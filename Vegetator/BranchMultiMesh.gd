tool
class_name BranchMultiMesh
extends MultiMesh

var normal = Vector3(1,0,0)

# build the branch mesh for use by the instancer. By default this is a simple 3-sided tapered cylinder.
func _init(vertices, color):
	var surface_tool = SurfaceTool.new();
	var material  = SpatialMaterial.new()
	
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES);
	
	for i in vertices:
		surface_tool.add_normal(normal)
		surface_tool.add_vertex(i)
	
	# apply a simple colored material. This can be replaced depending on your visual style.
	material.albedo_color = color
	material.params_cull_mode = SpatialMaterial.CULL_DISABLED
	surface_tool.set_material(material)
	
	self.mesh = surface_tool.commit();
