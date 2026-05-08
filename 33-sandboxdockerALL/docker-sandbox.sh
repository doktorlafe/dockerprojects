#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SANDBOX_NAME="docker-examples-sandbox"
SANDBOX_IMAGE="docker:27-dind"
SANDBOX_VOLUME="docker-examples-sandbox-data"

usage() {
        cat <<'EOF'
Použití:
    ./docker-sandbox.sh start
    ./docker-sandbox.sh stop
    ./docker-sandbox.sh clean
    ./docker-sandbox.sh destroy
    ./docker-sandbox.sh list
    ./docker-sandbox.sh status
    ./docker-sandbox.sh up <projekt|all>
    ./docker-sandbox.sh down <projekt|all>
    ./docker-sandbox.sh shell

Co to dělá:
  Spustí samostatný Docker-in-Docker sandbox, ve kterém běží docker-projects.sh.
  Tím se kontejnery, sítě i volumes drží mimo hlavní Docker daemon serveru.

Příkazy:
    start
        Vytvoří a spustí sandbox kontejner. Pokud už existuje, jen ho znovu nastartuje.

    stop
        Zastaví sandbox kontejner, ale ponechá jeho data volume pro další spuštění.

    clean
        Uvnitř sandboxu zastaví všechny kontejnery a smaže nepoužívané images,
        sítě a volumes přes docker system prune.

    destroy
        Odstraní celý sandbox kontejner i jeho persistentní Docker data volume.

    list
        Uvnitř sandboxu spustí ./docker-projects.sh list a vypíše dostupné projekty.

    status
        Ukáže, zda sandbox běží, a když ano, vypíše kontejnery běžící uvnitř něj.

    up <projekt|all>
        Uvnitř sandboxu spustí ./docker-projects.sh up pro jeden projekt nebo pro all.

    down <projekt|all>
        Uvnitř sandboxu spustí ./docker-projects.sh down pro jeden projekt nebo pro all.

    shell
        Otevře interaktivní shell přímo uvnitř sandbox kontejneru.

Poznámky:
  Sandbox používá privileged kontejner a vlastní Docker data volume.
  Služby uvnitř sandboxu se standardně nepublikují ven na host server.
EOF
}

ensure_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        echo "Docker není nainstalovaný nebo není v PATH." >&2
        exit 1
    fi
}

sandbox_exists() {
    docker container inspect "$SANDBOX_NAME" >/dev/null 2>&1
}

sandbox_running() {
    [[ "$(docker inspect -f '{{.State.Running}}' "$SANDBOX_NAME" 2>/dev/null || true)" == "true" ]]
}

wait_for_sandbox() {
    local attempt
    for attempt in $(seq 1 30); do
        if docker exec "$SANDBOX_NAME" docker info >/dev/null 2>&1; then
            return 0
        fi
        sleep 1
    done

    echo "Sandbox Docker daemon nenaběhl včas." >&2
    exit 1
}

ensure_sandbox_running() {
    if ! sandbox_exists; then
        echo "Sandbox neexistuje. Spusť nejdřív: ./docker-sandbox.sh start" >&2
        exit 1
    fi

    if ! sandbox_running; then
        echo "Sandbox neběží. Spusť nejdřív: ./docker-sandbox.sh start" >&2
        exit 1
    fi

    wait_for_sandbox
}

start_sandbox() {
    ensure_docker

    if sandbox_running; then
        echo "Sandbox už běží." >&2
        return 0
    fi

    if sandbox_exists; then
        docker start "$SANDBOX_NAME" >/dev/null
    else
        docker volume create "$SANDBOX_VOLUME" >/dev/null
        docker run -d \
            --privileged \
            --name "$SANDBOX_NAME" \
            --hostname "$SANDBOX_NAME" \
            -e DOCKER_TLS_CERTDIR= \
            -v "$SANDBOX_VOLUME:/var/lib/docker" \
            -v "$ROOT_DIR:/workspace" \
            -w /workspace \
            "$SANDBOX_IMAGE" >/dev/null
    fi

    wait_for_sandbox
    echo "Sandbox je připravený." 
}

stop_sandbox() {
    ensure_docker
    if sandbox_running; then
        docker stop "$SANDBOX_NAME" >/dev/null
        echo "Sandbox byl zastaven."
    else
        echo "Sandbox neběží."
    fi
}

clean_sandbox() {
    ensure_docker
    ensure_sandbox_running

    docker exec "$SANDBOX_NAME" sh -lc '
        set -eu
        container_ids="$(docker ps -aq)"
        if [[ -n "$container_ids" ]]; then
            docker stop $container_ids >/dev/null
        fi
        docker system prune -af --volumes >/dev/null
    '

    echo "Sandbox Docker daemon byl vyčištěn: kontejnery zastaveny, nepoužívané image, sítě a volumes odstraněny."
}

destroy_sandbox() {
    ensure_docker
    docker rm -f "$SANDBOX_NAME" >/dev/null 2>&1 || true
    docker volume rm "$SANDBOX_VOLUME" >/dev/null 2>&1 || true
    echo "Sandbox i jeho Docker data byly odstraněny."
}

exec_in_sandbox() {
    ensure_sandbox_running
    docker exec -it "$SANDBOX_NAME" sh -lc "$*"
}

run_launcher() {
    local escaped=()
    local arg
    for arg in "$@"; do
        escaped+=("$(printf '%q' "$arg")")
    done
    exec_in_sandbox "./docker-projects.sh ${escaped[*]}"
}

status_sandbox() {
    ensure_docker

    if ! sandbox_exists; then
        echo "Sandbox neexistuje."
        return 0
    fi

    if sandbox_running; then
        echo "Sandbox běží."
        docker exec "$SANDBOX_NAME" docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'
    else
        echo "Sandbox existuje, ale je zastavený."
    fi
}

main() {
    local action="${1:-}"
    shift || true

    case "$action" in
        start)
            start_sandbox
            ;;
        stop)
            stop_sandbox
            ;;
        clean)
            clean_sandbox
            ;;
        destroy)
            destroy_sandbox
            ;;
        list)
            run_launcher list
            ;;
        status)
            status_sandbox
            ;;
        up)
            if [[ $# -eq 0 ]]; then
                usage
                exit 1
            fi
            run_launcher up "$@"
            ;;
        down)
            if [[ $# -eq 0 ]]; then
                usage
                exit 1
            fi
            run_launcher down "$@"
            ;;
        shell)
            exec_in_sandbox "exec sh"
            ;;
        ""|-h|--help|help)
            usage
            ;;
        *)
            echo "Neznámá akce: $action" >&2
            usage
            exit 1
            ;;
    esac
}

main "$@"