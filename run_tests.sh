#!/bin/bash
# --- Configuration ---
PROJECT_NAME="projectdemo"
LOG_FILE="test_execution_log.txt"
VIDEO_FILE="test_video.mp4"
DEVICE_PATH="/sdcard/$VIDEO_FILE"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# --- Start Logging ---
echo "==========================================" | tee $LOG_FILE
echo "   AUTO-TEST SCRIPT FOR $PROJECT_NAME" | tee -a $LOG_FILE
echo "   Date: $DATE" | tee -a $LOG_FILE
echo "==========================================" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# --- Clean Project ---
echo "[1/5] Cleaning project..." | tee -a $LOG_FILE
flutter clean >> $LOG_FILE 2>&1
flutter pub get >> $LOG_FILE 2>&1
echo "      Done." | tee -a $LOG_FILE

# --- Run Static Analysis ---
echo "[2/5] Running Static Analysis..." | tee -a $LOG_FILE
flutter analyze >> $LOG_FILE 2>&1
if [ $? -eq 0 ]; then
    echo "      Analysis Passed." | tee -a $LOG_FILE
else
    echo "      Analysis Failed. Check log for details." | tee -a $LOG_FILE
fi

# --- Run Unit & Widget Tests ---
echo "[3/5] Running Unit & Widget Tests..." | tee -a $LOG_FILE
flutter test >> $LOG_FILE 2>&1
if [ $? -eq 0 ]; then
    echo "      All Tests Passed." | tee -a $LOG_FILE
else
    echo "      Some Tests Failed. Check log for details." | tee -a $LOG_FILE
fi

# --- Integration Tests & Video Recording ---
echo "[4/5] Checking for connected devices..." | tee -a $LOG_FILE
DEVICES=$(flutter devices | grep -v "devices" | grep -v "•")

if [ -z "$DEVICES" ]; then
    echo "      No devices connected. Skipping Integration Tests." | tee -a $LOG_FILE
else
    echo "      Device found. Starting Video Recording..." | tee -a $LOG_FILE
    
    # Remove old video if exists
    adb shell rm $DEVICE_PATH 2>/dev/null
    
    # Start recording WITHOUT time limit (let integration tests control duration)
    adb shell screenrecord --size 1280x720 --bit-rate 6000000 $DEVICE_PATH &
    
    # Give recording 3 seconds to initialize
    sleep 3
    
    echo "      Running Integration Tests..." | tee -a $LOG_FILE
    flutter test integration_test >> $LOG_FILE 2>&1
    TEST_STATUS=$?
    
    echo "      Tests Finished. Stopping Recording..." | tee -a $LOG_FILE
    
    # Send signal to screenrecord process on the device
    # This allows it to finalize the MP4 file properly
    adb shell "pkill -SIGINT screenrecord" 2>/dev/null
    
    # Wait for screenrecord to finalize the file (write moov atom)
    echo "      Finalizing video file (waiting 8 seconds)..." | tee -a $LOG_FILE
    sleep 8
    
    # Verify the file exists and has content
    echo "      Verifying video file..." | tee -a $LOG_FILE
    FILE_SIZE=$(adb shell "ls -l $DEVICE_PATH 2>/dev/null | awk '{print \$4}'")
    
    if [ -z "$FILE_SIZE" ] || [ "$FILE_SIZE" -eq 0 ]; then
        echo "      ERROR: Video file not created or is empty!" | tee -a $LOG_FILE
    else
        echo "      Video file size on device: $FILE_SIZE bytes" | tee -a $LOG_FILE
        echo "      Pulling video file to computer..." | tee -a $LOG_FILE
        
        adb pull $DEVICE_PATH ./$VIDEO_FILE >> $LOG_FILE 2>&1
        
        if [ -f "./$VIDEO_FILE" ]; then
            LOCAL_SIZE=$(ls -l ./$VIDEO_FILE | awk '{print $5}')
            echo "      Video saved locally: $LOCAL_SIZE bytes" | tee -a $LOG_FILE
            
            # Verify the video is valid
            if command -v ffmpeg &> /dev/null; then
                echo "      Validating video file..." | tee -a $LOG_FILE
                ffmpeg -v error -i "./$VIDEO_FILE" -f null - 2>&1 | tee -a $LOG_FILE
                if [ $? -eq 0 ]; then
                    echo "      ✓ Video file is valid and playable!" | tee -a $LOG_FILE
                else
                    echo "      ⚠ Video file may be corrupted" | tee -a $LOG_FILE
                fi
            fi
        else
            echo "      ERROR: Failed to pull video file!" | tee -a $LOG_FILE
        fi
        
        # Cleanup file on device
        adb shell rm $DEVICE_PATH 2>/dev/null
    fi
    
    echo "      Integration Tests & Recording Completed." | tee -a $LOG_FILE
fi

echo "" | tee -a $LOG_FILE
echo "==========================================" | tee -a $LOG_FILE
echo "   Testing Complete." | tee -a $LOG_FILE
echo "   Logs saved to: $LOG_FILE" | tee -a $LOG_FILE
if [ -f "./$VIDEO_FILE" ]; then
    echo "   Video saved to: $VIDEO_FILE" | tee -a $LOG_FILE
fi
echo "==========================================" | tee -a $LOG_FILE