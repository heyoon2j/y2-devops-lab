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
	"sync"
	"testing"
)

const testToken = `test-token-"\-value-12345`

func fixture(t *testing.T) Config {
	t.Helper()
	b, err := os.ReadFile("../../examples/registration.json")
	if err != nil {
		t.Fatal(err)
	}
	b = bytes.ReplaceAll(b, []byte("i-EXAMPLE"), []byte("i-123"))
	c, err := LoadConfig(bytes.NewReader(b))
	if err != nil {
		t.Fatal(err)
	}
	return c
}
func write(t *testing.T, path string, data []byte) {
	t.Helper()
	if err := os.WriteFile(path, data, 0600); err != nil {
		t.Fatal(err)
	}
}

type mockForeman struct {
	sync.Mutex
	scenario string
	present  bool
	calls    []string
	post     map[string]any
	host     Host
	badAuth  bool
}

func (m *mockForeman) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	m.Lock()
	defer m.Unlock()
	m.calls = append(m.calls, r.Method+" "+r.URL.Path)
	username, token, ok := r.BasicAuth()
	if !ok || username != "bootstrap_dev" || token != testToken {
		m.badAuth = true
		w.WriteHeader(401)
		return
	}
	send := func(v any) { w.Header().Set("Content-Type", "application/json"); json.NewEncoder(w).Encode(v) }
	if m.scenario == "get403" {
		w.WriteHeader(403)
		return
	}
	if m.scenario == "redirect" {
		w.Header().Set("Location", "https://elsewhere.invalid/")
		w.WriteHeader(302)
		return
	}
	if m.scenario == "badjson" {
		w.Write([]byte("not json"))
		return
	}
	if r.Method == "POST" {
		if r.URL.Path != "/api/hosts" {
			w.WriteHeader(404)
			return
		}
		if m.scenario == "post403" {
			w.WriteHeader(403)
			return
		}
		if json.NewDecoder(r.Body).Decode(&m.post) != nil {
			w.WriteHeader(400)
			return
		}
		m.present = true
		if m.scenario == "ambiguous" {
			w.WriteHeader(503)
			return
		}
		send(map[string]any{"id": 42})
		return
	}
	if r.Method != "GET" {
		w.WriteHeader(405)
		return
	}
	switch r.URL.Path {
	case "/api/hosts":
		if r.URL.Query().Get("search") != `name="`+m.host.Name+`"` {
			w.WriteHeader(422)
			return
		}
		results := []any{}
		if m.present {
			results = append(results, map[string]any{"id": 42, "name": m.host.Name})
		}
		send(map[string]any{"subtotal": len(results), "results": results})
	case "/api/hosts/42":
		org := m.host.OrganizationID
		if m.scenario == "orgcollision" {
			org++
		}
		send(map[string]any{"id": 42, "name": m.host.Name, "organization_id": org, "location_id": m.host.LocationID})
	case "/api/hosts/42/enc":
		p := map[string]any{"csp": m.host.CSP, "bootstrap_identity": m.host.Identity, "deploy_env": m.host.Parameters.DeployEnv, "puppet_managed": *m.host.Parameters.Managed, "dr_site": "primary"}
		env, role := m.host.Environment, m.host.Role
		switch m.scenario {
		case "existing":
			p["team"] = "devops"
			p["deploy_env"] = "prd"
			env = "production"
			role = "role::devops"
		case "identitycollision":
			p["bootstrap_identity"] = "aws/another-instance"
		case "stringbool":
			p["puppet_managed"] = "true"
		case "nullinherit":
			p["team"] = "inherited"
		case "badenv":
			env = "production"
		case "baddr":
			p["dr_site"] = "invalid"
		case "unmanagedtrue":
			role = "role::unmanaged"
		}
		classes := map[string]any{role: map[string]any{}}
		if m.scenario == "twoRoles" {
			classes["role::devops"] = map[string]any{}
		}
		send(map[string]any{"data": map[string]any{"environment": env, "parameters": p, "classes": classes}})
	case "/api/hostgroups/1":
		name := m.host.CSP
		if m.scenario == "badreference" {
			name = "gcp"
		}
		send(map[string]any{"name": name})
	case "/api/environments/1":
		send(map[string]any{"name": m.host.Environment})
	case "/api/puppetclasses/1":
		send(map[string]any{"name": m.host.Role})
	default:
		w.WriteHeader(404)
	}
}

