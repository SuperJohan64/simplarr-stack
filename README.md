# Simplarr-Stack

This project guides you in building an ARR-Stack with Plex or Jellyfin in Docker, focusing on configuring the ARR apps. It does not cover Plex, Jellyfin, or other app configurations, as preferences vary.

It assumes you'll be using NordVPN with the OpenVPN protocol to route BitTorrent traffic from public trackers. If you're not a NordVPN user and want to use another VPN provider, you'll need to adjust the Gluetun configuration in your `simplarr-stack.env` file. For instructions, refer to the [Gluetun documentation](https://github.com/qdm12/gluetun-wiki/tree/main/setup/providers).

## Included Containers

### Media Servers

* **[Plex](https://docs.linuxserver.io/images/docker-plex/)**: A premium media server that requires a paid license for extra features such as hardware (GPU) transcoding and remote access.

OR

* **[Jellyfin](https://docs.linuxserver.io/images/docker-jellyfin/)**: A free media server that supports hardware (GPU) transcoding.

### ARR-Stack

* **[DeUnhealth](https://github.com/qdm12/deunhealth)**: Restarts unhealthy containers.
* **[Gluetun](https://github.com/qdm12/gluetun)**: A VPN client for routing container traffic.
* **[FlareSolverr](https://github.com/flaresolverr/FlareSolverr/pkgs/container/flaresolverr)**: A proxy that completes Cloudflare challenges.
* **[Gotify](https://github.com/gotify/server)**: A simple notification app for your alerts.
* **[qBittorrent](https://docs.linuxserver.io/images/docker-qbittorrent/)**: A full-featured BitTorrent client.
* **[Prowlarr](https://docs.linuxserver.io/images/docker-prowlarr/)**: Manages torrent indexers.
* **[Sonarr](https://docs.linuxserver.io/images/docker-sonarr/)**: Manages TV and anime libraries.
* **[Radarr](https://docs.linuxserver.io/images/docker-radarr/)**: Manages movie libraries.
* **[Cleanuparr](https://github.com/cleanuparr/Cleanuparr/pkgs/container/cleanuparr)**: Removes malicious and stalled downloads from qBittorrent.
* **[Seerr](https://github.com/seerr-team/seerr)**: A front-end for managing media library requests.
* **[Maintainerr](https://github.com/maintainerr/maintainerr)**: Deletes unwanted media from your library.

### Optional Tools

* **[Watchtower (forked by nicholas-fedor)](https://github.com/nicholas-fedor/watchtower)**: Automatically updates containers and removes old images at 4am daily.

## Folder Structure

It's crucial to ensure that your **qBittorrent**, **Sonarr**, **Radarr**, and **Plex/Jellyfin** containers all share the **exact same volume mappings**. If these volumes differ, the containers won't work.

The host or file server's folder structure used by this project is as follows:

```
Media/
├── Anime/
├── Downloads/
│   ├── Complete/
│   └── Downloading/
├── Movies/
└── Shows/
```

The containers will map `Media` to `/data/`, allowing you to access these directories at `/data/Anime/`, `/data/Downloads/`, `/data/Movies/`, etc as follows.

```
data/
├── Anime/
├── Downloads/
│   ├── Complete/
│   └── Downloading/
├── Movies/
└── Shows/
```

## Getting Started

1. Decide whether you want to use Plex or Jellyfin as your media server. If you don’t already have a Plex Pass lifetime subscription, Jellyfin is generally the recommended option. You will need Plex or Jellyfin deployed before the ARR-Stack to complete the setup.
2. Ensure the system running your containers has a static IP address. Throughout this guide, service URLs will use the format `http://<ip>:port` referring to that IP.
3. Rename the `.env.EXAMPLE` files to `.env` and edit the details inside. Some containers require `GLOBAL_PUID` and `GLOBAL_PGID` set to `1000` so changing it is not reccomended.

## Building the Containers

### Plex

To create a Plex container run:

```bash
docker compose -f plex.yml --env-file plex.env up -d
```

To create a Plex container with Nvidia GPU support run:

```bash
docker compose -f plex-nvidia.yml --env-file plex.env up -d
```

### Jellyfin

To create a Jellyfin container run:

```bash
docker compose -f jellyfin.yml --env-file jellyfin.env up -d
```

To create a Jellyfin container with Nvidia GPU support run:

```bash
docker compose -f jellyfin-nvidia.yml --env-file jellyfin.env up -d
```

### ARR-Stack

To create your ARR-Stack run:

```bash
docker compose -f simplarr-stack.yml --env-file simplarr-stack.env up -d
```

### Extra Tools

If you want Watchtower to update your containers dialy run:

```bash
docker compose -f watchtower.yml --env-file watchtower.env up -d
```

# Container Configuration

Next, configure your media server and ARR-stack applications with the settings below.

## Gotify

### 1. Access the Web UI
- Open: `http://<ip>:8880`
  - login with the username *admin* and the password in your `.env` file.
  - Verify you can login and reach `Apps > Create Application`.

You will need to setup each app in Gotify to receive notifications. This will be covered in later steps.

## qBittorrent

When qBittorrent runs for the first time, it generates a default username and password in the container logs. You can view the container logs by running the following command.

```bash
docker logs qbittorrent
```

### 1. Access the Web UI
- Open: `http://<ip>:8080`
  - `Tools > Options > Web UI > Authentication`
    - Change the **Username** and **Password**
    - Check `Bypass authentication for clients on localhost`

### 2. VPN Reconnection Settings
- `Tools > Options > Advanced > qBittorrent Section`
  - **Network interface**: `tun0`
  - **Option IP addresses to bind to**: `All IPv4 addresses`

### 3. BitTorrent
- `Tools > Options > BitTorrent` `Privacy`
  - **Encryption mode**: `Require encryption`
  - Check `Enable anonymous mode`
- `Tools > Options > BitTorrent > Torrent Queueing`
  - Check `Do not count slow torrents in these limits`
- `Tools > Options > BitTorrent > Seeding Limits`
  - Check **When ratio reaches**: `0`
  - Check **When total seeding time reaches**: `0 minutes`
  - Check **When inactive seeding time reaches**: `0 minutes`
  - **Action** `Stop torrent`

### 4. Download Management
- `Tools > Options > Downloads > When adding a torrent`
  - Check `Delete .torrent files afterwards`
- `Tools > Options > Downloads > Saving Management`
  - **Default Torrent Management Mode**: `Automatic`
  - **When Torrent Category changed**: `Relocate Torrent`
  - **When Default Save Path changed**: `Relocate affected torrents`
  - **When Category Save Path changed**: `Relocate affected torrents`
  - Check `Use Subcategories`
  - **Default Save Path**: `/data/Downloads/Complete`
  - Check **Keep incomplete torrents in**: `/data/Downloads/Downloading`

### 5. Reverse Proxy (Optional)
*Note if you don't have a reverse proxy (not included in this guide) you can skip this step.* 
 - `Tools > Options > Web UI > Authentication`
  - Check `Enable reverse proxy support`
  - **Trusted proxies list:** `reverse-proxy-ip`

## Sonarr

### 1. Access the Web UI
- `http://<ip>:8989`
  - **Authentication Method**: `Forms (Login Page)`
  - **Authentication Required**: `Enabled`
  - Set your **Username** and **Password**

### 2. Add Download Client
- `Settings > Download Clients`
  - Click **+ Add**
  - Select `qBittorrent`
    - **Category** `sonarr`
    - Click **Test** then **Save** 
      - *No password should be required if qBittorrent is configured to bypass authentication for clients on localhost*

### 3. Add Root Folder
- `Settings > Media Management > Root Folders`
  - Click **+ Add Root Folder** and choose your TV shows directory
    - `/data/Shows`
    - `/data/Anime`

### 4. Configure Media Management
- `Settings > Media Management`
  - Click `Show Advanced`
  - Check `Rename Episodes`
  - Check `Replace Illegal Characters` 
  - **Colon Repplacement**: `Delete`
  - Optional - Only change these settings if you want a clean file name
    - **Standard Episode Format**: `{Series Title} S{season:00}E{episode:00} {Episode Title}`
    - **Daily Episode Format**: `{Series Title} {Air-Date} {Episode Title}`
    - **Anime Episode Format**: `{Series Title} S{season:00}E{episode:00} {Episode Title}`
  - Check `Delete Empty Folders`
  - **Episode Title Required**: `Never`
  - Check `Import Extra Files`
  - **Import Extra Files**: `.srt, .sub, .ass`
  - Check `Unmonitor Deleted Episodes`
  - Click **Save Changes**

### 5. Custom Formats and Profiles for Shows
- `Settings > Custom Formats`
  - Then click on the + to add a new **Custom Format** followed by the Import in the lower left
    - Open the `5.1 Surround.json` file from this repository and paste the JSON in the empty `Custom Format JSON` box and click the  `Import` then **Save**. Repeat this process for the following JSON files.
      - `HDR.json`
      - `Sonarr Season Packs.json`
      - `Sonarr Target 1080p File Size`
      - `x265.json`
  - Go to `Settings > Profile`
    - Select `HD-1080p`
      - **Minimum Custom Format Score**: `10`
      - Under the **Custom Format**
        - **Sonarr Season Packs**: `10`
        - **Sonarr Target 1080p File Size**: `10`
        - **5.1 Surround**: `2`
        - **x265**: `1`
      - Click **Save**

### 6. Custom Formats and Profiles for Anime (Optional)
- `Settings > Custom Formats`
  - Then click on the + to add a new **Custom Format** followed by the Import in the lower left
  - Import the `Erai-Raws Custom Format.json`, `Erai-Raws Perferred Subs.json`, `Erai-Raws Preferred Audio Language.json` and `SubsPlease HorribleSubs Custom Format.json` Custom Formats
- `Settings > Profile`
  - Click on the **Clone Profile** button icon in the top right of the `HD-1080p` **Quality Profile**.
    - **Name**: `Anime HD-1080p (Erai/SubsPlease)`
    - Check `Upgrades Allowed`
    - **Upgrade Until**: `Bluray-1080p`
    - **Minimum Custom Format Score**: `10`
    - **Upgrade Until Custom Format Score**: `40`
    - **Minimum Custom Format Score Increment**: `1`
    - Under the **Custom Format** set all existing scores to `0` and then configure the following
      - **Erai-Raws Preferred Audio Language**: `20`
      - **Erai-Raws Perferred Subs**: `15`
      - **Erai-Raws Custom Format**: `11`
      - **SubsPlease/HorribleSubs Releases Custom Format**: `10`
      - **x265**: `1`

### 7. Alerts
- `Settings > Connect`
  - Click **+ Add**
    - Click **Gotify**
      - Uncheck `On Grab`
      - Uncheck `On File Import`
      - **Gotify Server**: `http://gluetun:8880`
      - **App Token**: Go to `http://<ip>:8880 > Apps > Create Application` and create a new application called `Sonarr` and copy the token
      - Click **Test** and verify that the notifications are enabled then click **Save**

## Radarr

### 1. Access the Web UI
- Open: `http://<ip>:7878`
  - **Authentication Method**: `Forms (Login Page)`
  - **Authentication Required**: `Enabled`
  - Set your **Username** and **Password**

### 2. Add Download Client
- `Settings > Download Clients`
  - Click **+ Add**
  - Select `qBittorrent`
  - Click **Test** then **Save**
    - *No password should be required if qBittorrent is configured to bypass authentication for clients on localhost*

### 3. Add Root Folder
- Go to `Settings > Media Management > Root Folders`.
  - Click **+ Add Root Folder**
    - `/data/Movies`

### 4. Configure Media Management
- `Settings > Media Management`
  - Click `Show Advanced`
  - Check `Rename Movies`
  - Check `Replace Illegal Characters` 
  - **Colon Repplacement**: `Delete`
  - Optional - Only change this setting if you want a clean file name
    - **Standard Movie Format**: `{Movie Title} ({Release Year})`
  - Check `Delete empty folders`
  - Check `Import Extra Files`
  - **Import Extra Files**: `.srt, .sub, .ass`
  - Check **Unmonitor Deleted Episodes**
  - Click **Save Changes**

### 5. Custom Formats and Profiles for Movies
- `Settings > Custom Formats`
  - Then click on the + to add a new **Custom Format** followed by the Import in the lower left.
  - Open the `5.1 Surround.json` file from this repository and paste the JSON in the empty `Custom Format JSON` box and click the  `Import` then **Save**. Repeat this process for the following JSON files.
    - `HDR.json`
    - `Radarr Target 1080p File Size.json`
    - `x265.json`
- `Settings > Profile`
  - Select `HD-1080p`
    - **Minimum Custom Format Score**: `10`
    - Under the **Custom Format**
      - **Radarr Target 1080p File Size**: `10`
      - **5.1 Surround**: `2`
      - **x265**: `1`
    - Click **Save**

### 6. Alerts
- `Settings > Connect`
  - Click **+ Add**
    - Click **Gotify**
      - Uncheck `On Grab`
      - Uncheck `On File Import`
      - **Gotify Server**: `http://gluetun:8880`
      - **App Token**: Go to `http://<ip>:8880 > Apps > Create Application` and create a new application called `Radarr` and copy the token
      - Click **Test** and verify that the notifications are enabled then click **Save**

## Prowlarr

### 1. Access the Web UI
- Open: `http://<ip>:9696`
  - **Authentication Method**: `Forms (Login Page)`
  - **Authentication Required**: `Enabled`
  - Set your **Username** and **Password**

### 2. Add Indexer Proxies
- `Settings > Indexers`
  - Click the **+** and select **FlareSolverr**
  - **Tags**: `flaresolverr`
    - Press tab after you finish typing to complete the tag
    - *If this step times out you need to restart Gluetun, Flaresolverr, and then Prowlarr's containers in that order until it comples the challenge*
  - Click **Save** 

### 3. Add Indexers
- `Indexers` in the sidebar
  - Click the **+** button to add a new indexer
  - Choose from public or private indexers and follow the prompts to configure them
  - Test and save each indexer once configured
  - If your Indexer requires a Cloudflare challenge, add the `flaresolverr` tag to the indexer.
  
### 4. Connect Prowlarr to Sonarr & Radarr
- `Settings > Apps`
  - Enabled advanced settings by clicking on `Show Advanced`
  - Click **+ Add Application**
  - Choose **Sonarr** or **Radarr**
    - **Name**: e.g., `Sonarr`
    - **Host**: `http://localhost:8989` or `http://localhost:7878`
    - **API Key**: Found in the **Sonarr/Radarr > Settings > General** section
    - Check `Sync Reject Blocklisted Torrent Hashes While Grabbing`
    - Click **Test** then **Save**
    - Repeat these steps for **Radarr**

### 5. Alerts
- `Settings > Notificiations`
  - Click **+ Add**
    - Click **Gotify**
      - **Gotify Server**: `http://gluetun:8880`
      - **App Token**: Go to `http://<ip>:8880 > Apps > Create Application` and create a new application called `Prowlarr` and copy the token
      - Click **Test** and verify that the notifications are enabled then click **Save**

## Cleanuparr

### 1. Access the Web UI
- Open: `http://<ip>:11011`
  - Change your username and password
    - Configuring MFA and Plex is not required.
-Once logged in toggle `Performance mode` in top right hand corner.

### 2. Add Media Apps
- `Media Apps > Sonarr`
  - Click **Add Instance**
    - **Name**: `Sonarr`
    - **URL**: `http://gluetun:8989`
    - **API Key**: copy from `Sonarr > Settings > General > API Key`
    - Click **Save**
- `Media Apps > Radarr`
  - Click **Add Instance**
    - **Name**: `Radarr`
    - **URL**: `http://gluetun:7878`
    - **API Key**: copy from `Radarr > Settings > General > API Key`
    - Click **Save**
- `Media Apps > Download Clients`
  - Click **Add Client**
    - **Name**:: `qBittorrent`
    - **Client Type**: `qBittorrent`
    - **Host**: `http://gluetun:8080`
    - **Username**: qBittorrent's Username
    - **Password**: qBittorrent's Password
      - Change the qBittorrent username/password in `qBittorrent > Tools > Options > WebUI > Authentication > Username/Password`

### 3. Enable Queue Cleaner
- `Settings > Queue Cleaner`
  - General
    - Check **Enabled**
    - **Scheduled Unit**: `Minutes`
    - **Every**: `20`
  - Expand **Failed Import Settings**
    - **Max Strikes**: `3`
    - **Pattern Mode**: `Exclude`
  - Expand **Download Metadata Settings (qBittorrent only)**
    - **Max Strikes for Downloading Metadata**: `3`
  - Expand **Stalled Download Rules**
    - Click **Add Rule**
      - **Name**: `Stall Rule`
      - **Max Strikes**: `3`
      - **Privacy Type**: `Both`
      - Check **Reset Strikes on Progress**
      - **Minimum Porgress to reset**: `1MB`
      - Click **Create**
  - Expand **Slow Download Rules**
    - Click **Add Rule**
      - **Name**: `Slow Rule`
      - **Max Strikes**: `3`
      - **Min Speed**: `10 KB/s`
      - **Maximum Time (Hours)**: `2`
      - **Privacy Type**: `Both`
      - Check **Reset Strikes on Progress**
      - Click **Create**
  - Click **Save Settings**

### 4. Malware Blocker
- `Settings > Malware Blocker`
  - Check **Enabled**
    - Expand **Arr Blocklists**
      - Check **Sonarr > Enabled**
      - **Blocklist Path**: `https://raw.githubusercontent.com/SuperJohan64/simplarr-stack/refs/heads/main/cleanuparr-blacklist.txt`
    - Repeat for **Radarr Settings**
  - Click **Save Settings**

### 5. Notifications
- `Notifications > Add Provider`
  - Click **Gotify**
    - **Name**: `Gotify`
    - **Server URL**: `http://gluetun:8880`
    - **App Token**: Go to `http://<ip>:8880 > Apps > Create Application` and create a new application called `Cleanuparr` and copy the token
      - Click **Test** and verify that the notifications are enabled then click **Save**

## Seerr

### 1. Setup Wizard
- Open `http://<ip>:5055`
  - `Choose Server Type`
    - Enter the details for your media server. Note that Seerr will not resolve `localhost` or `127.0.0.1` so you must specifiy an IP address or Hostname when connecting Seerr to your other services.
  - `Sign in`
    - Click `Sync Libraries` and select all your libraries
    - Click `Continue`
  - `Confiugre Services`
    - Click `Add Radarr Server`
      - Check `Default Server`
      - **Server Name**: `Radarr`
      - **Hostname or IP Address**: `gluetun`
      - **API Key**: Found in the **Sonarr/Radarr > Settings > General** section
      - Click `Test` at bottom of page
      - **Quality Profile**: `HD-1080p`
      - **Root Folder**: `/data/Movies`
      - **Minimum Availability**: `Released`
      - Check `Enable Scan`
      - Click `Add Server` at bottom of page
    - Click `Add Sonarr Server`
      - Check `Default Server`
      - **Server Name**: `Sonarr`
      - **Hostname or IP Address**: `gluetun`
      - **API Key**: Found in the **Sonarr/Radarr > Settings > General** section
      - Click `Test` at bottom of page
      - **Series Type**: `Standard`
      - **Quality Profile**: `HD-1080p`
      - **Root Folder**: `/data/Shows`
      - **Anime Series Type**: `Anime`
      - **Anime Quality Profile**: `Anime HD-1080p (Erai/SubsPlease)` or `HD-1080p` if you did not setup profile for anime
      - **Anime Root Folder**: `/data/Anime`
      - Check `Season Folders`
      - Check `Enable Scan`
      - Click `Add Server` at bottom of page
    - Click `Finish Setup`

### 2. Metadata Providers
- `Settings > Metadata Providers`
  - **Series metadata provider**: `TheTVDB`
  - **Anime metadata provider**: `TheTVDB`
  - Click **Save Changes**

### 3. Settings (Optional)
- `Settings > General`
  - Check `Enable Image Caching`
  - **Discover Region**: `United States` (or whichever region you're in)
  - **Discover Language**: `English` and `Japanese` (Japnese for anime)
  - Check `Hide Available Media`
  - Click **Save Changes**

### 4. Notifications
- `Notifications > Gotify`
  - Check **Enable Agent**
  - **Server URL**: `http://gluetun:8880`
  - **Application Token**: Go to `http://<ip>:8880 > Apps > Create Application` and create a new application called `Seerr` and copy the token
  - Check all the **Notifications Types** click **Test** then **Save Changes**

## Maintainerr

### 1. Setup Media Server
- Open `http://<ip>:6246`
  - `Choose Server Type`
    - For Jellyfin
      - **Jellyfin URL**: `http://jellyfin:8096`
      - **API Key**
        - Go to `http://<ip>:8096 > Dashboard > API Keys` and create a new API key named **Maintainerr**
        - Copy the API Key
      - Click **Test Connection** and **Save Changes**

### 2. Setup Sonarr & Radarr
- Open `http://<ip>:6246 > Settings > Sonarr`
  - `Add Server`
    - **Server Name**: `Sonarr`
    - **Hostname or IP**: `gluetun`
    - **Port**: `8989`
    - **API Key**: Found in the **Sonarr/Radarr > Settings > General** section
- Open `http://<ip>:6246 > Settings > Radarr`
  - `Add Server`
    - **Server Name**: `Radarr`
    - **Hostname or IP**: `gluetun`
    - **Port**: `7878`
    - **API Key**: Found in the **Sonarr/Radarr > Settings > General** section

### 3. Rules - Movies Leaving Soon
- Open `http://<ip>:6246 > Rules`
  - Click `New Rule`
    - **Name**: `Movies Leaving Soon`
    - **Library**: `Movies`
    - **Radarr server**: `Radarr`
    - **Radarr action**: `Unmonitor and delete files`
    - Under **Notifications** click `Configure`
      - Check the box for your notification agent
    - Scroll down to the **Rules** section
      - `Section #1 > Rule #1`
        - **Select First Value**: `Radarr - [list] Tags`
        - **Action**: `Contains (All items)`
        - **Select Second Value...**: `Text`
        - **Custom Value**: `temp`
    - Scroll to bottom of the page and click **Save**

### 4. Rules - Episodes Leaving Soon
  - Click `New Rule`
    - **Name**: `Episodes Leaving Soon`
    - **Library**: `Shows`
    - **Media type**: `Episodes`
    - **Sonarr server**: `Sonarr`
    - **Sonarr action**: `Unmonitor and delete files`
    - Under **Notifications** click `Configure`
      - Check the box for your notification agent
    - Scroll down to the **Rules** section
      - `Section #1 > Rule #1`
        - **Select First Value**: `Sonarr - [list] Tags (show)`
        - **Action**: `Contains (All items)`
        - **Select Second Value...**: `Text`
        - **Custom Value**: `temp`
    - Scroll to bottom of the page and click **Save**

### 5. Rules - Anime Leaving Soon
  - Click `New Rule`
    - **Name**: `Anime Leaving Soon`
    - **Library**: `Anime`
    - **Media type**: `Episodes`
    - **Sonarr server**: `Sonarr`
    - **Sonarr action**: `Unmonitor and delete files`
    - Under **Notifications** click `Configure`
      - Check the box for your notification agent
    - Scroll down to the **Rules** section
      - `Section #1 > Rule #1`
        - **Select First Value**: `Sonarr - [list] Tags (show)`
        - **Action**: `Contains (All items)`
        - **Select Second Value...**: `Text`
        - **Custom Value**: `temp`
    - Scroll to bottom of the page and click **Save**

### 6. Notifications
- Open `http://<ip>:6246 > Settings > Notifications`
  - `Add Agent`
    - **Name**: `Gotify`
    - Check `Enabled`
    - **Agent**: `Gotify`
    - **URL**: `http://gluetun:8880`
    - **Token**: Go to `http://<ip>:8880 > Apps > Create Application` and create a new application called `Maintainerr` and copy the token
    - Check all `Types` boxes
    - Click **Test Connection** and **Save Changes**