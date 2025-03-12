extends Node3D

var current_rings = 8  # Number of vertical segments (rings)
var current_radial_segments = 16  # Number of horizontal segments (radial)
var multi_mesh_instance  # MultiMeshInstance3D for vertex markers
var sphere_mesh          # Mesh for the main sphere

func _ready():
	# Create MultiMeshInstance3D for vertex markers
	multi_mesh_instance = MultiMeshInstance3D.new()
	add_child(multi_mesh_instance)
	
	# Generate the initial sphere
	update_sphere(current_rings, current_radial_segments)

func update_sphere(rings, radial_segments):
	current_rings = rings
	current_radial_segments = radial_segments
	
	# Remove previous sphere mesh instance if it exists
	for child in get_children():
		if child is MeshInstance3D and child != multi_mesh_instance:
			child.queue_free()
	
	# Generate sphere mesh
	sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 1  # Ensure uniform radius
	sphere_mesh.height = sphere_mesh.radius * 2
	sphere_mesh.rings = rings
	sphere_mesh.radial_segments = radial_segments
	
	# Assign mesh to MeshInstance3D (main sphere)
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = sphere_mesh
	add_child(mesh_instance)
	
	# Update vertex markers using MultiMesh
	var points = get_mesh_vertices(mesh_instance.mesh)
	create_vertex_markers(points)

func get_mesh_vertices(mesh):
	var points = []
	
	# Extract vertices from the mesh surface
	var arrays = mesh.surface_get_arrays(0)
	
	if arrays.size() > Mesh.ARRAY_VERTEX:
		var vertices = arrays[Mesh.ARRAY_VERTEX]
		for vertex in vertices:
			points.append(vertex.normalized())  # Normalize positions to ensure they lie on the sphere's surface
	
	return points

func create_vertex_markers(points):
	# Create a new MultiMesh resource
	var multi_mesh = MultiMesh.new()
	
	# Set up MultiMesh properties
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.instance_count = points.size()
	
	# Assign MultiMesh to MultiMeshInstance3D
	multi_mesh_instance.multimesh = multi_mesh
	
	# Create a small sphere mesh for markers
	var marker_mesh = SphereMesh.new()
	marker_mesh.radius = 0.01  # Small radius for markers
	marker_mesh.height = marker_mesh.radius * 2
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.BLACK
	marker_mesh.surface_set_material(0, material)
	
	multi_mesh.mesh = marker_mesh
	
	# Set transforms for each instance in the MultiMesh
	for i in range(points.size()):
		var position = points[i] * 1.01  # Slightly offset to prevent z-fighting with the main sphere
		var transform = Transform3D(Basis(), position)
		multi_mesh.set_instance_transform(i, transform)

func _process(delta):
	if Input.is_action_just_pressed("increase_points"):
		update_sphere(min(current_rings + 2, 64), min(current_radial_segments + 4, 128))  # Maximum detail: rings=64, radial=128
	elif Input.is_action_just_pressed("decrease_points"):
		update_sphere(max(current_rings - 1, 1), max(current_radial_segments - 2, 1))  # Minimum detail: rings=4, radial=8
	elif Input.is_action_just_pressed("up_arrow"):
		update_sphere(0, current_radial_segments + 1)  # add a ring
	elif Input.is_action_just_pressed("down_arrow"):
		update_sphere(0, current_radial_segments - 1)  # add a ring
