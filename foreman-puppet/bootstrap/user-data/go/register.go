// Package registration registers existing instances directly through the Foreman
// HTTPS API. No Ruby, Bash or Puppet process is invoked. Linux targets only.
package registration

import (
	"bytes"
	"context"
	"crypto/tls"
	"crypto/x509"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"regexp"
	"strings"
	"syscall"
	"time"
)

type Foreman struct {
	URL      string `json:"url"`
	CACert   string `json:"ca_cert"`
	Username string `json:"username"`
}
type Auth struct {
	Source    string `json:"source"`
	Region    string `json:"region,omitempty"`
	Reference string `json:"reference,omitempty"`
	Path      string `json:"path,omitempty"`
}
type Parameters struct {
	DeployEnv string  `json:"deploy_env"`
	Team      *string `json:"team"`
	DRSite    *string `json:"dr_site"`
	Managed   *bool   `json:"puppet_managed"`
}
type Host struct {
	Name           string     `json:"name"`
	Identity       string     `json:"bootstrap_identity"`
	CSP            string     `json:"csp"`
	OrganizationID int        `json:"organization_id"`
	LocationID     int        `json:"location_id"`
	HostgroupID    int        `json:"hostgroup_id"`
	EnvironmentID  int        `json:"environment_id"`
	RoleID         int        `json:"role_id"`
	ProxyID        int        `json:"puppet_proxy_id"`
	CAProxyID      int        `json:"puppet_ca_proxy_id"`
	Environment    string     `json:"environment"`
	Role           string     `json:"role"`
	Parameters     Parameters `json:"parameters"`
}
type Config struct {
	Foreman Foreman `json:"foreman"`
	Auth    Auth    `json:"auth"`
	Host    Host    `json:"host"`
}
type Result struct {
	Mode       string `json:"mode,omitempty"`
	Status     string `json:"status,omitempty"`
	ID         int    `json:"id,omitempty"`
	Name       string `json:"name,omitempty"`
	Host       string `json:"host,omitempty"`
	Policy     string `json:"policy,omitempty"`
	AuthSource string `json:"auth_source,omitempty"`
}

func match(pattern, value string) bool { return regexp.MustCompile(pattern).MatchString(value) }
func validRole(role string) bool {
	switch role {
	case "role::base", "role::unmanaged", "role::devops", "role::data_infra":
		return true
	}
	return false
}
func environment(env string) string {
	switch env {
	case "dev":
		return "development"
	case "prd":
		return "production"
	}
	return ""
}
func validTeam(team *string) bool { return team == nil || match(`^[a-z][a-z0-9_-]{0,63}$`, *team) }
func validDR(site *string) bool   { return site == nil || *site == "primary" || *site == "secondary" }

// LoadConfig never reads credentials or makes network requests. Parse errors are
// deliberately sanitized, since callers must not log untrusted JSON fragments.
func LoadConfig(reader io.Reader) (Config, error) {
	var c Config
	b, err := io.ReadAll(io.LimitReader(reader, 1048577))
	if err != nil || len(b) > 1048576 {
		return c, errors.New("could not read registration input")
	}
	d := json.NewDecoder(bytes.NewReader(b))
	d.DisallowUnknownFields()
	if err = d.Decode(&c); err != nil {
		return c, errors.New("invalid registration input")
	}
	if d.Decode(new(any)) != io.EOF {
		return c, errors.New("invalid registration input")
	}
	return c, c.Validate()
}
func (c Config) Validate() error {
	h, p, a := c.Host, c.Host.Parameters, c.Auth
	if !match(`^https://[A-Za-z0-9.-]+(:[0-9]+)?/?$`, c.Foreman.URL) || !strings.HasPrefix(c.Foreman.CACert, "/") || !match(`^[a-zA-Z0-9_.@-]+$`, c.Foreman.Username) {
		return errors.New("invalid Foreman HTTPS origin, CA path or username")
	}
	for _, id := range []int{h.OrganizationID, h.LocationID, h.HostgroupID, h.EnvironmentID, h.RoleID, h.ProxyID, h.CAProxyID} {
		if id <= 0 {
			return errors.New("reference IDs must be positive integers")
		}
	}
	if !match(`^[a-z0-9][a-z0-9.-]*\.[a-z0-9-]+$`, h.Name) || len(h.Name) > 253 {
		return errors.New("use a unique FQDN as host name and agent certname")
	}
	if (h.CSP != "aws" && h.CSP != "gcp" && h.CSP != "kc") || !validRole(h.Role) || environment(p.DeployEnv) == "" || h.Environment != environment(p.DeployEnv) || !validTeam(p.Team) || !validDR(p.DRSite) || p.Managed == nil || (h.Role == "role::unmanaged" && *p.Managed) {
		return errors.New("invalid initial classification policy")
	}
	if !match(`^[a-zA-Z0-9_:/\.=-]{3,256}$`, h.Identity) || !strings.HasPrefix(h.Identity, h.CSP+"/") {
		return errors.New("stable cloud resource identity required")
	}
	switch a.Source {
	case "aws_ssm":
		if !match(`^[a-z0-9-]+$`, a.Region) || !match(`^[a-zA-Z0-9_/\.:-]+$`, a.Reference) {
			return errors.New("SSM region/reference required")
		}
	case "file":
		if !strings.HasPrefix(a.Path, "/") {
			return errors.New("absolute PAT file path required")
		}
	default:
		return errors.New("unknown PAT source")
	}
	return nil
}

