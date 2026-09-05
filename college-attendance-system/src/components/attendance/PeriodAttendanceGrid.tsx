import React, { useState, useEffect, useRef } from 'react';
import { 
  CheckCircle2, 
  XCircle, 
  Clock, 
  Save, 
  Sparkles, 
  ShieldCheck, 
  AlertTriangle,
  UserCheck,
  Calendar,
  Lock,
  Search,
  Check,
  Keyboard,
  Fingerprint,
  RotateCcw,
  Zap
} from 'lucide-react';
import { useAttendance } from '../../context/AttendanceContext';
import { AttendanceStatus } from '../../types';
import { periodTimeSlots } from '../../data/mockData';

export const PeriodAttendanceGrid: React.FC = () => {
  const { 
    batches, 
    students, 
    selectedBatchCode, 
    setSelectedBatchCode,
    selectedPeriodForMarking,
    setSelectedPeriodForMarking,
    selectedDateForMarking,
    setSelectedDateForMarking,
    savePeriodAttendance,
    complianceList,
    showToast
  } = useAttendance();

  const [studentSearch, setStudentSearch] = useState('');
  const [markingMode, setMarkingMode] = useState<'grid' | 'keyboard' | 'biometric'>('grid');
  const [activeRollIndex, setActiveRollIndex] = useState(0);
  const [isBiometricSyncing, setIsBiometricSyncing] = useState(false);

  const batchStudents = students.filter(s => s.batchCode === selectedBatchCode);

  // Filtered by search within batch
  const displayedStudents = studentSearch.trim()
    ? batchStudents.filter(s => 
        s.name.toLowerCase().includes(studentSearch.toLowerCase()) || 
        s.rollNo.includes(studentSearch) ||
        s.regNo.includes(studentSearch)
      )
    : batchStudents;

  // Local state for fast marking
  const [statuses, setStatuses] = useState<Record<string, AttendanceStatus>>({});

  // Synchronize statuses when batch, date, or period changes
  useEffect(() => {
    const initial: Record<string, AttendanceStatus> = {};
    batchStudents.forEach(s => {
      const dateRecord = s.recentAttendance[selectedDateForMarking];
      if (dateRecord && dateRecord[selectedPeriodForMarking - 1]) {
        initial[s.id] = dateRecord[selectedPeriodForMarking - 1];
      } else {
        initial[s.id] = 'present';
      }
    });
    setStatuses(initial);
    setActiveRollIndex(0);
  }, [selectedBatchCode, selectedPeriodForMarking, selectedDateForMarking, students]);

  // Check if this period for this batch is already submitted
  const currentCompliance = complianceList.find(
    c => c.batchCode === selectedBatchCode && c.periodNumber === selectedPeriodForMarking
  );
  const isAlreadySubmitted = currentCompliance?.isSubmitted ?? false;

  const handleMarkAllPresent = () => {
    const updated: Record<string, AttendanceStatus> = {};
    batchStudents.forEach(s => {
      const current = statuses[s.id];
      if (current === 'leave_prior_cl' || current === 'leave_od' || current === 'leave_ml') {
        updated[s.id] = current;
      } else {
        updated[s.id] = 'present';
      }
    });
    setStatuses(updated);
  };

  const toggleStudentStatus = (studentId: string) => {
    const current = statuses[studentId] || 'present';
    if (current === 'leave_prior_cl' || current === 'leave_od' || current === 'leave_ml') {
      return; // Locked: Approved Prior Leave
    }
    const next: AttendanceStatus = current === 'present' ? 'absent_uninformed' : 'present';
    setStatuses(prev => ({ ...prev, [studentId]: next }));
  };

  const handleSave = () => {
    savePeriodAttendance(selectedBatchCode, selectedPeriodForMarking, selectedDateForMarking, statuses);
  };

  // Keyboard navigation handler for rapid roll call
  const handleKeyboardMark = (status: AttendanceStatus) => {
    if (activeRollIndex >= displayedStudents.length) return;
    const currentStudent = displayedStudents[activeRollIndex];
    if (!currentStudent) return;

    // Don't overwrite locked leave unless explicitly done
    const current = statuses[currentStudent.id];
    if (current !== 'leave_prior_cl' && current !== 'leave_od' && current !== 'leave_ml') {
      setStatuses(prev => ({ ...prev, [currentStudent.id]: status }));
    }

    if (activeRollIndex < displayedStudents.length - 1) {
      setActiveRollIndex(prev => prev + 1);
    } else {
      showToast('Completed rapid keyboard roll call for all students in section!');
    }
  };

  // Biometric Turnstile Sync simulation
  const handleSimulateBiometricSync = () => {
    setIsBiometricSyncing(true);
    setTimeout(() => {
      const updated: Record<string, AttendanceStatus> = {};
      batchStudents.forEach((s, idx) => {
        const current = statuses[s.id];
        if (current === 'leave_prior_cl' || current === 'leave_od' || current === 'leave_ml') {
          updated[s.id] = current;
        } else if (idx % 18 === 0 || s.attendancePercentage < 72) {
          // Absent
          updated[s.id] = 'absent_uninformed';
        } else {
          updated[s.id] = 'present';
        }
      });
      setStatuses(updated);
      setIsBiometricSyncing(false);
      showToast(`Biometric Turnstile Synced for ${batchStudents.length} students!`);
    }, 800);
  };

  const currentSlot = periodTimeSlots.find(p => p.periodNumber === selectedPeriodForMarking) || periodTimeSlots[0];
  const presentCount = Object.values(statuses).filter(st => st === 'present' || st === 'leave_od').length;
  const absentCount = Object.values(statuses).filter(st => st === 'absent_uninformed').length;
  const leaveCount = Object.values(statuses).filter(st => st === 'leave_prior_cl' || st === 'leave_ml').length;

  return (
    <div className="space-y-6">
      {/* Controls Header */}
      <div className="p-5 rounded-3xl glass-panel border-slate-800 space-y-4">
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-2">
              <span className="px-2.5 py-0.5 rounded-full text-[10px] font-extrabold uppercase bg-academic-950 text-academic-300 border border-academic-700/80">
                AIDS Fast Marker 3.0
              </span>
              <h2 className="text-base font-bold text-white tracking-tight">
                Subject Attendance Matrix & Multi-Mode Input
              </h2>
            </div>
            <p className="text-xs text-slate-400 mt-0.5">
              1-Click Bulk Mark, Keyboard Rapid Roll Call, and Real-time Auto-Locking.
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            {/* Batch Selector */}
            <select
              value={selectedBatchCode}
              onChange={(e) => setSelectedBatchCode(e.target.value)}
              className="px-3.5 py-2 text-xs font-bold rounded-xl bg-[#121828] border border-slate-700 text-white focus:outline-none focus:border-academic-500"
            >
              {batches.map(b => (
                <option key={b.id} value={b.batchCode}>
                  {b.yearName} - Sec {b.section} ({b.batchCode}) · {b.totalStudents} Students
                </option>
              ))}
            </select>

            {/* Date Picker */}
            <input
              type="date"
              value={selectedDateForMarking}
              onChange={(e) => setSelectedDateForMarking(e.target.value)}
              className="px-3 py-1.5 text-xs font-bold rounded-xl bg-[#121828] border border-slate-700 text-white focus:outline-none"
            />

            {/* Save Attendance */}
            <button
              onClick={handleSave}
              className="px-4 py-2 text-xs font-bold rounded-xl bg-academic-600 hover:bg-academic-500 text-white shadow-glow-indigo transition-all hover:scale-[1.02] flex items-center gap-1.5"
            >
              <Save className="w-4 h-4" />
              <span>Save & Verify Period</span>
            </button>
          </div>
        </div>

        {/* Mode Selector & Quick Tools */}
        <div className="flex flex-wrap items-center justify-between gap-3 pt-2 border-t border-slate-800/80">
          <div className="flex items-center gap-2">
            <button
              onClick={() => setMarkingMode('grid')}
              className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-all flex items-center gap-1.5 ${
                markingMode === 'grid' ? 'bg-academic-600 text-white' : 'bg-[#121828] text-slate-400 hover:text-white'
              }`}
            >
              <span>1-Click Grid</span>
            </button>

            <button
              onClick={() => setMarkingMode('keyboard')}
              className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-all flex items-center gap-1.5 ${
                markingMode === 'keyboard' ? 'bg-indigo-600 text-white' : 'bg-[#121828] text-slate-400 hover:text-white'
              }`}
            >
              <Keyboard className="w-3.5 h-3.5" />
              <span>Rapid Keyboard Mode</span>
            </button>

            <button
              onClick={() => setMarkingMode('biometric')}
              className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-all flex items-center gap-1.5 ${
                markingMode === 'biometric' ? 'bg-cyan-600 text-white' : 'bg-[#121828] text-slate-400 hover:text-white'
              }`}
            >
              <Fingerprint className="w-3.5 h-3.5" />
              <span>Biometric Turnstile Sync</span>
            </button>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={handleMarkAllPresent}
              className="px-3.5 py-1.5 text-xs font-bold rounded-xl bg-[#121828] hover:bg-slate-800 border border-slate-700 text-emerald-400 hover:text-emerald-300 transition-all flex items-center gap-1.5"
            >
              <CheckCircle2 className="w-3.5 h-3.5" />
              <span>Mark All Present</span>
            </button>
          </div>
        </div>

        {/* 8 Periods Selector Ribbon */}
        <div className="flex gap-2 overflow-x-auto pb-1 pt-2 border-t border-slate-800/80">
          {periodTimeSlots.map(slot => (
            <button
              key={slot.periodNumber}
              onClick={() => setSelectedPeriodForMarking(slot.periodNumber)}
              className={`flex-1 min-w-[120px] p-2.5 rounded-2xl text-xs font-bold border transition-all text-center ${
                selectedPeriodForMarking === slot.periodNumber
                  ? 'bg-academic-600 text-white border-academic-400 shadow-glow-indigo'
                  : 'bg-[#121828] border-slate-800 text-slate-400 hover:text-white hover:border-slate-700'
              }`}
            >
              <div className="text-[11px] block">Period {slot.periodNumber}</div>
              <div className="text-[9px] opacity-80 font-normal mt-0.5">{slot.timeRange}</div>
            </button>
          ))}
        </div>
      </div>

      {/* Mode 2: Rapid Keyboard Roll Call Bar */}
      {markingMode === 'keyboard' && (
        <div className="p-4 rounded-2xl bg-indigo-950/30 border border-indigo-700/60 flex flex-col md:flex-row md:items-center justify-between gap-4 animate-in slide-in-from-top-2">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-indigo-600 text-white flex items-center justify-center font-bold">
              {activeRollIndex + 1}/{displayedStudents.length}
            </div>
            <div>
              <span className="text-[10px] uppercase font-bold text-indigo-300">Active Student on Deck:</span>
              <h4 className="text-sm font-bold text-white">
                {displayedStudents[activeRollIndex]?.name} ({displayedStudents[activeRollIndex]?.rollNo})
              </h4>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={() => handleKeyboardMark('present')}
              className="px-4 py-2 text-xs font-bold rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white shadow-sm flex items-center gap-1.5"
            >
              <span>[P] Mark Present</span>
            </button>
            <button
              onClick={() => handleKeyboardMark('absent_uninformed')}
              className="px-4 py-2 text-xs font-bold rounded-xl bg-rose-600 hover:bg-rose-500 text-white shadow-sm flex items-center gap-1.5"
            >
              <span>[A] Mark Absent</span>
            </button>
            <button
              onClick={() => setActiveRollIndex(prev => Math.min(displayedStudents.length - 1, prev + 1))}
              className="px-3 py-2 text-xs font-semibold rounded-xl bg-[#121828] text-slate-400 hover:text-white"
            >
              Skip →
            </button>
            <button
              onClick={() => setActiveRollIndex(0)}
              className="p-2 rounded-xl bg-[#121828] text-slate-400 hover:text-white"
              title="Reset Roll Deck"
            >
              <RotateCcw className="w-4 h-4" />
            </button>
          </div>
        </div>
      )}

      {/* Mode 3: Biometric Sync Panel */}
      {markingMode === 'biometric' && (
        <div className="p-4 rounded-2xl bg-cyan-950/30 border border-cyan-700/60 flex flex-col md:flex-row md:items-center justify-between gap-4 animate-in slide-in-from-top-2">
          <div className="flex items-center gap-3">
            <Fingerprint className="w-8 h-8 text-cyan-400 animate-pulse" />
            <div>
              <h4 className="text-xs font-bold text-white">Biometric Turnstile & Face Punch Simulator</h4>
              <p className="text-[11px] text-slate-400">
                Simulate gate telemetry import for all {batchStudents.length} students in {selectedBatchCode}.
              </p>
            </div>
          </div>

          <button
            onClick={handleSimulateBiometricSync}
            disabled={isBiometricSyncing}
            className="px-5 py-2.5 text-xs font-bold rounded-xl bg-cyan-600 hover:bg-cyan-500 text-white shadow-glow-indigo transition-all flex items-center gap-2"
          >
            <Zap className="w-4 h-4" />
            <span>{isBiometricSyncing ? 'Synchronizing Gates...' : 'Sync All Gate Punches'}</span>
          </button>
        </div>
      )}

      {/* Live Status Bar & Search Filter */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 px-2 text-xs font-bold">
        <div className="flex items-center gap-3">
          <span className="text-slate-300">
            {selectedBatchCode} · Period {selectedPeriodForMarking} ({currentSlot.timeRange})
          </span>
          {isAlreadySubmitted ? (
            <span className="text-[10px] px-2 py-0.5 rounded-full bg-emerald-950 text-emerald-300 border border-emerald-800 flex items-center gap-1">
              <Check className="w-3 h-3" /> Verified Entry
            </span>
          ) : (
            <span className="text-[10px] px-2 py-0.5 rounded-full bg-amber-950 text-amber-300 border border-amber-800">
              ⏳ Pending Entry
            </span>
          )}
        </div>

        <div className="flex items-center gap-4">
          <div className="relative">
            <Search className="w-3.5 h-3.5 text-slate-400 absolute left-2.5 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="Search student or roll no..."
              value={studentSearch}
              onChange={(e) => setStudentSearch(e.target.value)}
              className="pl-8 pr-3 py-1 text-xs rounded-xl bg-[#121828] border border-slate-700 text-white focus:outline-none w-48"
            />
          </div>

          <div className="flex items-center gap-3">
            <span className="text-emerald-400">{presentCount} Present</span>
            <span className="text-rose-400">{absentCount} Cuts</span>
            {leaveCount > 0 && <span className="text-cyan-400">{leaveCount} Leaves</span>}
          </div>
        </div>
      </div>

      {/* Students 8-Period Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3.5">
        {displayedStudents.map((student, idx) => {
          const status = statuses[student.id] || 'present';
          const isPriorCL = status === 'leave_prior_cl';
          const isOD = status === 'leave_od';
          const isML = status === 'leave_ml';
          const isUninformed = status === 'absent_uninformed';
          const isPresent = status === 'present';

          const isLocked = isPriorCL || isOD || isML;
          const isDeckActive = markingMode === 'keyboard' && idx === activeRollIndex;

          return (
            <div
              key={student.id}
              onClick={() => {
                if (markingMode === 'keyboard') {
                  setActiveRollIndex(idx);
                } else {
                  toggleStudentStatus(student.id);
                }
              }}
              className={`p-4 rounded-2xl border transition-all cursor-pointer select-none relative ${
                isDeckActive
                  ? 'ring-2 ring-indigo-400 border-indigo-400 bg-indigo-950/40 shadow-glow-indigo'
                  : isPresent
                  ? 'bg-[#121828]/80 border-slate-800 hover:border-emerald-500/50'
                  : isUninformed
                  ? 'bg-rose-950/40 border-rose-600 shadow-glow-rose'
                  : 'bg-indigo-950/40 border-indigo-500'
              }`}
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <img src={student.avatar} alt={student.name} className="w-10 h-10 rounded-full object-cover ring-2 ring-slate-700" />
                  <div>
                    <h4 className="text-xs font-bold text-white leading-tight">{student.name}</h4>
                    <span className="text-[10px] font-mono text-slate-400">{student.rollNo}</span>
                  </div>
                </div>

                <div>
                  {isPresent && (
                    <span className="text-[11px] font-bold px-2.5 py-1 rounded-full bg-emerald-950 text-emerald-300 border border-emerald-800 flex items-center gap-1">
                      <CheckCircle2 className="w-3.5 h-3.5 text-emerald-400" />
                      Present
                    </span>
                  )}
                  {isUninformed && (
                    <span className="text-[11px] font-bold px-2.5 py-1 rounded-full bg-rose-950 text-rose-300 border border-rose-700 flex items-center gap-1">
                      <XCircle className="w-3.5 h-3.5 text-rose-400" />
                      Uninformed
                    </span>
                  )}
                  {isOD && (
                    <span className="text-[10px] font-extrabold px-2 py-0.5 rounded-full bg-indigo-950 text-cyan-300 border border-cyan-700 flex items-center gap-1">
                      <Lock className="w-3 h-3" />
                      Approved OD
                    </span>
                  )}
                  {isPriorCL && (
                    <span className="text-[10px] font-extrabold px-2 py-0.5 rounded-full bg-blue-950 text-blue-300 border border-blue-700 flex items-center gap-1">
                      <Lock className="w-3 h-3" />
                      Approved CL
                    </span>
                  )}
                  {isML && (
                    <span className="text-[10px] font-extrabold px-2 py-0.5 rounded-full bg-purple-950 text-purple-300 border border-purple-700 flex items-center gap-1">
                      <Lock className="w-3 h-3" />
                      Medical ML
                    </span>
                  )}
                </div>
              </div>

              {/* Student Cumulative Attendance Meter */}
              <div className="mt-3 pt-2 border-t border-slate-800/80 flex items-center justify-between text-[10px] text-slate-400">
                <span>Cumulative: <strong className={student.attendancePercentage < 75 ? 'text-rose-400' : 'text-emerald-400'}>{student.attendancePercentage}%</strong></span>
                <span>{isLocked ? '🔒 Pre-Locked (Prior Leave)' : 'Tap to toggle status'}</span>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