func TestDirectClients(t *testing.T) {
	root, err := filepath.Abs("../../..")
	if err != nil {
		t.Fatal(err)
	}
	curl, err := exec.LookPath("curl")
	if err != nil {
		t.Fatal(err)
	}
	for _, implementation := range []string{"go", "bash"} {
		for _, scenario := range []string{"new", "new_unmanaged", "new_data_infra", "new_devops", "existing", "identitycollision", "orgcollision", "stringbool", "nullinherit", "badenv", "baddr", "unmanagedtrue", "twoRoles", "badreference", "ambiguous", "get403", "post403", "redirect", "badjson", "untrusted"} {
			t.Run(implementation+"/"+scenario, func(t *testing.T) {
				c := fixture(t)
				switch scenario {
				case "new_unmanaged":
					c.Host.Role = "role::unmanaged"
					v := false
					c.Host.Parameters.Managed = &v
				case "new_data_infra":
					c.Host.Role = "role::data_infra"
				case "new_devops":
					c.Host.Role = "role::devops"
				}
				dir := t.TempDir()
				mock := &mockForeman{scenario: scenario, host: c.Host}
				switch scenario {
				case "existing", "identitycollision", "orgcollision", "stringbool", "badenv", "baddr", "unmanagedtrue", "twoRoles":
					mock.present = true
				}
				server := httptest.NewTLSServer(mock)
				defer server.Close()
				c.Foreman.URL = server.URL
				c.Foreman.CACert = filepath.Join(dir, "ca.pem")
				if scenario == "untrusted" {
					other := httptest.NewTLSServer(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {}))
					defer other.Close()
					write(t, c.Foreman.CACert, pem.EncodeToMemory(&pem.Block{Type: "CERTIFICATE", Bytes: other.Certificate().Raw}))
					// httptest uses the same static certificate for all servers; system trust
					// excludes its issuer, so use the system bundle for this negative case.
					c.Foreman.CACert = "/etc/ssl/certs/ca-certificates.crt"
				} else {
					write(t, c.Foreman.CACert, pem.EncodeToMemory(&pem.Block{Type: "CERTIFICATE", Bytes: server.Certificate().Raw}))
				}
				response, _ := json.Marshal(map[string]any{"Parameter": map[string]any{"Type": "SecureString", "Value": testToken}})
				secretFile := filepath.Join(dir, "ssm.json")
				write(t, secretFile, response)
				// Only the fake SSM child reads this fixture, never a real AWS account.
				aws := filepath.Join(dir, "aws")
				write(t, aws, []byte("#!/bin/bash\nprintf '%s\\n' \"$@\" > \"$TEST_ARGS\"\ncat \"$TEST_SSM\"\n"))
				os.Chmod(aws, 0700)
				// Record process argv/environment to guard against accidental token exports.
				wrapper := filepath.Join(dir, "curl")
				write(t, wrapper, []byte("#!/bin/bash\nprintf '%s\\n' \"$@\" >> \"$TEST_ARGS\"\nenv >> \"$TEST_ARGS\"\nexec \"$TEST_CURL\" \"$@\"\n"))
				os.Chmod(wrapper, 0700)
				t.Setenv("PATH", dir+":"+os.Getenv("PATH"))
				t.Setenv("TEST_ARGS", filepath.Join(dir, "args"))
				t.Setenv("TEST_SSM", secretFile)
				t.Setenv("TEST_CURL", curl)
				var result Result
				var runErr error
				var output []byte
				var diagnostics bytes.Buffer
				if implementation == "go" {
					result, runErr = RegisterForeman(context.Background(), c, true)
				} else {
					config := filepath.Join(dir, "input.json")
					b, _ := json.Marshal(c)
					write(t, config, b)
					// Exercise the public reusable API function as an unprivileged test user.
					// CLI root guard is checked separately, without bypasses in production.
					cmd := exec.Command("bash", "-c", `set -a; pat=old; escaped_pat=old; secret_response=old; source "$1"; foreman_register "$2" "$3" apply`, "test", filepath.Join(root, "bootstrap/user-data/register.bash"), root, config)
					cmd.Stderr = &diagnostics
					output, runErr = cmd.Output()
					if runErr == nil {
						if err := json.Unmarshal(output, &result); err != nil {
							t.Fatalf("invalid result: %s", output)
						}
					}
				}
				success := strings.HasPrefix(scenario, "new") || scenario == "existing" || scenario == "ambiguous"
				if success != (runErr == nil) {
					t.Fatalf("success=%v, got %v, output=%s", success, runErr, append(output, diagnostics.Bytes()...))
				}
				if success {
					want := "existing_preserved"
					if strings.HasPrefix(scenario, "new") {
						want = "created"
					}
					if result.Status != want {
						t.Fatalf("status: %s", result.Status)
					}
				}
				if bytes.Contains(append(output, diagnostics.Bytes()...), []byte(testToken)) {
					t.Fatal("token leaked to output")
				}
				args, _ := os.ReadFile(filepath.Join(dir, "args"))
				if bytes.Contains(args, []byte(testToken)) {
					t.Fatal("token leaked to process argv/environment")
				}
				mock.Lock()
				defer mock.Unlock()
				if mock.badAuth {
					t.Fatal("wrong Basic auth encoding")
				}
				posts := 0
				for _, call := range mock.calls {
					if strings.HasPrefix(call, "POST ") {
						posts++
					}
					if !strings.HasPrefix(call, "POST ") && !strings.HasPrefix(call, "GET ") {
						t.Fatal("unexpected mutation", call)
					}
				}
				if posts > 1 {
					t.Fatal("POST retried")
				}
				if scenario == "existing" && posts != 0 {
					t.Fatal("existing host mutated")
				}
				if scenario == "badreference" && posts != 0 {
					t.Fatal("bad reference created host")
				}
				if mock.post != nil {
					h := mock.post["host"].(map[string]any)
					if h["overwrite"] != false || h["managed"] != false {
						t.Fatal("unsafe creation flags")
					}
					params := h["host_parameters_attributes"].([]any)
					typed := false
					for _, value := range params {
						p := value.(map[string]any)
						if p["name"] == "team" {
							t.Fatal("null team not omitted")
						}
						if p["name"] == "puppet_managed" {
							typed = p["parameter_type"] == "boolean" && p["value"] == fmt.Sprint(*c.Host.Parameters.Managed)
						}
					}
					if !typed {
						t.Fatal("missing typed Boolean")
					}
				}
			})
		}
	}
}

