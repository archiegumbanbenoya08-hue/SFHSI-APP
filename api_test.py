#!/usr/bin/env python3
"""
Quick test script for SCMCIES API
Run this after starting the FastAPI server to verify all endpoints
"""

import requests
import json
import os
from datetime import datetime

BASE_URL = "http://localhost:8000"
TOKEN = None

def test_health():
    """Test health check endpoint"""
    print("\n▶ Testing health check...")
    response = requests.get(f"{BASE_URL}/health")
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")
    return response.status_code == 200

def test_login():
    """Test login and get token"""
    global TOKEN
    print("\n▶ Testing login...")
    
    payload = {
        "email": os.environ["ADMIN_EMAIL"],
        "password": os.environ["ADMIN_PASSWORD"]
    }
    
    response = requests.post(
        f"{BASE_URL}/auth/login",
        json=payload
    )
    
    print(f"Status: {response.status_code}")
    data = response.json()
    print(f"Response: {json.dumps(data, indent=2)}")
    
    if response.status_code == 200:
        TOKEN = data['access_token']
        print(f"✅ Login successful! Token: {TOKEN[:20]}...")
        return True
    return False

def test_get_current_user():
    """Test getting current user"""
    if not TOKEN:
        print("❌ No token available")
        return False
    
    print("\n▶ Testing get current user...")
    
    headers = {
        "Authorization": f"Bearer {TOKEN}"
    }
    
    response = requests.get(
        f"{BASE_URL}/auth/me",
        headers=headers
    )
    
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.status_code == 200

def test_list_students():
    """Test listing students"""
    if not TOKEN:
        print("❌ No token available")
        return False
    
    print("\n▶ Testing list students...")
    
    headers = {
        "Authorization": f"Bearer {TOKEN}"
    }
    
    response = requests.get(
        f"{BASE_URL}/students/",
        headers=headers
    )
    
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.status_code == 200

def test_get_database_stats():
    """Test getting database statistics"""
    if not TOKEN:
        print("❌ No token available")
        return False
    
    print("\n▶ Testing database statistics...")
    
    headers = {
        "Authorization": f"Bearer {TOKEN}"
    }
    
    response = requests.get(
        f"{BASE_URL}/stats/database/",
        headers=headers
    )
    
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.status_code == 200

def test_get_today_attendance():
    """Test getting today's attendance"""
    if not TOKEN:
        print("❌ No token available")
        return False
    
    print("\n▶ Testing today's attendance...")
    
    headers = {
        "Authorization": f"Bearer {TOKEN}"
    }
    
    response = requests.get(
        f"{BASE_URL}/attendance/today/",
        headers=headers
    )
    
    print(f"Status: {response.status_code}")
    data = response.json()
    print(f"Response: {json.dumps(data, indent=2)}")
    return response.status_code == 200

def test_api_docs():
    """Test API documentation endpoint"""
    print("\n▶ Testing API documentation...")
    response = requests.get(f"{BASE_URL}/docs")
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        print("✅ Swagger UI is accessible at http://localhost:8000/docs")
    return response.status_code == 200

def run_all_tests():
    """Run all tests"""
    print("=" * 60)
    print("🧪 SCMCIES API Test Suite")
    print("=" * 60)
    
    tests = [
        ("Health Check", test_health),
        ("API Docs", test_api_docs),
        ("Login", test_login),
        ("Get Current User", test_get_current_user),
        ("List Students", test_list_students),
        ("Database Stats", test_get_database_stats),
        ("Today's Attendance", test_get_today_attendance),
    ]
    
    results = []
    
    for test_name, test_func in tests:
        try:
            result = test_func()
            results.append((test_name, result))
        except Exception as e:
            print(f"❌ Error: {e}")
            results.append((test_name, False))
    
    # Print summary
    print("\n" + "=" * 60)
    print("📊 Test Summary")
    print("=" * 60)
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for test_name, result in results:
        status = "✅" if result else "❌"
        print(f"{status} {test_name}")
    
    print(f"\nPassed: {passed}/{total}")
    print("=" * 60)
    
    if passed == total:
        print("🎉 All tests passed!")
    else:
        print("⚠️  Some tests failed. Check the API server is running.")

if __name__ == "__main__":
    try:
        run_all_tests()
    except requests.exceptions.ConnectionError:
        print("❌ Could not connect to API server!")
        print("Make sure the FastAPI server is running on http://localhost:8000")
        print("\nTo start the server:")
        print("  Windows: cd backend && run.bat")
        print("  Linux/Mac: cd backend && ./run.sh")
