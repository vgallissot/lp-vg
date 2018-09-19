
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

# Add K8S infos
# Based on https://github.com/jonmosco/kube-ps1/blob/master/kube-ps1.sh
# Only if LP_ENABLE_KUBERNETES equals 1 AND config file is readable
if [[ $LP_ENABLE_KUBERNETES == 1 ]] && [[ -r ~/.kube/config ]]
then
    # kubectl can be very slow: caching its responses to file
    _LP_KUBERNETES_CLUSTER_SAVED_FILE="/tmp/_LP_KUBERNETES_CLUSTER_${LOGNAME}"
    _LP_KUBERNETES_CLUSTER_LAST=$(date +%s -r ~/.kube/config)

    # Get infos and save to file
    _update_k8s_infos(){
        # Not using kubectl command, but grep in the file, way faster.
        #_LP_KUBERNETES_CLUSTER=$(kubectl config current-context 2>/dev/null)
        _LP_KUBERNETES_CLUSTER=$(grep current-context ~/.kube/config|cut -c 19-)
        _LP_KUBERNETES_CLUSTER=${_LP_KUBERNETES_CLUSTER%\"}
        if [[ ! -z $_LP_KUBERNETES_CLUSTER ]]
        then
            # We want a short cluster name
            if [[ $LP_KUBERNETES_CLUSTER_SHORTEN == 1 ]]
            then
                _LP_KUBERNETES_CLUSTER=${_LP_KUBERNETES_CLUSTER%%.*}
            fi

            _LP_KUBERNETES_NAMESPACE=$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null)
            _LP_KUBERNETES_NAMESPACE="${_LP_KUBERNETES_NAMESPACE:-default}"

            # Save cluster config infos to file
            echo -e "${_LP_KUBERNETES_CLUSTER_LAST} ${_LP_KUBERNETES_CLUSTER} ${_LP_KUBERNETES_NAMESPACE}" > $_LP_KUBERNETES_CLUSTER_SAVED_FILE
        fi
    }

    # Use cached infos if possible
    if [[ ! -f $_LP_KUBERNETES_CLUSTER_SAVED_FILE ]]
    then
        # no cached file, we need to update infos
        _update_k8s_infos
    else
        # Cached file exist, get infos and check if needed update
        while read timestamp cluster namespace
        do
            _timestamp=$timestamp
            _LP_KUBERNETES_CLUSTER=$cluster
            _LP_KUBERNETES_NAMESPACE=$namespace
        done < $_LP_KUBERNETES_CLUSTER_SAVED_FILE

        # Update cache if k8s config file has been modified
        if [[ $_LP_KUBERNETES_CLUSTER_LAST -gt $_timestamp ]]
        then
            _update_k8s_infos
        fi
    fi

    # Update prompt if context is set
    if [[ ! -z $_LP_KUBERNETES_CLUSTER ]]
    then
        LP_PS1="${LP_PS1} ${LP_COLOR_KUBERNETES_SYMBOL}${LP_MARK_KUBERNETES}${LP_COLOR_KUBERNETES_CLUSTER}${_LP_KUBERNETES_CLUSTER}${NO_COL}"
        if [[ $LP_ENABLE_KUBERNETES_NAMESPACE -eq 1 ]]
        then
            LP_PS1="${LP_PS1}:${LP_COLOR_KUBERNETES_NAMESPACE}${_LP_KUBERNETES_NAMESPACE}${NO_COL}"
        fi
    fi
fi

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
