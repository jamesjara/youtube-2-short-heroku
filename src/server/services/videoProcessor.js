import ffmpeg from 'fluent-ffmpeg';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import { downloadVideo } from './videoDownloader.js';
import { PLATFORM_SETTINGS } from '../config/settings.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const TEMP_DIR = path.join(__dirname, '../../../temp');

// Ensure temp directory exists
if (!fs.existsSync(TEMP_DIR)) {
  fs.mkdirSync(TEMP_DIR, { recursive: true });
}

export async function processVideo(videoData) {
  const videoId = Date.now().toString();
  const tempFilePath = path.join(TEMP_DIR, `${videoId}_temp.mp4`);
  const outputFilePath = path.join(TEMP_DIR, `${videoId}_processed.mp4`);

  try {
    // Download video
    await downloadVideo(videoData.youtube_url, tempFilePath);

    // Process video
    await processVideoFile(
      tempFilePath,
      outputFilePath,
      videoData.start_time,
      videoData.duration,
      PLATFORM_SETTINGS[videoData.platform]
    );

    // Return the processed video path
    return outputFilePath;
  } catch (error) {
    // Cleanup on error
    if (fs.existsSync(tempFilePath)) fs.unlinkSync(tempFilePath);
    if (fs.existsSync(outputFilePath)) fs.unlinkSync(outputFilePath);
    throw error;
  }
}

async function processVideoFile(inputPath, outputPath, startTime, duration, settings) {
  return new Promise((resolve, reject) => {
    ffmpeg(inputPath)
      .setStartTime(startTime)
      .duration(duration)
      .size(`${settings.width}x${settings.height}`)
      .videoBitrate(settings.videoBitrate)
      .audioBitrate(settings.audioBitrate)
      .autopad(true, 'black')
      .format(settings.format)
      .on('end', () => {
        fs.unlinkSync(inputPath); // Clean up input file
        resolve(outputPath);
      })
      .on('error', (err) => {
        fs.unlinkSync(inputPath); // Clean up input file
        reject(err);
      })
      .save(outputPath);
  });
}