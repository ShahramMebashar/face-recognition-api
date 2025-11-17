/*
 * Arduino Face Recognition Attendance System
 * 
 * This sketch captures images using ESP32-CAM and sends them to the 
 * face recognition API for attendance tracking.
 * 
 * Hardware Required:
 * - ESP32-CAM (AI-Thinker model)
 * - FTDI programmer (for initial upload)
 * - LED (optional, for status indication)
 * - Button (optional, for manual capture trigger)
 * 
 * Connections:
 * - LED -> GPIO 4 (built-in flash LED)
 * - Button -> GPIO 13 (with internal pull-up)
 */

#include "esp_camera.h"
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

// WiFi credentials
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// API endpoints
const char* recognizeApiUrl = "http://facerecognition-attendance-w1hldw-e52aca-46-62-229-91.traefik.me/api/attendance";
const char* pythonApiUrl = "http://facerecognition-w1hldw-e52aca-46-62-229-91.traefik.me/recognize";

// GPIO pins
#define BUTTON_PIN 13
#define LED_PIN 4
#define RELAY_PIN 12  // For controlling door lock or other device

// Timing
unsigned long lastCaptureTime = 0;
const unsigned long captureInterval = 5000;  // Capture every 5 seconds in auto mode

// Mode selection
bool autoMode = true;  // Set to false for button-triggered mode

// Camera pins for AI-Thinker ESP32-CAM
#define PWDN_GPIO_NUM     32
#define RESET_GPIO_NUM    -1
#define XCLK_GPIO_NUM      0
#define SIOD_GPIO_NUM     26
#define SIOC_GPIO_NUM     27
#define Y9_GPIO_NUM       35
#define Y8_GPIO_NUM       34
#define Y7_GPIO_NUM       39
#define Y6_GPIO_NUM       36
#define Y5_GPIO_NUM       21
#define Y4_GPIO_NUM       19
#define Y3_GPIO_NUM       18
#define Y2_GPIO_NUM        5
#define VSYNC_GPIO_NUM    25
#define HREF_GPIO_NUM     23
#define PCLK_GPIO_NUM     22

void setup() {
  Serial.begin(115200);
  Serial.println("\n\nArduino Face Recognition Attendance System");
  Serial.println("==========================================");
  
  // Initialize GPIO
  pinMode(LED_PIN, OUTPUT);
  pinMode(RELAY_PIN, OUTPUT);
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  
  digitalWrite(LED_PIN, LOW);
  digitalWrite(RELAY_PIN, LOW);
  
  // Connect to WiFi
  connectWiFi();
  
  // Initialize camera
  if (!initCamera()) {
    Serial.println("❌ Camera initialization failed!");
    while (true) {
      blinkLED(3, 200);  // Error indication
      delay(2000);
    }
  }
  
  Serial.println("✓ System ready!");
  Serial.println(autoMode ? "Mode: AUTO (continuous)" : "Mode: MANUAL (button trigger)");
  Serial.println("==========================================\n");
  
  blinkLED(2, 500);  // Success indication
}

void loop() {
  // Check WiFi connection
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("⚠️  WiFi disconnected. Reconnecting...");
    connectWiFi();
  }
  
  bool shouldCapture = false;
  
  if (autoMode) {
    // Auto mode: capture at regular intervals
    if (millis() - lastCaptureTime >= captureInterval) {
      shouldCapture = true;
      lastCaptureTime = millis();
    }
  } else {
    // Manual mode: capture on button press
    if (digitalRead(BUTTON_PIN) == LOW) {
      shouldCapture = true;
      delay(300);  // Debounce
      while (digitalRead(BUTTON_PIN) == LOW) delay(10);  // Wait for release
    }
  }
  
  if (shouldCapture) {
    captureAndRecognize();
  }
  
  delay(100);
}

void connectWiFi() {
  Serial.print("Connecting to WiFi");
  WiFi.begin(ssid, password);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✓ WiFi connected!");
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\n❌ WiFi connection failed!");
  }
}

bool initCamera() {
  Serial.println("Initializing camera...");
  
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sscb_sda = SIOD_GPIO_NUM;
  config.pin_sscb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_JPEG;
  
  // Init with high specs to pre-allocate larger buffers
  if (psramFound()) {
    config.frame_size = FRAMESIZE_UXGA;  // 1600x1200
    config.jpeg_quality = 10;
    config.fb_count = 2;
  } else {
    config.frame_size = FRAMESIZE_SVGA;  // 800x600
    config.jpeg_quality = 12;
    config.fb_count = 1;
  }
  
  // Camera init
  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("Camera init failed with error 0x%x\n", err);
    return false;
  }
  
  // Adjust settings for better face recognition
  sensor_t * s = esp_camera_sensor_get();
  s->set_framesize(s, FRAMESIZE_VGA);  // 640x480 - good balance
  s->set_quality(s, 10);  // 0-63, lower is better quality
  s->set_brightness(s, 0);     // -2 to 2
  s->set_contrast(s, 0);       // -2 to 2
  s->set_saturation(s, 0);     // -2 to 2
  
  Serial.println("✓ Camera initialized successfully");
  return true;
}

