# Anvisa Tesseract Runtime

Publikt runtime-repo för Anvisas valfria Tesseract-motor.

Anvisa laddar inte med Tesseract i själva appen. I stället kan användaren klicka på
`Ladda ner Tesseract-motor` under `Inställningar > OCR och HTR`. Appen hämtar då
`manifest.json` från senaste GitHub Release och installerar rätt zip för datorns
arkitektur i Application Support.

## Release-struktur

Varje release ska innehålla:

```text
manifest.json
AnvisaTesseractRuntime-macos-arm64.zip
AnvisaTesseractRuntime-macos-x86_64.zip
```

Varje zip ska packas så att roten innehåller:

```text
bin/tesseract
lib/
licenses/
README.txt
```

`bin/tesseract` ska vara körbar och byggd så att den hittar sina bibliotek relativt
till runtime-roten, normalt via `@executable_path/../lib`.

## Manifest

`manifest.json` ska följa detta format:

```json
{
  "version": "1.0.0",
  "packages": [
    {
      "architecture": "arm64",
      "url": "https://github.com/gemenatyper/anvisa-tesseract-runtime/releases/download/v1.0.0/AnvisaTesseractRuntime-macos-arm64.zip",
      "sha256": "byt-ut-mot-riktig-checksumma",
      "byteCount": 0
    },
    {
      "architecture": "x86_64",
      "url": "https://github.com/gemenatyper/anvisa-tesseract-runtime/releases/download/v1.0.0/AnvisaTesseractRuntime-macos-x86_64.zip",
      "sha256": "byt-ut-mot-riktig-checksumma",
      "byteCount": 0
    }
  ]
}
```

## Licenser

Tesseract är Apache 2.0. Runtimepaketet måste också innehålla licenser för alla
bundlade beroenden, till exempel Leptonica och bildbibliotek.

## Skapa paket

Scriptet i `scripts/package-local-runtime.sh` är en startpunkt för att paketera en
lokalt installerad Tesseract-runtime. Det kräver att `tesseract` finns lokalt och
att dess beroenden kan samlas in för aktuell arkitektur.
