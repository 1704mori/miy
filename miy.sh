#!/usr/bin/bash

# Define ANSI color codes
COLOR_GREEN=$(printf '\033[32m')
COLOR_YELLOW=$(printf '\033[33m')
COLOR_GREEN_BG=$(printf '\033[42;30m') # Green background with black text
COLOR_YELLOW_BG=$(printf '\033[43;30m') # Yellow background with black text
NC=$(printf '\033[0m') # No Color

function select_option {
  local header="\nAdd A Header\nWith\nAs Many\nLines as you want"
  header+="\n\nPlease choose an option (use space to select, enter to confirm):\n\n"
  printf "$header"
  options=("$@")
  local selected=() # Array to keep track of selected options

  # helpers for terminal print control and key input
  ESC=$(printf "\033")
  cursor_blink_on()       { printf "$ESC[?25h"; }
  cursor_blink_off()      { printf "$ESC[?25l"; }
  cursor_to()             { printf "$ESC[$1;${2:-1}H"; }
  print_option()          { printf "\t$1 "; }
  print_selected()        { printf "\t${COLOR_GREEN_BG}$1${NC}"; } # Selected by cursor
  toggle_selected()       { printf "\t${COLOR_YELLOW}$1${NC}"; } # Selected
  highlight_both()       { printf "\t${COLOR_YELLOW_BG}$1${NC}"; } # Selected and under cursor
  get_cursor_row()        { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }

  key_input() {
    local key
    IFS= read -rsn1 input 2>/dev/null >&2
    if [[ $input =~ ^[1-9]$ ]]; then
      echo "number$input"; return;
    elif [[ $input = "" ]]; then
      echo enter; return;
    elif [[ $input = " " ]]; then
      echo space; return;
    elif [[ $input = $ESC ]]; then
      read -rsn2 -t 0.0001 input
      key+="$input"
      if [[ $key = "[A" ]]; then echo up; fi;
      if [[ $key = "[B" ]]; then echo down; fi;
    fi
  }

  for opt in "${options[@]}"; do printf "\n"; done

  local lastrow=$(get_cursor_row)
  local startrow=$(($lastrow - $#))
  local current=0

  trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
  cursor_blink_off

  while true; do
    local idx=0
    for opt in "${options[@]}"; do
      cursor_to $(($startrow + $idx))
      local label="$(($idx + 1)). $opt"
      if [[ " ${selected[@]} " =~ " ${idx} " ]] && [ $idx -eq $current ]; then
        highlight_both "$label"
      elif [[ " ${selected[@]} " =~ " ${idx} " ]]; then
        toggle_selected "$label"
      elif [ $idx -eq $current ]; then
        print_selected "$label"
      else
        print_option "$label"
      fi
      ((idx++))
    done

    input=$(key_input)
    case $input in
      enter) break;;
      space)
        if [[ " ${selected[@]} " =~ " ${current} " ]]; then
          selected=(${selected[@]/$current}) # Remove if exists
        else
          selected+=($current) # Add if not exists
        fi
        ;;
      number*)
        input=${input//number}
        if [ $input -le $# ]; then
          current=$(($input - 1))
          if [[ " ${selected[@]} " =~ " ${current} " ]]; then
            selected=(${selected[@]/$current})
          else
            selected+=($current)
          fi
        fi
        ;;
      up)
        ((current--))
        if [ $current -lt 0 ]; then current=$(($# - 1)); fi;;
      down)
        ((current++))
        if [ $current -ge $# ]; then current=0; fi;;
    esac
 

 done

  cursor_blink_on

  echo "You selected the following option(s):"
  for i in "${selected[@]}"; do
    if [[ "${options[$i]}" == "Go" ]]; then
      install_golang
    elif [[ "${options[$i]}" == "NVM" ]]; then
      install_nvm
    fi
  done
}

USER_HOME=$(eval echo ~${SUDO_USER})

install_golang() {
  echo "Starting Go installation process"
  GO_VERSION=$(curl -s "https://go.dev/VERSION?m=text" | head -1)

  wget https://golang.org/dl/${GO_VERSION}.linux-amd64.tar.gz
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf ${GO_VERSION}.linux-amd64.tar.gz
  rm -rf ${GO_VERSION}.linux-amd64.tar.gz

  echo "export PATH=\$PATH:/usr/local/go/bin" >> "$USER_HOME/.bashrc"
  source "$USER_HOME/.bashrc"
  echo "Golang installation is complete."
}

install_nvm() {
  echo "Starting NVM installation process"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash

  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

  echo "NVM installation is complete."
}

# Define your options
options=("Go" "NVM")

# Call the select_option function with your options
select_option "${options[@]}"
