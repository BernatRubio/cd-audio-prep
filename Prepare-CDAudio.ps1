param (
    [Parameter(Mandatory=$true)][string]$Directory,
    [Parameter(Mandatory=$true)][string]$OutDirectory,
    [switch]$Help
)

if ($help)
{
    Write-Host @"
usage: Prepare-CDAudio.ps1 [options] -Directory <path> -OutDirectory <path>

options:
    -Help                    Show this help message
    -Directory <path>        Input directory containing audio tracks
    -OutDirectory <path>     Output directory for resampled audio folder
"@
}

$folderName = Split-Path $Directory -Leaf
$outFolder = Join-Path $OutDirectory ($folderName + " - CDAudio")

# Create output folder if it doesn't exist
New-Item -ItemType Directory -Force -Path $outFolder | Out-Null

Write-Host "`n=========================="
Write-Host " AUDIO PROCESSING STATUS"
Write-Host "=========================="

Write-Host "✔️ Input already correct (no changes needed)"
Write-Host "🔁 Resampling required (sample rate conversion)"
Write-Host "✨ Dithering required (bit-depth reduction)"

Write-Host "==========================`n"

Get-ChildItem $Directory -Recurse -File |
    Where-Object Extension -in '.flac', '.wav', '.mp3', '.m4a', '.aac', '.ogg', '.opus', '.wma' |
    ForEach-Object {

        $inputFile = $_.FullName
        $outputFile = Join-Path $outFolder $_.Name

        $probeJson = ffprobe -v error -select_streams a:0 `
            -show_entries stream=sample_rate,bits_per_raw_sample,sample_fmt `
            -of json "$inputFile" | ConvertFrom-Json

        $sampleRate = [int]$probeJson.streams[0].sample_rate
        $sampleBits  = $probeJson.streams[0].bits_per_raw_sample

        if (-not $sampleBits)
        {
            $sampleFmt = $probeJson.streams[0].sample_fmt

            # Fallback mapping
            switch ($sampleFmt)
            {
                "s16"
                {
                    $sampleBits = "16"
                }
                "s32"
                {
                    $sampleBits = "24"
                }
                default
                {
                    $sampleBits = "unknown"
                }
            }
        }

        $is44100Hz = ($sampleRate -eq 44100)
        $is16bit = ($sampleBits -eq "16")

        # Skip full processing if already correct
        if ($is44100Hz -and $is16bit)
        {
            Write-Host "✔️ $($_.Name)"
            Copy-Item $inputFile $outputFile -Force
            return
        }

        $ffmpegArgs  = @(
            "-i", $inputFile
        )

        $needsResample = -not $is44100Hz  # CD-Audio sample rate is 44100 Hz
        $needsDither   = -not $is16bit # Bit depth must be reduced (CD-Audio has 16 bit depth), then it needs dithering

        if ($needsResample)
        {
            Write-Host "🔁 $($_.Name)"
            $ffmpegArgs  += "-osr"
            $ffmpegArgs  += "44100"
            $ffmpegArgs  += "-resampler"
            $ffmpegArgs  += "soxr"
        }

        $ffmpegArgs  += "-sample_fmt"
        $ffmpegArgs  += "s16"

        if ($needsDither)
        {
            Write-Host "✨ $($_.Name)"
            $ffmpegArgs  += "-dither_method"
            $ffmpegArgs  += "triangular"
        }

        $ffmpegArgs  += $outputFile

        ffmpeg -v error @ffmpegArgs
    }
