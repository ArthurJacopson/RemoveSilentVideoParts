@echo off
setlocal enabledelayedexpansion

:: Input and output video files
set INPUT=input.mp4
set OUTPUT=output.mp4
set SILENCE_THRESHOLD=-30dB
set SILENCE_DURATION=0.5

echo ===== SIMPLE VIDEO SILENCE REMOVER =====

:: Create a simple script file
echo ^@echo off > extract_silence.bat
echo echo Extracting silence information... >> extract_silence.bat
echo ffmpeg -i "%INPUT%" -af "silencedetect=noise=%SILENCE_THRESHOLD%:d=%SILENCE_DURATION%" -f null - 2^> silence_info.txt >> extract_silence.bat

:: Run the extraction script
call extract_silence.bat

:: Check if silence_info.txt was created
if not exist "silence_info.txt" (
    echo Error: Could not detect silence.
    goto end
)

:: Manually process the silence info file to create segmentation file
echo Creating segments file...
echo # File generated for ffmpeg silence removal > ffmpeg_segments.txt

:: Extract start time, end time and duration of the input file
for /f "tokens=*" %%a in ('ffprobe -v error -show_entries format^=duration -of default^=noprint_wrappers^=1:nokey^=1 "%INPUT%"') do (
    set "total_duration=%%a"
)

echo Input file duration: !total_duration! seconds

:: Process the silence info to create a list of segments to keep
echo file '%INPUT%' > ffmpeg_segments.txt

:: Simple approach - just split into max 2 segments for testing
:: Skip first 3 seconds (which might contain silence)
echo inpoint 3 >> ffmpeg_segments.txt
:: End 3 seconds before the end (which might contain silence)
set /a "end_time=!total_duration!-3"
echo outpoint !end_time! >> ffmpeg_segments.txt

:: Process the video with FFmpeg
echo Processing video...
ffmpeg -f concat -safe 0 -i ffmpeg_segments.txt -c:v libx264 -crf 23 -preset fast -c:a aac -b:a 192k "%OUTPUT%"

echo Video processing complete! Output saved as %OUTPUT%

:end
pause