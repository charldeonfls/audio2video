@echo off
setlocal enabledelayedexpansion

REM Check if ffmpeg is available
where ffmpeg >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: ffmpeg not found. Please install ffmpeg and add it to PATH.
    exit /b 1
)

REM Check minimum arguments
if "%~3"=="" (
    echo Usage: audio2video [image] [audio] [output] [optional ffmpeg parameters]
    echo        audio2video [audio] [image] [output] [optional ffmpeg parameters]
    echo.
    echo Supported image formats: jpg, jpeg, png, bmp, webp, avif, gif, tiff
    echo Supported audio formats: mp3, wav, flac, m4a, aac, opus, ogg, wma
    echo.
    echo Example: audio2video image.jpg audio.mp3 output.mkv
    echo Example: audio2video audio.wav image.png output.mkv -crf 40 -r 10
    exit /b 1
)

REM Initialize variables
set "image_file="
set "audio_file="
set "output_file=%~3"
set "extra_params="

REM Define supported extensions
set "image_exts=.jpg.jpeg.png.bmp.webp.avif.gif.tiff.tif."
set "audio_exts=.mp3.wav.flac.m4a.aac.opus.ogg.wma."

REM Identify input files based on extension
for %%F in ("%~1" "%~2") do (
    set "ext=%%~xF"
    set "ext=!ext:~1!"
    
    REM Check if it's an image
    echo !image_exts! | find /i ".!ext!." >nul
    if !errorlevel! equ 0 (
        if not defined image_file (
            set "image_file=%%~F"
        ) else (
            echo Error: Multiple image files detected.
            exit /b 1
        )
    )
    
    REM Check if it's an audio file
    echo !audio_exts! | find /i ".!ext!." >nul
    if !errorlevel! equ 0 (
        if not defined audio_file (
            set "audio_file=%%~F"
        ) else (
            echo Error: Multiple audio files detected.
            exit /b 1
        )
    )
)

REM Validate that we found both files
if not defined image_file (
    echo Error: No valid image file found.
    echo Supported formats: jpg, jpeg, png, bmp, webp, avif, gif, tiff
    exit /b 1
)

if not defined audio_file (
    echo Error: No valid audio file found.
    echo Supported formats: mp3, wav, flac, m4a, aac, opus, ogg, wma
    exit /b 1
)

REM Check if input files exist
if not exist "!image_file!" (
    echo Error: Image file not found: !image_file!
    exit /b 1
)

if not exist "!audio_file!" (
    echo Error: Audio file not found: !audio_file!
    exit /b 1
)

REM Check if output file already exists
if exist "!output_file!" (
    echo Error: Output file already exists: !output_file!
    echo Please use a different filename or delete the existing file.
    exit /b 1
)

REM Collect extra parameters (arguments after the 3rd one)
set "param_count=0"
for %%A in (%*) do (
    set /a param_count+=1
    if !param_count! gtr 3 (
        set "extra_params=!extra_params! %%A"
    )
)

echo.
echo ========================================
echo Image file: !image_file!
echo Audio file: !audio_file!
echo Output file: !output_file!
if defined extra_params echo Extra parameters:!extra_params!
echo ========================================
echo.

REM Create temporary 10-second video from image
echo Step 1/2: Creating 10-second video segment...
set "tempfile=temp_audio2video_%random%.mp4"
ffmpeg -loop 1 -r 25 -i "!image_file!" -c:v libx264 -preset veryfast -tune stillimage -pix_fmt yuv420p -crf 18 -t 10!extra_params! "!tempfile!" -y
if %errorlevel% neq 0 (
    echo Error: Failed to create temporary video file.
    if exist "!tempfile!" del "!tempfile!"
    exit /b 1
)

REM Concatenate and merge with audio using stream_loop
echo Step 2/2: Looping video and merging with audio...
ffmpeg -stream_loop -1 -i "!tempfile!" -i "!audio_file!" -c:v copy -c:a copy -shortest "!output_file!" -y
if %errorlevel% neq 0 (
    echo Error: Failed to create final output file.
    if exist "!tempfile!" del "!tempfile!"
    exit /b 1
)

REM Clean up temporary file
del "!tempfile!"

echo.
echo ========================================
echo Success! Output created: !output_file!
echo ========================================

endlocal
exit /b 0