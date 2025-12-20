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

# ---  Run Static Analysis ---
echo "[2/5] Running Static Analysis..." | tee -a $LOG_FILE
flutter analyze >> $LOG_FILE 2>&1
if [ $? -eq 0 ]; then
    echo "      Analysis Passed." | tee -a $LOG_FILE
else
    echo "      Analysis Failed. Check log for details." | tee -a $LOG_FILE
fi

# ---  Run Unit & Widget Tests ---
echo "[3/5] Running Unit & Widget Tests..." | tee -a $LOG_FILE
flutter test >> $LOG_FILE 2>&1

if [ $? -eq 0 ]; then
    echo "      All Tests Passed." | tee -a $LOG_FILE
else
    echo "      Some Tests Failed. Check log for details." | tee -a $LOG_FILE
fi

# ---  Integration Tests & Video Recording ---
echo "[4/5] Checking for connected devices..." | tee -a $LOG_FILE
DEVICES=$(flutter devices | grep -v "devices" | grep -v "•")

if [ -z "$DEVICES" ]; then
    echo "      No devices connected. Skipping Integration Tests." | tee -a $LOG_FILE
else
    echo "      Device found. Starting Video Recording..." | tee -a $LOG_FILE
    
    # --- start recording ---
    # This runs screenrecord on the android device in the background
    adb shell screenrecord $DEVICE_PATH &
    RECORDING_PID=$!  # Save the Process ID so we can stop it later
    
    echo "      Running Integration Tests..." | tee -a $LOG_FILE
    flutter test integration_test >> $LOG_FILE 2>&1
    
    # --- stop recording ---
    echo "      Tests Finished. Stopping Recording..." | tee -a $LOG_FILE
    # Kill the background adb process (this stops the recording gracefully)
    kill -2 $RECORDING_PID 
    
    # Wait a moment for the file to finalize on the device
    sleep 3
    
    # --- pull video to computer ---
    echo "      Pulling video file to computer..." | tee -a $LOG_FILE
    adb pull $DEVICE_PATH ./$VIDEO_FILE >> $LOG_FILE 2>&1
    
    # Cleanup file on device
    adb shell rm $DEVICE_PATH
    
    echo "      Integration Tests & Recording Completed." | tee -a $LOG_FILE
fi

echo "" | tee -a $LOG_FILE
echo "==========================================" | tee -a $LOG_FILE
echo "   Testing Complete." | tee -a $LOG_FILE
echo "   Logs saved to: $LOG_FILE" | tee -a $LOG_FILE
echo "   Video saved to: $VIDEO_FILE" | tee -a $LOG_FILE
echo "==========================================" | tee -a $LOG_FILE