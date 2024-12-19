import ytdl from 'ytdl-core';
import fs from 'fs';

export async function downloadVideo(url, outputPath) {
  return new Promise((resolve, reject) => {
    ytdl(url, {
      quality: 'highest',
      filter: 'videoandaudio'
    })
    .pipe(fs.createWriteStream(outputPath))
    .on('finish', resolve)
    .on('error', reject);
  });
}