import React from 'react';

export default function DownloadModal({ isOpen, onClose, videoUrl }) {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-6 max-w-md w-full mx-4">
        <h2 className="text-xl font-bold mb-4">Your Video is Ready!</h2>
        <p className="text-gray-600 mb-4">
          Your video has been processed successfully. Click the button below to download.
        </p>
        <div className="flex flex-col gap-4">
          <a
            href={videoUrl}
            download
            className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 text-center"
          >
            Download Video
          </a>
          <button
            onClick={onClose}
            className="w-full border border-gray-300 py-2 px-4 rounded-md hover:bg-gray-50"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  );
}