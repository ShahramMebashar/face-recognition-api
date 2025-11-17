#!/usr/bin/env python3
"""
ESP32-CAM Simulator for Face Recognition Attendance System

This script simulates the Arduino ESP32-CAM behavior without hardware.
It captures images from your webcam or uses test images and sends them
to the attendance API, just like the real Arduino would.

Requirements:
    pip install opencv-python requests pillow
"""

import cv2
import requests
import time
import os
import sys
from pathlib import Path
from datetime import datetime
import argparse

# API Configuration
API_URL = "http://localhost:8080/api/attendance"

# Simulation modes
MODE_WEBCAM = "webcam"
MODE_IMAGE = "image"
MODE_AUTO = "auto"

class ESP32CAMSimulator:
    def __init__(self, mode=MODE_WEBCAM, image_path=None, interval=5):
        self.mode = mode
        self.image_path = image_path
        self.interval = interval
        self.cap = None
        self.running = True
        
        print("\n" + "="*50)
        print("ESP32-CAM Simulator")
        print("="*50)
        print(f"Mode: {mode}")
        print(f"API: {API_URL}")
        print(f"Capture interval: {interval}s")
        print("="*50 + "\n")
    
    def initialize_camera(self):
        """Initialize webcam (simulates ESP32-CAM initialization)"""
        if self.mode != MODE_WEBCAM:
            return True
        
        print("🎥 Initializing camera...")
        self.cap = cv2.VideoCapture(0)
        
        if not self.cap.isOpened():
            print("❌ Camera initialization failed!")
            print("   Make sure your webcam is connected and not in use.")
            return False
        
        # Set camera properties (similar to ESP32-CAM settings)
        self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
        self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
        self.cap.set(cv2.CAP_PROP_FPS, 30)
        
        print("✓ Camera initialized successfully")
        print("  Resolution: 640x480 (VGA)")
        return True
    
    def capture_image(self):
        """Capture image from webcam or load from file"""
        if self.mode == MODE_WEBCAM:
            ret, frame = self.cap.read()
            if not ret:
                print("❌ Failed to capture frame")
                return None
            
            # Show preview window
            cv2.imshow('ESP32-CAM Simulator - Press Q to quit', frame)
            cv2.waitKey(1)
            
            # Convert to JPEG
            ret, buffer = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, 90])
            if not ret:
                print("❌ Failed to encode image")
                return None
            
            return buffer.tobytes()
        
        elif self.mode == MODE_IMAGE:
            if not os.path.exists(self.image_path):
                print(f"❌ Image file not found: {self.image_path}")
                return None
            
            with open(self.image_path, 'rb') as f:
                return f.read()
        
        return None
    
    def send_to_api(self, image_data):
        """Send image to attendance API (simulates Arduino HTTP request)"""
        print(f"\n--- Capture & Recognize [{datetime.now().strftime('%H:%M:%S')}] ---")
        print(f"📸 Image captured: {len(image_data)} bytes")
        
        try:
            print("📤 Sending to API...")
            
            # Prepare multipart form data (same as Arduino does)
            files = {'image': ('capture.jpg', image_data, 'image/jpeg')}
            
            # Send POST request
            response = requests.post(API_URL, files=files, timeout=30)
            
            print(f"📡 HTTP Response: {response.status_code}")
            
            if response.status_code == 200:
                data = response.json()
                
                if data.get('success'):
                    # Check if authorized
                    authorized = data.get('authorized', False)
                    person_name = data.get('name', 'Unknown')
                    confidence = data.get('confidence', 0)
                    message = data.get('message', '')
                    
                    if authorized:
                        print(f"✅ Face recognized!")
                        print(f"   Person: {person_name}")
                        print(f"   Confidence: {confidence:.2f}")
                        print(f"   Message: {message}")
                        print("   🔓 ACCESS GRANTED")
                        
                        self.grant_access()
                        return True
                    else:
                        print(f"⚠️  Recognition failed")
                        print(f"   Person: {person_name}")
                        print(f"   Message: {message}")
                        print("   🔒 ACCESS DENIED")
                        
                        self.deny_access()
                        return False
                else:
                    error = data.get('error', 'Unknown error')
                    message = data.get('message', '')
                    print(f"⚠️  Recognition failed")
                    print(f"   Error: {error}")
                    if message:
                        print(f"   Message: {message}")
                    print("   🔒 ACCESS DENIED")
                    
                    self.deny_access()
                    return False
            else:
                print(f"❌ HTTP Error: {response.status_code}")
                print(f"   Response: {response.text[:200]}")
                self.deny_access()
                return False
        
        except requests.exceptions.Timeout:
            print("❌ Request timeout - API not responding")
            self.deny_access()
            return False
        
        except requests.exceptions.ConnectionError:
            print("❌ Connection error - Check network/API availability")
            self.deny_access()
            return False
        
        except Exception as e:
            print(f"❌ Error: {str(e)}")
            self.deny_access()
            return False
    
    def grant_access(self):
        """Simulate access granted (LED blinks + relay activation)"""
        print("   💡 LED: Blink-Blink-Blink (fast)")
        print("   🔌 RELAY: ON for 3 seconds")
        # In real Arduino: digitalWrite(RELAY_PIN, HIGH); delay(3000);
    
    def deny_access(self):
        """Simulate access denied (LED long blink)"""
        print("   💡 LED: Long blink")
        # In real Arduino: digitalWrite(LED_PIN, HIGH); delay(500);
    
    def run_auto_mode(self):
        """Run in automatic mode (continuous capture)"""
        print("🔄 AUTO MODE - Capturing every {} seconds".format(self.interval))
        print("   Press Ctrl+C to stop\n")
        
        if not self.initialize_camera():
            return
        
        # Initial countdown
        print("⏱️  Starting in...")
        for i in range(3, 0, -1):
            print(f"   {i}...")
            time.sleep(1)
        print("   🚀 Starting!\n")
        
        try:
            while self.running:
                image_data = self.capture_image()
                
                if image_data:
                    self.send_to_api(image_data)
                
                # Wait for next capture
                print(f"\n⏳ Waiting {self.interval} seconds...\n")
                time.sleep(self.interval)
        
        except KeyboardInterrupt:
            print("\n\n⏹️  Stopped by user")
        
        finally:
            self.cleanup()
    
    def run_manual_mode(self):
        """Run in manual mode (press Enter to capture)"""
        print("🖱️  MANUAL MODE")
        print("   Press ENTER to capture, or 'q' to quit\n")
        
        if not self.initialize_camera():
            return
        
        try:
            while self.running:
                user_input = input("Press ENTER to capture (q to quit): ").strip().lower()
                
                if user_input == 'q':
                    break
                
                image_data = self.capture_image()
                
                if image_data:
                    self.send_to_api(image_data)
                
                print()
        
        except KeyboardInterrupt:
            print("\n\n⏹️  Stopped by user")
        
        finally:
            self.cleanup()
    
    def run_single_capture(self):
        """Capture once and exit"""
        if self.mode == MODE_IMAGE:
            print("📁 Using image file:", self.image_path)
        else:
            if not self.initialize_camera():
                return
            
            # Give user time to position themselves
            print("\n⏱️  Get ready! Capturing in...")
            for i in range(3, 0, -1):
                print(f"   {i}...")
                time.sleep(1)
            print("   📸 Capturing NOW!\n")
        
        image_data = self.capture_image()
        
        if image_data:
            self.send_to_api(image_data)
        
        self.cleanup()
    
    def cleanup(self):
        """Clean up resources"""
        if self.cap:
            self.cap.release()
        cv2.destroyAllWindows()
        print("\n✓ Cleanup complete")


