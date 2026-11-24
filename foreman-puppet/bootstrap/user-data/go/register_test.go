package registration

import (
	"bytes"
	"context"
	"encoding/json"
	"encoding/pem"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

const testToken = `example-token-"\-$-123456789`

func payload(managed bool, team string) []byte {
	params := []map[string]string{{"name": "deploy_env", "value": "dev", "parameter_type": "string"}, {"name": "puppet_managed", "value": "true", "parameter_type": "boolean"}}
	if !managed {
		params[1]["value"] = "false"
	}
	if team != "" {
		params = append(params, map[string]string{"name": "team", "value": team, "parameter_type": "string"})
	}
	body, _ := json.Marshal(map[string]any{"host": map[string]any{"name": "node.dev.internal", "managed": false, "build": false, "overwrite": false, "organization_id": 1, "location_id": 2, "hostgroup_id": 3, "puppet_proxy_id": 6, "puppet_ca_proxy_id": 7, "puppet_attributes": map[string]any{"environment_id": 4, "puppetclass_ids": []int{5}}, "host_parameters_attributes": params}})
	return body
}
func quote(s string) string { return "'" + strings.ReplaceAll(s, "'", "'\"'\"'") + "'" }
func bashCall(t *testing.T, c Config) ([]byte, error) {
	t.Helper()
	root, _ := filepath.Abs("../../..")
	script := `set +x; set -a
source "$1"
`
	for _, p := range []struct{ name, value string }{{"FOREMAN_URL", c.URL}, {"FOREMAN_CA_CERT", c.CACert}, {"FOREMAN_USERNAME", c.Username}, {"FOREMAN_PAT", c.Token}, {"PAYLOAD", string(c.Payload)}} {
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
		for _, scenario := range []string{"created", "unmanaged", "team", "duplicate", "denied", "servererror", "redirect", "untrusted", "http"} {
			t.Run(implementation+"/"+scenario, func(t *testing.T) {
				c := Config{Username: "bootstrap_dev", Token: testToken, Payload: payload(scenario != "unmanaged", "")}
				if scenario == "team" {
					c.Payload = payload(true, "data_infra")
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
					body, _ := io.ReadAll(r.Body)
					if !bytes.Equal(body, c.Payload) {
						t.Error("caller payload changed")
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
		_, err := bashCall(t, Config{URL: "https://localhost", Username: "bootstrap", Token: token, Payload: payload(true, "")})
		if err == nil {
			t.Fatal("unsafe curl config credential accepted")
		}
	}
}
