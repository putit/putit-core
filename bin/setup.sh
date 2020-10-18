#!/bin/bash
# This script is for building and install gems for putit-auth
set -ue

get_help() {
  echo -e "Usage: $0 [--pg_config <PATH> --build-only --db-only --sqlite3-path] "
  echo -e "\t --pg_config      - path to pg_config"
  echo -e "\t --sqlite3-path   - path to sqlite3 install dir"
  echo -e "\t --build-only     - only install and build gems"
  echo -e "\t --db-only        - only setup database"
  echo -e "\t --config-only    - only setup config files"
  echo -e "\t --help|-h        - show this message"
}

parse_args_without_values() {
  if [ -z ${!OPTIND+x} ]; then
    PUTIT_DB_SETUP_ONLY=true
  elif [[ ${!OPTIND} =~ ${regex} ]]; then 
    true
  else
    get_help
    exit 1
  fi
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
					pg_config)
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

  # drop debug messages when PUTIT_DEBUG_CLI is not set
  if [ $level == 'DEBUG' ] && [ -z ${PUTIT_DEBUG_BUILD+x} ]; then
    echo > /dev/null
  # when putit should NOT log on console
  elif [[ ! -z ${PUTIT_DISABLE_LOG_CONSOLE+x} && "$PUTIT_LOG_CONSOLE" == "true" ]]; then
    echo "$log_event_to_file" >> $PUTIT_LOG_FILE
  else
    echo "$log_event_to_console"
    echo "$log_event_to_file" >> $PUTIT_LOG_FILE
  fi
  unset date
}

check_ruby() {
  log "INFO" "Checking if Ruby is installed..."
  local is_ruby=$(ruby -v | grep -Ec 'ruby 2.4|ruby 2.5|ruby 2.6|ruby 2.7|ruby 2.8')
  if [ ${is_ruby} -ne 1 ]; then
    log "ERROR" "Please install Ruby 2.4.0 or greater."
    exit 1
  else
    log "INFO" "Found: $(ruby -v)"
  fi
}

# set putit GEM_HOME and add GEM_HOME/bin to the path
set_vars() {
  APP_USER=$(whoami)
  APP_GROUP="${APP_USER}"
  export RACK_ENV="production"
  export BUNDLER_VERSION="2.1.4"

  local script_dir=$(dirname $(abspath $0))
  export PUTIT_APP_DIR="${script_dir%/bin}"
  export PUTIT_LOG_FILE="${PUTIT_APP_DIR}/log/build.log"

  if type gem >/dev/null 2>&1 ; then
    export PUTIT_GEM_PATH=$(type gem | cut -d' ' -f3)
  else
    echo >&2 "[ERROR] Required gem binaries not found. Please install gem binary."
    exit 1
  fi

  export GEM_HOME="${PUTIT_APP_DIR}/lib/bundler"
  export CONFIG_DIR="${PUTIT_APP_DIR}/config"

  BUNDLE="$GEM_HOME/bin/bundle"

  log "DEBUG" "Set \$APP_USER: $APP_USER"
  log "DEBUG" "Set \$APP_GROUP: $APP_GROUP"
  log "DEBUG" "Set \$PUTIT_APP_DIR: $PUTIT_APP_DIR"
  log "DEBUG" "Set \$PUTIT_GEM: $PUTIT_GEM_PATH"
  log "DEBUG" "Set \$CONFIG_DIR: $CONFIG_DIR"
  log "DEBUG" "Set \$BUNDLE: $BUNDLE"
  log "DEBUG" "Set \$RUBY: $(which ruby)"

}