type boundedBuffer struct{ bytes.Buffer }

func (b *boundedBuffer) Write(p []byte) (int, error) {
	if b.Len()+len(p) > 65536 {
		return 0, errors.New("secret response too large")
	}
	return b.Buffer.Write(p)
}
func loadToken(ctx context.Context, a Auth) (string, error) {
	var data []byte
	if a.Source == "file" {
		fd, err := syscall.Open(a.Path, syscall.O_RDONLY|syscall.O_NOFOLLOW|syscall.O_NONBLOCK, 0)
		if err != nil {
			return "", errors.New("could not securely open PAT file")
		}
		f := os.NewFile(uintptr(fd), a.Path)
		defer f.Close()
		s, err := f.Stat()
		if err != nil {
			return "", errors.New("could not stat PAT file")
		}
		owner, ok := s.Sys().(*syscall.Stat_t)
		if !ok || owner.Uid != 0 || !s.Mode().IsRegular() || s.Mode().Perm() != 0600 || s.Size() > 4096 {
			return "", errors.New("PAT file must be root-owned regular file with mode 0600")
		}
		data, err = io.ReadAll(io.LimitReader(f, 4097))
		if err != nil {
			return "", errors.New("could not securely read PAT file")
		}
	} else {
		ctx, cancel := context.WithTimeout(ctx, 30*time.Second)
		defer cancel()
		cmd := exec.CommandContext(ctx, "aws", "ssm", "get-parameter", "--name", a.Reference, "--with-decryption", "--region", a.Region, "--output", "json")
		cmd.Env = append(os.Environ(), "AWS_PAGER=")
		cmd.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
		cmd.Cancel = func() error {
			if cmd.Process == nil {
				return os.ErrProcessDone
			}
			err := syscall.Kill(-cmd.Process.Pid, syscall.SIGKILL)
			if err == syscall.ESRCH {
				return os.ErrProcessDone
			}
			return err
		}
		cmd.WaitDelay = time.Second
		var output boundedBuffer
		cmd.Stdout = &output
		cmd.Stderr = io.Discard
		if err := cmd.Run(); err != nil {
			return "", errors.New("could not securely load SSM PAT")
		}
		var response struct {
			Parameter struct {
				Type  string
				Value string
			}
		}
		if json.Unmarshal(output.Bytes(), &response) != nil || response.Parameter.Type != "SecureString" {
			return "", errors.New("SSM parameter must be SecureString")
		}
		data = []byte(response.Parameter.Value)
	}
	token := strings.Trim(string(data), " \t\r\n\v\f")
	if !match(`^[!-~]+$`, token) || len(token) < 16 || len(token) > 2048 {
		return "", errors.New("invalid PAT format")
	}
	return token, nil
}

type api struct {
	client                *http.Client
	base, username, token string
}

