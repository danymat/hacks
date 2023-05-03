#!/bin/bash

read_domains() {
  local filename="$1"
  local domains=()

  while read -r domain; do
    domains+=("$domain")
  done < "$filename"

  echo "${domains[@]}"
}

print_csv_header() {
  echo "domain,record_type,result"
}

query_domain() {
  local domain="$1"
  local record_types=("${!2}")

  local any_results=$(dig "$domain" any +short)

  if [ -n "$any_results" ]; then
    IFS=$'\n' read -rd '' -a result_array <<< "$any_results"
    for result in "${result_array[@]}"; do
      echo "\"$domain\",\"ANY\",\"$result\""
    done
  else
    for type in "${record_types[@]}"; do
      local results=$(dig "$domain" "$type" +short)
      IFS=$'\n' read -rd '' -a result_array <<< "$results"

      for result in "${result_array[@]}"; do
        echo "\"$domain\",\"$type\",\"$result\""
      done
    done
  fi
}

main() {
  local domains_file=""
  local single_domain=""
  local domains=()

  if [[ $# -eq 0 ]]; then
    echo "Usage: $0 -l hosts.txt OR $0 example.com"
    exit 1
  fi

  while getopts "l:" opt; do
    case $opt in
      l)
        domains_file="$OPTARG"
        ;;
      *)
        echo "Usage: $0 -l hosts.txt OR $0 example.com"
        exit 1
        ;;
    esac
  done

  shift $((OPTIND-1))

  if [ -n "$domains_file" ]; then
    domains=($(read_domains "$domains_file"))
  elif [ -n "$1" ]; then
    single_domain="$1"
    domains+=("$single_domain")
  else
    echo "No domains provided. Please use the -l flag to specify a file with a list of domains or provide a single domain as an argument."
    exit 1
  fi

  types=("A" "AAAA" "CNAME" "MX" "TXT" "NS" "SRV" "SOA")

  print_csv_header
  for domain in "${domains[@]}"; do
    query_domain "$domain" types[@]
  done
}

main "$@"

