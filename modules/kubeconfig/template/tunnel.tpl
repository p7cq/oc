#!/usr/bin/env bash

function usage() {
  echo "Usage: $${0##*/} action"
  echo -e "  action: can be one of open, close, or status\n"
}

declare -a actions=("open" "status" "close")

[[ ! "$#" = "1" ]] || [[ ! " $${actions[*]} " =~ " $${1} " ]] && usage && exit 0

case "$${1}" in
    open)
        id_rsa="${private_key_path}"
        if [[ -z "$${id_rsa}" ]]; then
          ssh -v -N -L ${local_port}:${target_host}:${target_port} -p 22 ${ssh_user}@${ssh_host} > ${tunnel_log} 2>&1 &
        else
          ssh -i "$${id_rsa}" -v -N -L ${local_port}:${target_host}:${target_port} -p 22 ${ssh_user}@${ssh_host} > ${tunnel_log} 2>&1 &
        fi
        echo -e "\e[32mSSH tunnel is open\e[0m\nRun \e[3m$${0##*/} close\e[0m from CLI to close it"
        ;;
    status)
        status=$(ps -aux | grep ssh | grep "${local_port}:${target_host}:${target_port} -p 22 ${ssh_user}@${ssh_host}" | awk '{ print $2;}')
        [[ -z "$${status}" ]] && echo "SSH tunnel unavailable" || echo "SSH tunnel available"
        ;;
    close)
        kill -9 $(ps -aux | grep ssh | grep "${local_port}:${target_host}:${target_port} -p 22 ${ssh_user}@${ssh_host}" | awk '{ print $2;}')
        echo "SSH tunnel is closed"
        ;;
esac

exit 0
