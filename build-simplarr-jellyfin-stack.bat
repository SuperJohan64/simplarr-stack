docker compose -f "%~dp0arr.yml" -f "%~dp0jellyfin.yml" --env-file "%~dp0simplarr-stack.env" up -d
PAUSE