def main():
    parser = argparse.ArgumentParser(
        description='ESP32-CAM Simulator for Face Recognition',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  # Auto mode with webcam (capture every 5 seconds)
  python simulator.py --auto
  
  # Manual mode with webcam (press Enter to capture)
  python simulator.py --manual
  
  # Single capture from webcam
  python simulator.py --once
  
  # Use a test image file instead of webcam
  python simulator.py --image path/to/photo.jpg
  
  # Auto mode with custom interval
  python simulator.py --auto --interval 10
        '''
    )
    
    parser.add_argument('--auto', action='store_true',
                       help='Auto mode: capture continuously at intervals')
    parser.add_argument('--manual', action='store_true',
                       help='Manual mode: press Enter to capture')
    parser.add_argument('--once', action='store_true',
                       help='Capture once and exit')
    parser.add_argument('--image', type=str,
                       help='Use image file instead of webcam')
    parser.add_argument('--interval', type=int, default=5,
                       help='Capture interval in seconds (default: 5)')
    parser.add_argument('--api-url', type=str, default=None,
                       help='Custom API URL')
    
    args = parser.parse_args()
    
    # Use custom API URL if provided
    api_url = args.api_url if args.api_url else API_URL
    
    # Determine mode
    if args.image:
        simulator = ESP32CAMSimulator(
            mode=MODE_IMAGE,
            image_path=args.image,
            interval=args.interval
        )
        simulator.run_single_capture()
    
    elif args.auto:
        simulator = ESP32CAMSimulator(
            mode=MODE_WEBCAM,
            interval=args.interval
        )
        simulator.run_auto_mode()
    
    elif args.manual:
        simulator = ESP32CAMSimulator(
            mode=MODE_WEBCAM,
            interval=args.interval
        )
        simulator.run_manual_mode()
    
    elif args.once:
        simulator = ESP32CAMSimulator(mode=MODE_WEBCAM)
        simulator.run_single_capture()
    
    else:
        # Default: auto mode
        print("No mode specified, using --auto mode")
        print("Run with --help to see all options\n")
        simulator = ESP32CAMSimulator(
            mode=MODE_WEBCAM,
            interval=args.interval
        )
        simulator.run_auto_mode()


if __name__ == "__main__":
    main()
