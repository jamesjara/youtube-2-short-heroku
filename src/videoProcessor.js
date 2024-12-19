import ytdl from 'ytdl-core';
import ffmpeg from 'fluent-ffmpeg';
import { createWriteStream } from 'fs';
import { mkdir } from 'fs/promises';

const PLATFORM_SETTINGS = {
  'TikTok': {
    width: 1080,
    height: 1920,
    format: 'mp4',
    audioBitrate: '128k',
    videoBitrate: '2500k'
  },
  'Instagram Reels': {
    width: 1080,
    height: 1920,
    format: 'mp4',
    audioBitrate: '128k',
    videoBitrate: '2500k'
  },
  'YouTube Shorts': {
    width: 1080,
    height: 1920,
    format: 'mp4',
    audioBitrate: '128k',
    videoBitrate: '2500k'
  }
};

export async function processVideo({ youtubeUrl, startTime, duration, platform }) {
  try {
    await mkdir('output', { recursive: true });
    
    const videoInfo = await ytdl.getInfo(youtubeUrl);
    const videoFormat = ytdl.chooseFormat(videoInfo.formats, { quality: 'highest' });
    
    const settings = PLATFORM_SETTINGS[platform];
    const outputFileName = `output/${videoInfo.videoDetails.videoId}_${platform.toLowerCase()}.${settings.format}`;
    
    const videoStream = ytdl(youtubeUrl, { format: videoFormat });
    
    return new Promise((resolve, reject) => {
      ffmpeg(videoStream)
        .setStartTime(startTime)
        .duration(duration)
        .size(`${settings.width}x${settings.height}`)
        .videoBitrate(settings.videoBitrate)
        .audioBitrate(settings.audioBitrate)
        .autopad(true, 'black')
        .format(settings.format)
        .on('end', () => {
          console.log(`✅ Video saved as: ${outputFileName}`);
          resolve();
        })
        .on('error', (err) => {
          console.error('❌ Error:', err);
          reject(err);
        })
        .save(outputFileName);
    });
  } catch (error) {
    throw new Error(`Failed to process video: ${error.message}`);
  }
}