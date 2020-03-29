###########################
# Docker Stack functions
###########################

help() {
  # Display help
  echo "Usage : "
  echo "$0 project_name docker_compose_options..."
  echo "$0 project_name git git_options..."
  echo ""
  echo "Wrapper to docker-compose"
}

get_docker_config() {
  # Cache docker config for later use
  if [ -z "$CACHE_DOCKER_CONFIG" ]; then
    CACHE_DOCKER_CONFIG="$($HERE/venv/bin/docker-compose $files config)"
  fi
  echo "$CACHE_DOCKER_CONFIG"
}

find_traefik_hosts() {
  # Determine the list of host that is handled by traefik
  log debug "Getting host list required by Traefik"
  get_docker_config | $HERE/venv/bin/python3 -c 'import yaml,os; print("\n".join([v["labels"]["traefik.frontend.rule"].split(";")[0] for v in yaml.load(os.sys.stdin)["services"].values() if "labels" in v and "traefik.frontend.rule" in v["labels"]]))' | grep -E '^Host:' | cut -d: -f2 | tr -d '[:blank:]' | sed 's/,/ /g'
}

get_app_dir_from_repo() {
  # Output the directory name from the repo name
  # :param: git clone address or directory

  if echo $1 | grep -sE '\.git$' >/dev/null; then
    app_dir=$(echo $1 | rev | cut -d/ -f1 | rev | sed -E 's/\.git$//g')
  else
    app_dir=$1
  fi

  echo $HERE/apps/$app_dir
}

checkAndCreateVirtualEnv() {
  if ! [ -d "$HERE/venv" ]; then
    # Check venv module
    set +e
    venv_status=$(
      python3 -m virtualenv 2>/dev/null 1>/dev/null
      echo $?
    )
    set -e
    if [ $venv_status != "2" ]; then
      log error "You must install python 3 \"virtualenv\" module"
      exit 2
    fi

    log info "Creating virtualenv"
    python3 -m virtualenv --python $(which python3) $HERE/venv
  fi
}

checkAndInstallPythonDependancies() {
  set +e
  diff=$(diff -B <($HERE/venv/bin/pip3 freeze | grep -v "pkg-resources" | sort) <(cat $HERE/requirements.txt | sort))
  set -e
  if ! [ -z "$diff" ]; then
    $HERE/venv/bin/pip3 install -r $HERE/requirements.txt
  fi
}
