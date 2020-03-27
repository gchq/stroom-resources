#!/usr/bin/env bash

# Exit the script on any error
set -e

# Shell colour constants for use in 'echo -e'
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
LGREY='\e[37m'
DGREY='\e[90m'
NC='\033[0m' # No colour

show_help() {
  # Get the full name of the file sourcing this one.
  this_script="$(pwd)/`basename "$0"`"

  # Two things happening here:
  # 1. grep the sourcing file to get lines with functions on them
  # 2. get rid of white-space, which will cause extra elements in the array
  # No idea why shellcheck is complaining.
  functions=($(grep -n '^[A-Za-z0-9 -_]*()[ ]*{' ${this_script} | tr -d ' '))

  # That was easy, but we also want comments for each function.
  for i in "${functions[@]}"
  do
     # Pull out the line number from the grep
     IFS=: read line_number rest <<< $i

     # Just keep the function name.
     # TODO: use a capture group in the original grep. This would avoid the tr too.
     function_name=$(sed 's/(){$//' <<< $rest)

     # This $((...)) nonsense is the "arithmetic expansion operator".
     # Bash treats things as strings or numbers depending on context,
     # so we need to use this operator to treat $line_number as a number.
     previous_line_number=$(($line_number-1))

     # sed out the previous line, to use as a comment
     # TODO: what about sedding out all previous commented lines?
     previous_line=$(sed "${previous_line_number}q;d" ${this_script})

     # TODO Check that the previous line is in fact a comment
    output="${output}\n${YELLOW}${function_name}${NC}+++${BLUE}${previous_line}${NC}" 
  done

  echo -e "${LGREY}The following functions are available ${DGREY}i.e./run <function_name>${NC}${LGREY}:${NC}"
  echo -e ${output} | column -t -s+++
}

# If there aren't any arguments then display the help.
if [ $# -eq 0 ]; then
  show_help "$@"
else
  # This will call the first argument as a function, passing in the subsequent arguments
  "$@"
fi
