#!/bin/bash

# No need to check for git, brew etc. (can just use HTTP for now, at
# least until package is publicly available)

# will install dependencies locally.
# TODO: for system-wide install pass a `-g`
# by default will install to .bin. TODO can change with --prefix
BINDIR=~/.local/bin
LATEST='http://releases.ndr.md/latest'
DOWNLOADER='curl'
alias curl='curl -s'
mkdir -p $BINDIR

download () {
    # fixme: if this is a subprocess -- will it work?
    command -v curl >/dev/null 2>&1 || 
        { DOWNLOADER='wget'; alias curl='wget -qO- '; }
}

cmd_exists () {
    command -v $1 >/dev/null 2>&1 && 
        echo 'true' ||
        echo 'false';
}

node_version () {
    v=$(node -v | tr -d v | sed 's/\..*$//'); 
    if [ $v -ge '4' ]; then
        echo 'true'
    else
        echo 'false'
    fi
}

node_install () {
    # by default, will install the version I have locally:)
    VERSION='5.3.0'
    PLATFORM=$(uname | tr '[:upper:]' '[:lower:]')

    if [ $PLATFORM = 'darwin' ]; then
        # I don't see any x32 for Darwin!
        ARCH=x64;
    else
        if [ $(uname -m) == 'x86_64' ]; then
            ARCH=x64
        else
            ARCH=x86
        fi
    fi

    PREFIX="$BINDIR/node-v$VERSION-$PLATFORM-$ARCH";
    URL=http://nodejs.org/dist/v$VERSION/node-v$VERSION-$PLATFORM-$ARCH.tar.gz
    echo "Downloading dependencies ($VERSION-$PLATFORM-$ARCH) into $BINDIR"
    echo "(this might take a while depending on your connection)"
    mkdir -p $PREFIX;
    curl -s $URL | tar xzf - --strip-components=1 -C $PREFIX
    mv $PREFIX/bin/* $BINDIR
    rm -rf $PREFIX
    #if [[ $PATH != *":$BINDIR"* ]]
    #then
    #    for i in ~/.*shrc; do
    #        echo "Adding path $PREFIX/bin to startup: $i"
    #        echo "export PATH=\"\$PATH:$BINDIR\" # andromeda node" >> $i
    #    done
    #    export PATH="$PATH:$PREFIX/bin"
    #fi
}

unix_startup() {
	cat  <<- 'EOF' >$BINDIR/andromeda
#!/bin/bash

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

cmd_exists () {
    command -v $1 >/dev/null 2>&1 && echo 'true' || echo 'false';
}

$DIR/node $DIR/andromeda.js "$*"
EOF
  chmod +x $BINDIR/andromeda
}

andromeda_install () {
    # 1 OK, get the code (dev version)
    curl -s $LATEST | tar xzf - --strip-components=1 -C $BINDIR
#   ln -sf $BINDIR/andromeda.js $BINDIR/andromeda
    unix_startup
}

path_note () {
  echo "Launch using \`$BINDIR/andromeda\`"
}

# by default, fetch everything
node_install 
mkdir -p $BINDIR
andromeda_install && path_note || echo 'something went wrong; please let me know.'