func newAPI(c Foreman, token string) (*api, error) {
	pem, err := os.ReadFile(c.CACert)
	if err != nil {
		return nil, errors.New("could not read Foreman CA certificate")
	}
	pool := x509.NewCertPool()
	if !pool.AppendCertsFromPEM(pem) {
		return nil, errors.New("invalid Foreman CA certificate")
	}
	transport := &http.Transport{Proxy: nil, DialContext: (&net.Dialer{Timeout: 10 * time.Second}).DialContext, TLSClientConfig: &tls.Config{RootCAs: pool, MinVersion: tls.VersionTLS12}, TLSHandshakeTimeout: 10 * time.Second, ResponseHeaderTimeout: 30 * time.Second}
	client := &http.Client{Transport: transport, Timeout: 60 * time.Second, CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse }}
	return &api{client: client, base: strings.TrimSuffix(c.URL, "/"), username: c.Username, token: token}, nil
}
func (a *api) call(ctx context.Context, method, path string, body any, out any) error {
	var reader io.Reader
	if body != nil {
		b, err := json.Marshal(body)
		if err != nil {
			return errors.New("invalid create payload")
		}
		reader = bytes.NewReader(b)
	}
	req, err := http.NewRequestWithContext(ctx, method, a.base+path, reader)
	if err != nil {
		return errors.New("invalid API request")
	}
	req.SetBasicAuth(a.username, a.token)
	req.Header.Set("Accept", "application/json")
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	response, err := a.client.Do(req)
	if err != nil {
		return errors.New("Foreman transport failed (check TLS/network; POST is not retried)")
	}
	defer response.Body.Close()
	if response.StatusCode < 200 || response.StatusCode > 299 {
		return fmt.Errorf("Foreman HTTP %d", response.StatusCode)
	}
	b, err := io.ReadAll(io.LimitReader(response.Body, 8388609))
	if err != nil || len(b) > 8388608 || json.Unmarshal(b, out) != nil {
		return errors.New("invalid Foreman JSON response")
	}
	return nil
}

type hostRecord struct {
	ID             int    `json:"id"`
	Name           string `json:"name"`
	OrganizationID int    `json:"organization_id"`
	LocationID     int    `json:"location_id"`
}
type encPolicy struct {
	Environment string                     `json:"environment"`
	Parameters  map[string]any             `json:"parameters"`
	Classes     map[string]json.RawMessage `json:"classes"`
}

func (a *api) lookup(ctx context.Context, h Host) (*hostRecord, error) {
	var list struct {
		Subtotal *int         `json:"subtotal"`
		Results  []hostRecord `json:"results"`
	}
	q := url.Values{"search": {`name="` + h.Name + `"`}, "per_page": {"100"}}
	if err := a.call(ctx, "GET", "/api/hosts?"+q.Encode(), nil, &list); err != nil {
		return nil, err
	}
	if list.Subtotal == nil || *list.Subtotal > 100 || list.Results == nil {
		return nil, errors.New("host lookup incomplete")
	}
	var found *hostRecord
	for _, r := range list.Results {
		if r.Name == h.Name {
			if found != nil {
				return nil, errors.New("ambiguous host name")
			}
			copy := r
			found = &copy
		}
	}
	return found, nil
}
func verifyPolicy(e encPolicy, h Host, created bool) error {
	p := e.Parameters
	if p["bootstrap_identity"] != h.Identity || p["csp"] != h.CSP {
		return errors.New("host identity collision; policy will not be overwritten")
	}
	var roles []string
	for role := range e.Classes {
		if strings.HasPrefix(role, "role::") {
			roles = append(roles, role)
		}
	}
	managed, ok := p["puppet_managed"].(bool)
	if len(roles) != 1 || !validRole(roles[0]) || !ok || (roles[0] == "role::unmanaged" && managed) {
		return errors.New("invalid central role/management policy")
	}
	env, _ := p["deploy_env"].(string)
	if environment(env) == "" || e.Environment != environment(env) {
		return errors.New("invalid central environment")
	}
	for _, key := range []string{"team", "dr_site"} {
		if p[key] != nil {
			s, ok := p[key].(string)
			if !ok || (key == "team" && !validTeam(&s)) || (key == "dr_site" && !validDR(&s)) {
				return errors.New("invalid central team/dr_site")
			}
		}
	}
	if created {
		if roles[0] != h.Role || e.Environment != h.Environment || env != h.Parameters.DeployEnv || managed != *h.Parameters.Managed {
			return errors.New("created host policy differs from input")
		}
		for key, expected := range map[string]*string{"team": h.Parameters.Team, "dr_site": h.Parameters.DRSite} {
			if (expected == nil && p[key] != nil) || (expected != nil && p[key] != *expected) {
				return errors.New("created host policy differs from input; check inheritance")
			}
		}
	}
	return nil
}
func (a *api) verify(ctx context.Context, h Host, r hostRecord, created bool) (Result, error) {
	if r.ID <= 0 {
		return Result{}, errors.New("invalid host ID")
	}
	var detail hostRecord
	path := fmt.Sprintf("/api/hosts/%d", r.ID)
	if err := a.call(ctx, "GET", path, nil, &detail); err != nil {
		return Result{}, err
	}
	if detail.ID != r.ID || detail.Name != h.Name || detail.OrganizationID != h.OrganizationID || detail.LocationID != h.LocationID {
		return Result{}, errors.New("host name/organization/location mismatch")
	}
	var enc struct {
		Data encPolicy `json:"data"`
	}
	if err := a.call(ctx, "GET", path+"/enc", nil, &enc); err != nil {
		return Result{}, err
	}
	if err := verifyPolicy(enc.Data, h, created); err != nil {
		return Result{}, err
	}
	status := "existing_preserved"
	if created {
		status = "created"
	}
	return Result{Status: status, ID: r.ID, Name: h.Name}, nil
}
func payload(h Host) any {
	parameters := []map[string]any{{"name": "deploy_env", "value": h.Parameters.DeployEnv, "parameter_type": "string"}, {"name": "puppet_managed", "value": fmt.Sprint(*h.Parameters.Managed), "parameter_type": "boolean"}, {"name": "bootstrap_identity", "value": h.Identity, "parameter_type": "string"}}
	for _, kv := range []struct {
		name  string
		value *string
	}{{"team", h.Parameters.Team}, {"dr_site", h.Parameters.DRSite}} {
		if kv.value != nil {
			parameters = append(parameters, map[string]any{"name": kv.name, "value": *kv.value, "parameter_type": "string"})
		}
	}
	return map[string]any{"host": map[string]any{"name": h.Name, "organization_id": h.OrganizationID, "location_id": h.LocationID, "hostgroup_id": h.HostgroupID, "puppet_proxy_id": h.ProxyID, "puppet_ca_proxy_id": h.CAProxyID, "managed": false, "build": false, "overwrite": false, "puppet_attributes": map[string]any{"environment_id": h.EnvironmentID, "puppetclass_ids": []int{h.RoleID}}, "host_parameters_attributes": parameters}}
}

