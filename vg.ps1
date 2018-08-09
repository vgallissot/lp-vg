
#######################################
# LIQUID PROMPT DEFAULT TEMPLATE FILE #
#######################################

# Available features:
# LP_BATT battery
# LP_LOAD load
# LP_JOBS screen sessions/running jobs/suspended jobs
# LP_USER user
# LP_HOST hostname
# LP_PERM a colon ":"
# LP_PWD current working directory
# LP_VENV Python virtual environment
# LP_PROXY HTTP proxy
# LP_VCS the content of the current repository
# LP_ERR last error code
# LP_MARK prompt mark
# LP_TIME current time
# LP_TTYN number of current terminal (useful in title for quick switching)
# LP_RUNTIME runtime of last command
# LP_MARK_PREFIX user-defined prompt mark prefix (helpful if you want 2-line prompts)
# LP_PS1_PREFIX user-defined general-purpose prefix (default set a generic prompt as the window title)
# LP_PS1_POSTFIX user-defined general-purpose postfix
# LP_BRACKET_OPEN open bracket
# LP_BRACKET_CLOSE close bracket

# Remember that most features come with their corresponding colors,
# see the README.

# Remove pre space in error code and append one at the end
if [ ! -z $LP_ERR ]; then LP_ERR=${LP_ERR#" "}" "; fi

# add error_code, time, jobs, load and battery
LP_PS1="${LP_ERR}${LP_PS1_PREFIX}${LP_TIME}${LP_BATT}${LP_LOAD}${LP_JOBS}"
# add user, host
LP_PS1="${LP_PS1}${LP_BRACKET_OPEN}${LP_USER}${LP_HOST}"

## Custom workaround to change pwd color if no write access.
# LP_MARK_PERM & LP_PERM & LP_COLOR_WRITE are not used anymore
if [[ ! -w "${PWD}" ]]
then
    local LP_COLOR_PATH_TMP=${LP_COLOR_PATH}
    LP_COLOR_PATH=${LP_COLOR_NOWRITE}
    _lp_shorten_path
    LP_COLOR_PATH=${LP_COLOR_PATH_TMP}
fi

LP_PS1="${LP_PS1} ${LP_PWD}${LP_BRACKET_CLOSE}${LP_VENV}${LP_PROXY}"

# Add VCS infos
# If root, the info has not been collected unless LP_ENABLE_VCS_ROOT
# is set.
LP_PS1="${LP_PS1}${LP_VCS}"

# Add TerraForm workspace info
# Only if directory already handled by TF
if [[ -d .terraform ]]
then
    _TERRAFORM_WORKSPACE=$(terraform workspace show)
    LP_PS1="${LP_PS1} {${LP_COLOR_TERRAFORM}${LP_MARK_TERRAFORM} ${_TERRAFORM_WORKSPACE}${NO_COL}}"
fi

# Add custom cloud envs
# Because I use _CLOUD_ENV to now in which cloud env I am
if [[ ! -z "$_CLOUD_ENV" ]]
then
    case "$_CLOUD_ENV" in
        prod | production )
            LP_COLOR_CLOUD_ENV="${LP_COLOR_CLOUD_ENV_CRIT}"
            ;;
        stg | staging )
            LP_COLOR_CLOUD_ENV="${LP_COLOR_CLOUD_ENV_WARN}"
            ;;
        root | services )
            LP_COLOR_CLOUD_ENV="${LP_COLOR_CLOUD_ENV_DANGER}"
            ;;
        * )
            LP_COLOR_CLOUD_ENV="${LP_COLOR_CLOUD_ENV_NOMINAL}"
            ;;
    esac
    LP_PS1="${LP_PS1} [${LP_COLOR_CLOUD_ENV}${LP_MARK_CLOUD} ${_CLOUD_ENV}${NO_COL}]"
fi

# add prompt mark
LP_PS1="${LP_PS1}${LP_RUNTIME}${LP_MARK_PREFIX}${LP_COLOR_MARK}${LP_MARK}${LP_PS1_POSTFIX}"

# "invisible" parts
# Get the current prompt on the fly and make it a title
LP_TITLE="$(_lp_title "$LP_PS1")"

# Insert it in the prompt
LP_PS1="${LP_TITLE}${LP_PS1}"

# vim: set et sts=4 sw=4 tw=120 ft=sh:
