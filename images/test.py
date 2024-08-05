def draw_circle_grid(cx, cy, r, grid_size):
    grid = [['.' for _ in range(grid_size)] for _ in range(grid_size)]
    
    for x in range(cx - r, cx + r + 1):
        for y in range(cy - r, cy + r + 1):
            if 0 <= x < grid_size and 0 <= y < grid_size:
                if (x - cx) ** 2 + (y - cy) ** 2 <= r ** 2:
                    grid[y][x] = 'O'
                else:
                    grid[y][x] = '.'
    
    for row in grid:
        print(" ".join(row))

# Example usage:
center_x = 5
center_y = 5
radius = 3
grid_size = 11  # Adjust the grid size to be large enough to accommodate the circle

draw_circle_grid(center_x, center_y, radius, grid_size)
