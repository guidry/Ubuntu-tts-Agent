#!/bin/bash

#./piper --model /home/cashier/.local/share/piper/models/en_US-lessac-medium.onnx --text "Hello, this is a Piper TTS demo on Linux." --output_file piper_output.wav
#echo "Hello, this is a Piper TTS demo on Linux." | ./piper --model /home/cashier/.local/share/piper/models/en_US-lessac-medium.onnx --output_file /home/guidry/tmp/piper_output.wav
#./piper --model /home/cashier/.local/share/piper/models/en_US-lessac-medium.onnx --output_file /home/cashier/tmp/piper_output.wav --text "Hello, this is a Piper TTS demo on Linux."

echo "🟢 Installing Piper TTS and integrating with Speech Dispatcher..."

# Install dependencies
echo "🟡 Checking dependencies (wget, aplay)..."
sudo apt install -y wget alsa-utils libsox-dev
sudo apt install -y socat espeak-ng
# Download Piper binary
echo "⬇️ Downloading Piper binary..."
wget https://github.com/rhasspy/piper/releases/latest/download/piper_linux_x86_64.tar.gz -O /tmp/piper_linux_x86_64.tar.gz
tar -xvzf /tmp/piper_linux_x86_64.tar.gz -C /tmp/
sudo mv /tmp/piper /usr/local/bin/

# Download Piper model
echo "⬇️ Downloading Piper model (en_US-lessac-medium)..."
mkdir -p ~/.local/share/piper/models
wget https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx -O ~/.local/share/piper/models/en_US-lessac-medium.onnx
wget https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx.json -O ~/.local/share/piper/models/en_US-lessac-medium.onnx.json
wget https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/ryan/high/en_US-ryan-high.onnx -O ~/.local/share/piper/models/en_US-ryan-high.onnx
wget https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/ryan/high/en_US-ryan-high.onnx.json -O ~/.local/share/piper/models/en_US-ryan-high.onnx.json


# Create Piper wrapper script
echo "⚙️ Creating Piper wrapper script..."
echo '#!/bin/bash
MODEL="$HOME/.local/share/piper/models/en_US-ryan-high.onnx"
TMPFILE=$(mktemp /tmp/piper-tts-XXXXXX.wav)
# Get absolute path to this scripts directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PIPER_BIN="$SCRIPT_DIR/piper/piper"

if [ ! -x "$PIPER_BIN" ]; then
    echo "Error: Piper binary not found at $PIPER_BIN"
    exit 1
fi

if [ -t 0 ]; then
    # Input from argument
    TEXT="$*"
    echo "$TEXT" | "$PIPER_BIN" --model "$MODEL" --output_file "$TMPFILE"
else
    # Input from stdin
    "$PIPER_BIN" --model "$MODEL" --output_file "$TMPFILE"
fi

aplay "$TMPFILE" > /dev/null 2>&1
rm "$TMPFILE"
' > "piper-tts.sh"
sudo mv "piper-tts.sh" "/usr/local/bin/piper-tts.sh"
sudo chmod +x "/usr/local/bin/piper-tts.sh"

# Add Piper module to Speech Dispatcher
echo "⚙️ Configuring Speech Dispatcher module..."
sudo tee $HOME/.config/speech-dispatcher/modules/piper.conf > /dev/null <<'EOF'
GenericExecuteSynth "if command -v sox > /dev/null; then\
        SAFE_RATE=\$(echo \"$RATE\" | awk '{ if (\$1 < 0.8) print 0.8; else if (\$1 > 1.4) print 1.4; else print \$1 }');\
        PROCESS='sox -r 22050 -c 1 -b 16 -e signed-integer -t raw - -t wav - tempo '\$SAFE_RATE' pitch $PITCH norm';\
        OUTPUT='$PLAY_COMMAND';\
    elif command -v paplay > /dev/null; then\
        PROCESS='cat'; OUTPUT='$PLAY_COMMAND --raw --channels 1 --rate 22050';\
    else\
        PROCESS='cat'; OUTPUT='aplay -t raw -c 1 -r 22050 -f S16_LE';\
    fi;\
    echo '$DATA' | /usr/local/bin/piper/piper --model $HOME/.local/share/piper/models/en_US-ryan-high.onnx --output_raw | \$PROCESS | \$OUTPUT;"


GenericRateAdd 1
GenericPitchAdd 1
GenericVolumeAdd 1
GenericRateMultiply 1
GenericPitchMultiply 1000

AddVoice "en-us" "MALE1" "en_US-ryan-high.onnx"
EOF

sudo tee -a $HOME/.config/speech-dispatcher/speechd.conf > /dev/null <<'EOF'
# Piper TTS
AddModule "piper" "sd_generic" "piper.conf"
DefaultVoiceType  "MALE1"
DefaultLanguage   en-us
DefaultModule   piper

EOF

# Set Piper as default module
#echo "⚙️ Setting Piper as default module..."
#CONFIG_FILE="$HOME/.config/speech-dispatcher/speechd.conf"
#mkdir -p "$(dirname "$CONFIG_FILE")"
#echo "DefaultModule piper" > "$CONFIG_FILE"

# Restart Speech Dispatcher
echo "🔄 Restarting Speech Dispatcher..."
systemctl --user restart speech-dispatcher

# Test
echo "✅ Test: Saying 'Piper TTS is now ready.'"
spd-say "Piper TTS is now ready."

echo "✅ All done! Piper TTS is now working with Speech Dispatcher."
