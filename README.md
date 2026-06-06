# CD-Audio Resampler

Minimal PowerShell script to convert a folder of audio files into a CD-audio–ready format (44.1 kHz, 16-bit PCM).

## Requirements
---
- ```ffmpeg```
- ```ffprobe```
- PowerShell 5+ / 7+

Make sure ```ffmpeg``` and ```ffprobe``` are available in your PATH.

## Usage:
---
```.\resample.ps1 -Directory "C:\Music\InputAlbum" -OutDirectory "C:\Music\OutputDirectory"```

Options:
- -Directory → Input directory containing audio tracks
- -OutDirectory → Output directory for resampled album folder
- -Help → Show usage information

## What it does
---
For each supported audio file (```.flac```, ```.wav```, ```.mp3```, ```.m4a```, ```.aac```, ```.ogg```, ```.opus```, ```.wma```):
- Detects sample rate and bit depth via ffprobe
- Converts audio to CD standard if needed:
  - 44,100 Hz sample rate
  - 16-bit PCM
- Applies:
  - Resampling (SoXR) when needed
  - Dithering (triangular) when reducing bit depth
- Copies files directly if already CD-compliant

## Output
---
Creates a new folder:

```<OutDirectory>\<AlbumName> - CDAudio\```

## Notes
---
- Folder structure is flattened (files are written directly into output folder)
- Existing files are overwritten
- Designed for quick album preparation for CD burning
