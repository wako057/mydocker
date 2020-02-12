# wakodock


## System requirements

For every system :

    docker-ce >= 18.06.0
    bash-completion
    python3 >= 3.5
    python3-virtualenv >= 3.5

Additional requirements for MacOS :

    coreutils (brew packages)
    4Go RAM dedicated to Docker Machine

Optional requirements for Debian based distributions :

    python3-dev (speed up docker-compose)
    libyaml-dev (speed up docker-compose)

Please note that if you install one optional requirements, you must install them all.

## Build and publish an image

Start by bumping version in apps/{application name}/docker-compose.yml then run theses commands,

wakodock <project-name> build <container-name>
wakodock <project-name> push <container-name>


## Debugging

You can use those env var for debug :

    DC_DEBUG=1 : will display debug logs
    DC_TRACE=1 : will execute set -x so you can see internal commands being executed (this is very verbose)


## Examples :
Show docker-compose help

indb-dc <project-name> help

Launch stack in background

indb-dc <project-name> up -d

Exec a shell in a running container

indb-dc <project-name> exec <container-name> bash

You must not use the docker run command since docker will create a container outside of the docker-compose context and won't get the stack context (AWS ID, dynamics /etc/hosts, etc...)
Stop the stack

indb-dc <project-name> stop

Stop the stack and remove non-persistent data

indb-dc <project-name> down

Stop the stack and remove ALL data (including persistent ones)

indb-dc <project-name> down -v