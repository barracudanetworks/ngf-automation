package barracudacgf

import (
	"bytes"
	"crypto/tls"
	"encoding/json"
	"errors"
	"io"
	"io/ioutil"
	"net"
	"net/http"
	"net/url"
	"strings"
	"time"
)

// Predefine standard errors
var (
	ErrInternalServer = errors.New("CGF: Internal Server error")
	ErrUnknown        = errors.New("CGF: Unknown error")
)

// Client represents a BarracudaCGF API client
type Client struct {
	client           *http.Client
	baseURL          *url.URL
	authtoken        string
	secureConnection bool

	box *boxService
}

// ErrorResponse represents an error response
type ErrorResponse struct {
	Messages []*ErrorMessage `json:"messages"`
}

func (e *ErrorResponse) Error() string {
	var errs []string
	for _, m := range e.Messages {
		errs = append(errs, m.Details)
	}
	return strings.Join(errs, "\n")
}

// ErrorMessage represents a single API error
type ErrorMessage struct {
	Level   string `json:"level"`
	Code    string `json:"code"`
	Context string `json:"context,omitempty"`
	Details string `json:"details"`
}

// NewClient creates a new client for communicating with a Cisco ASA
func newClient(apiURL, authtoken string, secureConnection, sslNoVerify bool) (*Client, error) {

	baseURL, err := url.Parse(apiURL)

	if err != nil {
		return nil, err
	}

	c := &Client{
		client: &http.Client{
			Transport: &http.Transport{
				Proxy: http.ProxyFromEnvironment,
				Dial: (&net.Dialer{
					Timeout:   30 * time.Second,
					KeepAlive: 30 * time.Second,
				}).Dial,
				TLSClientConfig:     &tls.Config{InsecureSkipVerify: sslNoVerify},
				TLSHandshakeTimeout: 10 * time.Second,
			},
			Timeout: 60 * time.Second,
		},
		baseURL:   baseURL,
		authtoken: authtoken,
	}

	//c.firewall = &firewallService{c}
	c.box = &boxService{c}

	return c, nil
}

// newRequest creates a HTTP request of given method and data.
func (c *Client) newRequest(method string, api string, v interface{}) (*http.Request, error) {
	var body io.Reader

	if v != nil {
		data, err := json.Marshal(v)
		if err != nil {
			return nil, err
		}

		body = bytes.NewReader(data)
	}

	u, err := url.Parse(api)
	if err != nil {
		return nil, err
	}

	req, err := http.NewRequest(method, c.baseURL.ResolveReference(u).String(), body)
	if err != nil {
		return nil, err
	}

	req.Close = true
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("User-Agent", "REST API Go Agent")
	req.Header.Set("X-API-Token", c.authtoken)

	return req, nil
}

// do makes the actual API request.
func (c *Client) do(req *http.Request, v interface{}) (*http.Response, error) {
	resp, err := c.client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	err = checkResponse(resp)
	if err != nil {
		return resp, err
	}

	if v != nil {
		if w, ok := v.(io.Writer); ok {
			_, err = io.Copy(w, resp.Body)
		} else {
			err = json.NewDecoder(resp.Body).Decode(v)
		}
	}

	return resp, err
}

// CheckResponse checks the API response for errors, and returns them if present.
func checkResponse(r *http.Response) error {
	switch r.StatusCode {
	case 200, 201, 202, 204:
		return nil
	}

	errorResponse := &ErrorResponse{}
	data, err := ioutil.ReadAll(r.Body)
	if err == nil && data != nil {
		if err := json.Unmarshal(data, errorResponse); err != nil {
			errorResponse.Messages = append(errorResponse.Messages, &ErrorMessage{
				Details: "failed to parse unknown error format",
				Level:   "Error",
			})
		}
	}

	return errorResponse
}
