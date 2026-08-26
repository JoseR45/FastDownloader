# FastDownloader

FastDownloader is a simple and fast application for downloading videos from URLs.

## Supported Platforms

FastDownloader uses `yt-dlp` to support video downloads from a wide range of websites, including:

- YouTube
- Instagram
- TikTok
- Facebook
- X (Twitter)
- Reddit
- Twitch
- Vimeo
- Dailymotion
- And many more

## Installation

1. Open the `FastDownloader-0.0.1.dmg` file.
2. Drag the `FastDownloader.app` into your **Applications** folder.
3. Right-click on the app and select **"Open"** to bypass macOS security warnings for the first launch (since it is not notarized yet).

> **Note**: The app uses `yt-dlp` as its download engine. On the first launch, it automatically copies the binary to your `Application Support` folder.

## Troubleshooting: Updating yt-dlp Manually

FastDownloader uses the `yt-dlp` binary to extract and download videos. 
Platforms like YouTube frequently change their internal APIs, which can cause 
the old binary to stop working or return errors (e.g., **"HTTP Error 403: Forbidden"**).

If you experience download failures, you can manually update the binary by 
following these steps:

1. **Copy the path to the folder**: Open Finder, press `Cmd + Shift + G`, and paste this path: ~/Library/Application Support/FastDownloader
2. **Download and replace the file**: Open Terminal and run this command. It will automatically download the latest version and replace the old file:
```bash
curl -L "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos" -o ~/Library/Application\ Support/FastDownloader/yt-dlp
```
4. **Make it executable**: Open Terminal and run:
```bash
chmod +x ~/Library/Application Support/FastDownloader/yt-dlp
```
5. Remove the quarantine flag (optional, but recommended if macOS blocks it):
```bash
xattr -d com.apple.quarantine ~/Library/Application Support/FastDownloader/yt-dlp
```

After these steps, restart FastDownloader and try downloading again.

## License

FastDownloader is licensed under the PolyForm Noncommercial License 1.0.0.

See [LICENSE](LICENSE) for the full license terms.

## Disclaimer

FastDownloader is intended for downloading content that you have
permission to download or that is otherwise permitted by the applicable
platform's terms and applicable law.

FastDownloader is not affiliated with or endorsed by YouTube or Instagram.