void captureAndRecognize() {
  Serial.println("\n--- Capture & Recognize ---");
  
  // Flash LED to indicate capture
  digitalWrite(LED_PIN, HIGH);
  delay(100);
  digitalWrite(LED_PIN, LOW);
  
  // Capture image
  camera_fb_t * fb = esp_camera_fb_get();
  if (!fb) {
    Serial.println("❌ Camera capture failed");
    return;
  }
  
  Serial.printf("Image captured: %d bytes\n", fb->len);
  
  // Send to API
  bool recognized = sendImageToAPI(fb->buf, fb->len);
  
  // Return frame buffer
  esp_camera_fb_return(fb);
  
  // Handle response
  if (recognized) {
    Serial.println("✓ Face recognized! Access granted.");
    grantAccess();
  } else {
    Serial.println("⚠️  Face not recognized or no face detected.");
    denyAccess();
  }
}

bool sendImageToAPI(uint8_t* imageBuffer, size_t imageSize) {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("❌ WiFi not connected");
    return false;
  }
  
  HTTPClient http;
  
  // Use the Go API endpoint which handles everything
  http.begin(recognizeApiUrl);
  http.addHeader("Content-Type", "multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW");
  
  // Build multipart form data
  String boundaryStart = "------WebKitFormBoundary7MA4YWxkTrZu0gW\r\n";
  String contentDisposition = "Content-Disposition: form-data; name=\"image\"; filename=\"capture.jpg\"\r\n";
  String contentType = "Content-Type: image/jpeg\r\n\r\n";
  String boundaryEnd = "\r\n------WebKitFormBoundary7MA4YWxkTrZu0gW--\r\n";
  
  // Calculate total size
  size_t totalSize = boundaryStart.length() + contentDisposition.length() + 
                     contentType.length() + imageSize + boundaryEnd.length();
  
  // Allocate buffer for complete request
  uint8_t* postData = (uint8_t*)malloc(totalSize);
  if (!postData) {
    Serial.println("❌ Memory allocation failed");
    http.end();
    return false;
  }
  
  // Build the POST data
  size_t offset = 0;
  memcpy(postData + offset, boundaryStart.c_str(), boundaryStart.length());
  offset += boundaryStart.length();
  memcpy(postData + offset, contentDisposition.c_str(), contentDisposition.length());
  offset += contentDisposition.length();
  memcpy(postData + offset, contentType.c_str(), contentType.length());
  offset += contentType.length();
  memcpy(postData + offset, imageBuffer, imageSize);
  offset += imageSize;
  memcpy(postData + offset, boundaryEnd.c_str(), boundaryEnd.length());
  
  // Send POST request
  Serial.println("Sending image to API...");
  int httpResponseCode = http.POST(postData, totalSize);
  
  free(postData);
  
  bool success = false;
  
  if (httpResponseCode > 0) {
    Serial.printf("HTTP Response code: %d\n", httpResponseCode);
    String response = http.getString();
    Serial.println("Response: " + response);
    
    // Parse JSON response
    DynamicJsonDocument doc(2048);
    DeserializationError error = deserializeJson(doc, response);
    
    if (!error) {
      bool apiSuccess = doc["success"] | false;
      
      if (apiSuccess) {
        // Check if face was recognized
        JsonObject attendance = doc["attendance"];
        if (!attendance.isNull()) {
          const char* personName = attendance["person_name"];
          const char* timestamp = attendance["timestamp"];
          
          Serial.printf("✓ Recognized: %s at %s\n", personName, timestamp);
          success = true;
        }
      } else {
        // API returned success=false
        const char* errorMsg = doc["error"] | "Unknown error";
        Serial.printf("API Error: %s\n", errorMsg);
      }
    } else {
      Serial.println("❌ JSON parsing failed");
    }
  } else {
    Serial.printf("❌ HTTP Error: %d\n", httpResponseCode);
  }
  
  http.end();
  return success;
}

void grantAccess() {
  // Visual feedback
  for (int i = 0; i < 3; i++) {
    digitalWrite(LED_PIN, HIGH);
    delay(100);
    digitalWrite(LED_PIN, LOW);
    delay(100);
  }
  
  // Activate relay (e.g., unlock door)
  digitalWrite(RELAY_PIN, HIGH);
  delay(3000);  // Keep unlocked for 3 seconds
  digitalWrite(RELAY_PIN, LOW);
}

void denyAccess() {
  // Visual feedback - long blink
  digitalWrite(LED_PIN, HIGH);
  delay(500);
  digitalWrite(LED_PIN, LOW);
}

void blinkLED(int times, int duration) {
  for (int i = 0; i < times; i++) {
    digitalWrite(LED_PIN, HIGH);
    delay(duration);
    digitalWrite(LED_PIN, LOW);
    delay(duration);
  }
}
