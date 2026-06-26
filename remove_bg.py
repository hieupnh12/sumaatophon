from PIL import Image

def remove_white(img_path):
    img = Image.open(img_path)
    img = img.convert("RGBA")
    datas = img.getdata()
    newData = []
    
    # We want to keep the inner white pixels (like robot body).
    # Flood-fill from 0,0 is much better.
    # Since we have Pillow, we can use ImageDraw floodfill or simple BFS.
    pass

def flood_fill_transparent(img_path, out_path):
    img = Image.open(img_path).convert("RGBA")
    width, height = img.size
    
    # Target color: white or near white
    def is_bg(r, g, b, a):
        return r > 240 and g > 240 and b > 240

    pixels = img.load()
    
    # BFS queue
    q = []
    
    # start from edges
    for x in range(width):
        q.append((x, 0))
        q.append((x, height - 1))
    for y in range(height):
        q.append((0, y))
        q.append((width - 1, y))
        
    visited = set(q)
    
    while q:
        x, y = q.pop(0)
        r, g, b, a = pixels[x, y]
        if is_bg(r, g, b, a):
            pixels[x, y] = (255, 255, 255, 0)
            
            # Add neighbors
            for dx, dy in [(1,0), (-1,0), (0,1), (0,-1)]:
                nx, ny = x + dx, y + dy
                if 0 <= nx < width and 0 <= ny < height:
                    if (nx, ny) not in visited:
                        visited.add((nx, ny))
                        q.append((nx, ny))
                        
    img.save(out_path, "PNG")

flood_fill_transparent("assets/images/guest_illustration.png", "assets/images/guest_illustration.png")

