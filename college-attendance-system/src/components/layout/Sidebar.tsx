import React from 'react';
import { 
  LayoutDashboard, 
  Grid3X3, 
  FileCheck2, 
  UserCheck, 
  CloudRain, 
  AlertTriangle, 
  CheckCircle2, 
  Users, 
  Layers,
  Sparkles,
  BrainCircuit,
  FileSpreadsheet
} from 'lucide-react';
import { useAttendance, ActiveTab } from '../../context/AttendanceContext';

interface SidebarProps {
  onOpenJarvis?: () => void;
  onOpenExport?: () => void;
}

export const Sidebar: React.FC<SidebarProps> = ({ onOpenJarvis, onOpenExport }) => {
  const { activeTab, setActiveTab, pendingLeaves, departmentSummary, students } = useAttendance();

  const shortageCount = students.filter(s => s.attendancePercentage < 75.0).length;

  const navItems: { id: ActiveTab; label: string; icon: React.FC<any>; badge?: number; badgeColor?: string }[] = [
    { 
      id: 'hod_cockpit', 
      label: '2 HOD Command Cockpit', 
      icon: LayoutDashboard,
      badge: shortageCount,
      badgeColor: 'bg-rose-950 text-rose-300 border-rose-800'
    },
    { 
      id: 'period_marker', 
      label: '8-Period Attendance Grid', 
      icon: Grid3X3 
    },
    { 
      id: 'leave_triage', 
      label: 'Prior Leave vs Uninformed', 
      icon: FileCheck2, 
      badge: pendingLeaves.length,
      badgeColor: 'bg-amber-950 text-amber-300 border-amber-800'
    },
    { 
      id: 'student_dossier', 
      label: 'Student 360° Dossier', 
      icon: UserCheck 
    },
    { 
      id: 'cloud_naac', 
      label: 'Cloud Storage & NAAC Audit', 
      icon: CloudRain 
    },
  ];

  return (
    <aside className="w-64 flex-shrink-0 flex flex-col h-screen border-r border-slate-800/80 bg-[#0a0d16]/95 backdrop-blur-2xl transition-all select-none">
      {/* Years Quick Breakdown */}
      <div className="p-4 border-b border-slate-800/70">
        <div className="flex items-center justify-between mb-2">
          <span className="text-[10px] font-extrabold uppercase tracking-wider text-slate-400">
            AIDS Sections (10)
          </span>
          <span className="text-[10px] font-bold text-cyan-400">{students.length} Students</span>
        </div>
        <div className="grid grid-cols-3 gap-1.5 text-xs">
          <div className="p-2 rounded-xl bg-[#121828] border border-slate-800 text-center">
            <span className="text-[9px] text-slate-400 block font-bold">II Year</span>
            <span className="text-[11px] font-extrabold text-emerald-400">89.2%</span>
          </div>
          <div className="p-2 rounded-xl bg-[#121828] border border-slate-800 text-center">
            <span className="text-[9px] text-slate-400 block font-bold">III Year</span>
            <span className="text-[11px] font-extrabold text-academic-300">85.8%</span>
          </div>
          <div className="p-2 rounded-xl bg-[#121828] border border-slate-800 text-center">
            <span className="text-[9px] text-slate-400 block font-bold">IV Year</span>
            <span className="text-[11px] font-extrabold text-cyan-300">86.4%</span>
          </div>
        </div>
      </div>

      {/* Main Navigation List */}
      <div className="flex-1 px-3 py-4 space-y-1.5 overflow-y-auto">
        <div className="px-3 py-1 text-[10px] font-extrabold uppercase tracking-wider text-slate-500">
          Core Workspaces
        </div>

        {navItems.map(item => {
          const Icon = item.icon;
          const isActive = activeTab === item.id;
          return (
            <button
              key={item.id}
              onClick={() => setActiveTab(item.id)}
              className={`w-full flex items-center justify-between px-3.5 py-3 rounded-2xl text-xs font-bold transition-all group ${
                isActive
                  ? 'bg-gradient-to-r from-academic-600/30 to-indigo-600/10 text-white border border-academic-500/50 shadow-glow-indigo'
                  : 'text-slate-400 hover:bg-[#121828] hover:text-white border border-transparent'
              }`}
            >
              <div className="flex items-center gap-3">
                <Icon className={`w-4 h-4 transition-colors ${isActive ? 'text-academic-400' : 'text-slate-500 group-hover:text-slate-300'}`} />
                <span>{item.label}</span>
              </div>
              {item.badge !== undefined && item.badge > 0 && (
                <span className={`px-2 py-0.5 text-[10px] font-extrabold rounded-full border ${item.badgeColor || 'bg-academic-950 text-academic-300 border-academic-800'}`}>
                  {item.badge}
                </span>
              )}
            </button>
          );
        })}

        {/* Quick Tool Links */}
        <div className="pt-3 px-3 py-1 text-[10px] font-extrabold uppercase tracking-wider text-slate-500">
          Smart AI Tools
        </div>

        {onOpenJarvis && (
          <button
            onClick={onOpenJarvis}
            className="w-full flex items-center gap-3 px-3.5 py-2.5 rounded-2xl text-xs font-bold text-cyan-300 bg-cyan-950/30 border border-cyan-800/60 hover:bg-cyan-900/40 transition-all shadow-sm"
          >
            <Sparkles className="w-4 h-4 text-cyan-400" />
            <span>Jarvis AI Copilot</span>
          </button>
        )}

        {onOpenExport && (
          <button
            onClick={onOpenExport}
            className="w-full flex items-center gap-3 px-3.5 py-2.5 rounded-2xl text-xs font-bold text-academic-300 bg-academic-950/30 border border-academic-800/60 hover:bg-academic-900/40 transition-all shadow-sm"
          >
            <FileSpreadsheet className="w-4 h-4 text-academic-400" />
            <span>CSV Export & Broadcast</span>
          </button>
        )}
      </div>

      {/* Cloud & Accreditation Status Box */}
      <div className="p-4 m-3 rounded-2xl bg-gradient-to-b from-[#131b2e] to-[#0c101c] border border-academic-800/40">
        <div className="flex items-center justify-between mb-2">
          <div className="flex items-center gap-1.5">
            <div className="w-2 h-2 rounded-full bg-emerald-500 animate-ping" />
            <span className="text-xs font-bold text-white">AWS S3 & EventBridge</span>
          </div>
          <span className="text-[10px] font-extrabold px-1.5 py-0.5 rounded bg-emerald-950 text-emerald-300 border border-emerald-800">
            Active
          </span>
        </div>
        <p className="text-[10px] text-slate-400 leading-relaxed">
          Daily 4:30 PM Absent Reconciler & Medical Proof Vault synced.
        </p>
      </div>
    </aside>
  );
};
