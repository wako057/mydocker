###########################
# Host Related functions
###########################

get_host() {
  # Determine if an host is resolvable
  # :param: Host to resolve

  if $OSX; then
    resolved=$(dscacheutil -q host -a name $1 | grep ip_address | cut -d: -f2 | tr -d '[:blank:]')
  elif $LINUX; then
    resolved=$(getent hosts $1 | cut -d" " -f1)
  else
    log error "Unknow system $(uname -s)"
    exit 1
  fi
  log debug "Host $host point to : $resolved"
  echo $resolved
}

# TODO IN PROGRESS
# based on https://superuser.com/questions/553932/how-to-check-if-i-have-sudo-access
doesIHaveSudoAccess() {
  local sudoAccess
  sudoAccess=$(timeout 2 sudo id && echo "granted" || echo "denied")
  log info "[doesIHaveSudoAccess]: L'utilisateur courant a un acces $sudoAccess pour sudo"
  echo $sudoAccess
}

# based on https://unix.stackexchange.com/questions/6345/how-can-i-get-distribution-name-and-version-number-in-a-simple-shell-script
# modification for my usecase
getDistro() {
  local DISTRO
  local OSFILE="/etc/os-release"

  if [ -f $OSFILE ]; then # freedesktop.org and systemd
    DISTRO=$(grep "^ID=" /etc/os-release | tr -d '"' | sed -e 's/ID=//' | tr "[:upper:]" "[:lower:]")
    log info "[getDistro]: On cat /etc/release"
  elif type lsb_release >/dev/null 2>&1; then
    DISTRO=$(lsb_release -i | cut -d: -f2 | sed s/'^\t'// | tr "[:upper:]" "[:lower:]")
    log info "[getDistro]: On utilise la commande lsb_release"
  elif [ -f /etc/lsb-release ]; then # For some versions of Debian/Ubuntu without lsb_release command
    DISTRO=DISTRO=$(grep "^DISTRIB_ID=" /etc/os-release | sed -e 's/^DISTRIB_ID="//' -e 's/"$//')
    log info "[getDistro]: On cat /etc/debian_version: Old debian $VER"
  elif [ -f /etc/debian_version ]; then # Older Debian/Ubuntu/etc.
    VER=$(cat /etc/debian_version)
    log info "[getDistro]: On cat /etc/debian_version: Old debian $VER"
    DISTRO="debian"
    #  elif [ -f /etc/SuSe-release ]; then
    # Older SuSE/etc.
    #  elif [ -f /etc/redhat-release ]; then
    # Older Red Hat, CentOS, etc.
  else
    OS=$(uname -s)
    VER=$(uname -r)
    DISTRO="$OS$VER"
  fi
  echo "$DISTRO"
}

detectIfVirtualMachine() {
  local result
  result=$(systemd-detect-virt)
  if [[ result != "none" ]]; then
    log info "[detectIfVirtualMachine]: On est dans une machine virtuel"
    return 0
  else
    log info "[detectIfVirtualMachine]: On est PAS dans une machine virtuel"
    return 1
  fi
}

detectIfInContainer() {
  local chk
  chk=$(grep -cE '/(lxc|docker)/[[:xdigit:]]{64}' /proc/1/cgroup)
  if [[ $chk -gt 0 ]]; then
    log info "[detectIfInContainer]: On est dans un container"
    return 0
  else
    log info "[detectIfInContainer]: On est PAS dans un container"
    return 1
  fi
}

getGidByGroup() {
  # Get the Gid of a group by its name
  # :param: GroupName
  local gidfound
  gidfound=$(getent group "$1" | cut -d: -f3)
  log info "[getGidByGroup]: Le group $1 a le gid [$gidfound]"
  echo $gidfound
}

getCurrentUserUid() {
  # Get uid of the current User
  local uidfound
  uidfound=$(id -u)
  log info "[getCurrentUserUid]: Le user courant a l'uid [$uidfound]"
  echo $uidfound
}

getCurrentUserGid() {
  # Get uid of the current User
  local gidfound
  gidfound=$(id -g)
  log info "[getCurrentUserGid]: Le user courant a le gid [$gidfound]"
  echo $uidfound
}

getUidByUser() {
  # Get the username of the Uid parameters
  # :param: Uid
  local uidfound
  uidfound=$(getent passwd "$1" | cut -d: -f1)
  log info "[getUidByUser]: Le user [$1] a pour uid: [$uidfound]"
  echo "$uidfound"
}

getUserByUid() {
  # Get the username of the Uid parameters
  # :param: Uid
  local name
  name=$(getent passwd "$1" | cut -d: -f1)
  log info "[getUserByUid]: Le user avec l'uid [$1] est: [$name]"
  echo "$name"
}

addUserGroupSudoers() {
  # :param: User
  RUN echo "$1 ALL=(ALL) NOPASSWD " >>/etc/sudoers
}

createConfigureSshRoot() {
  if [[ "$USER" == "root" ]]; then
    if [[ ! -d /root/.ssh ]]; then
      log info "[createConfigureSshRoot]: On cree le reperoire ssh"
      mkdir -p /root/.ssh
    else
      log info "[createConfigureSshRoot]: Repertoire /root/.ssh existe deja"
    fi
    log info "[createConfigureSshRoot]: On set les droit sur /root/.ssh"
    chmod 700 /root/.ssh
  fi
}

insertPS1BashBashrc() {
  log info "[insertPS1BashBashrc]: Cas particulier on dirait, on force le bash.bashrc"

  {
    echo "########### CUSTOM /etc/bash.bashrc due to no healthy HOME ###########"
    echo "PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\] [\D{%T}] \[\033[01;34m\]\w\[\033[00m\]\[\033[36;40m\]\[\033[00m\] > '"
    cat ./linuxinit/sh_aliases
  } >>/etc/bash.bashrc

}
