# ukho-tides-pixlet

Display UK tide times on your [Tidbyt](https://tidbyt.com) using the [UKHO Admiralty Tidal API](https://admiraltyapi.portal.azure-api.net).

Shows a tide curve chart with the current tidal state shaded in blue, plus the next high and low tide times and heights.

## Setup

### 1. Get API keys

- **Admiralty API key**: Sign up for a free Discovery account at https://admiraltyapi.portal.azure-api.net
- **Tidbyt credentials**: Open the Tidbyt mobile app → Settings → Get API key

### 2. Find your station ID

Browse https://easytide.admiralty.co.uk to find your station. Default is `0020` (Salcombe).

### 3. Run with Docker

```bash
cp .env.example .env
# Edit .env with your credentials

docker compose up -d
```

The container uses a systemd timer to push updates every 15 minutes.

### 4. Run locally

```bash
bundle install
ADMIRALTY_API_KEY=xxx TIDBYT_DEVICE_ID=xxx TIDBYT_API_TOKEN=xxx ruby bin/push
```

Requires Ruby and ImageMagick (`convert` command).

## Unraid

Install via Community Applications using the included template, or manually:

1. Clone this repo on your Unraid server
2. Copy `.env.example` to `.env` and fill in your credentials
3. Run `docker compose up -d`

## Configuration

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `ADMIRALTY_API_KEY` | Yes | — | UKHO API subscription key |
| `TIDBYT_DEVICE_ID` | Yes | — | Tidbyt device ID |
| `TIDBYT_API_TOKEN` | Yes | — | Tidbyt API token |
| `STATION_ID` | No | `0020` | UKHO station ID (0020 = Salcombe) |
| `PUSH_INTERVAL` | No | `15min` | Update interval (systemd timer format) |
