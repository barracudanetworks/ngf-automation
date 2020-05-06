package barracudacgf

import "net/http"

type boxService struct {
	*Client
}

//List
func (s *boxService) GetCGFInfo() (*http.Response, error) {
	u := "/box/info"

	req, err := s.newRequest("GET", u, nil)
	if err != nil {
		return nil, err
	}

	res, err := s.do(req, nil)
	if err != nil {
		return nil, err
	}

	return res, nil
}

//Create

//Update

//Delete
