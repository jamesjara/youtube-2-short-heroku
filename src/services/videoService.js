const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000';

export async function processVideo(videoData) {
  const response = await fetch(`${API_URL}/api/videos`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(videoData)
  });

  if (!response.ok) {
    throw new Error('Failed to process video');
  }

  return response.json();
}