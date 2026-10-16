package site

import (
	"net/url"
	"path"
	"strings"
)

// repoURL is where files of the repository that the site does not serve
// are linked to: the main branch on GitHub.
var repoURL = url.URL{Scheme: "https", Host: "github.com", Path: "/podhmo/html-sandbox/blob/main"}

// postsDir is the directory of the repository that holds the posts.
const postsDir = "posts"

// postSource is the file path of p in the repository.
func postSource(p Post) string {
	return postsDir + "/" + p.File
}

// linker resolves the URL of a Markdown link, as written in the file at
// source (a path in the repository), to an href. ok is false when the URL
// must not be linked; the link text is then shown as plain text.
type linker func(u string) (href string, ok bool)

// linker returns the linker for links written in the file at source.
//
// Links with a scheme are kept for http, https, and mailto only, so a post
// cannot run script through a "javascript:" URL. Links to "/..." and
// "#..." are kept as they are. Other links are relative to source, as on
// GitHub: those to a document or post served here go to its page, others
// go to the file on GitHub, and those that leave the repository are not
// linked.
func (st *site) linker(source string) linker {
	return func(raw string) (string, bool) {
		u, err := url.Parse(raw)
		if err != nil {
			return "", false
		}
		switch {
		case u.Scheme != "":
			switch strings.ToLower(u.Scheme) {
			case "http", "https", "mailto":
				return raw, true
			}
			return "", false
		case u.Host != "" || strings.HasPrefix(raw, "/") || strings.HasPrefix(raw, "#") || raw == "":
			return raw, true
		}
		p := path.Join(path.Dir(source), u.Path)
		if p == ".." || strings.HasPrefix(p, "../") {
			return "", false
		}
		var target url.URL
		if d, ok := st.bySource[p]; ok {
			target.Path = docPath(d)
		} else if post, ok := st.byFile[p]; ok {
			target.Path = postPath(post)
		} else {
			// GitHub redirects blob/ to tree/ for directories.
			target = repoURL
			target.Path = path.Join(target.Path, p)
			target.RawQuery = u.RawQuery
		}
		target.Fragment = u.Fragment
		return target.String(), true
	}
}
