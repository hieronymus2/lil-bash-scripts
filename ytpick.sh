#!/bin/bash

# script using yt-dlp and ffmpeg to search for youtube songs to download or download and format playlists

# burn audio from directories, requires cdrtools:
# cdrecord -v dev=/dev/sr0 speed=8 -audio -pad *.wav

show_help() {
    echo "Uses:"
    echo "-n SONG to search for a song"
    echo "-p PLAYLIST_URL to download a formatted playlist"
    echo "by default, ytpick uses interactive search"
}




do_query() {
    # Clear arrays each round to prevent leftover data
    titles=()
    ids=()
    urls=()
    count=1

    # Read exactly 3 lines sequentially for every video
    while IFS= read -r title && IFS= read -r id && IFS= read -r url; do
        # Ignore empty metadata returns
        [ -z "$title" ] && continue

        echo "[$count] $title"
        
        titles+=("$title")
        ids+=("$id")
        urls+=("$url")
        ((count++))
    done <<< "$results"

    # Get user choice
    echo ""
    read -p "Select a number to download (1-$((count-1))): " choice

    if [[ $choice -ge 1 && $choice -lt $count ]]; then
        selected_title=${titles[$((choice-1))]}
        selected_url=${urls[$((choice-1))]}
        
        echo -e "\nDownloading: $selected_title..."
        
        yt-dlp -x --audio-format mp3 "$selected_url"
    else
        echo "Invalid selection."
    fi

    echo ""
}




name() {
    echo -e "\nSearching for: $1...\n"

    results=$(yt-dlp "ytsearch5:$1" \
        --no-playlist \
        --flat-playlist \
        --print "%(title)s" \
        --print "%(id)s" \
        --print "%(url)s")

    do_query
}




repeat_search() {
    repeat=1

    while [ $repeat -eq 1 ]; do
        read -p "Enter search query: " query

        echo -e "\nSearching for: $query...\n"

        results=$(yt-dlp "ytsearch5:$query" \
            --no-playlist \
            --flat-playlist \
            --print "%(title)s" \
            --print "%(id)s" \
            --print "%(url)s")

        do_query

        read -r -p "Download another song? [y/N] " response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
        then
            repeat=1
        else
            repeat=0
        fi
        echo ""
    done
}





playlist() {
    # Check if an argument was passed
    if [ -z "$1" ]; then
        echo "Error: Missing URL. Usage: playlist <URL>" >&2
        return 1
    fi

    local url="$1"
    local title

    # fetch playlist title
    title=$(yt-dlp --skip-download --no-warnings --flat-playlist --print "playlist:%(title)s" "$url" 2>/dev/null)
    
    # Check if a title was successfully retrieved and isn't empty/NA
    if [ -n "$title" ] && [ "$title" != "NA" ]; then
        mkdir -p "$title"
        echo "Created directory: $title"
        cd "$title"
        # download playlist in created folder
        yt-dlp -o "%(playlist_index)02d - %(title)s.%(ext)s" -x --audio-format mp3 --no-warnings "$url"
    else
        echo "Error: Could not retrieve playlist title. Check your URL or connection." >&2
        return 1
    fi
}




while getopts "n:p:h" opt; do
  case $opt in
    n) name "$OPTARG" ;;
    p) playlist "$OPTARG" ;;
    h) show_help; exit 0 ;;
    \?) echo "Invalid usage"; exit 1 ;;
  esac
done

shift $((OPTIND - 1))

if [ $# -eq 0 ]; then
    repeat_search
fi

if [ $# -eq 1 ]; then
    yt-dlp -x --audio-format mp3 $1
fi

echo "Exiting..."