func TestPlanAndValidation(t *testing.T) {
	c := fixture(t)
	c.Auth = Auth{Source: "file", Path: "/nonexistent/pat"}
	result, err := RegisterForeman(context.Background(), c, false)
	if err != nil || result.Mode != "plan" {
		t.Fatal("offline plan failed", err)
	}
	root, _ := filepath.Abs("../../..")
	config := filepath.Join(t.TempDir(), "input with spaces.json")
	b, _ := json.Marshal(c)
	write(t, config, b)
	output, err := exec.Command("bash", filepath.Join(root, "bootstrap/agent/register.sh"), "--config", config).CombinedOutput()
	if err != nil || json.Unmarshal(output, &result) != nil || result.Mode != "plan" {
		t.Fatalf("Bash plan failed %v %s", err, output)
	}
	relative, _ := filepath.Rel(root, config)
	relativeCmd := exec.Command("bash", "bootstrap/agent/register.sh", "--config", relative)
	relativeCmd.Dir = root
	if out, err := relativeCmd.CombinedOutput(); err != nil {
		t.Fatalf("relative CLI input failed: %v %s", err, out)
	}
	if os.Geteuid() != 0 {
		output, err = exec.Command("bash", filepath.Join(root, "bootstrap/agent/register.sh"), "--config", config, "--apply").CombinedOutput()
		if err == nil || !bytes.Contains(output, []byte("requires root")) {
			t.Fatal("CLI root guard missing")
		}
	}
	for _, kind := range []string{"sandbox", "http", "userinfo", "unknownrole", "unmanaged", "environment", "boolean", "unknownparam"} {
		t.Run(kind, func(t *testing.T) {
			b, _ := json.Marshal(fixture(t))
			var obj map[string]any
			json.Unmarshal(b, &obj)
			h := obj["host"].(map[string]any)
			p := h["parameters"].(map[string]any)
			f := obj["foreman"].(map[string]any)
			switch kind {
			case "sandbox":
				p["deploy_env"] = "sandbox"
			case "http":
				f["url"] = "http://localhost"
			case "userinfo":
				f["url"] = "https://user:token@localhost"
			case "unknownrole":
				h["role"] = "role::other"
			case "unmanaged":
				h["role"] = "role::unmanaged"
			case "environment":
				h["environment"] = "production"
			case "boolean":
				p["puppet_managed"] = "false"
			case "unknownparam":
				p["extra"] = true
			}
			bad, _ := json.Marshal(obj)
			if _, err := LoadConfig(bytes.NewReader(bad)); err == nil {
				t.Fatal("Go accepted invalid input")
			}
			write(t, config, bad)
			if out, err := exec.Command("bash", filepath.Join(root, "bootstrap/agent/register.sh"), "--config", config).CombinedOutput(); err == nil {
				t.Fatalf("Bash accepted invalid input: %s", out)
			}
		})
	}
}

