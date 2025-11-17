# Arduino Face Recognition Attendance System

ESP32-CAM based face recognition system that integrates with the attendance API.

## Hardware Requirements

- **ESP32-CAM** (AI-Thinker model recommended)
- **FTDI Programmer** (for uploading code)
- **Relay Module** (optional, for controlling door lock/access)
- **Button** (optional, for manual trigger mode)
- **Power Supply** (5V, 2A minimum)

## Wiring Diagram

### ESP32-CAM to FTDI (for programming)
```
ESP32-CAM  ->  FTDI
GND        ->  GND
5V         ->  5V (or 3.3V)
U0R        ->  TX
U0T        ->  RX
IO0        ->  GND (only when uploading, disconnect after)
```

### Optional Components
```
Relay Module:
- VCC -> 5V
- GND -> GND
- IN  -> GPIO 12

Button:
- One side -> GPIO 13
- Other side -> GND
(Internal pull-up used)
```

## Setup Instructions

### 1. Install Arduino IDE & Libraries

1. **Install Arduino IDE** (v1.8.19 or later)

2. **Add ESP32 Board Support:**
   - File → Preferences
   - Add to "Additional Board Manager URLs":
     ```
     https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
     ```
   - Tools → Board → Boards Manager
   - Search "esp32" and install "esp32 by Espressif Systems"

3. **Install Required Libraries:**
   - Sketch → Include Library → Manage Libraries
   - Install:
     - `ArduinoJson` by Benoit Blanchon (v6.21.0 or later)

### 2. Configure the Code

Open `arduino-face-detector.ino` and modify:

```cpp
// WiFi credentials
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// API endpoints (already configured for your deployment)
const char* recognizeApiUrl = "http://facerecognition-attendance-w1hldw-e52aca-46-62-229-91.traefik.me/api/attendance/mark";
```

**Mode Selection:**
```cpp
bool autoMode = true;  // true = continuous capture every 5 seconds
                       // false = capture only on button press
```

### 3. Upload the Code

1. **Connect ESP32-CAM to FTDI:**
   - Connect all wires as shown above
   - **Important:** Connect IO0 to GND before uploading

2. **Select Board Settings:**
   - Tools → Board → ESP32 Arduino → AI Thinker ESP32-CAM
   - Tools → Upload Speed → 115200
   - Tools → Flash Frequency → 80MHz
   - Tools → Partition Scheme → Huge APP (3MB No OTA)

3. **Upload:**
   - Click Upload button
   - Wait for "Connecting...." message
   - Press RESET button on ESP32-CAM if needed
   - After upload completes, disconnect IO0 from GND

4. **Test:**
   - Disconnect FTDI
   - Power ESP32-CAM with 5V supply
   - Open Serial Monitor (115200 baud)
   - Should see WiFi connection and "System ready!" message

## Usage

### Auto Mode (Default)
- System captures images every 5 seconds
- Automatically sends to API for recognition
- LED blinks on capture
- If face recognized: 3 quick blinks + relay activates for 3 seconds
- If not recognized: 1 long blink

### Manual Mode
Set `autoMode = false` in code:
- Press button to capture image
- Same LED/relay behavior as auto mode

## API Integration

The system uses your Go attendance API endpoint:
```
POST http://facerecognition-attendance-w1hldw-e52aca-46-62-229-91.traefik.me/api/attendance/mark
```

### Expected Response Format:
```json
{
  "success": true,
  "attendance": {
    "id": 123,
    "person_id": 1,
    "person_name": "John Doe",
    "timestamp": "2025-11-17T10:30:00Z"
  }
}
```

## Troubleshooting

### Camera Initialization Failed
- Check camera ribbon cable connection
- Ensure cable is inserted correctly (blue side up)
- Try lower resolution: `config.frame_size = FRAMESIZE_QVGA;`

### WiFi Connection Failed
- Verify SSID and password
- Check 2.4GHz WiFi (ESP32 doesn't support 5GHz)
- Move closer to router

### Memory Allocation Failed
- ESP32-CAM has limited RAM
- Reduce image quality: `config.jpeg_quality = 15;`
- Use smaller frame size: `FRAMESIZE_SVGA`

### No Face Detected
- Ensure good lighting
- Face should be front-facing
- Distance: 0.5m - 2m from camera
- Add more light or adjust camera brightness:
  ```cpp
  s->set_brightness(s, 1);  // Increase if too dark
  ```

### HTTP Errors
- Check API URL is correct
- Verify WiFi has internet access
- Test API with Postman first
- Check Dokploy service is running

## LED Indicators

- **2 blinks at startup**: System initialized successfully
- **3 fast blinks repeatedly**: Camera initialization error
- **Single flash**: Capturing image
- **3 quick blinks**: Face recognized, access granted
- **1 long blink**: Face not recognized, access denied

## Power Requirements

- **Voltage**: 5V regulated (3.3V may work but not recommended)
- **Current**: 2A minimum (camera draws significant current)
- **Note**: USB power from computer may not be sufficient

## Optional Enhancements

1. **Add OLED Display** (I2C):
   - Show recognized person's name
   - Display status messages

2. **Add Speaker/Buzzer**:
   - Audio feedback for recognition

3. **Multiple Relays**:
   - Control different locks/doors
   - Trigger alarms for unknown faces

4. **Deep Sleep Mode**:
   - Save power between captures
   - Wake on button press

5. **Local Storage**:
   - Save images to SD card
   - Buffer captures when WiFi is down

## Security Considerations

⚠️ **Important:**
- This system uses HTTP (not HTTPS) for simplicity
- For production, consider:
  - HTTPS endpoints
  - API authentication tokens
  - Encrypted storage of credentials
  - Network isolation

## Testing

1. **Test WiFi Connection:**
   - Open Serial Monitor
   - Check for "WiFi connected" message

2. **Test Camera:**
   - Should see "Camera initialized successfully"
   - Try adjusting brightness if image is too dark

3. **Test API:**
   - Upload a known face to the system first
   - Stand in front of camera
   - Check Serial Monitor for recognition results

4. **Test Relay:**
   - Verify relay clicks when face is recognized
   - Check voltage on relay output

## API Endpoints Reference

Your system has two APIs working together:

1. **Go Attendance API** (Primary):
   ```
   POST /api/attendance/mark
   - Accepts: multipart/form-data image
   - Returns: Attendance record with person info
   ```

2. **Python Recognition API** (Backend):
   ```
   POST /recognize
   - Used internally by Go API
   - Returns: Face recognition results
   ```

The Arduino only needs to call the Go API endpoint.
