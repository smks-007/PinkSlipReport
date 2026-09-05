import React, { useState } from 'react';
import { 
  Users, 
  AlertTriangle, 
  CheckCircle2, 
  Clock, 
  Flame, 
  Calculator, 
  TrendingDown, 
  FileSpreadsheet, 
  ArrowRight,
  Sparkles,
  PhoneCall,
  ShieldAlert,
  ChevronRight,
  BrainCircuit
} from 'lucide-react';
import { useAttendance } from '../../context/AttendanceContext';

export const HODCockpit: React.FC = () => {
  const { 
    batches, 
    students, 
    departmentSummary, 
    complianceList, 
    setSelectedStudentId, 
    setSelectedBatchCode,
    setActiveTab, 
    setIsNAACModalOpen 
  } = useAttendance();

  const [selectedYearFilter, setSelectedYearFilter] = useState<number | 'all'>('all');

  // Shortage students (< 75%)
  const shortageStudents = students.filter(s => s.attendancePercentage < 75);

  const filteredBatches = selectedYearFilter === 'all' 
    ? batches 
    : batches.filter(b => b.yearLevel === selectedYearFilter);

  const handleInspectStudent = (studentId: string) => {
    setSelectedStudentId(studentId);
    setActiveTab('student_dossier');
  };

  const handleInspectBatch = (batchCode: string) => {
    setSelectedBatchCode(batchCode);
    setActiveTab('period_marker');
  };

  return (
    <div className="space-y-6">
      {/* Top Banner: 2 HOD Executive Pulse */}
      <div className="p-6 rounded-3xl glass-panel border-academic-700/40 bg-gradient-to-r from-academic-600/15 via-cyan-600/10 to-transparent relative overflow-hidden">
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-6 relative z-10">
          <div>
            <div className="flex items-center gap-2 mb-2">
              <span className="px-2.5 py-0.5 rounded-full text-[10px] font-extrabold uppercase bg-academic-950 text-academic-300 border border-academic-700/80 flex items-center gap-1.5 shadow-sm">
                <BrainCircuit className="w-3.5 h-3.5 text-cyan-400" />
                Department Executive Cockpit
              </span>
              <span className="text-xs text-slate-400 font-semibold">Active: Period 5 (01:15 - 02:05 PM)</span>
            </div>

            <h2 className="text-xl font-extrabold text-white tracking-tight">
              Department of Artificial Intelligence & Data Science (AIDS) — Live Pulse
            </h2>
            <p className="text-xs text-slate-400 mt-1 max-w-3xl leading-relaxed">
              Monitoring <span className="font-bold text-white">{students.length} students</span> across 2nd, 3rd, and 4th Year sections (II AIDS A-D, III AIDS A-D, IV AIDS A-B). Automated AI classification has verified <span className="font-bold text-amber-400">{departmentSummary.approvedLeavesToday} authorized leaves</span> and flagged <span className="font-bold text-rose-400">{departmentSummary.uninformedAbsenteesToday} uninformed absentees</span>.
            </p>
          </div>

          <div className="flex items-center gap-3">
            <button
              onClick={() => setIsNAACModalOpen(true)}
              className="px-4 py-2.5 rounded-xl bg-academic-600 hover:bg-academic-500 text-white font-bold text-xs flex items-center gap-2 shadow-glow-indigo transition-all hover:scale-[1.02]"
            >
              <FileSpreadsheet className="w-4 h-4" />
              <span>Generate Signed NAAC Register</span>
            </button>
          </div>
        </div>
      </div>

      {/* 4 Stat Metric Counters */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="p-5 rounded-2xl glass-panel glass-panel-hover border-slate-800">
          <div className="flex items-center justify-between mb-2">
            <span className="text-xs font-extrabold text-slate-400 uppercase tracking-wider">AIDS Total Strength</span>
            <div className="w-8 h-8 rounded-xl bg-indigo-500/10 text-indigo-400 flex items-center justify-center">
              <Users className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-black text-white">{students.length} Students</div>
          <div className="flex items-center justify-between mt-2 pt-2 border-t border-slate-800/80 text-[11px]">
            <span className="text-emerald-400 font-bold">{departmentSummary.presentTodayCount} Present Today</span>
            <span className="text-slate-400">{departmentSummary.overallAttendancePercentage}% Avg</span>
          </div>
        </div>

        <div className="p-5 rounded-2xl glass-panel glass-panel-hover border-rose-900/40 bg-rose-950/10 shadow-glow-rose">
          <div className="flex items-center justify-between mb-2">
            <span className="text-xs font-extrabold text-rose-400 uppercase tracking-wider">Uninformed Cuts</span>
            <div className="w-8 h-8 rounded-xl bg-rose-500/20 text-rose-400 flex items-center justify-center">
              <ShieldAlert className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-black text-rose-400">{departmentSummary.uninformedAbsenteesToday} Absentees</div>
          <div className="flex items-center justify-between mt-2 pt-2 border-t border-rose-900/40 text-[11px]">
            <span className="text-rose-300 font-semibold">Zero prior notice logged</span>
            <span className="text-slate-400">Parent Alert Active</span>
          </div>
        </div>

        <div className="p-5 rounded-2xl glass-panel glass-panel-hover border-slate-800">
          <div className="flex items-center justify-between mb-2">
            <span className="text-xs font-extrabold text-slate-400 uppercase tracking-wider">Approved Prior Leaves</span>
            <div className="w-8 h-8 rounded-xl bg-cyan-500/10 text-cyan-400 flex items-center justify-center">
              <CheckCircle2 className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-black text-white">{departmentSummary.approvedLeavesToday} Approved</div>
          <div className="flex items-center justify-between mt-2 pt-2 border-t border-slate-800/80 text-[11px]">
            <span className="text-cyan-400 font-bold">CL · OD · ML</span>
            <span className="text-slate-400">Verified</span>
          </div>
        </div>

        <div className="p-5 rounded-2xl glass-panel glass-panel-hover border-amber-900/40 bg-amber-950/10 shadow-glow-amber">
          <div className="flex items-center justify-between mb-2">
            <span className="text-xs font-extrabold text-amber-400 uppercase tracking-wider">Detention Risk</span>
            <div className="w-8 h-8 rounded-xl bg-amber-500/20 text-amber-400 flex items-center justify-center">
              <AlertTriangle className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-black text-amber-400">{shortageStudents.length} Students &lt; 75%</div>
          <div className="flex items-center justify-between mt-2 pt-2 border-t border-amber-900/40 text-[11px]">
            <span className="text-amber-300 font-semibold">Counseling Mandatory</span>
            <span className="text-slate-400">Exam Alert</span>
          </div>
        </div>
      </div>

      {/* Cross-Year Batch Cards Grid */}
      <div className="p-6 rounded-3xl glass-panel border-slate-800">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-5">
          <div>
            <h3 className="text-base font-bold text-white tracking-tight">
              AIDS Batch Attendance Health (2nd, 3rd & 4th Year All Sections)
            </h3>
            <p className="text-xs text-slate-400 mt-0.5">
              Live period presence and unapproved cuts per section
            </p>
          </div>

          <div className="flex items-center gap-1.5 p-1 bg-[#121828] rounded-xl text-xs font-bold border border-slate-800">
            {['all', 2, 3, 4].map(y => (
              <button
                key={y}
                onClick={() => setSelectedYearFilter(y as any)}
                className={`px-3 py-1.5 rounded-lg transition-all ${
                  selectedYearFilter === y
                    ? 'bg-academic-600 text-white shadow-sm'
                    : 'text-slate-400 hover:text-white'
                }`}
              >
                {y === 'all' ? 'All Sections' : `${y === 2 ? 'II Year' : y === 3 ? 'III Year' : 'IV Year'}`}
              </button>
            ))}
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {filteredBatches.map(batch => (
            <div
              key={batch.id}
              onClick={() => handleInspectBatch(batch.batchCode)}
              className="p-4 rounded-2xl bg-[#121828]/80 border border-slate-800 hover:border-academic-500/50 transition-all hover:scale-[1.01] cursor-pointer space-y-3"
            >
              <div className="flex items-start justify-between">
                <div>
                  <span className="text-[10px] font-extrabold px-2 py-0.5 rounded bg-slate-800 text-academic-300 border border-slate-700">
                    {batch.yearName} · Sec {batch.section}
                  </span>
                  <h4 className="text-sm font-bold text-white mt-1.5">{batch.batchCode}</h4>
                  <p className="text-[11px] text-slate-400">{batch.advisorName}</p>
                </div>
                <span className={`text-xs font-extrabold px-2.5 py-1 rounded-full ${
                  batch.avgAttendance >= 85
                    ? 'bg-emerald-950 text-emerald-300 border border-emerald-800'
                    : 'bg-amber-950 text-amber-300 border border-amber-800'
                }`}>
                  {batch.avgAttendance}%
                </span>
              </div>

              {/* Progress Bar */}
              <div>
                <div className="flex justify-between text-[10px] font-bold text-slate-400 mb-1">
                  <span>{batch.presentToday} / {batch.totalStudents} Present</span>
                  <span className="text-rose-400 font-bold">{batch.uninformedToday} Cuts</span>
                </div>
                <div className="w-full h-2 rounded-full bg-slate-800 overflow-hidden">
                  <div
                    style={{ width: `${batch.avgAttendance}%` }}
                    className="h-full rounded-full bg-gradient-to-r from-academic-500 to-cyan-400"
                  />
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Critical Shortage (< 75%) & Faculty Compliance */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Left: Shortage Student Radar */}
        <div className="lg:col-span-7 p-6 rounded-3xl glass-panel border-rose-900/50 bg-gradient-to-b from-rose-950/20 to-transparent">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <span className="p-2 rounded-xl bg-rose-500/20 text-rose-400">
                <AlertTriangle className="w-4 h-4" />
              </span>
              <div>
                <h3 className="text-base font-bold text-white tracking-tight">
                  Critical Attendance Shortage Radar (&lt; 75%)
                </h3>
                <p className="text-[11px] text-slate-400">AIDS students facing detention risk for End-Sem exams</p>
              </div>
            </div>
            <span className="text-xs font-mono font-bold text-rose-400 bg-rose-950 px-2 py-0.5 rounded border border-rose-800">
              {shortageStudents.length} Students
            </span>
          </div>

          <div className="space-y-3 max-h-96 overflow-y-auto pr-1">
            {shortageStudents.map(s => {
              const neededClasses = Math.max(0, Math.ceil((0.75 * s.totalConductedPeriods - s.attendedPeriods) / 0.25));

              return (
                <div
                  key={s.id}
                  onClick={() => handleInspectStudent(s.id)}
                  className="p-3.5 rounded-2xl bg-[#121828] border border-rose-900/40 hover:border-rose-500/60 cursor-pointer transition-all hover:scale-[1.01] flex items-center justify-between gap-4"
                >
                  <div className="flex items-center gap-3">
                    <img src={s.avatar} alt={s.name} className="w-10 h-10 rounded-full ring-2 ring-rose-500/40 object-cover" />
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="text-xs font-bold text-white">{s.name}</span>
                        <span className="text-[10px] font-mono px-1.5 py-0.5 rounded bg-slate-800 text-slate-300">{s.rollNo}</span>
                      </div>
                      <p className="text-[11px] text-slate-400">
                        {s.batchCode} · <span className="text-rose-400 font-bold">{s.uninformedAbsencesCount} Uninformed Cuts</span>
                      </p>
                    </div>
                  </div>

                  <div className="text-right">
                    <div className="text-sm font-black text-rose-400">{s.attendancePercentage}%</div>
                    <div className="text-[10px] font-semibold text-amber-300">
                      Needs <span className="underline font-bold">{neededClasses} classes</span> for 75%
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Right: Faculty Period Attendance Compliance Ticker */}
        <div className="lg:col-span-5 p-6 rounded-3xl glass-panel border-slate-800">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <Clock className="w-4 h-4 text-academic-400" />
              <h3 className="text-base font-bold text-white tracking-tight">Faculty Period Compliance Ticker</h3>
            </div>
            <span className="text-[10px] px-2 py-0.5 rounded bg-slate-800 text-slate-300 font-mono">02-09-2026</span>
          </div>

          <div className="space-y-2 max-h-96 overflow-y-auto pr-1">
            {complianceList.slice(0, 20).map((item, idx) => (
              <div
                key={idx}
                className={`p-3 rounded-xl border text-xs flex items-center justify-between ${
                  item.isSubmitted
                    ? 'bg-[#121828]/60 border-slate-800 text-slate-300'
                    : 'bg-amber-950/20 border-amber-800/60 text-amber-300 animate-pulse'
                }`}
              >
                <div>
                  <div className="flex items-center gap-1.5 font-bold text-white">
                    <span className="px-1.5 py-0.2 rounded bg-slate-800 text-cyan-300 text-[10px]">{item.batchCode}</span>
                    <span>P{item.periodNumber}</span>
                    <span className="text-[10px] text-slate-400 font-normal">({item.timeSlot})</span>
                  </div>
                  <div className="text-[11px] text-slate-400">
                    {item.subjectCode} · {item.facultyName}
                  </div>
                </div>

                <div className="text-right">
                  {item.isSubmitted ? (
                    <span className="text-[10px] font-extrabold px-2 py-0.5 rounded bg-emerald-950 text-emerald-300 border border-emerald-800">
                      ✓ Submitted
                    </span>
                  ) : (
                    <span className="text-[10px] font-extrabold px-2 py-0.5 rounded bg-amber-950 text-amber-300 border border-amber-800">
                      ⏳ Pending Entry
                    </span>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};
