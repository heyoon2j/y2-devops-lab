// Package registration sends the caller's JSON to Foreman once.
package registration

import (
	"bytes"
	"context"
	"crypto/tls"
	"crypto/x509"
	"errors"
	"fmt"
	"net/http"
	"os"
	"strings"
	"time"
)

type Config struct {
	URL, CACert, Username, Token string
	Payload                      []byte // Caller builds the host JSON, including overwrite:false.
}

func RegisterForeman(ctx context.Context, c Config) error {
	if !strings.HasPrefix(c.URL, "https://") {
		return errors.New("Foreman requires HTTPS")
	}
	pem, err := os.ReadFile(c.CACert)
	if err != nil {
		return errors.New("could not read Foreman CA")
	}
	roots := x509.NewCertPool()
	if !roots.AppendCertsFromPEM(pem) {
		return errors.New("invalid Foreman CA")
	}
	transport := &http.Transport{TLSClientConfig: &tls.Config{RootCAs: roots, MinVersion: tls.VersionTLS12}}
	defer transport.CloseIdleConnections()
	client := &http.Client{Transport: transport, Timeout: 60 * time.Second,
		CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse }}
	request, err := http.NewRequestWithContext(ctx, http.MethodPost, strings.TrimSuffix(c.URL, "/")+"/api/hosts", bytes.NewReader(c.Payload))
	if err != nil {
		return errors.New("could not build Foreman request")
	}
	request.SetBasicAuth(c.Username, c.Token)
	request.Header.Set("Content-Type", "application/json")
	response, err := client.Do(request)
	if err != nil {
		return errors.New("Foreman request failed")
	}
	defer response.Body.Close()
	if response.StatusCode < 200 || response.StatusCode > 299 {
		return fmt.Errorf("Foreman HTTP %d", response.StatusCode)
	}
	return nil
}
