#!/bin/bash
set -ue

get_help() {
  echo -e "Usage: $0 [--pgconfig-path <PATH> | --sqlite3-path <PATH> | --build-only | --db-only | --config-only]"
  echo -e "\t --pgconfig-path  - path to pg_config binary"
  echo -e "\t --sqlite3-path   - path to sqlite3 install directory"
  echo -e "\t --build-only     - only install and build dependencies"
  echo -e "\t --db-only        - only setup database"
  echo -e "\t --config-only    - only setup config files"
  echo -e "\t --with-development-gems - build with development gems group"
  echo -e "\t --help|-h        - show this message"
}

parse_args() {
  optspec=":h-:"
  local regex="\-\-.*"
  while getopts "$optspec" optchar; do
    case "${optchar}" in
      -)
        case "${OPTARG}" in
          sqlite3-path)
            val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
            SQLITE3_PATH=${val}
            ;;
          pgconfig-path)
            val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
            PG_CONFIG_PATH=${val}
            ;;
          build-only)
            if [ -z ${!OPTIND+x} ] || [[ ${!OPTIND} =~ ${regex} ]]; then
              PUTIT_BUILD_ONLY=true
            else
              get_help
              exit 1
            fi
            ;;
          db-only)
            if [ -z ${!OPTIND+x} ] || [[ ${!OPTIND} =~ ${regex} ]]; then
              PUTIT_DB_ONLY=true
            else
              get_help
              exit 1
            fi
            ;;
          config-only)
            if [ -z ${!OPTIND+x} ] || [[ ${!OPTIND} =~ ${regex} ]]; then
              PUTIT_CONFIG_ONLY=true
            else
              get_help
              exit 1
            fi
            ;;
          with-development-gems)
            if [ -z ${!OPTIND+x} ] || [[ ${!OPTIND} =~ ${regex} ]]; then
              PUTIT_WITH_DEV_GEMS=true
            else
              get_help
              exit 1
            fi
            ;;
          help)
            get_help
            exit 0
          ;;
          *)
            echo "${optspec:0:1} ${OPTARG}"
            if [ "$OPTERR" = 1 ]; then
              echo -e "Unknown option --${OPTARG}\n" >&2
              get_help
              exit 1
          fi
          ;;
        esac;;
      h)
        get_help
        exit 0
        ;;
      *)
        if [ "$OPTERR" = 1 ] || [ "${optspec:0:1}" = ":" ]; then
          echo "Non-option argument: '-${OPTARG}'" >&2
          exit 1
        fi
        ;;
    esac
  done
}

