import React, { useState } from 'react';
import { toast } from 'react-hot-toast';
import { useSupabaseAuth } from '../hooks/useSupabaseAuth';
import { saveVideoMetadata } from '../services/videoService';
import RetryButton from './RetryButton';

export default function VideoForm({ onSubmit }) {
  const { user } = useSupabaseAuth();
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!user) {
      toast.error('Please sign in to generate videos');
      return;
    }

    setLoading(true);

    try {
      const formData = new FormData(e.target);
      const data = {
        youtube_url: formData.get('youtubeUrl'),
        start_time: parseInt(formData.get('startTime')),
        duration: parseInt(formData.get('duration')),
        platform: formData.get('platform'),
        user_id: user.id
      };

      if (!data.youtube_url.includes('youtube.com') && !data.youtube_url.includes('youtu.be')) {
        throw new Error('Please enter a valid YouTube URL');
      }

      const video = await saveVideoMetadata(data);
      onSubmit(video);
    } catch (error) {
      console.error('Error:', error);
      throw error; // Propagate error for retry mechanism
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={(e) => e.preventDefault()} className="bg-white shadow-md rounded-lg p-6 space-y-6">
      <div>
        <label htmlFor="youtubeUrl" className="block text-sm font-medium text-gray-700">
          YouTube URL
        </label>
        <input
          type="url"
          id="youtubeUrl"
          name="youtubeUrl"
          required
          placeholder="https://www.youtube.com/watch?v=..."
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
        />
      </div>

      <div>
        <label htmlFor="startTime" className="block text-sm font-medium text-gray-700">
          Start Time (seconds)
        </label>
        <input
          type="number"
          id="startTime"
          name="startTime"
          min="0"
          required
          defaultValue="0"
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
        />
      </div>

      <div>
        <label htmlFor="duration" className="block text-sm font-medium text-gray-700">
          Duration (seconds)
        </label>
        <input
          type="number"
          id="duration"
          name="duration"
          min="1"
          max="60"
          required
          defaultValue="30"
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
        />
      </div>

      <div>
        <label htmlFor="platform" className="block text-sm font-medium text-gray-700">
          Platform
        </label>
        <select
          id="platform"
          name="platform"
          required
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
        >
          <option value="TikTok">TikTok</option>
          <option value="Instagram Reels">Instagram Reels</option>
          <option value="YouTube Shorts">YouTube Shorts</option>
        </select>
      </div>

      <RetryButton
        onClick={() => handleSubmit(new Event('submit'))}
        maxAttempts={3}
      >
        {loading ? 'Processing...' : 'Generate Video'}
      </RetryButton>
    </form>
  );
}