set_config() {
  local run_script="${PUTIT_APP_DIR}/bin/run.sh"
  local run_script_template="${PUTIT_APP_DIR}/bin/run.sh.template"
  local thin_config_template="${CONFIG_DIR}/thin.yml.template"
  local thin_config="${CONFIG_DIR}/thin.yml"
  local settings="${CONFIG_DIR}/settings.yml"
  local settings_template="${CONFIG_DIR}/settings.yml.template"

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
  if [ -f ${thin_config_template} ]; then
    sed -e s,APP_DIR,${PUTIT_APP_DIR}, -i ${thin_config_template}
    sed -e s,APP_USER,${APP_USER}, -i ${thin_config_template}
    sed -e s,APP_GROUP,${APP_USER}, -i ${thin_config_template}
    mv ${thin_config_template} ${thin_config}
  elif [ -f ${thin_config} ]; then
    log "WARNING" "Thin server seems to be already configured, skipping..."
  else
    log "ERROR" "Thin server config file and its template are missing!"
    exit 1
  fi

  #settings.yml (only for putit-core)
  if [ ${putit_app_name} == "putit-core" ]; then
    if [ -f ${settings_template} ]; then
      local plugins_path="$(dirname ${PUTIT_APP_DIR})/putit-plugins"
      sed -e s,PLUGINS_PATH_TEMPLATE,${plugins_path}, -i ${settings_template}
      mv ${settings_template} ${settings}
    elif [ -f ${settings} ]; then
      log "WARNING" "Settings file seems to be already configured, skipping..."
    else
      log "ERROR" "Settings file and its template are missing!"
      exit 1
    fi
  fi

  # run.sh
  if [ -f ${run_script_template} ]; then
    sed -e s,APP_DIR_TEMPLATE,${PUTIT_APP_DIR}, -i ${run_script_template}
    sed -e s,APP_NAME_TEMPLATE,${putit_app_name}, -i ${run_script_template}
    mv ${run_script_template} ${run_script}
    chmod +x ${run_script}
  elif [ -f ${run_script} ]; then
    log "WARNING" "Start script seems to be already configured, skipping..."
  else
    log "ERROR" "Start script and its template are missing!"
    exit 1
  fi
}

# check if pg_config is installed - required
check_pg_config() {
  if type pg_config >/dev/null 2>&1 ; then
    export PG_CONFIG_PATH=$(type pg_config | cut -d' ' -f3)
  elif [[ ! -z ${PG_CONFIG_PATH+x} && -f ${PG_CONFIG_PATH} ]] ; then
    return 0
  else
    echo >&2 "[ERROR] No PostgreSQL binaries found. Please install postgresql-devel package. Please try to specify it as argument .$0 --pg_config <PATH>"
    exit 1
  fi
}

install_bundler_gems() {
  ${BUNDLE} config --local path lib/gems >> ${PUTIT_LOG_FILE}
  ${BUNDLE} config --local without development >> ${PUTIT_LOG_FILE}
  ${BUNDLE} config --local build.pg --with-pg-config=${PG_CONFIG_PATH} >> ${PUTIT_LOG_FILE}
  # case for new sqlite3 which is deliverd by putit team. Should apply for Centos 7 only. 
  if ! [ -z ${SQLITE3_PATH+x} ]; then
    ${BUNDLE} config --local build.sqlite3 \ 
      --with-opt-include=${SQLITE3_PATH}/ \
      --with-opt-lib=${SQLITE3_PATH}/lib \
      --with-cflags='-O3 -DSQLITE_ENABLE_ICU' \
      --with-cppflags='icu-config --cppflags' \
      --with-ldflags='icu-config --ldflags' >> ${PUTIT_LOG_FILE}
  fi

  if [ -f "${PUTIT_APP_DIR}/Gemfile" ]; then
    log "INFO" "Installing gems..."
    if $(${BUNDLE} install --gemfile="${PUTIT_APP_DIR}/Gemfile" >> ${PUTIT_LOG_FILE}) ; then
      return 0
    else
      log "ERROR" "Error while installing gems. Check out the log: ${PUTIT_LOG_FILE} for more details."
      exit 1
    fi
  else
    log "ERROR" "Missing Gemfile: ${PUTIT_APP_DIR}/Gemfile"
  fi
}

install_bundler() {
  if [ -f ${BUNDLE} ] && [ -d ${GEM_HOME}/gems/bundler-${BUNDLER_VERSION} ]; then
    log "INFO" "Bundler seems to be already installed, skipping..."
  else
    log "INFO" "Installing Bundler..."
    if $(${PUTIT_GEM_PATH} install bundler --version=${BUNDLER_VERSION} --no-document --no-user-install --bindir=$GEM_HOME/bin --env-shebang >> ${PUTIT_LOG_FILE}); then
      return 0
    else
      log "ERROR" "Error installing Bundler. Check out the log: ${PUTIT_LOG_FILE} for more details."
      exit 1
    fi
  fi
}

