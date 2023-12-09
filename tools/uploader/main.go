package main

import (
	"log"
)

func main() {
	dyUploader, err := NewDyUploader(DyUploaderOpts{
		Credential: "/Users/lzhhhh/Documents/Projects/ass/tools/uploader/cookie.json",
		Video:      "/Users/lzhhhh/Documents/Projects/ass/temp/result.mp4",
		Title:      `江西税务热线回应「花 10 万买彩票中 2.2 亿」是否需缴税，称「存在争议」，如何从法律角度解读？`,
		Tags:       []string{"彩票"},
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
