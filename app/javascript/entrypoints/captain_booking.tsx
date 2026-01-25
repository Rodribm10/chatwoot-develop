import React from 'react';
import { createRoot } from 'react-dom/client';
import App from '../../../enterprise/app/javascript/captain_booking_app/App';
import '../../../enterprise/app/javascript/captain_booking_app/index.css';

const container = document.getElementById('root');
if (container) {
  const root = createRoot(container);
  root.render(
    <React.StrictMode>
      <App />
    </React.StrictMode>
  );
} else {
  console.error('Root element not found');
}
