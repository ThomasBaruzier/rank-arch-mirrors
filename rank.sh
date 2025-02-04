#!/bin/bash

config() {
  pass1_limit=2000
  pass2_limit=100
  results_limit=10

  threads="${1:-32}"
  test_package='systemd'

  mirror_path='/etc/pacman.d/mirrorlist'
  mirror_cache="$HOME/.cache/mirrorlist_cache"
  mirror_latency="$HOME/.cache/mirrorlist_latency"
}

main() {
  init "$@"
  perform_pass1
  perform_pass2
  process_results
  apply_results
}

init() {
  echo -e '\n\e[34mInitializing...\e[0m'

  config "$@"
  arch=$(uname -m)
  TIMEFORMAT='%3R'
  trap 'cleanup' EXIT

  determine_repo_urls
  determine_package_url
}

check_empty() {
  [ ! -s "$1" ] && echo -e '\e[31mNo mirrors available\e[0m\n' && exit
}

cleanup() {
  rm -f "$mirror_cache" "$mirror_results"
  exit "${1:-0}"
}

determine_repo_urls() {
  arch=$(uname -m)

  if [ "$arch" = 'x86_64' ]; then
    arch_url="core/os/$arch"
    arch_url_src='$repo/os/$arch'
    mirrors_url='https://archlinux.org/mirrorlist/all/'
    geoip_url="http://geo.mirror.pkgbuild.com/$arch_url"
  elif [ "$arch" = 'aarch64' ] || [ "$arch" = 'armv7l' ]; then
    arch_url="$arch/core"
    arch_url_src='$arch/$repo'
    mirrors_url='https://raw.githubusercontent.com/archlinuxarm/PKGBUILDs/master/core/pacman-mirrorlist/mirrorlist'
    geoip_url="http://mirror.archlinuxarm.org/$arch_url"
  else
    echo 'Unsupported arch'
    exit 1
  fi
}

determine_package_url() {
  local package_info=$(
    curl -sL -m 5 "$geoip_url" |
    grep -P "${test_package}-[0-9.-]+-${arch}.pkg.tar.[a-z]+(?=\">)"
  )

  package_size="${package_info##* }"
  package_size="${package_size//[^0-9]}"
  package_url="${package_info#*\"}"
  package_url="${package_url%\"*}"

  [ -z "$package_url" ] && echo 'No connection' && exit 1
}

worker_thread() {
  echo -en "\e[2K\e[s\e[2K$3/$num_urls $1\e[u"
  tmp=$(mktemp)

  elapsed=$((
    time curl -sL --fail --connect-timeout 1 \
      --speed-limit 100000 --speed-time 3 "$1/$2" -o "$tmp"
    ) 2>&1
  )

  [[ $(file --mime-type -b "$tmp") = 'application/'* ]] && \
  echo "$elapsed $1" >> "$mirror_cache"
  rm -f "$tmp"
}

wait_threads() {
  [ "$threads" = 1 ] && wait && return
  sleep=$(bc <<< "scale=3;2/$threads")

  while true; do
    sleep "$sleep"
    jobs=$(jobs)
    num_jobs="${jobs//[!$'\n']}"
    (( "${#num_jobs}" + 1 < threads )) && break
  done
}

urls_test() {
  rm -f "$mirror_cache"
  num_urls="${#@}"
  ((num_urls--))
  i=1

  for url in "${@:2}"; do
    worker_thread "$url" "$1" "$i" &
    wait_threads
    ((i++))
  done
  wait
}

perform_pass1() {
  mapfile -t pass1_urls < <(
    curl -sL "$mirrors_url" | grep -Po '#? *Server *= *\K.+' |
    sed "s:\$arch:$arch:; s:\$repo:core:" |
    grep -vF "//${geoip_url#*\/\/}" | head -n "$pass1_limit"
  )

  echo -e "\n\e[34mLatency test of ${#pass1_urls[@]} mirrors...\e[0m"
  urls_test 'core.db' "${pass1_urls[@]}"
  check_empty "$mirror_cache"
}

perform_pass2() {
  cp "$mirror_cache" "$mirror_latency"
  threads=1

  mapfile -t pass2_urls < <(
    sort -n "$mirror_cache" | cut -d' ' -f2 |
    head -n "$pass2_limit"
  )

  echo -e "\n\n\e[34mSpeed test of ${#pass2_urls[@]} mirrors...\e[0m"
  urls_test "$package_url" "${pass2_urls[@]}"
  check_empty "$mirror_cache"
}

process_results() {
  result_output=$(
    sort -k2 <(
      sort -n "$mirror_cache" | head -n "$results_limit"
    ) "$mirror_latency" | uniq -f1 -D | \
    awk -v package_size="$package_size" -v arch_url="$arch_url" '
      NR % 2 == 1 { time_taken = $1; full_url = $2 }
      NR % 2 == 0 {
        sub("/" arch_url "$", "", full_url)
        mbps = package_size / time_taken / 1024 / 1024
        printf "%-50s %8.2f %8.3f %8.2f\n", full_url, mbps, $1, mbps/$1
      }
    ' | sort -k4 -nr
  )

  result_urls=$(
    cut -d' ' -f1 <<< "$result_output" | \
    sed "s:$:/$arch_url_src:; s:^:Server = :"
  )

  mirrorlist=$'\n'"## Mirrorlist generated on $(date +%F)"$'\n\n'
  mirrorlist+="$result_urls"
}

apply_results() {
  printf '\n\n\e[34m%-50s %8s %8s %8s\e[0m\n' 'Best mirrors' 'Speed' 'Latency' 'Score'
  echo "$result_output"

  read -p $'\n\e[34mApply new mirrorlist? (y/N):\e[0m ' confirm
  if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Aborted. No changes were made."
    exit
  fi

  sudo mv "$mirror_path" "$mirror_path.bkp" && \
  sudo tee "$mirror_path" <<< "$mirrorlist"

  if [ "$?" = 0 ]; then
    echo -e '\n\e[32mMirrorlist updated successfully!\e[0m\n'
  else
    echo -e '\n\e[31mFailed to update mirrorlist\e[0m\n'
  fi
}

main "$@"
