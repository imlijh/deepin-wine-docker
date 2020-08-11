#! /bin/bash

toHelp() {
  echo "hello, world"
}

toRunPulseAudio() {
  [ $# -eq 1 ] || { toHelp; return 1; }
  echo "start to init pulseaudio server"
  docker ps | grep "deepin-wine" >/dev/null 2>&1 \
  && {
    printf "%s" "application exist!" \
      " please execute the command './command.sh -d' to uninstall" \
      " or execute the command './command.sh -', then" \
      " execute command './command.sh -i' to init pulseaudio server"$'\n'
    return 1
  }
  if docker images | grep "pulseaudio-server_pulseaudio" >/dev/null 2>&1; then
    startResult=$(docker-compose -f $1/pulseaudio-server/docker-compose.yml up -d 2>&1 >/dev/null) \
    && printf "%s" "pulseaudio server start successfully.." \
      " Please execute the command './command.sh -r applicationName'" \
      " to start application container"$'\n' \
    || echo "pulseaudio server start failed, the reason is $startResult.."
  else
    buildResult=$(docker-compose -f $1/pulseaudio-server/docker-compose.yml build 2>&1 >/dev/null) \
    && startResult=$(docker-compose -f $1/pulseaudio-server/docker-compose.yml up -d 2>&1 >/dev/null) \
    && printf "%s" "pulseaudio server build and start successfully.." \
      " Please execute the command './command.sh -r applicationName'" \
      " to start application container"$'\n' \
    || printf "%s" "pulseaudio server build and start failed.." \
      " the reason is $buildResult, and $startResult.."
  fi
}

_getWineAppName() {
  case $1 in
    # if you need to launch another app, add the app name here.
    wechat)
      appName='Wechat'
      ;;
    wxwork)
      appName='WXWork'
      ;;
    tim)
      appName='TIM'
      ;;
    thunder)
      appName='Thunder'
      ;;
    qqmusic)
      appName='QQMusic'
      ;;
    *)
      printf "unsupported_application"
      return 1
      ;;
  esac
  printf "$appName"
}

