// Package registration builds host JSON from inputs and registers it once.
package registration

import (
	"bytes"
	"context"
	"crypto/tls"
	"crypto/x509"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"os"
	"strings"
	"time"
)

// Config contains function inputs; no caller-generated JSON is required.
type Config struct {
	URL, CACert, Username, Token                                   string
	Name                                                           string
	OrganizationID, LocationID, HostgroupID, EnvironmentID, RoleID int
	ProxyID, CAProxyID                                             int
	DeployEnv, Team, DRSite                                        string
	Managed                                                        bool
}

func RegisterForeman(ctx context.Context, c Config) error {
	if !strings.HasPrefix(c.URL, "https://") {
		return errors.New("Foreman requires HTTPS")
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
	payload, err := json.Marshal(map[string]any{"host": map[string]any{
		"name": c.Name, "managed": false, "build": false, "overwrite": false,
		"organization_id": c.OrganizationID, "location_id": c.LocationID, "hostgroup_id": c.HostgroupID,
		"puppet_proxy_id": c.ProxyID, "puppet_ca_proxy_id": c.CAProxyID,
		"puppet_attributes":          map[string]any{"environment_id": c.EnvironmentID, "puppetclass_ids": []int{c.RoleID}},
		"host_parameters_attributes": parameters,
	}})
	if err != nil {
		return errors.New("could not build Foreman request")
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
	request, err := http.NewRequestWithContext(ctx, http.MethodPost, strings.TrimSuffix(c.URL, "/")+"/api/hosts", bytes.NewReader(payload))
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
