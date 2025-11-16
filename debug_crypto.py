#!/usr/bin/env python3
"""Debug script to isolate the cryptography X25519 issue"""

import sys
import os

def test_openssl_info():
    """Test OpenSSL configuration"""
    try:
        import ssl
        print(f"SSL version: {ssl.OPENSSL_VERSION}")
        print(f"SSL version info: {ssl.OPENSSL_VERSION_INFO}")
        return True
    except Exception as e:
        print(f"SSL import failed: {e}")
        return False

def test_cryptography():
    """Test cryptography X25519 key generation"""
    try:
        from cryptography.hazmat.primitives.asymmetric import x25519
        print("Attempting X25519 key generation...")
        private_key = x25519.X25519PrivateKey.generate()
        print("✓ X25519 key generation successful")
        return True
    except Exception as e:
        print(f"✗ X25519 key generation failed: {e}")
        print(f"Exception type: {type(e)}")
        return False

def test_paramiko():
    """Test paramiko import and basic functionality"""
    try:
        import paramiko
        print("✓ Paramiko import successful")
        return True
    except Exception as e:
        print(f"✗ Paramiko import failed: {e}")
        return False

def test_rembg():
    """Test rembg import"""
    try:
        import rembg
        print("✓ Rembg import successful")
        return True
    except Exception as e:
        print(f"✗ Rembg import failed: {e}")
        return False

if __name__ == "__main__":
    print("=== Cryptography Debug Test ===")
    print(f"Python version: {sys.version}")
    print(f"Platform: {sys.platform}")
    
    print("\n1. Testing OpenSSL...")
    test_openssl_info()
    
    print("\n2. Testing cryptography X25519...")
    test_cryptography()
    
    print("\n3. Testing paramiko...")
    test_paramiko()
    
    print("\n4. Testing rembg...")
    test_rembg()
