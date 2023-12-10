package main

import (
	"flag"
	"log"
	"strings"
)

type args struct {
	Credential string
	Video      string
	Title      string
	Tags       arrayFlags
	VCover     string
	HCover     string
	Test       bool
}

type arrayFlags []string

func (i *arrayFlags) String() string {
	if len(*i) == 0 {
		return ""
	} else {
		return strings.Join(*i, ",")
	}
}

func (i *arrayFlags) Set(value string) error {
	*i = append(*i, value)
	return nil
}

var Args args

func main() {
	flag.StringVar(&Args.Credential, "credential", "", "凭证路径，执行playwright open https://creator.douyin.com/creator-micro/content/upload --save-storage cookie.json，登录后即可得到")
	flag.StringVar(&Args.Video, "video", "", "视频路径")
	flag.StringVar(&Args.Title, "title", "", "标题")
	flag.Var(&Args.Tags, "tag", "#话题，可指定多次")
	flag.StringVar(&Args.VCover, "v-cover", "", "竖版封面路径")
	flag.StringVar(&Args.HCover, "h-cover", "", "横版封面路径")
	flag.BoolVar(&Args.Test, "test", false, "是否测试发布过程，如果是，那么会打开浏览器且不会进行发布动作")
	flag.Parse()

	dyUploader, err := NewDyUploader(DyUploaderOpts{
		Credential: Args.Credential,
		Video:      Args.Video,
		Title:      Args.Title,
		Tags:       Args.Tags,
		VCover:     Args.VCover,
		HCover:     Args.HCover,
		Test:       &Args.Test,
	})
	if err != nil {
		log.Fatalf("create DyUploader failed: %v", err)
	}
	if err := dyUploader.Upload(); err != nil {
		log.Fatalf("dy upload failed: %v", err)
	}
}
