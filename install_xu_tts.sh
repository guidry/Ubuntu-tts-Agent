#!/bin/bash
sudo apt-get -y install xclip
sudo apt-get  -y  install festival
sudo apt-get  -y  install festvox-us1 festvox-us2 festvox-us3
sudo apt-get  -y  install libttspico-utils 
sudo apt-get -y install xsel libnotify-bin libttspico0 libttspico-utils libttspico-data libwww-perl libwww-mechanize-perl libhtml-tree-perl sox libsox-fmt-mp3
#git clone https://github.com/Glutanimate/simple-google-tts.git
#sudo mv simple-google-tts/* /opt/xu_tts/
echo '
#!/bin/bash
#if [ -z $running ]
#then
#read it festival
#xclip -out -selection clipboard >> /tmp/file.txt
#xclip -o | spd-say "If you hear Pipers voice "

#spd-say "$(xclip -o)"
#xclip -o | /usr/local/bin/piper-tts.sh
#xclip -o | /opt/xu_tts/simple_google_tts en
#else
#kill it

#killall spd-say
#spd-say "Stop speaking."
#killall spd-say
#killall piper-tts.sh; 
#killall simple_google_tts
#killall pico2wave;
#killall festival;killall aplay;killall sox;sleep .1;killall aplay
#killall pw-play
#rm /tmp/test.wav
#rm /tmp/file.txt
#fi


PIPER_CMD="/usr/local/bin/piper/piper"
MODEL="/home/guidry/.local/share/piper/models/en_US-lessac-medium.onnx"
PIDFILE="/tmp/xu_tts_piper.pid"


# Kill all aplay processes playing raw data
#if pgrep -x aplay > /dev/null; then
#    echo "🔇 Stopping aplay playback..."
#    pkill -x aplay
#    exit 0
#fi

# Kill previous Piper playback if running
if [ -f "$PIDFILE" ]; then
    OLD_PID=$(cat "$PIDFILE")
    if [[ "$OLD_PID" =~ ^[0-9]+$ ]]; then
        if ps -p $OLD_PID > /dev/null; then
            echo "Stopping previous Piper (PID $OLD_PID)..."
            kill $OLD_PID            
            sleep 0.3  # small delay to ensure kill takes effect
            exit 0
        fi
    else
        echo "PID file exists but contains invalid data: $OLD_PID. Ignoring."
    fi
fi

# Get selection content
CLIP="$(xclip -selection primary -o 2>/dev/null)"

# Fallback to clipboard if primary is empty
#if [ -z "$CLIP" ]; then
#    CLIP="$(xclip -selection clipboard -o 2>/dev/null)"
#fi

if [ -z "$CLIP" ]; then
    echo "Selection is empty. Nothing to read."
    echo "Please select some text to read." | $PIPER_CMD --model "$MODEL" --output_raw | aplay -t raw -c 1 -r 22050 -f S16_LE &
    exit 1
fi

echo "Speaking clipboard content: $CLIP"

# Run Piper in background and store PID
echo "$CLIP" | $PIPER_CMD --model "$MODEL" --output_raw | aplay -t raw -c 1 -r 22050 -f S16_LE &

#SPEED=1.0  # 0.8 = 80% speed, slower

#echo "$CLIP" | $PIPER_CMD --model "$MODEL" --output_raw | \
#sox -t raw -b 16 -e signed -c 1 -r 22050 - -t raw - tempo "$SPEED" | \
#aplay -t raw -c 1 -r 22050 -f S16_LE &

PIPER_PID=$!
echo $PIPER_PID > "$PIDFILE"
' > xu_tts.sh

echo '
#!/bin/bash
pico2wave -l "en-US" -w=/tmp/test.wav "$1"
aplay /tmp/test.wav
rm /tmp/test.wav' > golden_dict_tts.sh

sudo mkdir -p /opt/xu_tts
sudo mv xu_tts.sh  /opt/xu_tts/xu_tts.sh
sudo mv golden_dict_tts.sh  /opt/xu_tts/golden_dict_tts.sh
sudo chmod a+x /opt/xu_tts/xu_tts.sh
sudo mv Gnome_User_Speech.svg  /usr/share/icons

echo "
[Desktop Entry]
Type=Application
Version=1.0
Name=Text to speech
Name[zh_TW]=Text to speech
GenericName=Text to speech
GenericName[zh_TW]=Text to speech
Comment=Text to speech
Comment[zh_TW]=Text to speech
Exec=/opt/xu_tts/xu_tts.sh
Icon=/usr/share/icons/Gnome_User_Speech.svg
Terminal=false
Keywords=tts
Categories=GTK;GNOME;AudioVideo;
" > xu_tts.desktop 

sudo mv xu_tts.desktop /usr/share/applications/xu_tts.desktop
sudo update-desktop-database 
echo "Xu text to speech installed."

# delete download
#sudo rm -rf simple-google-tts
# delete self
rm -- "$0"
