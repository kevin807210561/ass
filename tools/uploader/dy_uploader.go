package main

import (
	"errors"
	"fmt"
	"log"
	"os"
	"regexp"
	"strings"
	"time"

	"github.com/playwright-community/playwright-go"
)

type DyUploader struct {
	credential string
	video      string
	title      string
	tags       []string
	vCover     string
	hCover     string

	page                      playwright.Page
	waitDurationBeforePublish time.Duration

	test bool
}

type DyUploaderOpts struct {
	Credential string
	Video      string
	Title      string
	Tags       []string
	VCover     string
	HCover     string
	Test       *bool
}

func NewDyUploader(opts DyUploaderOpts) (*DyUploader, error) {
	checkPath := func(path, ext string) error {
		if path == "" {
			return errors.New("can not be empty")
		} else {
			if _, err := os.Stat(path); err != nil {
				return err
			}
			if !strings.HasSuffix(path, "."+ext) {
				return fmt.Errorf("must end with %s", "."+ext)
			}
		}
		return nil
	}
	if err := checkPath(opts.Credential, "json"); err != nil {
		return nil, fmt.Errorf("credential invalid: %v", err)
	}
	if err := checkPath(opts.Video, "mp4"); err != nil {
		return nil, fmt.Errorf("video invalid: %v", err)
	}
	if opts.Title == "" {
		return nil, errors.New("title invalid: can not be empty")
	}
	if err := checkPath(opts.VCover, "jpg"); err != nil {
		return nil, fmt.Errorf("v cover invalid: %v", err)
	}
	if err := checkPath(opts.HCover, "jpg"); err != nil {
		return nil, fmt.Errorf("h cover invalid: %v", err)
	}
	return &DyUploader{
		credential:                opts.Credential,
		video:                     opts.Video,
		title:                     opts.Title,
		tags:                      opts.Tags,
		vCover:                    opts.VCover,
		hCover:                    opts.HCover,
		waitDurationBeforePublish: 10 * time.Second,
		test: func() bool {
			if opts.Test != nil {
				return *opts.Test
			} else {
				return false
			}
		}(),
	}, nil
}

func (du *DyUploader) Upload() error {
	// prepare
	pw, err := playwright.Run()
	if err != nil {
		return fmt.Errorf("could not start playwright: %v", err)
	}
	browser, err := pw.Chromium.Launch(playwright.BrowserTypeLaunchOptions{
		Headless: func(b bool) *bool {
			return &b
		}(!du.test),
	})
	if err != nil {
		return fmt.Errorf("could not launch browser: %v", err)
	}
	context, err := browser.NewContext(playwright.BrowserNewContextOptions{
		StorageStatePath: &du.credential,
		Permissions:      []string{"geolocation"},
	})
	if err != nil {
		return fmt.Errorf("could not create context: %v", err)
	}
	du.page, err = context.NewPage()
	if err != nil {
		return fmt.Errorf("could not create page: %v", err)
	}
	// automation
	if err := du.uploadVideo(); err != nil {
		return fmt.Errorf("could not upload video: %v", err)
	}
	if err := du.setVideoInfo(); err != nil {
		return fmt.Errorf("could not set video info: %v", err)
	}
	if err := du.uploadVCover(); err != nil {
		return fmt.Errorf("could not upload v cover: %v", err)
	}
	if err := du.uploadHCover(); err != nil {
		return fmt.Errorf("could not upload h cover: %v", err)
	}
	if err := du.notAllowDownload(); err != nil {
		return fmt.Errorf("failed to not allow download: %v", err)
	}
	if err := du.publish(); err != nil {
		return fmt.Errorf("failed to publish: %v", err)
	}
	// stop
	if err = browser.Close(); err != nil {
		return fmt.Errorf("could not close browser: %v", err)
	}
	if err = pw.Stop(); err != nil {
		return fmt.Errorf("could not stop Playwright: %v", err)
	}
	return nil
}

func (du *DyUploader) uploadVideo() error {
	if _, err := du.page.Goto("https://creator.douyin.com/creator-micro/content/upload"); err != nil {
		return fmt.Errorf("could not goto: %v", err)
	}
	if err := du.page.GetByLabel("点击上传").SetInputFiles(du.video); err != nil {
		return fmt.Errorf("could not upload file: %v", err)
	}
	log.Printf("开始上传视频：%s", du.video)
	if err := du.page.WaitForURL("https://creator.douyin.com/creator-micro/content/publish**"); err != nil {
		return fmt.Errorf("could not wait for publish url: %v", err)
	}
	if err := du.page.GetByText("重新上传").WaitFor(playwright.LocatorWaitForOptions{Timeout: func(f float64) *float64 { return &f }(1000 * 60 * 30)}); err != nil {
		return fmt.Errorf("could not wait for 重新上传 visible: %v", err)
	}
	if err := du.page.GetByText("视频剪辑").WaitFor(playwright.LocatorWaitForOptions{Timeout: func(f float64) *float64 { return &f }(1000 * 60 * 30)}); err != nil {
		return fmt.Errorf("could not wait for 视频剪辑 visible: %v", err)
	}
	log.Printf("视频上传完成：%s", du.video)
	return nil
}

