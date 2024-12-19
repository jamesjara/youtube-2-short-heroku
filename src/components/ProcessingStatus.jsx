import React from 'react';

export default function ProcessingStatus({ progress }) {
  return (
    <div className="bg-white shadow-md rounded-lg p-6">
      <div className="text-center">
        <h3 className="text-lg font-medium text-gray-900 mb-4">Processing Video</h3>
        <div className="relative pt-1">
          <div className="overflow-hidden h-2 mb-4 text-xs flex rounded bg-gray-200">
            <div
              style={{ width: `${progress}%` }}
              className="shadow-none flex flex-col text-center whitespace-nowrap text-white justify-center bg-blue-500 transition-all duration-500"
            />
          </div>
          <div className="text-sm text-gray-600">{progress}% Complete</div>
        </div>
      </div>
    </div>
  );
}