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

## Legacy: Manual yt-dlp Updates

> **For FastDownloader v0.0.1**

In previous versions, FastDownloader used a standalone `yt-dlp` binary.
If the binary became outdated, users had to update it manually.

This procedure is no longer required in newer versions. Starting with
**v0.0.2**, FastDownloader uses the FastDownloader Engine and provides
an in-app option to update it.

<details>
<summary>Manual update procedure for v0.0.1</summary>

### Troubleshooting: Updating yt-dlp Manually

FastDownloader v0.0.1 uses the `yt-dlp` binary to extract and download videos.
Platforms like YouTube frequently change their internal APIs, which can cause
the old binary to stop working or return errors (e.g., **"HTTP Error 403: Forbidden"**).

If you experience download failures on **v0.0.1**, you can manually update the
binary by following these steps:

1. **Copy the path to the folder**

   Open Finder, press `Cmd + Shift + G`, and paste:

   `~/Library/Application Support/FastDownloader`

2. **Download and replace the file**

   Open Terminal and run:

   ```bash
   curl -L "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos" -o ~/Library/Application\ Support/FastDownloader/yt-dlp
   ```

3. **Make it executable**

   ```bash
   chmod +x ~/Library/Application Support/FastDownloader/yt-dlp
   ```

4. **Remove the quarantine flag** *(optional, but recommended if macOS blocks it)*

   ```bash
   xattr -d com.apple.quarantine ~/Library/Application Support/FastDownloader/yt-dlp
   ```

After these steps, restart FastDownloader and try downloading again.

</details>


## License

FastDownloader is licensed under the PolyForm Noncommercial License 1.0.0.

See [LICENSE](LICENSE) for the full license terms.

## Disclaimer

FastDownloader is intended for downloading content that you have
permission to download or that is otherwise permitted by the applicable
platform's terms and applicable law.

FastDownloader is not affiliated with or endorsed by YouTube or Instagram.
