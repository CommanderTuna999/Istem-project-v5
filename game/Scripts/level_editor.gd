@tool
extends TileMapLayer

@export var new_tileset: TileSet

@export var convert_now := false:
	set(value):
		if value:
			call_deferred("convert_to_new_terrain")


func convert_to_new_terrain() -> void:
	if new_tileset == null:
		print("Assign the new Level 1 TileSet first.")
		return

	# Remember the exact shape of the old level.
	var old_cells: Array[Vector2i] = get_used_cells()

	print("Found ", old_cells.size(), " old terrain cells.")

	# Remove the old tile graphics.
	clear()

	# Swap to the working terrain-enabled TileSet.
	tile_set = new_tileset

	# Repaint the SAME coordinates using:
	# Terrain Set 0
	# Rock Terrain 0
	set_cells_terrain_connect(
		old_cells,
		0,
		0,
		true
	)

	print("Terrain conversion complete.")
