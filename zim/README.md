# ZIM Files Directory

Place your .zim files in this directory to make them available through the Kiwix server.

## Getting ZIM Files

Download ZIM files from:

- Official content: https://wiki.kiwix.org/wiki/Content
- Direct downloads: https://download.kiwix.org/zim/
- docker run -v .:/output ghcr.io/openzim/zimit zimit --seeds URL --name myzimfile

## Popular ZIM Files

- **Wikipedia**: `wikipedia_en_all_novid.zim` (English Wikipedia without videos)
- **Stack Overflow**: `stackoverflow.com_en_all.zim`
- **MDN Web Docs**: `developer.mozilla.org_en_all.zim`
- **Wiktionary**: `wiktionary_en_all_novid.zim`

## Usage

1. Download .zim files into the `data/` subdirectory
2. Run `docker-compose up kiwix`
3. Access content at http://localhost:8080

The server will automatically serve all .zim files found in the `data/` directory.

## Directory Structure

```
zim/
├── README.md          # This file
└── data/             # Put your .zim files here
    ├── wikipedia_en_all_novid.zim
    ├── stackoverflow.com_en_all.zim
    └── ...
```
