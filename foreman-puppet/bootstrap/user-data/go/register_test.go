package registration

import (
	"bytes"
	"context"
	"encoding/json"
	"encoding/pem"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

const testToken = `example-token-"\-$-123456789`

func config() Config {
	return Config{URL: "https://foreman.example.internal", CACert: "/missing/ca.pem", Username: "bootstrap_dev", Token: testToken, Name: "node.dev.internal", OrganizationID: 1, LocationID: 2, HostgroupID: 3, EnvironmentID: 4, RoleID: 5, ProxyID: 6, CAProxyID: 7, DeployEnv: "dev", DRSite: "primary", Managed: true}
}
func quote(s string) string { return "'" + strings.ReplaceAll(s, "'", "'\"'\"'") + "'" }
func bashCall(t *testing.T, c Config) ([]byte, error) {
	t.Helper()
	root, _ := filepath.Abs("../../..")
	script := `set +x; set -a
source "$1"
`
	for _, p := range []struct{ name, value string }{{"FOREMAN_URL", c.URL}, {"FOREMAN_CA_CERT", c.CACert}, {"FOREMAN_USERNAME", c.Username}, {"FOREMAN_PAT", c.Token}, {"NODE_NAME", c.Name}, {"ORGANIZATION_ID", fmt.Sprint(c.OrganizationID)}, {"LOCATION_ID", fmt.Sprint(c.LocationID)}, {"HOSTGROUP_ID", fmt.Sprint(c.HostgroupID)}, {"ENVIRONMENT_ID", fmt.Sprint(c.EnvironmentID)}, {"ROLE_ID", fmt.Sprint(c.RoleID)}, {"PUPPET_PROXY_ID", fmt.Sprint(c.ProxyID)}, {"PUPPET_CA_PROXY_ID", fmt.Sprint(c.CAProxyID)}, {"DEPLOY_ENV", c.DeployEnv}, {"TEAM", c.Team}, {"DR_SITE", c.DRSite}, {"PUPPET_MANAGED", fmt.Sprint(c.Managed)}} {
		script += p.name + "=" + quote(p.value) + "\n"
	}
	script += "foreman_register\n"
	cmd := exec.Command("bash", "-s", "--", filepath.Join(root, "bootstrap/user-data/register.sh"))
	cmd.Stdin = strings.NewReader(script)
	return cmd.CombinedOutput()
}
func TestOneCreateRequest(t *testing.T) {
	curl, err := exec.LookPath("curl")
	if err != nil {
		t.Fatal(err)
	}
	for _, implementation := range []string{"bash", "go"} {
		for _, scenario := range []string{"created", "unmanaged", "team", "duplicate", "denied", "servererror", "redirect", "untrusted"} {
			t.Run(implementation+"/"+scenario, func(t *testing.T) {
				c := config()
				if scenario == "unmanaged" {
					c.Managed = false
				}
				if scenario == "team" {
					c.Team = "data_infra"
				}
				requests := 0
				server := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
					requests++
					if r.Method != "POST" || r.URL.Path != "/api/hosts" {
						t.Error("unexpected API request", r.Method, r.URL.Path)
					}
					user, token, ok := r.BasicAuth()
					if !ok || user != c.Username || token != c.Token {
						t.Error("wrong credentials")
					}
					var payload map[string]any
					if json.NewDecoder(r.Body).Decode(&payload) != nil {
						t.Error("invalid payload")
						w.WriteHeader(400)
						return
					}
					h := payload["host"].(map[string]any)
					if h["overwrite"] != false || h["managed"] != false || h["build"] != false {
						t.Error("unsafe creation flags")
					}
					if h["name"] != c.Name || h["organization_id"] != float64(c.OrganizationID) || h["hostgroup_id"] != float64(c.HostgroupID) {
						t.Error("wrong host fields")
					}
					puppet := h["puppet_attributes"].(map[string]any)
					if puppet["environment_id"] != float64(c.EnvironmentID) || puppet["puppetclass_ids"].([]any)[0] != float64(c.RoleID) {
						t.Error("wrong plugin payload")
					}
					params := map[string]map[string]any{}
					for _, raw := range h["host_parameters_attributes"].([]any) {
						p := raw.(map[string]any)
						params[p["name"].(string)] = p
					}
					if params["puppet_managed"]["value"] != fmt.Sprint(c.Managed) || params["puppet_managed"]["parameter_type"] != "boolean" || params["deploy_env"]["value"] != "dev" {
						t.Error("wrong parameter types/values")
					}
					if c.Team == "" {
						if _, ok := params["team"]; ok {
							t.Error("empty team should be omitted")
						}
					} else if params["team"]["value"] != c.Team {
						t.Error("wrong team")
					}
					status := 201
					switch scenario {
					case "duplicate":
						status = 422
					case "denied":
						status = 403
					case "servererror":
						status = 500
					case "redirect":
						status = 302
						w.Header().Set("Location", "https://elsewhere.invalid/")
					}
					w.WriteHeader(status)
					w.Write([]byte("response must not be logged: " + testToken))
				}))
				defer server.Close()
				c.URL = server.URL
				dir := t.TempDir()
				c.CACert = filepath.Join(dir, "ca.pem")
				os.WriteFile(c.CACert, pem.EncodeToMemory(&pem.Block{Type: "CERTIFICATE", Bytes: server.Certificate().Raw}), 0600)
				if scenario == "untrusted" {
					c.CACert = "/etc/ssl/certs/ca-certificates.crt"
				}
				// Inspect curl's argv/environment: PAT must only arrive through its pipe.
				log := filepath.Join(dir, "curl.log")
				wrapper := []byte("#!/bin/bash\nprintf '%s\\n' \"$@\" > \"$TEST_LOG\"\nenv >> \"$TEST_LOG\"\nexec \"$TEST_CURL\" \"$@\"\n")
				os.WriteFile(filepath.Join(dir, "curl"), wrapper, 0700)
				t.Setenv("PATH", dir+":"+os.Getenv("PATH"))
				t.Setenv("TEST_LOG", log)
				t.Setenv("TEST_CURL", curl)
				var output []byte
				var err error
				if implementation == "bash" {
					output, err = bashCall(t, c)
				} else {
					err = RegisterForeman(context.Background(), c)
					if err != nil {
						output = []byte(err.Error())
					}
				}
				success := scenario == "created" || scenario == "unmanaged" || scenario == "team"
				if success != (err == nil) {
					t.Fatalf("unexpected outcome: %v %s", err, output)
				}
				if bytes.Contains(output, []byte(testToken)) {
					t.Fatal("token/response leaked to output")
				}
				metadata, _ := os.ReadFile(log)
				if bytes.Contains(metadata, []byte(testToken)) {
					t.Fatal("token leaked to argv/environment")
				}
				want := 1
				if scenario == "untrusted" {
					want = 0
				}
				if requests != want {
					t.Fatalf("expected %d request, got %d", want, requests)
				}
			})
		}
	}
}
func TestInvalidInputNeverRequests(t *testing.T) {
	for _, kind := range []string{"url", "token", "id", "env", "team", "dr_site", "name"} {
		t.Run(kind, func(t *testing.T) {
			c := config()
			switch kind {
			case "url":
				c.URL = "http://localhost"
			case "token":
				c.Token = "bad\n"
			case "id":
				c.RoleID = 0
			case "env":
				c.DeployEnv = "sandbox"
			case "team":
				c.Team = "bad team"
			case "dr_site":
				c.DRSite = "unknown"
			case "name":
				c.Name = ""
			}
			if err := RegisterForeman(context.Background(), c); err == nil {
				t.Fatal("Go accepted invalid input")
			}
			if out, err := bashCall(t, c); err == nil {
				t.Fatalf("Shell accepted invalid input: %s", out)
			}
		})
	}
}