run_db_migrations() {
  log "INFO" "Running database migration..."
  cd ${PUTIT_APP_DIR}
  if $(${BUNDLE} exec rake db:migrate >> ${PUTIT_LOG_FILE}); then 
    return 0
  else
    log "ERROR" "Error while running DB migrations. Check out the log: ${PUTIT_LOG_FILE} for more details."
    exit 1
  fi
}

run_db_schema_load() {
  cd ${PUTIT_APP_DIR}
  if [ -f config/secrets.yml ]; then
    log "INFO" "Generating database secret key..."
    sed -i s/SECRET_KEY_TEMPLATE/$(head /dev/urandom | tr -dc a-f0-9 | head -c 128)/g config/secrets.yml
  fi
  log "INFO" "Running database schema load..."
  if ${BUNDLE} exec rake db:schema:load >> ${PUTIT_LOG_FILE}; then
    return 0
  else
    log "ERROR" "Unable to load DB schema. Check out the log: ${PUTIT_LOG_FILE} for more details."
  fi
}

setup_db() {
  log "INFO" "Checking database connection..."
  db_version=$(${BUNDLE} exec rake db:version 2>/dev/null | sed s/"Current version: "//g)
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
check_ruby

if [ ! -z ${PUTIT_DB_ONLY+x} ] && [ ! -z ${PUTIT_BUILD_ONLY+x} ] && [ ! -z ${PUTIT_CONFIG_ONLY+x} ]; then
  log "INFO" "Starting build, details can be found in ${PUTIT_LOG_FILE}..."
  check_pg_config
  install_bundler
  install_bundler_gems
  log "INFO" "Setting up configuration files and start script..."
  set_config
  setup_db
elif [ ! -z ${PUTIT_DB_ONLY+x} ] && [ ! -z ${PUTIT_BUILD_ONLY+x} ]; then
  log "INFO" "Starting build, details can be found in ${PUTIT_LOG_FILE}..."
  check_pg_config
  install_bundler
  install_bundler_gems
  log "INFO" "Skipping configuration files and start script setup..."
  setup_db
elif [ ! -z ${PUTIT_DB_ONLY+x} ] && [ ! -z ${PUTIT_CONFIG_ONLY+x} ]; then
  log "INFO" "Skipping build..."
  log "INFO" "Setting up configuration files and start script..."
  set_config
  setup_db
elif [ ! -z ${PUTIT_CONFIG_ONLY+x} ] && [ ! -z ${PUTIT_BUILD_ONLY+x} ]; then
  log "INFO" "Starting build, details can be found in ${PUTIT_LOG_FILE}..."
  check_pg_config
  install_bundler
  install_bundler_gems
  log "INFO" "Setting up configuration files and start script..."
  set_config
  log "INFO" "Skipping database setup..."
elif [ ! -z ${PUTIT_CONFIG_ONLY+x} ]; then
  log "INFO" "Skipping build..."
  log "INFO" "Setting up configuration files and start script..."
  set_config
  log "INFO" "Skipping database setup..."
elif [ ! -z ${PUTIT_DB_ONLY+x} ]; then
  log "INFO" "Skipping build..."
  log "INFO" "Skipping configuration files and start script setup..."
  setup_db
elif [ ! -z ${PUTIT_BUILD_ONLY+x} ]; then
  log "INFO" "Starting build, details can be found in ${PUTIT_LOG_FILE}..."
  check_pg_config
  install_bundler
  install_bundler_gems
  log "INFO" "Skipping configuration files and start script setup..."
  log "INFO" "Skipping database setup..."
else
  log "INFO" "Starting build, details can be found in ${PUTIT_LOG_FILE}..."
  check_pg_config
  install_bundler
  install_bundler_gems
  log "INFO" "Setting up configuration files and start script..."
  set_config
  setup_db
fi

log "INFO" "Setup done."
