# Simplarr-Stack

This project guides you in building an ARR stack with Plex or Jellyfin in Docker, focusing on configuring the ARR apps. It does not cover Plex, Jellyfin, or other app configurations, as preferences vary.

It assumes you'll be using NordVPN with the OpenVPN protocol to route BitTorrent traffic. If you're not a NordVPN user and want to use another VPN provider, you'll need to adjust the Gluetun configuration in the `arr.yml` file. For detailed instructions, refer to the [Gluetun documentation](https://github.com/qdm12/gluetun-wiki/tree/main/setup/providers).

### Included Containers

* **[Watchtower](https://github.com/nicholas-fedor/watchtower)**: Automatically updates containers and removes old images at 4am daily.
* **[DeUnhealth](https://github.com/qdm12/deunhealth)**: Restarts containers if their network connection is lost.
* **[Gluetun](https://github.com/qdm12/gluetun)**: A VPN client for routing container traffic.
* **[qBittorrent](https://docs.linuxserver.io/images/docker-qbittorrent/)**: A full-featured BitTorrent client.
* **[Prowlarr](https://docs.linuxserver.io/images/docker-prowlarr/)**: Manages torrent indexers.
* **[Sonarr](https://docs.linuxserver.io/images/docker-sonarr/)**: Manages TV and anime libraries.
* **[Radarr](https://docs.linuxserver.io/images/docker-radarr/)**: Manages movie libraries.
* **[Jellyseerr](https://docs.jellyseerr.dev/getting-started/docker?docker-methods=docker-compose)**: A front-end for managing media library requests.

AND

* **[Plex](https://docs.linuxserver.io/images/docker-plex/)**: A premium media server that requires a paid license for extra features such as hardware (GPU) transcoding and remote access.

OR

* **[Jellyfin](https://docs.linuxserver.io/images/docker-jellyfin/)**: A free media server that supports hardware (GPU) transcoding.

### Getting Started

1. Decide whether you want to use Plex or Jellyfin as your media server. If you don’t already have a Plex Pass lifetime subscription, Jellyfin is generally the recommended option.
2. Rename `simplarr-stack.env.EXAMPLE` to `simplarr-stack.env` and edit the details inside for your deployment. Unless you have specific requirements you can leave `GLOBAL_PUID` and `GLOBAL_PGID` set to `1000`.
3. This project's `.yml` and `.env` files map a single folder to the containers. If your media is spread across multiple folders/drives, you’ll need to adjust the volume mappings in the `simplarr-stack.env`, `arr.yml`, and the `plex.yml` or `jellyfin.yml` files for each container. These files have placeholder comments to make that process easy.
4. If you're not using an Nvidia GPU with Plex or Jellyfin, open their `.yml` files and delete the lines that enable GPU support.

### Building the Containers

For Plex run:

```bash
docker compose -f arr.yml -f plex.yml --env-file simplarr-stack.env up -d
```

For Jellyfin run:

```bash
docker compose -f arr.yml -f jellyfin.yml --env-file simplarr-stack.env up -d
```

Or for just the ARR apps run:

```bash
docker compose -f arr.yml --env-file simplarr-stack.env up -d
```

If you're using Docker on Windows you can also run these commands with the included `build-simplarr-plex-stack.bat` or `build-simplarr-jellyfin-stack.bat` files.

# Container Configuration

## Folder Structure

It's crucial to ensure that your **qBittorrent**, **Sonarr**, **Radarr**, and **Plex/Jellyfin** containers all share the **exact same volume mappings**. If these volumes differ the conainters won't work.

The folder structure used by this project is as follows. 

- Media
  - Anime
  - Downloads
    - Complete
    - Downloading
  - Movies
  - Shows

All containers will have the `Media` folder mounted to `/data/Media`. If you're on Windows you can create these folders by running the `create-media-folders.bat` file.

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

### 3. Privacy Settings
- `Tools > Options > BitTorrent > Privacy`
  - **Encryption mode**: `Require encryption`
  - Check `Enable anonymous mode`

### 4. Torrent Queueing
- `Tools > Options > BitTorrent > Torrent Queueing`
  - Check `Do not count slow torrents in these limits`

### 5. Seeding Limits
- `Tools > Options > BitTorrent > Seeding Limits`
  - Check **When ratio reaches**: `0`
  - Check **When total seeding time reaches**: `0 minutes`
  - Check **When inactive seeding time reaches**: `0 minutes`
  - **Action** `Stop torrent`

### 6. Download Management
- `Tools > Options > Downloads > Saving Management`
  - **Default Torrent Management Mode**: `Automatic`
  - **When Torrent Category changed**: `Relocate Torrent`
  - **When Default Save Path changed**: `Relocate affected torrents`
  - **When Category Save Path changed**: `Relocate affected torrents`
  - Check `Use Subcategories`
  - **Default Save Path**: `/data/Downloads/Complete`
  - Check **Keep incomplete torrents in**: `/data/Downloads/Downloading`

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
    - Click `Test` then `Save` 
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
  - **Standard Episode Format**: `{Series Title} S{season:00}E{episode:00} {Episode Title}`
  - **Daily Episode Format**: `{Series Title} {Air-Date} {Episode Title}`
  - **Anime Episode Format**: `{Series Title} S{season:00}E{episode:00} {Episode Title}`
  - Check `Create Empty Series Folders`
  - Check `Delete Empty Folders`
  - **Episode Title Required**: `Never`
  - Check `Import Extra Files`
  - **Import Extra Files**: `srt`
  - Check `Unmonitor Deleted Episodes`

### 5. Custom Formats and Profiles for Shows (Optional)
- `Settings > Custom Formats`
  - Then click on the + to add a new **Custom Format** followed by the Import in the lower left
    - Open the `5.1 Surround.json` file from this repository and paste the JSON in the empty `Custom Format JSON` box and click the  `Import` then `Save`. Repeat this process for the following JSON files.
      - `HDR.json`
      - `Sonarr Season Packs.json`
      - `Sonarr Target 1080p File Size and Blocklists.json`
      - `x265.json`
  - Go to `Settings > Profile`
    - Select `HD-1080p`
      - **Minimum Custom Format Score**: `10`
      - Under the **Custom Format**
        - **Sonarr Season Packs**: `10`
        - **Sonarr Target 1080p File Size and Blocklists**: `10`
        - **5.1 Surround**: `2`
        - **x265**: `1`
      - Click `Save`

### 6. Custom Formats and Profiles for Anime (Optional)
- `Settings > Custom Formats`
  - Then click on the + to add a new **Custom Format** followed by the Import in the lower left
  - Import the `Erai-Raws Custom Format.json` and `SubsPlease HorribleSubs Custom Format.json` Custom Formats
    - Go to `Settings > Profile`
    - Click on the **Clone Profile** button icon in the top right of the `HD-1080p` **Quality Profile**
      - **Name:** `Anime HD-1080p (Erai/SubsPlease)`
      - Check `Upgrades Allowed`
      - **Upgrade Until:** `HDTV-1080p`
      - **Minimum Custom Format Score:** `10`
      - **Upgrade Until Custom Format Score:** `25`
      - **Minimum Custom Format Score Increment:** `1`
      - Under the **Custom Format** remove all the current values and replace them the following
        - **Erai-Raws Custom Format:** `20`
        - **SubsPlease/HorribleSubs Releases Custom Format:** `10`
        - **x265:** `3`
        - **Sonarr Season Packs:** `2`

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
  - Click `Test` then `Save`
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
  - **Standard Movie Format**: `{Movie Title} ({Release Year})`
  - Check `Delete empty folders`
  - Check `Import Extra Files`
  - **Import Extra Files**: `srt`
  - Check **Unmonitor Deleted Episodes**

### 5. Custom Formats and Profiles for Movies (Optional)
- `Settings > Custom Formats`
  - Then click on the + to add a new **Custom Format** followed by the Import in the lower left.
  - Open the `5.1 Surround.json` file from this repository and paste the JSON in the empty `Custom Format JSON` box and click the  `Import` then `Save`. Repeat this process for the following JSON files.
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
    - Click `Save`

## Prowlarr

### 1. Access the Web UI
- Open: `http://<ip>:9696`
  - **Authentication Method**: `Forms (Login Page)`
  - **Authentication Required**: `Enabled`
  - Set your **Username** and **Password**

### 2. Add Indexers
- `Indexers` in the sidebar
  - Click the **+** button to add a new indexer
  - Choose from public or private indexers and follow the prompts to configure them
  - Test and save each indexer once configured
  
### 3. Connect Prowlarr to Sonarr & Radarr
- `Settings > Apps`
  - Click **+ Add Application**.
  - Choose **Sonarr** or **Radarr**
    - **Name**: e.g., `Sonarr` or `Radarr`
    - **Host**: `http://localhost:8989` or `http://localhost:7878`
    - **API Key**: Found in the **Sonarr/Radarr > Settings > General** section
    - Click `Test` then `Save`
      - *Prowlarr will manage indexers for both Sonarr and Radarr*

## Jellyseerr

### 1. Setup Wizard
- Open `http://<ip>:5055`
  - `Choose Server Type`
    - Enter the details for your media server. Note that Jellyseerr will not resolve `localhost` or `127.0.0.1` so you must specifiy an IP address or Hostname when connecting Jellyseerr to your other services.
  - `Sign in`
    - Click `Sync Libraries` and select all your libraries
    - Click `Continue`
  - `Confiugre Services`
    - Click `Add Radarr Server`
      - Check `Default Server`
      - **Server Name:** `Radarr`
      - **Hostname or IP Address**: `Your.I.P.Address`
      - **API Key:** Found in the **Sonarr/Radarr > Settings > General** section
      - Click `Test` at bottom of page
      - **Quality Profile:** `HD-1080p`
      - **Root Folder:** `/data/Movies`
      - **Minimum Availability:** `Released`
      - Check `Enable Scan`
      - Click `Add Server` at bottom of page
    - Click `Add Sonarr Server`
      - Check `Default Server`
      - **Server Name:** `Sonarr`
      - **Hostname or IP Address**: `Your.I.P.Address`
      - **API Key:** Found in the **Sonarr/Radarr > Settings > General** section
      - Click `Test` at bottom of page
      - **Series Type:** `Standard`
      - **Quality Profile:** `HD-1080p`
      - **Root Folder:** `/data/Shows`
      - **Anime Series Type:** `Anime`
      - **Anime Quality Profile:** `Anime HD-1080p (Erai/SubsPlease)` or `HD-1080p` if you did not setup profile for anime
      - **Anime Root Folder:** `/data/Anime`
      - Check `Season Folders`
      - Check `Enable Scan`
      - Click `Add Server` at bottom of page
    - Click `Finish Setup`

### 2. Settings (Optional)
- `Settings > General`
  - Check `Enable Image Caching`
  - **Discover Region:** `United States` (or whichever region you're in)
  - **Discover Language:** `English` and `Japanese` (Japnese for anime)
  - Check `Hide Available Media`
  - Click `Save Changes`
