# YouTube Shorts Generator

This application allows you to create short-form videos from YouTube videos, optimized for different social media platforms like TikTok, Instagram Reels, and YouTube Shorts.

## Features

- Download YouTube videos
- Cut videos with specific start time and duration
- Optimize output for different platforms
- Automatic video resizing and padding
- High-quality output

## Usage

1. Start the application:
   ```bash
   npm start
   ```

2. Follow the prompts to:
   - Enter a YouTube URL
   - Specify start time
   - Set duration
   - Choose target platform

3. The processed video will be saved in the `output` folder.

## Supported Platforms

- TikTok (1080x1920)
- Instagram Reels (1080x1920)
- YouTube Shorts (1080x1920)

## Requirements

- Node.js
- FFmpeg (must be installed on your system)