// SPDX-License-Identifier: Apache-2.0

package main

import (
	"crypto/ed25519"
	"crypto/rand"
	"encoding/base64"
	"os"
	"path/filepath"
	"testing"
)

func TestVerify(t *testing.T) {
	publicKey, privateKey, err := ed25519.GenerateKey(rand.Reader)
	if err != nil {
		t.Fatal(err)
	}

	artifact := []byte("verified runtime artifact")
	signature := ed25519.Sign(privateKey, artifact)
	if err := verify(publicKey, artifact, signature); err != nil {
		t.Fatalf("verify valid signature: %v", err)
	}

	signature[0] ^= 1
	if err := verify(publicKey, artifact, signature); err == nil {
		t.Fatal("verify accepted a tampered signature")
	}
}

func TestReadBase64(t *testing.T) {
	path := filepath.Join(t.TempDir(), "key")
	want := []byte("test value")
	if err := os.WriteFile(path, []byte(base64.StdEncoding.EncodeToString(want)), 0o600); err != nil {
		t.Fatal(err)
	}

	got, err := readBase64(path)
	if err != nil {
		t.Fatalf("read base64: %v", err)
	}
	if string(got) != string(want) {
		t.Fatalf("read base64 = %q, want %q", got, want)
	}

	if err := os.WriteFile(path, []byte("not base64!"), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := readBase64(path); err == nil {
		t.Fatal("readBase64 accepted invalid input")
	}
}
