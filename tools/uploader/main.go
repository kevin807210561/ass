package main

import (
	"log"
)

func main() {
	dyUploader, err := NewDyUploader(DyUploaderOpts{
		Credential: "/Users/lzhhhh/Documents/Projects/ass/tools/uploader/cookie.json",
		Video:      "/Users/lzhhhh/Documents/Projects/ass/temp/result.mp4",
		Title:      `靠谱员工越来越难找该怎么办？`,
		Labels:     []string{"靠谱", "打工", "员工", "老板", "职场"},
		VCover:     "/Users/lzhhhh/Documents/Projects/ass/temp/v_cover.jpg",
		HCover:     "/Users/lzhhhh/Documents/Projects/ass/temp/h_cover.jpg",
	})
	if err != nil {
		log.Fatalf("create DyUploader failed: %v", err)
	}
	if err := dyUploader.Upload(); err != nil {
		log.Fatalf("dy upload failed: %v", err)
	}
}
