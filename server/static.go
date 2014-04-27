package main

import (
	"net/http"
	"os"
	"path"
	"runtime"
	"strings"
)

const index = "index.html"
const defaultExt = ".html"

func getFile(dir http.FileSystem, name string) (http.File, os.FileInfo, error) {
	name = strings.TrimSuffix(name, "/")

	f, err := dir.Open(name)
	if err != nil {
		if strings.HasSuffix(name, defaultExt) {
			return nil, nil, err
		} else {
			return getFile(dir, name+defaultExt)
		}
	}

	d, err := f.Stat()
	if err != nil {
		f.Close()
		return nil, nil, err
	}

	if d.IsDir() {
		f.Close()
		return getFile(dir, path.Join(name, index))
	} else {
		return f, d, nil
	}
}

func static(root string) func(http.ResponseWriter, *http.Request) {
	_, filename, _, _ := runtime.Caller(1)
	dir := http.Dir(path.Join(path.Dir(filename), root))

	return func(w http.ResponseWriter, r *http.Request) {
		f, d, err := getFile(dir, r.URL.String())
		if err != nil {
			NotFound(w, r)
			return
		}
		defer f.Close()

		http.ServeContent(w, r, d.Name(), d.ModTime(), f)
	}
}
