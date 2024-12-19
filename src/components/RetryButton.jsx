import React, { useState } from 'react';
import { retry } from '../utils/retry';

export default function RetryButton({ onClick, children, maxAttempts = 3 }) {
  const [attempt, setAttempt] = useState(0);
  const [isRetrying, setIsRetrying] = useState(false);

  const handleClick = async () => {
    setIsRetrying(true);
    
    try {
      await retry(
        async (currentAttempt) => {
          setAttempt(currentAttempt);
          await onClick();
        },
        {
          maxAttempts,
          delay: 2000,
          backoff: 2,
          onRetry: (error, attemptNumber) => {
            console.warn(`Attempt ${attemptNumber} failed:`, error.message);
          }
        }
      );
    } catch (error) {
      console.error('All retry attempts failed:', error);
    } finally {
      setIsRetrying(false);
      setAttempt(0);
    }
  };

  return (
    <button
      onClick={handleClick}
      disabled={isRetrying}
      className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
    >
      {isRetrying ? `Retrying... (Attempt ${attempt}/${maxAttempts})` : children}
    </button>
  );
}