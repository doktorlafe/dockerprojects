#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v docker >/dev/null 2>&1; then
    echo "Docker není nainstalovaný nebo není v PATH." >&2
    exit 1
fi

if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD=(docker-compose)
else
    COMPOSE_CMD=()
fi

usage() {
    cat <<'EOF'
Použití:
  ./docker-projects.sh list
  ./docker-projects.sh up <projekt>
  ./docker-projects.sh up all
  ./docker-projects.sh down <projekt>
  ./docker-projects.sh down all
  ./docker-projects.sh status

Příklady:
  ./docker-projects.sh list
  ./docker-projects.sh up 03-nodejs-server
  ./docker-projects.sh up all
  ./docker-projects.sh down all

Poznámka:
  Při 'up all' skript přeskočí projekty, které kolidují na stejných host portech
  nebo vyžadují jiný runtime než Docker Compose/Docker run.
EOF
}

get_projects() {
    find "$ROOT_DIR" -mindepth 1 -maxdepth 1 -type d -regextype posix-extended -regex '.*/[0-9]{2}-[^/]+' | sort
}

project_name() {
    basename "$1"
}

container_name() {
    local name
    name="$(project_name "$1")"
    echo "docker-example-${name}"
}

image_name() {
    local name
    name="$(project_name "$1")"
    echo "docker-example-${name}:latest"
}

project_type() {
    local project_dir="$1"
    local name
    name="$(project_name "$project_dir")"

    case "$name" in
        23-kubernetes-setup)
            echo "kubernetes"
            ;;
        24-docker-swarm)
            echo "swarm"
            ;;
        *)
            if [[ -f "$project_dir/docker-compose.yml" ]]; then
                echo "compose"
            elif [[ -f "$project_dir/Dockerfile" ]]; then
                echo "dockerfile"
            else
                echo "unknown"
            fi
            ;;
    esac
}

supports_project() {
    local project_dir="$1"
    local name
    name="$(project_name "$project_dir")"

    case "$name" in
        23-kubernetes-setup|32-f5networks-k8s-bigip-ctlr)
            return 1
            ;;
    esac

    case "$(project_type "$project_dir")" in
        compose|dockerfile|swarm)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

unsupported_reason() {
    local project_dir="$1"
    local name
    name="$(project_name "$project_dir")"
    case "$name" in
        23-kubernetes-setup)
            echo "vyžaduje Kubernetes cluster a kubectl"
            ;;
        32-f5networks-k8s-bigip-ctlr)
            echo "vyžaduje externí BIG-IP a validní kubeconfig"
            ;;
        *)
            echo "nemá podporovaný způsob spuštění"
            ;;
    esac
}

project_ports() {
    local project_dir="$1"
    local name
    name="$(project_name "$project_dir")"

    case "$name" in
        03-nodejs-server|10-express-app|20-nextjs-app)
            echo "3000"
            ;;
        04-nginx-webserver)
            echo "8080"
            ;;
        05-mysql-database)
            echo "3306"
            ;;
        09-flask-api)
            echo "5000"
            ;;
        *)
            if [[ -f "$project_dir/docker-compose.yml" ]]; then
                grep -E '^\s*-\s*"?[0-9]+:[0-9]+' "$project_dir/docker-compose.yml" 2>/dev/null \
                    | sed -E 's/^\s*-\s*"?([0-9]+):.*/\1/' \
                    | sort -n -u \
                    | tr '\n' ' ' \
                    | xargs echo
            fi
            ;;
    esac
}

ensure_compose() {
    if [[ ${#COMPOSE_CMD[@]} -eq 0 ]]; then
        echo "Docker Compose není dostupný (docker compose ani docker-compose)." >&2
        exit 1
    fi
}

ensure_swarm() {
    local state
    state="$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null || true)"
    if [[ "$state" != "active" ]]; then
        echo "Docker Swarm není inicializovaný. Spusť nejdřív: docker swarm init" >&2
        exit 1
    fi
}

build_and_run_dockerfile_project() {
    local project_dir="$1"
    local name image container
    name="$(project_name "$project_dir")"
    image="$(image_name "$project_dir")"
    container="$(container_name "$project_dir")"

    docker build -t "$image" "$project_dir"

    case "$name" in
        01-hello-world)
            docker run --rm "$image"
            ;;
        02-python-app)
            docker run --rm "$image"
            ;;
        03-nodejs-server)
            docker rm -f "$container" >/dev/null 2>&1 || true
            docker run -d --name "$container" -p 3000:3000 "$image"
            ;;
        04-nginx-webserver)
            docker rm -f "$container" >/dev/null 2>&1 || true
            docker run -d --name "$container" -p 8080:80 "$image"
            ;;
        05-mysql-database)
            docker rm -f "$container" >/dev/null 2>&1 || true
            docker run -d --name "$container" -p 3306:3306 "$image"
            ;;
        09-flask-api)
            docker rm -f "$container" >/dev/null 2>&1 || true
            docker run -d --name "$container" -p 5000:5000 "$image"
            ;;
        10-express-app)
            docker rm -f "$container" >/dev/null 2>&1 || true
            docker run -d --name "$container" -p 3000:3000 "$image"
            ;;
        20-nextjs-app)
            docker rm -f "$container" >/dev/null 2>&1 || true
            docker run -d --name "$container" -p 3000:3000 "$image"
            ;;
        *)
            echo "Projekt $name nemá definovaný docker run postup." >&2
            return 1
            ;;
    esac
}

