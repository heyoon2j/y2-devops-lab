// Package registration sends one create-only Foreman API request from variables.
package registration

import (
	"bytes"
	"context"
	"crypto/tls"
	"crypto/x509"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"net/http"
	"os"
	"regexp"
	"strings"
	"time"
)

// Config is provided by the caller. Token must come from a secret store;
// never write it into source code, user-data, command-line flags or logs.
type Config struct {
	URL, CACert, Username, Token                                   string
	Name                                                           string
	OrganizationID, LocationID, HostgroupID, EnvironmentID, RoleID int
	ProxyID, CAProxyID                                             int
	DeployEnv, Team, DRSite                                        string
	Managed                                                        bool
}

// RegisterForeman makes exactly one POST, without lookup, update or retry.
// Success means host creation; CA enrollment and first Puppet run are separate.
func RegisterForeman(ctx context.Context, c Config) error {
	matches := func(pattern, value string) bool { return regexp.MustCompile(pattern).MatchString(value) }
	if !matches(`^https://[A-Za-z0-9.-]+(:[0-9]+)?/?$`, c.URL) || c.CACert == "" ||
		!matches(`^[a-zA-Z0-9_.@-]+$`, c.Username) || !matches(`^[!-~]+$`, c.Token) || len(c.Token) < 16 || len(c.Token) > 2048 ||
		!matches(`^[a-z0-9][a-z0-9.-]*\.[a-z0-9-]+$`, c.Name) || len(c.Name) > 253 {
		return errors.New("invalid HTTPS origin, CA path, username, PAT or node FQDN")
	}
	for _, id := range []int{c.OrganizationID, c.LocationID, c.HostgroupID, c.EnvironmentID, c.RoleID, c.ProxyID, c.CAProxyID} {
		if id <= 0 {
			return errors.New("reference IDs must be positive integers")
		}
	}
	if (c.DeployEnv != "dev" && c.DeployEnv != "prd") || (c.Team != "" && !matches(`^[a-z][a-z0-9_-]{0,63}$`, c.Team)) ||
		(c.DRSite != "" && c.DRSite != "primary" && c.DRSite != "secondary") {
		return errors.New("invalid deploy_env, team or dr_site")
	}
	parameters := []map[string]string{
		{"name": "deploy_env", "value": c.DeployEnv, "parameter_type": "string"},
		{"name": "puppet_managed", "value": fmt.Sprint(c.Managed), "parameter_type": "boolean"},
	}
	for _, p := range []struct{ name, value string }{{"team", c.Team}, {"dr_site", c.DRSite}} {
		if p.value != "" {
			parameters = append(parameters, map[string]string{"name": p.name, "value": p.value, "parameter_type": "string"})
		}
	}
	payload := map[string]any{"host": map[string]any{
		"name": c.Name, "managed": false, "build": false, "overwrite": false,
		"organization_id": c.OrganizationID, "location_id": c.LocationID, "hostgroup_id": c.HostgroupID,
		"puppet_proxy_id": c.ProxyID, "puppet_ca_proxy_id": c.CAProxyID,
		"puppet_attributes":          map[string]any{"environment_id": c.EnvironmentID, "puppetclass_ids": []int{c.RoleID}},
		"host_parameters_attributes": parameters,
	}}
	body, err := json.Marshal(payload)
	if err != nil {
		return errors.New("could not build Foreman request")
	}
	pem, err := os.ReadFile(c.CACert)
	if err != nil {
		return errors.New("could not read Foreman CA certificate")
	}
	roots := x509.NewCertPool()
	if !roots.AppendCertsFromPEM(pem) {
		return errors.New("invalid Foreman CA certificate")
	}
	transport := &http.Transport{Proxy: nil, DialContext: (&net.Dialer{Timeout: 10 * time.Second}).DialContext,
		TLSClientConfig: &tls.Config{RootCAs: roots, MinVersion: tls.VersionTLS12}, TLSHandshakeTimeout: 10 * time.Second}
	defer transport.CloseIdleConnections()
	client := &http.Client{Transport: transport, Timeout: 60 * time.Second,
		CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse }}
	request, err := http.NewRequestWithContext(ctx, http.MethodPost, strings.TrimSuffix(c.URL, "/")+"/api/hosts", bytes.NewReader(body))
	if err != nil {
		return errors.New("could not build Foreman request")
	}
	request.SetBasicAuth(c.Username, c.Token)
	request.Header.Set("Content-Type", "application/json")
	request.Header.Set("Accept", "application/json")
	response, err := client.Do(request)
	if err != nil {
		return errors.New("Foreman request failed; check TLS/network. No automatic retry")
	}
	defer response.Body.Close()
	if response.StatusCode < 200 || response.StatusCode > 299 {
		return fmt.Errorf("Foreman HTTP %d; host was not overwritten", response.StatusCode)
	}
	return nil
}
