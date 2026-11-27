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
	return Config{Username: "bootstrap_dev", Token: testToken, Name: "node.dev.internal",
		OrganizationID: 1, LocationID: 2, HostgroupID: 3, EnvironmentID: 4, RoleID: 5, ProxyID: 6, CAProxyID: 7,
		DeployEnv: "dev", DRSite: "primary", Managed: true}
}
func quote(s string) string { return "'" + strings.ReplaceAll(s, "'", "'\"'\"'") + "'" }
func bashCall(t *testing.T, c Config) ([]byte, error) {
	t.Helper()
	root, _ := filepath.Abs("../../..")
	script := `set +x; set -a
source "$1"
`
	// Supply the token through the shell function, never a process command line.
	script += "FOREMAN_PAT=" + quote(c.Token) + "\nforeman_register"
	args := []string{c.URL, c.CACert, c.Username, c.Token, c.Name,
		fmt.Sprint(c.OrganizationID), fmt.Sprint(c.LocationID), fmt.Sprint(c.HostgroupID),
		fmt.Sprint(c.EnvironmentID), fmt.Sprint(c.RoleID), fmt.Sprint(c.ProxyID), fmt.Sprint(c.CAProxyID),
		c.DeployEnv, fmt.Sprint(c.Managed), c.Team, c.DRSite}
	if c.Team == "" && c.DRSite == "" {
		args = args[:14]
	}
	for _, arg := range args {
		script += " " + quote(arg)
	}
	script += "\n"

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
		for _, scenario := range []string{"created", "unmanaged", "team", "duplicate", "denied", "servererror", "redirect", "untrusted", "http", "optional_empty", "escaped"} {
			t.Run(implementation+"/"+scenario, func(t *testing.T) {
				c := config()
				if scenario == "unmanaged" {
					c.Managed = false
				}
				if scenario == "optional_empty" {
					c.DRSite = ""
				}
				if scenario == "escaped" {
					c.Team = "devops\"\\"
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
					var body map[string]any
					if json.NewDecoder(r.Body).Decode(&body) != nil {
						t.Error("invalid JSON payload")
						w.WriteHeader(400)
						return
					}
					h := body["host"].(map[string]any)
					if h["name"] != c.Name || h["overwrite"] != false || h["build"] != false || h["managed"] != false {
						t.Error("wrong host/creation flags")
					}
					for key, want := range map[string]int{"organization_id": c.OrganizationID, "location_id": c.LocationID, "hostgroup_id": c.HostgroupID, "puppet_proxy_id": c.ProxyID, "puppet_ca_proxy_id": c.CAProxyID} {
						if h[key] != float64(want) {
							t.Error("wrong ID", key, h[key])
						}
					}
					puppet := h["puppet_attributes"].(map[string]any)
					ids := puppet["puppetclass_ids"].([]any)
					if puppet["environment_id"] != float64(c.EnvironmentID) || len(ids) != 1 || ids[0] != float64(c.RoleID) {
						t.Error("wrong Puppet environment/role")
					}
					params := map[string]map[string]any{}
					for _, raw := range h["host_parameters_attributes"].([]any) {
						p := raw.(map[string]any)
						params[p["name"].(string)] = p
					}
					if params["deploy_env"]["value"] != c.DeployEnv || params["puppet_managed"]["value"] != fmt.Sprint(c.Managed) || params["puppet_managed"]["parameter_type"] != "boolean" {
						t.Error("wrong typed parameters")
					}
					for key, want := range map[string]string{"team": c.Team, "dr_site": c.DRSite} {
						if want == "" {
							if _, ok := params[key]; ok {
								t.Error("empty optional parameter not omitted", key)
							}
						} else if params[key]["value"] != want {
							t.Error("wrong optional parameter", key)
						}
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
				if scenario == "http" {
					c.URL = strings.Replace(c.URL, "https:", "http:", 1)
				}
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
				success := scenario == "created" || scenario == "unmanaged" || scenario == "team" || scenario == "optional_empty" || scenario == "escaped"
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
				if scenario == "untrusted" || scenario == "http" {
					want = 0
				}
				if requests != want {
					t.Fatalf("expected %d request, got %d", want, requests)
				}
			})
		}
	}
}
func TestShellRejectsCredentialConfigInjection(t *testing.T) {
	for _, token := range []string{"bad\n", "bad\r", "bad\t"} {
		_, err := bashCall(t, Config{URL: "https://localhost", Username: "bootstrap", Token: token})
		if err == nil {
			t.Fatal("unsafe curl config credential accepted")
		}
	}
}

func TestShellRequiresArguments(t *testing.T) {
	root, _ := filepath.Abs("../../..")
	cmd := exec.Command("bash", "-c", `source "$1"; foreman_register`, "test", filepath.Join(root, "bootstrap/user-data/register.sh"))
	if err := cmd.Run(); err == nil {
		t.Fatal("accepted missing function arguments")
	}
}
