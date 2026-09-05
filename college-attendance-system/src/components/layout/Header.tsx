import React from 'react';
import { 
  GraduationCap, 
  ShieldCheck, 
  Sun, 
  Moon, 
  Bell, 
  Clock, 
  Zap, 
  ChevronDown, 
  BrainCircuit,
  FileSpreadsheet,
  Sparkles,
  Download
} from 'lucide-react';
import { useAttendance } from '../../context/AttendanceContext';
import { useTheme } from '../../context/ThemeContext';
import { UserRole } from '../../types';

interface HeaderProps {
  onOpenJarvis?: () => void;
  onOpenExport?: () => void;
}

export const Header: React.FC<HeaderProps> = ({ onOpenJarvis, onOpenExport }) => {
  const { 
    currentUser, 
    currentUserRole, 
    setCurrentUserRole, 
    pendingLeaves,
    triggerReconciliation430PM,
    isReconciliationTriggered,
    setIsNAACModalOpen
  } = useAttendance();
  const { theme, toggleTheme } = useTheme();

  return (
    <header className="h-20 px-6 border-b border-slate-800/80 bg-[#0c101c]/80 backdrop-blur-2xl flex items-center justify-between sticky top-0 z-30 select-none">
      {/* Brand & Department Badge */}
      <div className="flex items-center gap-3.5">
        <div className="w-11 h-11 rounded-2xl bg-gradient-to-tr from-academic-600 via-indigo-600 to-cyan-500 flex items-center justify-center text-white shadow-glow-indigo">
          <BrainCircuit className="w-6 h-6" />
        </div>
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-base font-black tracking-tight text-white flex items-center gap-1.5">
              SmartCampus <span className="text-transparent bg-clip-text bg-gradient-to-r from-academic-400 to-cyan-400">AI</span>
            </h1>
            <span className="px-2 py-0.5 rounded-full text-[10px] font-extrabold uppercase bg-academic-950 text-academic-300 border border-academic-700/60">
              AIDS Dept
            </span>
          </div>
          <p className="text-[11px] text-slate-400 font-medium">
            Artificial Intelligence & Data Science · II, III & IV Year Attendance
          </p>
        </div>
      </div>

      {/* Middle: Jarvis AI, 4:30 PM Reconciler, CSV Export, NAAC */}
      <div className="hidden lg:flex items-center gap-2.5">
        {onOpenJarvis && (
          <button
            onClick={onOpenJarvis}
            className="px-3.5 py-2 rounded-xl bg-cyan-950/80 hover:bg-cyan-900/80 border border-cyan-700/70 text-cyan-300 text-xs font-bold flex items-center gap-1.5 shadow-sm transition-all hover:scale-[1.02]"
          >
            <Sparkles className="w-3.5 h-3.5 text-cyan-400" />
            <span>Jarvis AI Copilot</span>
          </button>
        )}

        {onOpenExport && (
          <button
            onClick={onOpenExport}
            className="px-3.5 py-2 rounded-xl bg-slate-900/80 hover:bg-slate-800/90 border border-slate-700 text-slate-200 text-xs font-bold flex items-center gap-1.5 transition-all"
          >
            <Download className="w-3.5 h-3.5 text-academic-400" />
            <span>CSV / Broadcast</span>
          </button>
        )}

        <button
          onClick={triggerReconciliation430PM}
          className={`px-3.5 py-2 rounded-xl text-xs font-bold flex items-center gap-2 border transition-all ${
            isReconciliationTriggered
              ? 'bg-emerald-950/80 border-emerald-700/80 text-emerald-300'
              : 'bg-slate-900/80 hover:bg-slate-800/90 border-slate-700 text-slate-200 hover:border-academic-500'
          }`}
        >
          <Zap className={`w-3.5 h-3.5 ${isReconciliationTriggered ? 'text-emerald-400' : 'text-amber-400'}`} />
          <span>{isReconciliationTriggered ? '4:30 PM Reconciled' : '4:30 PM Auto-Reconciliation'}</span>
        </button>

        <button
          onClick={() => setIsNAACModalOpen(true)}
          className="px-3.5 py-2 rounded-xl bg-academic-600 hover:bg-academic-500 text-white text-xs font-bold flex items-center gap-2 shadow-glow-indigo transition-all hover:scale-[1.02]"
        >
          <FileSpreadsheet className="w-3.5 h-3.5" />
          <span>NAAC / NBA Export</span>
        </button>
      </div>

      {/* Right: Role Switcher & User Profile */}
      <div className="flex items-center gap-3">
        {/* Dynamic Role Switcher Dropdown */}
        <div className="flex items-center gap-2 bg-[#121828] border border-slate-700/80 rounded-xl px-3 py-1.5">
          <ShieldCheck className="w-4 h-4 text-academic-400" />
          <span className="text-[11px] text-slate-400 font-bold uppercase hidden sm:inline">Role:</span>
          <select
            value={currentUserRole}
            onChange={(e) => setCurrentUserRole(e.target.value as UserRole)}
            className="bg-transparent text-xs font-bold text-white focus:outline-none cursor-pointer"
          >
            <option value="hod1" className="bg-slate-900">Dr. K. Arulraj (HOD 1 - Admin)</option>
            <option value="hod2" className="bg-slate-900">Dr. S. Meenakshi (HOD 2 - Academics)</option>
            <option value="advisor_2a" className="bg-slate-900">Dr. N. Balamurugan (II AIDS A Advisor)</option>
            <option value="advisor_2b" className="bg-slate-900">Prof. P. Kavitha (II AIDS B Advisor)</option>
            <option value="advisor_3a" className="bg-slate-900">Prof. R. Venkatesh (III AIDS A Advisor)</option>
            <option value="advisor_3b" className="bg-slate-900">Dr. T. Sundaram (III AIDS B Advisor)</option>
            <option value="advisor_4a" className="bg-slate-900">Dr. M. Anitha (IV AIDS A Advisor)</option>
            <option value="advisor_4b" className="bg-slate-900">Dr. S. Karthikeyan (IV AIDS B Advisor)</option>
            <option value="faculty" className="bg-slate-900">Dr. N. Balamurugan (ML Faculty)</option>
            <option value="student" className="bg-slate-900">ABINAYA G (Student 25243001)</option>
          </select>
        </div>

        {/* Theme Toggle */}
        <button
          onClick={toggleTheme}
          aria-label="Toggle Theme"
          className="p-2 rounded-xl bg-[#121828] border border-slate-700/80 text-slate-300 hover:text-white transition-colors"
        >
          {theme === 'dark' ? <Sun className="w-4 h-4 text-amber-400" /> : <Moon className="w-4 h-4 text-academic-400" />}
        </button>

        {/* User Badge */}
        <div className="flex items-center gap-2 pl-2 border-l border-slate-800">
          <img
            src={currentUser.avatar}
            alt={currentUser.name}
            className="w-9 h-9 rounded-full ring-2 ring-academic-500/40 object-cover"
          />
          <div className="hidden xl:block text-left">
            <span className="text-xs font-bold text-white block leading-tight">{currentUser.name}</span>
            <span className="text-[10px] text-academic-300 font-medium">{currentUser.title}</span>
          </div>
        </div>
      </div>
    </header>
  );
};
