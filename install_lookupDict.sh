#!/bin/bash
#sudo apt-get install -y midori
sudo apt-get -y install xclip
# Check if the download was successful
if [ $? -eq 0 ]; then
    echo "Midori 瀏覽器成功下載了，可供查字典使用"
else
    echo "Midori 瀏覽器下載失敗，請另行手動設定"    
fi
# Install the .deb package using dpkg
echo "Installing Midori..."
sudo dpkg -i $DEB_FILE
# Fix any missing dependencies
sudo apt --fix-broken install -y
# Clean up by removing the downloaded .deb file
rm $DEB_FILE
echo "Midori installation completed!"


echo '
#!/bin/bash
sel=$(xclip -o)
url="https://www.onelook.com/?w=$sel&ls=a"
midori $url
sleep 1s && kill $$ &' > look_up_dict.sh
sudo mkdir -p /opt/xu_tts
sudo mv look_up_dict.sh  /opt/xu_tts/look_up_dict.sh
sudo chmod a+x /opt/xu_tts/look_up_dict.sh
sudo mv sem-soc-net.svg  /usr/share/icons
echo "
[Desktop Entry]
Type=Application
Version=1.0
Name=One look Dictionary
Name[zh_TW]=上網查單字
GenericName=One look Dictionary
GenericName[zh_TW]=上網查單字
Comment=One look Dictionary
Comment[zh_TW]=上網查單字
Exec=/opt/xu_tts/look_up_dict.sh
Icon=/usr/share/icons/sem-soc-net.svg
Terminal=false
Keywords=Dictionary
Categories=GTK;GNOME;AudioVideo;
" > look_up_dict.desktop 

sudo mv look_up_dict.desktop /usr/share/applications/look_up_dict.desktop

sudo update-desktop-database 
echo "look_up_dict installed."
# delete self
rm -- "$0"
