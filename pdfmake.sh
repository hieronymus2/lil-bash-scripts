#!/bin/bash
# Scale images to 1200px width and combine them into a single PDF using ImageMagick

shopt -s nocaseglob
shopt -s nullglob

images=( *.{jpg,jpeg,png} )

if [ ${#images[@]} -gt 0 ]; then
    echo "Found ${#images[@]} image(s). Processing..."
    # if argument is passed name file after argument
    if [ $# -eq 1 ]; then
        magick "${images[@]}" -resize 1024x $1.pdf
        echo "Done! Saved to $1.pdf"
    else
        magick "${images[@]}" -resize 1024x document.pdf
        echo "Done! Saved to document.pdf"
    fi
else
    echo "Error: No .jpg, .jpeg, or .png files found in this directory."
fi

shopt -u nocaseglob
shopt -u nullglob
