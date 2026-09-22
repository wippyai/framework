// SPDX-License-Identifier: Apache-2.0

package main

import (
	"crypto/ed25519"
	"encoding/base64"
	"fmt"
	"os"
	"strings"
)

func readBase64(path string) ([]byte, error) {
	encoded, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read %q: %w", path, err)
	}

	decoded, err := base64.StdEncoding.DecodeString(strings.TrimSpace(string(encoded)))
	if err != nil {
		return nil, fmt.Errorf("decode base64 in %q: %w", path, err)
	}

	return decoded, nil
}

func verify(publicKey, artifact, signature []byte) error {
	if len(publicKey) != ed25519.PublicKeySize {
		return fmt.Errorf("public key is %d bytes, want %d", len(publicKey), ed25519.PublicKeySize)
	}
	if len(signature) != ed25519.SignatureSize {
		return fmt.Errorf("signature is %d bytes, want %d", len(signature), ed25519.SignatureSize)
	}
	if !ed25519.Verify(ed25519.PublicKey(publicKey), artifact, signature) {
		return fmt.Errorf("runtime signature verification failed")
	}

	return nil
}

func main() {
	if len(os.Args) != 4 {
		fmt.Fprintln(os.Stderr, "usage: verify-release <public-key> <artifact> <signature>")
		os.Exit(2)
	}

	publicKey, err := readBase64(os.Args[1])
	if err != nil {
		fmt.Fprintf(os.Stderr, "read public key: %v\n", err)
		os.Exit(1)
	}

	artifact, err := os.ReadFile(os.Args[2])
	if err != nil {
		fmt.Fprintf(os.Stderr, "read artifact: %v\n", err)
		os.Exit(1)
	}

	signature, err := readBase64(os.Args[3])
	if err != nil {
		fmt.Fprintf(os.Stderr, "read signature: %v\n", err)
		os.Exit(1)
	}

	if err := verify(publicKey, artifact, signature); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