start_project() {
    local project_dir="$1"
    local type
    type="$(project_type "$project_dir")"

    case "$type" in
        compose)
            ensure_compose
            (
                cd "$project_dir"
                "${COMPOSE_CMD[@]}" up -d --build
            )
            ;;
        dockerfile)
            build_and_run_dockerfile_project "$project_dir"
            ;;
        swarm)
            ensure_compose
            ensure_swarm
            (
                cd "$project_dir"
                docker stack deploy -c docker-compose.yml docker-example-24
            )
            ;;
        *)
            echo "Projekt $(project_name "$project_dir") nelze spustit: $(unsupported_reason "$project_dir")" >&2
            return 1
            ;;
    esac
}

stop_project() {
    local project_dir="$1"
    local type container
    type="$(project_type "$project_dir")"
    container="$(container_name "$project_dir")"

    case "$type" in
        compose)
            ensure_compose
            (
                cd "$project_dir"
                "${COMPOSE_CMD[@]}" down
            )
            ;;
        dockerfile)
            docker rm -f "$container" >/dev/null 2>&1 || true
            ;;
        swarm)
            docker stack rm docker-example-24 >/dev/null 2>&1 || true
            ;;
        *)
            return 0
            ;;
    esac
}

list_projects() {
    local project_dir name type ports note
    while IFS= read -r project_dir; do
        name="$(project_name "$project_dir")"
        type="$(project_type "$project_dir")"
        ports="$(project_ports "$project_dir")"
        if supports_project "$project_dir"; then
            note="OK"
        else
            note="SKIP: $(unsupported_reason "$project_dir")"
        fi
        printf '%-28s %-10s ports: %-18s %s\n' "$name" "$type" "${ports:--}" "$note"
    done < <(get_projects)
}

status_projects() {
    local project_dir name type container
    while IFS= read -r project_dir; do
        name="$(project_name "$project_dir")"
        type="$(project_type "$project_dir")"
        case "$type" in
            compose)
                if [[ ${#COMPOSE_CMD[@]} -eq 0 ]]; then
                    printf '%-28s compose     compose není dostupný\n' "$name"
                else
                    printf '%s\n' "[$name]"
                    (
                        cd "$project_dir"
                        "${COMPOSE_CMD[@]}" ps
                    ) || true
                fi
                ;;
            dockerfile)
                container="$(container_name "$project_dir")"
                if docker ps --format '{{.Names}}' | grep -Fxq "$container"; then
                    printf '%-28s dockerfile  running (%s)\n' "$name" "$container"
                else
                    printf '%-28s dockerfile  stopped\n' "$name"
                fi
                ;;
            swarm)
                printf '%-28s swarm       %s\n' "$name" "docker stack ls | grep docker-example-24"
                ;;
            *)
                printf '%-28s %-10s %s\n' "$name" "$type" "skip"
                ;;
        esac
    done < <(get_projects)
}

find_project_dir() {
    local selector="$1"
    local candidate

    if [[ -d "$ROOT_DIR/$selector" ]]; then
        echo "$ROOT_DIR/$selector"
        return 0
    fi

    while IFS= read -r candidate; do
        if [[ "$(basename "$candidate")" == "$selector" ]]; then
            echo "$candidate"
            return 0
        fi
    done < <(get_projects)

    echo "Projekt '$selector' nebyl nalezen." >&2
    exit 1
}

up_all() {
    local project_dir name ports port conflict started=0 skipped=0
    declare -A reserved_ports=()
    declare -A reserved_by=()

    while IFS= read -r project_dir; do
        name="$(project_name "$project_dir")"

        if ! supports_project "$project_dir"; then
            printf 'SKIP %-28s %s\n' "$name" "$(unsupported_reason "$project_dir")"
            skipped=$((skipped + 1))
            continue
        fi

        conflict=""
        ports="$(project_ports "$project_dir")"
        for port in $ports; do
            if [[ -n "${reserved_ports[$port]:-}" ]]; then
                conflict="$port (už používá ${reserved_by[$port]})"
                break
            fi
        done

        if [[ -n "$conflict" ]]; then
            printf 'SKIP %-28s konflikt portu %s\n' "$name" "$conflict"
            skipped=$((skipped + 1))
            continue
        fi

        printf 'START %-27s\n' "$name"
        if ! start_project "$project_dir"; then
            printf 'FAIL %-28s start se nezdařil\n' "$name"
            skipped=$((skipped + 1))
            continue
        fi
        for port in $ports; do
            reserved_ports[$port]=1
            reserved_by[$port]="$name"
        done
        started=$((started + 1))
    done < <(get_projects)

    printf '\nHotovo. Startováno: %d, přeskočeno: %d\n' "$started" "$skipped"
}

down_all() {
    local project_dir name
    while IFS= read -r project_dir; do
        name="$(project_name "$project_dir")"
        printf 'STOP %-28s\n' "$name"
        stop_project "$project_dir"
    done < <(get_projects)
}

main() {
    local action="${1:-}"
    local target="${2:-}"
    local project_dir

    case "$action" in
        list)
            list_projects
            ;;
        status)
            status_projects
            ;;
        up)
            if [[ -z "$target" ]]; then
                usage
                exit 1
            fi
            if [[ "$target" == "all" ]]; then
                up_all
            else
                project_dir="$(find_project_dir "$target")"
                start_project "$project_dir"
            fi
            ;;
        down)
            if [[ -z "$target" ]]; then
                usage
                exit 1
            fi
            if [[ "$target" == "all" ]]; then
                down_all
            else
                project_dir="$(find_project_dir "$target")"
                stop_project "$project_dir"
            fi
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