toStartSoftware() {
  [ $# -eq 2 ] || { toHelp; return 1; }
  if _getWineAppName "$1" >/dev/null 2>&1; then
    echo "start to start $1 application"
    toRunSoftwareContainer $1 $2
  fi
}

_runDockerByAppName() {
  appName=$(_getWineAppName "$1") || { echo "unsupported app"; return 1; }
  [ -d "$HOME/Documents/$appName" ] || mkdir -p "$HOME/Documents/$appName"
  docker0IP=$(ip addr | grep 'docker0' | grep 'inet' | cut -c 10- | cut -c -10)
  runResult=$(docker run -d -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v $HOME/Documents/$appName:/home/files -e DISPLAY=unix$DISPLAY \
    -e GDK_SCALE -e GDK_DPI_SCALE -e PULSE_SERVER=tcp:$docker0IP:4713 \
    --name deepin-wine-$1 deepin-wine-$1-image 2>&1 >/dev/null) \
  && echo "$1 container run successfully.. enjoy!" \
  || echo "$1 container run failed.. the reason is $runResult"
}

toRunSoftwareContainer() {
  docker ps | grep "pulseaudio_server" >/dev/null 2>&1 \
  || {
    printf "%s" "pulseaudio server not running, please execute the command" \
      " './command.sh -i' to init pulseaudio server"$'\n'
    return 1
  }
  if docker images | grep "deepin-wine-$1" >/dev/null 2>&1; then
    if docker ps -a | grep "deepin-wine-$1" >/dev/null 2>&1; then
      if docker ps | grep "deepin-wine-$1" >/dev/null 2>&1; then
        startResult=$(docker exec deepin-wine-$1 /bin/bash -c "/home/run.sh" 2>&1 >/dev/null) \
          && echo "restart $1 application successfully" \
          || echo "restart $1 application failed, the reason is $startResult"
      else
        startResult=$(docker start deepin-wine-$1 2>&1 >/dev/null) \
          && echo "start $1 container successfully.." \
          || echo "start $1 container failed, reason is: $startResult.."
      fi
    else
      _runDockerByAppName $1
    fi
  else
    appName=$(_getWineAppName "$1") || return 1
    buildResult=$(docker build -t deepin-wine-$1-image $2/wine/$appName/ 2>&1 >/dev/null) \
    && echo "$1 container build successfully." \
    || { echo "$1 container build failed.. the reason is $buildResult"; return 1; }
    _runDockerByAppName $1
  fi
}

toStopSoftware() {
  [ $# -eq 1 ] || { toHelp; return 1; }
  if _getWineAppName "$1" >/dev/null 2>&1; then
    echo "start to stop $1 application"
    toStopSoftwareContainer $1
  fi
}

toStopSoftwareContainer() {
  if docker ps -a | grep "deepin-wine-$1" >/dev/null 2>&1; then
    result=$(docker stop deepin-wine-$1 2>&1 >/dev/null) \
    || echo "close $1 container failed, reason is: $result.."
  fi
  echo "close $1 container successfully.."
}

toClosePulseAudio() {
  [ $# -eq 1 ] || { toHelp; return 1; }
  echo "start to close pulseaudio.."
  if docker ps | grep "deepin-wine" >/dev/null 2>&1; then
    stopAppResult=$(docker stop $(docker ps | grep "deepin-wine" | awk '{print $1 }') 2>&1 >/dev/null) \
    && echo "stop application successfully.. now start to stop pulseaudio-server.." \
    || {
      echo "stop application failed, the reason is $stopAppResult.."
      return 1
    }
  fi
  if docker ps | grep "pulseaudio_server" >/dev/null 2>&1; then
    stopResult=$(docker-compose -f $1/pulseaudio-server/docker-compose.yml down 2>&1 >/dev/null) \
    || echo "stop pulseaudio server failed, the reason is $stopResult.."
  fi
  echo "stop pulseaudio server successfully.."
}

toUninstallAll() {
  [ $# -eq 1 ] || { toHelp; return 1; }
  echo "start to uninstall.."
  if docker images | grep "deepin-wine" >/dev/null 2>&1; then
    if docker ps | grep "deepin-wine" >/dev/null 2>&1; then
      wineContainers=$(docker ps | grep "deepin-wine" | awk '{print $1}')
      stopWineResult=$(docker stop $wineContainers 2>&1 >/dev/null) \
      && echo "stop wine containers successfully.." \
      || {
        echo "stop wine containers failed.. the reason $stopWineResult.."
        return 1
      }
    fi
    if docker ps -a | grep "deepin-wine" >/dev/null 2>&1; then
      wineContainer=$(docker ps -a | grep "deepin-wine" | awk '{print $1}')
      removeWineResult=$(docker rm $wineContainer 2>&1 >/dev/null) \
      && echo "remove wine containers successfully.." \
      || {
        echo "remove wine containers failed.. the reason $removeWineResult"
        return 1
      }
    fi
    wineImages=$(docker images | grep "deepin-wine" | awk '{print $3}')
    stopWineResult=$(docker rmi $wineImages 2>&1 >/dev/null) \
    && echo "remove wine images successfully.. start to stop and remove pulseaudio server container.." \
    || {
      echo "remove wine containers failed.. the reason is $stopWineResult.."
      return 1
    }
  fi

  if docker images | grep "pulseaudio-server_pulseaudio" >/dev/null 2>&1; then
    pulseaudioImages=$(docker images | grep "pulseaudio-server_pulseaudio" | awk '{print $3}')
    if docker ps | grep "pulseaudio_server" >/dev/null 2>&1; then
      stopPulseAudioResult=$(docker-compose -f $1/pulseaudio-server/docker-compose.yml down 2>&1 >/dev/null) \
      && echo "stop pulseaudio server successfully.." \
      || {
        echo "stop pulseaudio pulseaudio server failed.. the reason is $stopPulseAudioResult"
        return 1
      }
    fi
    removePulseAudioResult=$(docker rmi $pulseaudioImages 2>&1 >/dev/null) \
    && echo "remove pulseaudio server successfully.." \
    || {
      echo "remove pulseaudio server failed.. the reason is $removePulseAudioResult.."
      return 1
    }
  fi
  echo "uninstall deepin-wine-docker successfully!"
}

toUninstall() {
  [ $# -eq 3 ] || { toHelp; return 1; }
  if docker ps -a | grep "deepin-wine-$3" >/dev/null 2>&1; then
    if docker ps | grep "deepin-wine-$3" >/dev/null 2>&1; then
      stopResult=$(docker stop deepin-wine-$3 2>&1 >/dev/null) \
      && echo "stop the $3 container successfully... now start to remove the $3 container.." \
      || {
        echo "stop the $3 container failed.. the reason is $stopResult"
        return 1
      }
    fi
    case $2 in
      image)
        removeResult=$(docker rm deepin-wine-$3 2>&1 >/dev/null && docker rmi deepin-wine-$3-image 2>&1 >/dev/null) \
        && echo "remove the $3 container and image successfully.." \
        || echo "remove the $3 container failed.. the reason is $removeResult.."
        ;;
      container)
        removeResult=$(docker rm deepin-wine-$3 2>&1 >/dev/null) \
        && echo "remove the $3 container successfully.." \
        || {
          echo "remove the $3 container failed.. the reason is $removeResult.."
          return 1
        }
        ;;
    esac
  fi
  printf "%s" "uninstall deepin-wine-$3 successfully.." \
    " Please execute the command './command.sh -r applicationName'" \
    " to create and start the $3 container.."$'\n'
}

toUpgrade() {
  [ $# -eq 1 ] || { toHelp; return 1; }
  echo "start to upgrade.."
  toUninstallAll $1 || return 1
  upgradePulseAudioResult=$(docker-compose -f $1/pulseaudio-server/docker-compose.yml build 2>&1 >/dev/null) \
  && echo "rebuild the pulseaudio server container successfully.." \
  || {
    echo "rebuild pulseaudio failed.. the reason is $upgradePulseAudioResult"
    return 1
  }
  printf "%s" "please execute the command './command.sh -i' to init the" \
    " pulseaudio-server and execute the command './command.sh -r applicationName'," \
    " then will be upgrade the application container"$'\n'
}

##
type docker 2>&1 >/dev/null || {
  echo "docker command not found, please install docker.Abotring."
  exit
}

type docker-compose 2>&1 >/dev/null || {
  echo "docker-compose command not found, please install docker.Abotring."
  exit
}

xhostState=$(xhost +local:) && echo "start xhost successfully.." \
|| echo "start xhost failed.. the reason is $xhost.."

command_folder=$(
  cd "$(dirname "$0")"
  pwd
)

case $1 in
  -i)
    toRunPulseAudio $command_folder
    ;;
  -r)
    toStartSoftware $2 $command_folder
    ;;
  -s)
    toStopSoftware $2
    ;;
  -c)
    toClosePulseAudio $command_folder
    ;;
  -d)
    if [ $# -eq 1 ]; then
      toUninstallAll $command_folder
    else
      toUninstall $command_folder $2 $3
    fi
    ;;
  -u)
    toUpgrade $command_folder
    ;;
  -h) ;&
  *)
    toHelp
    ;;
esac
