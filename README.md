# Simplarr-Stack

This project provides everything you need to spin up an ARR stack with Plex or Jellyfin using Docker. It assumes you'll be using NordVPN with the OpenVPN protocol to route BitTorrent traffic. If you're not a NordVPN user and need to use another VPN provider, you'll need to adjust the Gluetun configuration in the appropiate `.yml` file. For detailed instructions, refer to the [Gluetun documentation](https://github.com/qdm12/gluetun-wiki/tree/main/setup/providers).

### Included Containers:

* **[Watchtower](https://github.com/containrrr/watchtower#)**: Automatically updates containers and removes old images.
* **[DeUnhealth](https://github.com/qdm12/deunhealth)**: Restarts containers if their network connection is lost.
* **[Gluetun](https://github.com/qdm12/gluetun)**: An open-source VPN client for routing container traffic.
* **[qBittorrent](https://docs.linuxserver.io/images/docker-qbittorrent/)**: A full-featured BitTorrent client.
* **[Prowlarr](https://docs.linuxserver.io/images/docker-prowlarr/)**: Manages torrent indexers.
* **[Sonarr](https://docs.linuxserver.io/images/docker-sonarr/)**: Manages TV and anime libraries.
* **[Radarr](https://docs.linuxserver.io/images/docker-radarr/)**: Manages movie libraries.
* **[Jellyseerr](https://docs.jellyseerr.dev/getting-started/docker?docker-methods=docker-compose)**: A front-end for managing media library requests.

AND

* **[Plex](https://docs.linuxserver.io/images/docker-plex/)**: An premium media server that requires a paid license for extra features such as transcoding and remote access.

OR

* **[Jellyfin](https://docs.linuxserver.io/images/docker-jellyfin/)**: An open source media server that supports hardware transcoding for free.

### Before You Start:

1. Decide whether you want to use Plex or Jellyfin to serve your media. If you don’t already have a Plex Pass lifetime subscription, Jellyfin is generally the recommended option. Plex used to offer free streaming outside your local network, but this feature now requires a paid subscription. If remote streaming is important to you, Jellyfin can support it—but securely enabling remote access to Jellyfin is complex, increases ongoing maintenance, and is not generally recommended for most users.
2. Rename `simplarr-stack.env.EXAMPLE` to `simplarr-stack.env` and update the details inside to fit your needs.
3. The `.yml` and `.env` files mount a single folder for containers. If your media is stored across multiple folders or drives, you’ll need to adjust the volume bindings for each container. Note that you must have consisitent bindings across your qBittorrent, Sonarr, Radarr, and Plex/Jellyfin containers or else they will not work properly.

### Building the Containers:

Once everything is configured, you can build your ARR stack with Plex by running:

```bash
docker compose -f simplarr-plex-stack.yml --env-file simplarr-stack.env up -d
```

or for Jellyfin:

```bash
docker compose -f simplarr-jellyfin-stack.yml --env-file simplarr-stack.env up -d
```

This repository also contains two batch files with the commands to quickly create the containers on Windows.

# Container Configuration

It's crucial to ensure that your **qBittorrent**, **Sonarr**, **Radarr**, and **Plex/Jellyfin** containers all share the **exact same volume mappings**. If these volumes differ, Sonarr and Radarr won't be able to properly manage your media library.

## qBittorrent

When qBittorrent runs for the first time, it generates a default username and password, which are shown in the container logs. You can view these logs via **Docker Desktop** or **Portainer**.

### 1. Access the Web UI

Open: `http://<ip>:8080`

Then go to:

- `Tools > Options > Web UI > Authentication`
  - Change the **Username** and **Password**.
  - Check: **Bypass authentication for clients on localhost**

### 2. VPN Reconnection Settings

Go to:

- `Tools > Options > Advanced > qBittorrent Section`
  - **Network interface**: `tun0`
  - **Option IP addresses to bind to**: `All IPv4 addresses`

### 3. Privacy Settings

Navigate to:

- `Tools > Options > BitTorrent > Privacy`
  - **Encryption mode**: `Require encryption`
  - Check: **Enable anonymous mode**

### 4. Torrent Queueing

- `Tools > Options > BitTorrent > Torrent Queueing`
  - Check: **Do not count slow torrents in these limits**

### 5. Seeding Limits

- `Tools > Options > BitTorrent > Seeding Limits`
  - Check: **When ratio reaches**: `0`
  - Check: **When total seeding time reaches**: `0 minutes`
  - Check: **When inactive seeding time reaches**: `0 minutes`
  - Action: **Stop torrent**

### 6. Download Management

- `Tools > Options > Downloads > Saving Management`
  - **Default Torrent Management Mode**: `Automatic`
  - **When Torrent Category changed**: `Relocate Torrent`
  - **When Default Save Path changed**: `Relocate affected torrents`
  - **When Category Save Path changed**: `Relocate affected torrents`
  - Check: **Use Subcategories**
  - **Default Save Path**: `/data/Downloads/Complete`
  - Check: **Keep incomplete torrents in**: `/data/Downloads/Downloading`

## Sonarr

### 1. Access the Web UI
Open:
`http://<ip>:8989`
  - **Authentication Method**: `Forms (Login Page)`
  - **Authentication Required**: `Enabled`
  - Set your **Username** and **Password**.

### 2. Add Download Client
  - Go to `Settings > Download Clients`
  - Click **+ Add**
  - Select qBittorrent
  - Change the Category to:
    - `sonarr`
  - Click `Test` then `Save`. No password should be required if qBittorrent is configured to bypass authentication for clients on localhost.

### 3. Add Root Folder
   - Go to `Settings > Media Management > Root Folders`
   - Click **+ Add Root Folder** and choose your TV shows directory.
      - `/data/Shows`
      - `/data/Anime`

### 4. Configure Media Management
  - Go to `Settings > Media Management`
    - Click **Show Advanced**
    - Check: **Rename Episodes**
    - **Colon Repplacement**: `Delete`
    - **Standard Episode Format**: `{Series Title} S{season:00}E{episode:00} {Episode Title}`
    - **Daily Episode Format**: `{Series Title} {Air-Date} {Episode Title}`
    - **Anime Episode Format**: `{Series Title} S{season:00}E{episode:00} {Episode Title}`
    - Check: **Create Empty Series Folders**
    - Check: **Delete Empty Folders**
    - **Episode Title Required**: `Never`
    - Check: **Import Extra Files**
    - **Import Extra Files**: `srt`
    - Check: **Unmonitor Deleted Episodes**

### 5. Custom Formats and Profiles for Shows
  - Go to `Settings > Custom Formats`
    - Then click on the + to add a new **Custom Format** followed by the Import in the lower left.
    - Open the `5.1 Surround.json` file from this repository and paste the JSON in the empty **Custom Format JSON** box and click the  **Import** then **Save**. Repeat this process for the following JSON files.
      - `HDR.json`
      - `Sonarr Season Packs.json`
      - `Sonarr Target 1080p File Size and Blocklists.json`
      - `x265.json`
  - Go to `Settings > Profile`
    - Select `HD-1080p`
      - **Minimum Custom Format Score**: `10`
      - Under the **Custom Format** section assign the following scores.
        - **Sonarr Season Packs**: `10`
        - **Sonarr Target 1080p File Size and Blocklists**: `10`
        - **5.1 Surround**: `2`
        - **x265**: `1`
      - Click Save.

### 6. Custom Formats and Profiles for Anime (Optional)
  - Go to `Settings > Custom Formats`
    - Then click on the + to add a new **Custom Format** followed by the Import in the lower left.
  - Import the `Erai-Raws Custom Format.json` and `SubsPlease HorribleSubs Custom Format.json` Custom Formats.
    - Go to `Settings > Profile`
    - Click on the **Clone Profile** button icon in the top right of the `HD-1080p` **Quality Profile**.
      - **Name:** `Anime HD-1080p (Erai/SubsPlease)`
      - Check **Upgrades Allowed**
      - **Upgrade Until:** `HDTV-1080p`
      - **Minimum Custom Format Score:** `10`
      - **Upgrade Until Custom Format Score:** `25`
      - **Minimum Custom Format Score Increment:** `1`
      - Under the **Custom Format** section assign the following scores.
        - **Erai-Raws Custom Format:** `20`
        - **SubsPlease/HorribleSubs Releases Custom Format:** `10`
        - **x265:** `3`
        - **Sonarr Season Packs:** `2`

## Radarr

### 1. Access the Web UI
  - Open: `http://<ip>:7878`
  - **Authentication Method**: `Forms (Login Page)`
  - **Authentication Required**: `Enabled`
  - Set your **Username** and **Password**.

### 2. Add Download Client
  - Go to `Settings > Download Clients`.
  - Click **+ Add**
  - Select qBittorrent
  - Click `Test` then `Save`. No password should be required if qBittorrent is configured to bypass authentication for clients on localhost.

### 3. Add Root Folder
   - Go to `Settings > Media Management > Root Folders`.
   - Click **+ Add Root Folder** and choose your TV shows directory.
      - `/data/Movies`

### 4. Configure Media Management
  - Go to `Settings > Media Management`
    - Click **Show Advanced**
    - Check: **Rename Movies**
    - **Colon Repplacement**: `Delete`
    - **Standard Movie Format**: `{Movie Title} ({Release Year})`
    - Check: **Import Extra Files**
    - **Import Extra Files**: `srt`
    - Check: **Unmonitor Deleted Episodes**

### 5. Custom Formats and Profiles for Movies
  - Go to `Settings > Custom Formats`
    - Then click on the + to add a new **Custom Format** followed by the Import in the lower left.
    - Open the `5.1 Surround.json` file from this repository and paste the JSON in the empty **Custom Format JSON** box and click the **Import** then **Save** button. Repeat this process for the following JSON files.
      - `HDR.json`
      - `Radarr Target 1080p File Size.json`
      - `x265.json`
  - Go to `Settings > Profile`
    - Select `HD-1080p`
      - **Minimum Custom Format Score**: `10`
      - Under the **Custom Format** section assign the following scores.
        - **Radarr Target 1080p File Siz**: `10`
        - **5.1 Surround**: `2`
        - **x265**: `1`
      - Click Save.

## Prowlarr

### 1. Access the Web UI
  - Open: `http://<ip>:9696`
  - **Authentication Method**: `Forms (Login Page)`
  - **Authentication Required**: `Enabled`
  - Set your **Username** and **Password**.

### 2. Add Indexers
   - Go to `Indexers` in the sidebar.
   - Click the **+** button to add a new indexer.
   - Choose from public or private indexers and follow the prompts to configure them.
   - Test and save each indexer once configured.
  
### 3. Connect Prowlarr to Sonarr & Radarr
   - Go to `Settings > Apps` in Prowlarr.
   - Click **+ Add Application**.
   - Choose **Sonarr** or **Radarr** and configure:
   - **Name**: e.g., `Sonarr` or `Radarr`
   - **Host**: `http://localhost:8989` or `http://localhost:7878`
   - **API Key**: Found in the **Sonarr/Radarr > Settings > General** section.
   - Click **Test**, then **Save**. Now Prowlarr will manage indexers for both Sonarr and Radarr.

## Jellyseerr

### 1. Setup Wizard
  - `Choose Server Type`
    - Enter the details for your media server. Note that Jellyseerr will not resolve `localhost` or `127.0.0.1` so you must specifiy an IP address or Hostname when connecting Jellyseerr to your other services.
  - `Sing in`
    - Click `Sync Libraries` and select all your libraries
    - Click `Continue`.
  - `Confiugre Services`
    - Click `Add Radarr Server`
      - Check `Default Server`
      - **Server Name:** `Radarr`
      - **Hostname or IP Address**: `Your.I.P.Address`
      - **API Key:** Found in the **Sonarr/Radarr > Settings > General** section.
      - Click `Test` at bottom of page
      - **Quality Profile:** `HD-1080p`
      - **Root Folder:** `/data/Movies`
      - **Minimum Availability:** `Released`
      - Check `Enable Scan`.
      - Click `Add Server` at bottom of page.
    - Click `Add Sonarr Server`
      - Check `Default Server`
      - **Server Name:** `Sonarr`
      - **Hostname or IP Address**: `Your.I.P.Address`
      - **API Key:** Found in the **Sonarr/Radarr > Settings > General** section.
      - Click `Test` at bottom of page
      - **Series Type:** `Standard`
      - **Quality Profile:** `HD-1080p`
      - **Root Folder:** `/data/Shows`
      - **Anime Series Type:** `Anime`
      - **Anime Quality Profile:** `Anime HD-1080p (Erai/SubsPlease)`
      - **Anime Root Folder:** `/data/Anime`
      - Check `Season Folders`
      - Check `Enable Scan`
      - Click `Add Server` at bottom of page
    - Click `Finish Setup`

### 2. Settings
  - Go to `Settings > General`
    - Check `Enable Image Caching`
    - **Discover Region:** `United States` (or whichever region you're in)
    - **Discover Language:** `English` and `Japanese` (for Anime)
    - Check `Hide Available Media`
    - Click `Save Changes`