// RegisterForeman executes an offline plan unless apply is true. On apply it
// uses PAT/HTTPS and creates at most once. Existing central policy is read-only.
// Success is host/ENC registration, not CA enrollment or a first Puppet run.
func RegisterForeman(ctx context.Context, c Config, apply bool) (Result, error) {
	if err := c.Validate(); err != nil {
		return Result{}, err
	}
	if !apply {
		return Result{Mode: "plan", Host: c.Host.Name, AuthSource: c.Auth.Source, Policy: "create-only; existing central policy preserved"}, nil
	}
	token, err := loadToken(ctx, c.Auth)
	if err != nil {
		return Result{}, err
	}
	a, err := newAPI(c.Foreman, token)
	if err != nil {
		return Result{}, err
	}
	defer a.client.CloseIdleConnections()
	return a.run(ctx, c.Host)
}
func (a *api) run(ctx context.Context, h Host) (Result, error) {
	found, err := a.lookup(ctx, h)
	if err != nil {
		return Result{}, err
	}
	if found != nil {
		return a.verify(ctx, h, *found, false)
	}
	for _, ref := range []struct {
		endpoint string
		id       int
		name     string
	}{{"hostgroups", h.HostgroupID, h.CSP}, {"environments", h.EnvironmentID, h.Environment}, {"puppetclasses", h.RoleID, h.Role}} {
		var obj struct {
			Name string `json:"name"`
		}
		if err := a.call(ctx, "GET", fmt.Sprintf("/api/%s/%d", ref.endpoint, ref.id), nil, &obj); err != nil {
			return Result{}, err
		}
		if obj.Name != ref.name {
			return Result{}, errors.New("reference ID/name mismatch")
		}
	}
	var created hostRecord
	if err := a.call(ctx, "POST", "/api/hosts", payload(h), &created); err != nil {
		// An ambiguous POST is reconciled, never retried or followed by an update.
		found, lookupErr := a.lookup(ctx, h)
		if lookupErr != nil {
			return Result{}, lookupErr
		}
		if found != nil {
			return a.verify(ctx, h, *found, false)
		}
		return Result{}, err
	}
	return a.verify(ctx, h, created, true)
}
