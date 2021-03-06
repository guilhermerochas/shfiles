#!/bin/sh

# This command removes all broken docker images that were not able to be built
# sometimes when building docker images, you can commit some mistake which will cause
# an stopped container and an broken image with a <none> tag.
# this function cleans all containers and images that were broken on the build process
function docker_clean() {
  none_images=$(docker images | tail -n +2 | awk '$2=="<none>" { print $3 }')
  for image in $none_images; do
    containers=$(docker ps -a -f ancestor="$image" | tail -n +2 | awk '{print $1}')
    for container in $containers; do
      docker rm "$container"
    done
    docker rmi $"image"
  done
}

# downloads m3u8 file joining all the TS files into a mp4 video
function download() {
  if [[ -n $1 ]]; then
    if [[ -x $(command -v ffmpeg) ]]; then
      ffmpeg -i "$1" -bsf:a aac_adtstoasc -vcodec copy -c copy -crf 50 "video-$(echo $RANDOM | md5sum | head -c 9).mp4"
    fi
  fi
}

# downloads only video output from a MPEG-DASH video stream
function streamer() {
  if [[ -x $1 ]]; then
    echo "please provide a mpd file as an input for streaming"
    return 1
  fi

  if [[ -x $(command -v ffmpeg) ]]; then
    ffmpeg -i "$1" -map 0:1 -map 0:2 -codec copy "$HOME/Videos/$RANDOM.m4v"
  else
     echo "please install ffmpeg for streaming"
  fi
}

# enhance content of file via a docker pretrained model, use --help to see the options
function enhance() {
  docker run --rm -v "$(pwd)/$(dirname "${@:$#}")":/ne/input -it alexjc/neural-enhance "${@:1:$#-1}" "input/$(basename "${@:$#}")"
}

# Bootstraping of a PotgreSQL database for fast initialization, for testing or local
# development, which you can also provide your own sql file (if it doesn't contain the
# name of the database) for bootstraping with the docker container initialized.
# DB_NAME=postgres;USER=pguser;PASSWORD=12345678;
function dbstrap() {
  docker run --rm -d \
    -e POSTGRES_PASSWORD=12345678 \
    -e POSTGRES_DB=postgrss \
    -e POSTGRES_USER=pguser \
    -p 5432:5432 \
    --name mydb \
    -v "$HOME"/.local/pgdata:/var/lib/postgresql/data \
    postgres:12-alpine

  if [[ -n $1 && -f $1 ]]; then
    docker cp "$1" mydb:/docker-entrypoint-initdb.d/file.sql
    docker exec mydb psql postgresql://pguser:12345678@localhost:5432/postgres \
      -f /docker-entrypoint-initdb.d/file.sql
  fi
}

# starts a qemu machine with with root access, first it checks if everything is setup,
# like iso's, shasums, you know... then it creates the virtual machine if not already setup.
# all the config and files goes under `$HOME/.config/alpine` directory.
function alpiny() {
  local -r sha_url="https://dl-cdn.alpinelinux.org/alpine/v3.14/releases/x86_64/alpine-standard-3.14.0-x86_64.iso.sha256"
  local -r alpine_iso_url="https://dl-cdn.alpinelinux.org/alpine/v3.14/releases/x86_64/alpine-standard-3.14.0-x86_64.iso"
  local -r alpine_path="$HOME/.config/alpine"

  echo "$alpine_path"

  if ! [[ -d $alpine_path ]]; then
    echo "creating alpine dir in .config..."
    mkdir -p "$alpine_path"
  fi

  if ! [[ -f "$alpine_path/alpine_sha.txt" ]]; then
    if ! [[ -x $(command -v wget) ]]; then
      >&2 echo "wget is not installed..."
      return 1
    fi
    echo "pulling sha256 file..."
    wget -O "$alpine_path/alpine_sha.txt" $sha_url
  fi

  if ! [[ -f "$alpine_path/alpine.iso" ]]; then
    if ! [[ -x $(command -v wget) ]]; then
      >&2 echo "wget is not installed..."
      return 1
    fi
    echo "pulling alpine iso..."
    wget -O "$alpine_path/alpine.iso" $alpine_iso_url

    echo "checking sha256..."
    if [[ $(more "$alpine_path/alpine_sha.txt" | awk '{print $1}') != $(shasum -a 256 "$alpine_path/alpine.iso" | awk '{print $1}') ]]; then
      >&2 echo "invalid shasum... removing alpine.iso"
      rm "$alpine_path/alpine.iso"
      return 1
    fi

    echo ""
    echo "shasum is valid !"
  fi

  if ! [[ -d "$alpine_path/data" ]]; then
    echo "creating data directory..."
    mkdir -p "$alpine_path/data"
  fi

  if ! [[ -f "$alpine_path/data/alpine.img" ]]; then
    if ! [[ -x $(command -v qemu-img) ]]; then
      >&2 echo "qemu is not installed..."
      return 1
    fi

    echo "creating alpine.img file..."
    qemu-img create -f qcow2 "$alpine_path/data/alpine.qcow2" 12G
  fi

  echo "starting qemu..."

  qemu-system-x86_64 -machine q35 -boot d \
    -m 1024 -smp cpus=2 -cpu kvm64 \
    -net user \
    -cdrom "$alpine_path"/alpine.iso \
    -serial mon:stdio \
    -hda "$alpine_path/data/alpine.qcow2"
}

function ex () {
  if [[ -f $1 ]]; then
    case $1 in
      *.tar.bz2 | *.tbz2)
        tar xjf "$1"
        ;;
     *.tar.gz | *.tgz)
        tar xzf "$1"
        ;;
     *.tar.xz | txz)
        tar xf "$1"
        ;;
     *.bz2)
        bunzip2 "$1"
        ;;
     *.rar)
        unrar x "$1"
        ;;
     *.gz)
        gunzip "$1"
        ;;
     *.tar)
        tar xf "$1"
        ;;
     *.zip)
        unzip "$1"
        ;;
     *.Z)
        uncompress "$1"
        ;;
     *.7z)
        7z x "$1"
        ;;
     *)
        echo "$1 cannot be extracted..."
        ;;
    esac
  else
    echo "$1 is not valid..."
  fi
}

alias \
    myip="curl ipinfo.io/ip && echo" \
    sha="shasum -a 256" \
    ports="netstat -tulanp" \
    dev="cd ~/Development" \
    ll="ls -alF" \
    open="xdg-open" \
    free="free -h" \
    sl="ls" \
    dutil="lsblk"

# if running under WSL2, use windows call for explorer for open
if uname -r | grep -q microsoft; then
  alias open="explorer.exe"
fi