func (du *DyUploader) setVideoInfo() error {
	desc := du.title
	if len(du.tags) > 0 {
		desc = desc + " #" + strings.Join(du.tags, " #") + " "
	}
	if err := du.page.Locator(".zone-container").PressSequentially(desc, playwright.LocatorPressSequentiallyOptions{Delay: func(f float64) *float64 {
		return &f
	}(50)}); err != nil {
		return fmt.Errorf("could not fill desc: %v", err)
	}
	log.Printf("填写简介：%s", desc)
	return nil
}

func (du *DyUploader) uploadVCover() error {
	if err := du.page.GetByText("选择封面").Click(); err != nil {
		return fmt.Errorf("could not click 选择封面: %v", err)
	}
	if err := du.page.GetByText("上传封面").Click(); err != nil {
		return fmt.Errorf("could not click 上传封面: %v", err)
	}
	if err := du.page.Locator(".semi-upload-hidden-input").SetInputFiles(du.vCover); err != nil {
		return fmt.Errorf("could not set input file for v cover: %v", err)
	}
	log.Printf("开始上传竖版封面：%s", du.vCover)
	if err := du.page.GetByText("重新选择").WaitFor(playwright.LocatorWaitForOptions{Timeout: func(f float64) *float64 { return &f }(1000 * 60)}); err != nil {
		return fmt.Errorf("could not wait for v cover uploaded: %v", err)
	}
	log.Printf("竖版封面上传完成：%s", du.vCover)
	if err := du.page.GetByText("竖封面").Click(); err != nil {
		return fmt.Errorf("could not click 竖封面: %v", err)
	}
	if err := du.page.GetByRole("button", playwright.PageGetByRoleOptions{Name: "完成"}).Click(); err != nil {
		return fmt.Errorf("could not click 完成: %v", err)
	}
	return nil
}

func (du *DyUploader) uploadHCover() error {
	if err := du.page.Locator("div").Filter(playwright.LocatorFilterOptions{HasText: regexp.MustCompile("^西瓜视频")}).GetByRole("switch").Check(); err != nil {
		return fmt.Errorf("could not ensure sync to xigua: %v", err)
	}
	if err := du.page.GetByText("替换").Nth(1).Click(); err != nil {
		return fmt.Errorf("could not click second 替换: %v", err)
	}
	if err := du.page.GetByText("上传封面").Click(); err != nil {
		return fmt.Errorf("could not click 上传封面: %v", err)
	}
	if err := du.page.Locator(".semi-upload-hidden-input").SetInputFiles(du.hCover); err != nil {
		return fmt.Errorf("could not set input file for h cover: %v", err)
	}
	log.Printf("开始上传横版封面：%s", du.hCover)
	if err := du.page.GetByText("重新选择").WaitFor(playwright.LocatorWaitForOptions{Timeout: func(f float64) *float64 { return &f }(1000 * 60)}); err != nil {
		return fmt.Errorf("could not wait for h cover uploaded: %v", err)
	}
	log.Printf("横版封面上传完成：%s", du.hCover)
	if err := du.page.GetByRole("button", playwright.PageGetByRoleOptions{Name: "完成"}).Click(); err != nil {
		return fmt.Errorf("could not click 完成: %v", err)
	}
	return nil
}

func (du *DyUploader) notAllowDownload() error {
	if err := du.page.GetByLabel("不允许").Click(); err != nil {
		return fmt.Errorf("could not click 不允许: %v", err)
	}
	log.Print("不允许他人保存视频")
	return nil
}

func (du *DyUploader) publish() error {
	if du.test {
		time.Sleep(10 * time.Minute)
		return nil
	}
	if du.waitDurationBeforePublish > 0 {
		time.Sleep(du.waitDurationBeforePublish)
	}
	if err := du.page.GetByRole("button", playwright.PageGetByRoleOptions{Name: "发布", Exact: func(b bool) *bool {
		return &b
	}(true)}).Click(); err != nil {
		return fmt.Errorf("could not click 发布: %v", err)
	}
	if err := du.page.WaitForURL("https://creator.douyin.com/creator-micro/content/manage"); err != nil {
		return fmt.Errorf("could not wait for 发布完成: %v", err)
	}
	log.Print("发布视频")
	return nil
}
