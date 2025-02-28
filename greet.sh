#!/bin/zsh

fastfetch --kitty-direct ~/Pictures/image.png

function greet_user() {
    h=$(date +%-H)

    if [[ $h -ge 0 && $h -lt 12 ]]; then
        greeting="Good Morning"
    elif [[ $h -ge 12 && $h -lt 18 ]]; then
        greeting="Good Afternoon"
    else
        greeting="Good Evening"
    fi  # <- Make sure `fi` is alone on this line

    # Fetch the current weather
    weather=$(curl -s --max-time 2 "wttr.in/Kota_Tinggi?format=1")

    # Handle cases where the weather data is unavailable
    if [[ -z "$weather" ]]; then
        weather="unavailable at the moment"
    fi  # <- This `fi` must also be correctly placed

    # Display the final greeting
    echo "$greeting, Master. The time is $(date "+%k:%M:%S, on %A, %d of %B, %Y")."
    echo "The weather is $weather as of right now."
    echo "What would you like to do, Master?"
}

# Call the function
greet_user
