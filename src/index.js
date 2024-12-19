import inquirer from 'inquirer';
import { processVideo } from './videoProcessor.js';

async function main() {
  const answers = await inquirer.prompt([
    {
      type: 'input',
      name: 'youtubeUrl',
      message: 'Enter YouTube video URL:',
      validate: (input) => input.includes('youtube.com') || input.includes('youtu.be')
    },
    {
      type: 'number',
      name: 'startTime',
      message: 'Enter start time (in seconds):',
      default: 0
    },
    {
      type: 'number',
      name: 'duration',
      message: 'Enter duration (in seconds):',
      default: 60
    },
    {
      type: 'list',
      name: 'platform',
      message: 'Select target platform:',
      choices: ['TikTok', 'Instagram Reels', 'YouTube Shorts']
    }
  ]);

  try {
    console.log('Processing video...');
    await processVideo(answers);
    console.log('Video processing completed!');
  } catch (error) {
    console.error('Error processing video:', error.message);
  }
}