func TestTokenFileGuards(t *testing.T) {
	file := filepath.Join(t.TempDir(), "pat")
	write(t, file, []byte(testToken))
	os.Chmod(file, 0644)
	if _, err := loadToken(context.Background(), Auth{Source: "file", Path: file}); err == nil {
		t.Fatal("unsafe mode accepted")
	}
	link := file + ".link"
	os.Symlink(file, link)
	if _, err := loadToken(context.Background(), Auth{Source: "file", Path: link}); err == nil {
		t.Fatal("symlink accepted")
	}
	os.Chmod(file, 0600)
	token, err := loadToken(context.Background(), Auth{Source: "file", Path: file})
	if os.Geteuid() == 0 {
		if err != nil || token != testToken {
			t.Fatal("safe file rejected", err)
		}
	} else if err == nil {
		t.Fatal("non-root-owned token accepted")
	}
}

func TestSSMAndSecretGuards(t *testing.T) {
	root, _ := filepath.Abs("../../..")
	for _, kind := range []string{"plaintext", "short", "nul", "too_long", "padded"} {
		t.Run(kind, func(t *testing.T) {
			c := fixture(t)
			dir := t.TempDir()
			mock := &mockForeman{scenario: "new", host: c.Host}
			server := httptest.NewTLSServer(mock)
			defer server.Close()
			c.Foreman.URL = server.URL
			c.Foreman.CACert = filepath.Join(dir, "ca.pem")
			write(t, c.Foreman.CACert, pem.EncodeToMemory(&pem.Block{Type: "CERTIFICATE", Bytes: server.Certificate().Raw}))
			value, paramType := testToken, "SecureString"
			switch kind {
			case "plaintext":
				paramType = "String"
			case "short":
				value = "short"
			case "nul":
				value = testToken + "\x00"
			case "too_long":
				value = strings.Repeat("x", 2049)
			case "padded":
				value = " \t" + testToken + "\r\n"
			}
			response, _ := json.Marshal(map[string]any{"Parameter": map[string]any{"Type": paramType, "Value": value}})
			write(t, filepath.Join(dir, "ssm.json"), response)
			write(t, filepath.Join(dir, "aws"), []byte("#!/bin/bash\ncat \"$TEST_SSM\"\n"))
			os.Chmod(filepath.Join(dir, "aws"), 0700)
			t.Setenv("PATH", dir+":"+os.Getenv("PATH"))
			t.Setenv("TEST_SSM", filepath.Join(dir, "ssm.json"))
			token, err := loadToken(context.Background(), c.Auth)
			if kind == "padded" {
				if err != nil || token != testToken {
					t.Fatal("Go trim mismatch", err)
				}
			} else if err == nil {
				t.Fatal("Go accepted unsafe secret")
			}
			b, _ := json.Marshal(c)
			config := filepath.Join(dir, "input.json")
			write(t, config, b)
			cmd := exec.Command("bash", "-c", `source "$1"; foreman_register "$2" "$3" apply`, "test", filepath.Join(root, "bootstrap/user-data/register.bash"), root, config)
			output, err := cmd.CombinedOutput()
			if (kind == "padded") != (err == nil) {
				t.Fatalf("Bash secret validation mismatch: %v %s", err, output)
			}
			if kind != "padded" {
				mock.Lock()
				calls := len(mock.calls)
				mock.Unlock()
				if calls != 0 {
					t.Fatal("unsafe secret sent to API")
				}
			}
			if bytes.Contains(output, []byte(testToken)) {
				t.Fatal("secret leaked to output")
			}
		})
	}
	// Bash also rejects file permissions, ownership and symlinks before networking.
	file := filepath.Join(t.TempDir(), "pat")
	write(t, file, []byte(testToken))
	for _, kind := range []string{"mode", "symlink", "owner"} {
		if kind == "owner" && os.Geteuid() == 0 {
			continue
		}
		path := file
		os.Chmod(file, 0600)
		if kind == "mode" {
			os.Chmod(file, 0644)
		}
		if kind == "symlink" {
			path = file + ".link"
			os.Symlink(file, path)
		}
		c := fixture(t)
		c.Auth = Auth{Source: "file", Path: path}
		config := filepath.Join(t.TempDir(), "input.json")
		b, _ := json.Marshal(c)
		write(t, config, b)
		output, err := exec.Command("bash", "-c", `source "$1"; foreman_register "$2" "$3" apply`, "test", filepath.Join(root, "bootstrap/user-data/register.bash"), root, config).CombinedOutput()
		if err == nil || !bytes.Contains(output, []byte("PAT file")) {
			t.Fatalf("Bash file guard missing: %v %s", err, output)
		}
	}
}
