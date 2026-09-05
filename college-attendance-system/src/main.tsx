import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import { ThemeProvider } from './context/ThemeContext';
import { AttendanceProvider } from './context/AttendanceContext';
import './index.css';

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <ThemeProvider>
      <AttendanceProvider>
        <App />
      </AttendanceProvider>
    </ThemeProvider>
  </React.StrictMode>
);
