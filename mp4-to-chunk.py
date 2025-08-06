import cv2
import os
import json
import time
from concurrent.futures import ProcessPoolExecutor
import multiprocessing

# 16-color CC:Tweaked palette
CC_COLORS = {
    (0, 0, 0): '0',        # black
    (255, 255, 255): 'f',  # white
    (255, 0, 0): 'c',      # red
    (0, 255, 0): 'a',      # lime
    (0, 0, 255): '9',      # blue
    (255, 255, 0): 'e',    # yellow
    (0, 255, 255): 'b',    # cyan
    (255, 0, 255): 'd',    # magenta
    (192, 192, 192): '7',  # light gray
    (128, 128, 128): '8',  # gray
    (128, 0, 0): '4',      # dark red
    (0, 128, 0): '2',      # dark green
    (0, 0, 128): '1',      # dark blue
    (128, 128, 0): '6',    # brown
    (0, 128, 128): '3',    # teal
    (128, 0, 128): '5',    # purple
}

def closest_color(r, g, b):
    return min(CC_COLORS, key=lambda c: (int(c[0]) - int(r))**2 + (int(c[1]) - int(g))**2 + (int(c[2]) - int(b))**2)

def frame_to_blit_array(image_array):
    height, width, _ = image_array.shape
    lines = []
    for y in range(height):
        text = ""
        textColor = ""
        bgColor = ""
        for x in range(width):
            r, g, b = image_array[y, x]
            cc_char = "8"  # full block char
            color = CC_COLORS[closest_color(r, g, b)]
            text += cc_char
            textColor += color
            bgColor += color
        lines.append((text, textColor, bgColor))
    return lines

def chunk_frames(frames, chunk_size=500 * 1024):
    chunks = []
    current_chunk = []
    current_size = 0

    for frame in frames:
        encoded = json.dumps(frame)
        size = len(encoded.encode('utf-8'))

        if current_size + size > chunk_size and current_chunk:
            chunks.append(current_chunk)
            current_chunk = []
            current_size = 0

        current_chunk.append(frame)
        current_size += size

    if current_chunk:
        chunks.append(current_chunk)

    return chunks

def get_resolution_from_user():
    print("Enter monitor resolution (width x height), e.g. 39x19 or 78x38")
    while True:
        res = input("Resolution: ").lower().strip().replace(" ", "")
        if "x" not in res:
            print("Invalid format. Use format like 39x19")
            continue
        try:
            w, h = map(int, res.split("x"))
            if w < 1 or h < 1 or w > 164 or h > 100:
                print("Width or height out of reasonable range. Try something like 39x19.")
                continue
            return w, h
        except:
            print("Invalid numbers. Try again.")

def convert_video(input_file, output_folder, width, height, max_chunk_kb=500):
    cap = cv2.VideoCapture(input_file)
    if not cap.isOpened():
        print("Could not open video file.")
        return

    os.makedirs(output_folder, exist_ok=True)

    print("Reading and resizing frames...")
    frame_list = []
    success, image = cap.read()
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    frame_index = 0
    start_time = time.time()

    while success:
        resized = cv2.resize(image, (width, height), interpolation=cv2.INTER_AREA)
        frame_list.append(resized)

        # Live preview
        preview = cv2.resize(resized, (width * 10, height * 10), interpolation=cv2.INTER_NEAREST)
        cv2.imshow("Preview (Press Q or ESC to stop)", preview)
        key = cv2.waitKey(1)
        if key in [27, ord('q')]:
            print("User stopped early.")
            break

        frame_index += 1
        if frame_index % 10 == 0:
            print(f"Read {frame_index}/{total_frames} frames")

        success, image = cap.read()

    cv2.destroyAllWindows()
    print(f"Finished reading {len(frame_list)} frames in {time.time() - start_time:.1f}s")

    print("Converting frames to CC format using multicore processing...")
    with ProcessPoolExecutor(max_workers=multiprocessing.cpu_count()) as executor:
        frames = list(executor.map(frame_to_blit_array, frame_list))

    print("Splitting into chunks...")
    chunks = chunk_frames(frames, max_chunk_kb * 1024)

    for i, chunk in enumerate(chunks):
        with open(os.path.join(output_folder, f"chunk_{i+1}.lua"), "w") as f:
            f.write("return " + json.dumps(chunk))

    print(f"Done. {len(chunks)} chunks saved to '{output_folder}'.")

# ---- Main Runner ----
if __name__ == "__main__":
    input_video = input("Enter input video filename (e.g. video.mp4): ").strip()
    output_dir = input("Enter output folder name (default: chunks): ").strip() or "chunks"
    width, height = get_resolution_from_user()

    convert_video(input_video, output_dir, width, height)