abspath() {
  # generate absolute path from relative path
  # $1     : relative filename
  # return : absolute path
  if [ -d "$1" ]; then
    # dir
    (cd "$1"; pwd)
  elif [ -f "$1" ]; then
    # file
    if [[ $1 == */* ]]; then
      echo "$(cd "${1%/*}"; pwd)/${1##*/}"
    else
      echo "$(pwd)/$1"
    fi
  fi
}

log() {
  local sub_command=$(basename "$0" | cut -d'-' -f2)
  local level=$1
  local msg=$2
  local date=$(date '+%Y-%m-%d %H:%M:%S')
  local log_event_to_file="$date [PUTIT] [$sub_command] [$level] $msg"
  local log_event_to_console="[$level] $msg"

  # drop debug messages if PUTIT_DEBUG_BUILD is not set
  if [ $level == 'DEBUG' ] && [ -z ${PUTIT_DEBUG_BUILD+x} ]; then
    echo > /dev/null
  # do not log to console if PUTIT_DISABLE_LOG_CONSOLE is set
  elif [[ ! -z ${PUTIT_DISABLE_LOG_CONSOLE+x} ]]; then
    echo "$log_event_to_file" >> $PUTIT_LOG_FILE
  else
    echo "$log_event_to_console"
    echo "$log_event_to_file" >> $PUTIT_LOG_FILE
  fi
  unset date
}

set_vars() {
  export APP_USER=$(whoami)
  export APP_GROUP="${APP_USER}"
  export RACK_ENV="production"

  local script_dir=$(dirname $(abspath $0))
  export PUTIT_APP_DIR="${script_dir%/bin}"
  export PUTIT_LOG_FILE="${PUTIT_APP_DIR}/log/build.log"
  export CONFIG_DIR="${PUTIT_APP_DIR}/config"

  log "INFO" "Checking if Ruby is installed..."
  local is_ruby=$(ruby -v 2>/dev/null | grep -Ec 'ruby 2.7|ruby 3.*')
  if [ ${is_ruby} -ne 1 ]; then
    log "ERROR" "Required version of Ruby not found. Please install Ruby 2.7.0 or greater."
    exit 1
  else
    log "INFO" "Found: $(ruby -v)"
  fi

  log "INFO" "Checking if Bundler is installed..."
  local is_bundler=$(bundler -v 2>/dev/null | grep -Ec 'Bundler version 2.*')
  if [ ${is_bundler} -ne 1 ]; then
    log "ERROR" "Required version of Bundler not found in your Ruby distribution. Please install Bundler 2.1.4 or greater."
    exit 1
  else
    log "INFO" "Found: $(bundler -v)"
  fi

  log "DEBUG" "Set \$RUBY: $(which ruby)"
  log "DEBUG" "Set \$BUNDLE: $(which bundler)"
  log "DEBUG" "Set \$APP_USER: $APP_USER"
  log "DEBUG" "Set \$APP_GROUP: $APP_GROUP"
  log "DEBUG" "Set \$PUTIT_APP_DIR: $PUTIT_APP_DIR"
  log "DEBUG" "Set \$CONFIG_DIR: $CONFIG_DIR"
}

set_config() {
  log "INFO" "Setting up configuration files and start script..."

  local run_script="${PUTIT_APP_DIR}/bin/run.sh"
  local run_script_template="${PUTIT_APP_DIR}/bin/run.sh.template"
  local thin_config_template="${CONFIG_DIR}/thin.yml.template"
  local thin_config="${CONFIG_DIR}/thin.yml"
  local app_settings="${CONFIG_DIR}/settings.yml"
  local app_settings_template="${CONFIG_DIR}/settings.yml.template"

  # application name from thin template tag value
  if [ -f ${thin_config_template} ]; then
    export putit_app_name="$(grep 'tag' ${thin_config_template} | awk '{print $2}')"
  elif [ -f ${thin_config} ]; then
    export putit_app_name="$(grep 'tag' ${thin_config} | awk '{print $2}')"
  else
    log "ERROR" "Thin server config file and its template are missing!"
    exit 1
  fi

  #thin.yml
  if [ ! -f ${thin_config} ]; then
    sed -e s,APP_DIR,${PUTIT_APP_DIR}, -i ${thin_config_template}
    sed -e s,APP_USER,${APP_USER}, -i ${thin_config_template}
    sed -e s,APP_GROUP,${APP_USER}, -i ${thin_config_template}
    # keep template as thing.yml is in .gitignore
    cp ${thin_config_template} ${thin_config}
    sed -e s,APP_DIR,${PUTIT_APP_DIR}, -i ${thin_config}
    sed -e s,APP_USER,${APP_USER}, -i ${thin_config}
    sed -e s,APP_GROUP,${APP_USER}, -i ${thin_config}
  elif [ -f ${thin_config} ]; then
    log "WARNING" "Thin server seems to be already configured, skipping..."
  fi

  #settings.yml (only for putit-core)
  if [ ${putit_app_name} == "putit-core" ]; then
    if [ ! -f ${app_settings} ]; then
      local plugins_path="$(dirname ${PUTIT_APP_DIR})/putit-plugins"
      # keep template as thing.yml is in .gitignore
      cp ${app_settings_template} ${app_settings}
      sed -e s,PLUGINS_PATH_TEMPLATE,${plugins_path}, -i ${app_settings}
    elif [ -f ${app_settings} ]; then
      log "WARNING" "Settings file seems to be already configured, skipping..."
    fi
  fi

  # run.sh
  if [ -f ${run_script_template} ]; then
    cp ${run_script_template} ${run_script}
    sed -e s,APP_DIR_TEMPLATE,${PUTIT_APP_DIR}, -i ${run_script}
    sed -e s,APP_NAME_TEMPLATE,${putit_app_name}, -i ${run_script}
    chmod +x ${run_script}
  elif [ -f ${run_script} ]; then
    log "WARNING" "Start script seems to be already configured, skipping..."
  else
    log "ERROR" "Start script and its template are missing!"
    exit 1
  fi
}

install_gems() {
  log "INFO" "Installing gems..."

  bundler config --local path lib/gems >> ${PUTIT_LOG_FILE}
  if [ ! -z ${PUTIT_WITH_DEV_GEMS+x} ] && [ "${PUTIT_WITH_DEV_GEMS}" ]; then
    bundler config --local with development >> ${PUTIT_LOG_FILE}
  else
    bundler config --local without development >> ${PUTIT_LOG_FILE}
  fi

  if ! [ -z ${SQLITE3_PATH+x} ]; then
    log "INFO" "Using SQLite3 libraries from ${SQLITE3_PATH}..."
    bundler config --local build.sqlite3 --with-opt-include=${SQLITE3_PATH}/include --with-opt-lib=${SQLITE3_PATH}/lib --with-cflags='-O2 -DSQLITE_ENABLE_ICU' >> ${PUTIT_LOG_FILE}
  fi

  if ! [ -z ${PG_CONFIG_PATH+x} ]; then
    log "INFO" "Using PostgreSQL binaries from $(echo $PG_CONFIG_PATH | sed s,/bin/pg_config,,g)..."
    bundler config --local build.pg --with-pg-config=${PG_CONFIG_PATH} >> ${PUTIT_LOG_FILE}
  fi

  if [ -f "${PUTIT_APP_DIR}/Gemfile" ]; then
    if $(bundler install --gemfile="${PUTIT_APP_DIR}/Gemfile" >> ${PUTIT_LOG_FILE}) ; then
      return 0
    else
      log "ERROR" "Error while installing gems. Check out the log: ${PUTIT_LOG_FILE} for more details."
      exit 1
    fi
  else
    log "ERROR" "Missing Gemfile: ${PUTIT_APP_DIR}/Gemfile"
  fi
}

run_db_migrations() {
  log "INFO" "Running database migration..."
  if $(bundler exec rake db:migrate >> ${PUTIT_LOG_FILE}); then
    return 0
  else
    log "ERROR" "Error while running DB migrations. Check out the log: ${PUTIT_LOG_FILE} for more details."
    exit 1
  fi
}

run_db_schema_load() {
  if [ -f ${CONFIG_DIR}/secrets.yml ]; then
    log "INFO" "Generating database secret key..."
    sed -i s/SECRET_KEY_TEMPLATE/$(head /dev/urandom | tr -dc a-f0-9 | head -c 128)/g ${CONFIG_DIR}/secrets.yml
  fi
  log "INFO" "Running database schema load..."
  if $(bundler exec rake db:schema:load >> ${PUTIT_LOG_FILE}); then
    return 0
  else
    log "ERROR" "Unable to load DB schema. Check out the log: ${PUTIT_LOG_FILE} for more details."
  fi
}

setup_db() {
  log "INFO" "Checking database connection..."
  db_version=$(bundler exec rake db:version 2>/dev/null | sed s/"Current version: "//g)
  if [ -z ${db_version} ]; then
    log "ERROR" "Could not connect to the database. Check the database connection and re-run the setup script with --db-only flag."
    exit 1
  elif [ ${db_version} -eq 0 ]; then
    run_db_schema_load
  else
    run_db_migrations
  fi
}

# main body

parse_args $@
set_vars

pushd ${PUTIT_APP_DIR} >/dev/null 2>&1

if [ ! -z ${PUTIT_DB_ONLY+x} ] && [ ! -z ${PUTIT_BUILD_ONLY+x} ] && [ ! -z ${PUTIT_CONFIG_ONLY+x} ]; then
  log "INFO" "Starting build, details can be found in ${PUTIT_LOG_FILE}..."
  install_gems
  set_config
  setup_db
elif [ ! -z ${PUTIT_DB_ONLY+x} ] && [ ! -z ${PUTIT_BUILD_ONLY+x} ]; then
  log "INFO" "Starting build, details can be found in ${PUTIT_LOG_FILE}..."
  install_gems
  log "INFO" "Skipping configuration files and start script setup..."
  setup_db
elif [ ! -z ${PUTIT_DB_ONLY+x} ] && [ ! -z ${PUTIT_CONFIG_ONLY+x} ]; then
  log "INFO" "Skipping build..."
  set_config
  setup_db
elif [ ! -z ${PUTIT_CONFIG_ONLY+x} ] && [ ! -z ${PUTIT_BUILD_ONLY+x} ]; then
  log "INFO" "Starting build, details can be found in ${PUTIT_LOG_FILE}..."
  install_gems
  set_config
  log "INFO" "Skipping database setup..."
elif [ ! -z ${PUTIT_CONFIG_ONLY+x} ]; then
  log "INFO" "Skipping build..."
  set_config
  log "INFO" "Skipping database setup..."
elif [ ! -z ${PUTIT_DB_ONLY+x} ]; then
  log "INFO" "Skipping build..."
  log "INFO" "Skipping configuration files and start script setup..."
  setup_db
elif [ ! -z ${PUTIT_BUILD_ONLY+x} ]; then
  log "INFO" "Starting build, details can be found in ${PUTIT_LOG_FILE}..."
  install_gems
  log "INFO" "Skipping configuration files and start script setup..."
  log "INFO" "Skipping database setup..."
else
  log "INFO" "Starting build, details can be found in ${PUTIT_LOG_FILE}..."
  install_gems
  set_config
  setup_db
fi

log "INFO" "Setup done."

popd >/dev/null 2>&1
