#!/data/data/com.termux/files/usr/bin/env bash

############################
# Creator: Guilherme Rocha
############################

# setup apt package manager
apt update && apt upgrade -y

# setup pkg package manager
pkg upgrade

# installs termux api
pkg install termux-api

# intall basic software
apt install git starship wget \
  python net-tools zip unzip -y

# setup dotfiles
cat <<EOF > ~/.bashrc
eval "\$(starship init bash)"
bash "~/.bash_aliases"
EOF

cat <<EOF > ~/.inputrc
\$include /etc/inputrc
"\C-p":history-search-backward
"\C-n":history-search-forward

set colored-stats On
set completion-ignore-case On
set completion-prefix-display-length 3
set mark-symlinked-directories On
set show-all-if-ambiguous On
set show-all-if-unmodified On
set visible-stats On
EOF

# creates config folder
mkdir ~/.config

# donwloads my starship config
git clone https://gist.github.com/guilhermerochas/18fbef3de80eeca01d7d6987b11134ad starship_folder
mv starship_folder/starship.toml .config/starship.toml
rm -drf starship_folder

# installs pfetch
wget https://raw.githubusercontent.com/dylanaraps/pfetch/master/pfetch
chmod +x pfetch
mv pfetch ${PATH/:*/}/

# setup bash aliases
git clone https://gist.github.com/guilhermerochas/d068d5aed91057e59e6df3e28cb5cd2a aliases
mv aliases/aliasrc ~/.bash_aliases
rm -drf aliases

# installs micro editor
apt install micro

# create app folder
mkdir ~/Applications

# sources the bashrc file
source ~/.bashrc