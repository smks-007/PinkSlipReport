import React, { useState } from 'react';
import { Header } from './components/layout/Header';
import { Sidebar } from './components/layout/Sidebar';
import { HODCockpit } from './components/hod/HODCockpit';
import { PeriodAttendanceGrid } from './components/attendance/PeriodAttendanceGrid';
import { LeaveTriageCenter } from './components/leave/LeaveTriageCenter';
import { StudentDossier } from './components/student/StudentDossier';
import { CloudAndNAACView } from './components/cloud/CloudAndNAACView';
import { JarvisAiAdvisor } from './components/ai/JarvisAiAdvisor';
import { ExportImportModal } from './components/export/ExportImportModal';
import { useAttendance } from './context/AttendanceContext';
import { useTheme } from './context/ThemeContext';

export const App: React.FC = () => {
  const { activeTab, toastMessage } = useAttendance();
  const { theme } = useTheme();

  const [isJarvisOpen, setIsJarvisOpen] = useState(false);
  const [isExportModalOpen, setIsExportModalOpen] = useState(false);

  return (
    <div className={`flex h-screen w-screen overflow-hidden ${
      theme === 'dark' ? 'ambient-bg text-slate-100' : 'ambient-bg-light text-slate-900'
    }`}>
      {/* Toast Notification */}
      {toastMessage && (
        <div className="fixed bottom-6 right-6 z-50 bg-academic-600 text-white px-5 py-3 rounded-2xl shadow-glow-indigo font-bold text-xs animate-in slide-in-from-bottom-5">
          {toastMessage}
        </div>
      )}

      {/* Sidebar */}
      <Sidebar
        onOpenJarvis={() => setIsJarvisOpen(true)}
        onOpenExport={() => setIsExportModalOpen(true)}
      />

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col h-screen overflow-hidden">
        <Header
          onOpenJarvis={() => setIsJarvisOpen(true)}
          onOpenExport={() => setIsExportModalOpen(true)}
        />

        <main className="flex-1 overflow-y-auto p-6 space-y-6">
          {activeTab === 'hod_cockpit' && <HODCockpit />}
          {activeTab === 'period_marker' && <PeriodAttendanceGrid />}
          {activeTab === 'leave_triage' && <LeaveTriageCenter />}
          {activeTab === 'student_dossier' && <StudentDossier />}
          {activeTab === 'cloud_naac' && <CloudAndNAACView />}
        </main>
      </div>

      {/* Jarvis AI Copilot Modal */}
      <JarvisAiAdvisor
        isOpen={isJarvisOpen}
        onClose={() => setIsJarvisOpen(false)}
      />

      {/* Export / CSV Import & Broadcast Center Modal */}
      <ExportImportModal
        isOpen={isExportModalOpen}
        onClose={() => setIsExportModalOpen(false)}
      />
    </div>
  );
};

export default App;
