import React, { useState } from 'react';
import VideoForm from './components/VideoForm';
import ProcessingStatus from './components/ProcessingStatus';
import DownloadModal from './components/DownloadModal';
import Auth from './components/Auth';
import { getVideoById } from './services/videoService';
import { useSupabaseAuth } from './hooks/useSupabaseAuth';

export default function App() {
  const [isProcessing, setIsProcessing] = useState(false);
  const [progress, setProgress] = useState(0);
  const [showDownloadModal, setShowDownloadModal] = useState(false);
  const [processedVideoUrl, setProcessedVideoUrl] = useState('');
  const { user, loading } = useSupabaseAuth();

  const pollVideoStatus = async (videoId) => {
    try {
      const video = await getVideoById(videoId);
      if (video.status === 'completed' && video.output_url) {
        setProcessedVideoUrl(video.output_url);
        setShowDownloadModal(true);
        setIsProcessing(false);
        setProgress(0);
      } else if (video.status === 'failed') {
        throw new Error('Video processing failed');
      } else {
        setProgress((prev) => Math.min(prev + 10, 90));
        setTimeout(() => pollVideoStatus(videoId), 5000);
      }
    } catch (error) {
      console.error('Error polling video status:', error);
      setIsProcessing(false);
      setProgress(0);
    }
  };

  if (loading) {
    return <div>Loading...</div>;
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-4xl mx-auto py-12 px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold text-gray-900 mb-4">
            YouTube Shorts Generator
          </h1>
          <p className="text-lg text-gray-600">
            Create short-form videos for TikTok, Instagram Reels, and YouTube Shorts
          </p>
        </div>

        {!user ? (
          <Auth />
        ) : isProcessing ? (
          <ProcessingStatus progress={progress} />
        ) : (
          <VideoForm 
            onSubmit={async (video) => {
              setIsProcessing(true);
              setProgress(10);
              pollVideoStatus(video.id);
            }}
          />
        )}

        <DownloadModal
          isOpen={showDownloadModal}
          onClose={() => setShowDownloadModal(false)}
          videoUrl={processedVideoUrl}
        />
      </div>
    </div>
  );
}