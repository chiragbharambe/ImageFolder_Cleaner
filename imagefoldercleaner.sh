#!/bin/bash
input_folder=$(pwd)
icons_folder="$input_folder/icons"
corrupted_folder="$input_folder/corrupted"

progress_bar() {
    local current=$1
    local total=$2
    local width=50
    local progress=$((current * width / total))
    local filled=$(printf "%${progress}s" "")
    local empty=$(printf "%$((width - progress))s" "")
    echo -ne "[${filled// /#}${empty// /-}] $current/$total\r"
}

# Ensure the folders exist
[ ! -d "$icons_folder" ] && mkdir "$icons_folder"
[ ! -d "$corrupted_folder" ] && mkdir "$corrupted_folder"

# Count total images
image_count=$(find "$input_folder" -maxdepth 1 -type f -exec file --mime-type {} \; | grep -E 'image/jpeg|image/png' | wc -l)
current_count=0

# Icon sizes
declare -a icon_sizes=("200x200" "128x128" "160x160" "320x320" "500x500" "534x534" "16x16" "24x24" "32x32" "48x48" "57x57" "60x60" "64x64" "72x72" "76x76" "96x96" "114x114" "120x120" "128x128" "144x144" "152x152" "160x160" "167x167" "180x180" "192x192" "200x200" "256x256" "320x320" "400x400" "480x480" "500x500" "512x512" "534x534" "600x600")

# Processing images
for img in "$input_folder"/*; do
    if [[ -f $img && $(file --mime-type -b "$img") == image/* ]]; then
        # Check image integrity
        if ! convert "$img" -ping - >/dev/null 2>&1; then
            echo "Moving corrupted image to corrupted folder - $img"
            mv "$img" "$corrupted_folder/"
            continue
        fi

        # Extract image dimensions
        dimensions=$(identify -format "%wx%h" "$img" 2>/dev/null)

        # Move images with specified dimensions to icons folder
        for size in "${icon_sizes[@]}"; do
            if [ "$dimensions" == "$size" ]; then
                mv "$img" "$icons_folder"/
                break # exit the loop once a match is found
            fi
        done

        # Move images with width and height below 240x240 to icons folder
        width=$(identify -format "%w" "$img" 2>/dev/null)
        height=$(identify -format "%h" "$img" 2>/dev/null)
        if [[ $width -lt 240 && $height -lt 240 ]]; then
            mv "$img" "$icons_folder"/
        fi
    fi

    # Update progress bar
    current_count=$((current_count+1))
    progress_bar $current_count $image_count
done

echo -e "\nProcessing Complete!"
