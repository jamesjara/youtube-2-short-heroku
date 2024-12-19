import express from 'express';
import cors from 'cors';
import { processVideo } from './services/videoProcessor.js';
import path from 'path';
import { corsOptions } from './config/cors.js';

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors(corsOptions));
app.use(express.json());

// Serve processed videos statically
app.use('/videos', express.static('temp'));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Process video endpoint
app.post('/api/videos', async (req, res) => {
  try {
    const { youtube_url, start_time, duration, platform } = req.body;
    const outputPath = await processVideo({
      youtube_url,
      start_time,
      duration,
      platform
    });
    
    // Return the URL to access the processed video
    const videoUrl = `/videos/${path.basename(outputPath)}`;
    res.json({ url: videoUrl });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: 'Failed to process video' });
  }
});