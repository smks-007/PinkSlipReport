import React, { useState } from 'react';
import { 
  Calendar as CalendarIcon, 
  ChevronLeft, 
  ChevronRight, 
  CheckCircle2, 
  Clock, 
  AlertTriangle, 
  ShieldCheck, 
  Save, 
  Send, 
  UserCheck, 
  FileText,
  Filter,
  Check,
  Search,
  Sparkles
} from 'lucide-react';
import { useAttendance } from '../../context/AttendanceContext';
import { AttendanceStatus } from '../../types';

export const MonthlyAttendanceCalendar: React.FC = () => {
  const { 
    batches, 
    students, 
    daySubmissions, 
    workingDates, 
    selectedBatchCode, 
    setSelectedBatchCode,
    saveDayAttendance,
    submitDayAttendanceToHOD,
    verifyDayAttendanceByHOD,
    currentUserRole,
    currentUser,
    showToast
  } = useAttendance();

  const [selectedDate, setSelectedDate] = useState<string>('2026-09-02');
  const [studentSearch, setStudentSearch] = useState<string>('');
  const [activeMonthView, setActiveMonthView] = useState<'2026-08' | '2026-09'>('2026-08');

  const batchStudents = students.filter(s => s.batchCode === selectedBatchCode);

  // Local state for day attendance
  const [dayStatuses, setDayStatuses] = useState<Record<string, AttendanceStatus>>(() => {
    const initial: Record<string, AttendanceStatus> = {};
    batchStudents.forEach(s => {
      const records = s.recentAttendance[selectedDate];
      initial[s.id] = records ? records[0] : 'present';
    });
    return initial;
  });

  // Sync when date or batch changes
  React.useEffect(() => {
    const initial: Record<string, AttendanceStatus> = {};
    batchStudents.forEach(s => {
      const records = s.recentAttendance[selectedDate];
      initial[s.id] = records ? records[0] : 'present';
    });
    setDayStatuses(initial);
  }, [selectedDate, selectedBatchCode, students]);

  // Current Day Submission Status
  const currentSubmission = daySubmissions.find(
    s => s.batchCode === selectedBatchCode && s.date === selectedDate
  );

  const isVerifiedByHOD = currentSubmission?.status === 'verified_by_hod';
  const isSubmittedToHOD = currentSubmission?.status === 'submitted_to_hod';

  const displayedStudents = studentSearch.trim()
    ? batchStudents.filter(s => 
        s.name.toLowerCase().includes(studentSearch.toLowerCase()) || 
        s.rollNo.includes(studentSearch)
      )
    : batchStudents;

  const handleToggleStatus = (studentId: string) => {
    const cur = dayStatuses[studentId] || 'present';
    if (cur === 'leave_prior_cl' || cur === 'leave_od' || cur === 'leave_ml') {
      return; // Locked: Approved leave
    }
    const next: AttendanceStatus = cur === 'present' ? 'absent_uninformed' : 'present';
    setDayStatuses(prev => ({ ...prev, [studentId]: next }));
  };

  const handleMarkAllDayPresent = () => {
    const updated: Record<string, AttendanceStatus> = {};
    batchStudents.forEach(s => {
      const cur = dayStatuses[s.id];
      if (cur === 'leave_prior_cl' || cur === 'leave_od' || cur === 'leave_ml') {
        updated[s.id] = cur;
      } else {
        updated[s.id] = 'present';
      }
    });
    setDayStatuses(updated);
  };

  const handleSaveDay = () => {
    saveDayAttendance(selectedBatchCode, selectedDate, dayStatuses);
  };

  const handleSubmitToHOD = () => {
    saveDayAttendance(selectedBatchCode, selectedDate, dayStatuses);
    submitDayAttendanceToHOD(selectedBatchCode, selectedDate);
  };

  const handleVerifyHOD = () => {
    verifyDayAttendanceByHOD(selectedBatchCode, selectedDate);
  };

  // Generate days array for calendar grid
  const monthDates = workingDates.filter(d => d.startsWith(activeMonthView));

  const presentCount = Object.values(dayStatuses).filter(st => st === 'present' || st === 'leave_od').length;
  const absentCount = Object.values(dayStatuses).filter(st => st === 'absent_uninformed').length;
  const leaveCount = Object.values(dayStatuses).filter(st => st === 'leave_prior_cl' || st === 'leave_ml').length;
  const dayPercentage = Number(((presentCount / Math.max(1, batchStudents.length)) * 100).toFixed(1));

  return (
    <div className="space-y-6">
      {/* Top Banner */}
      <div className="p-6 rounded-3xl glass-panel border-slate-800 bg-gradient-to-r from-academic-600/10 via-indigo-600/10 to-transparent">
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <span className="px-2.5 py-0.5 rounded-full text-[10px] font-extrabold uppercase bg-academic-950 text-academic-300 border border-academic-700/80 flex items-center gap-1.5">
                <CalendarIcon className="w-3.5 h-3.5 text-cyan-400" />
                30-Day Attendance Calendar & Ledger
              </span>
              <span className="text-xs text-slate-400 font-semibold">1 Month Historical Entry & HOD Verification</span>
            </div>
            <h2 className="text-xl font-extrabold text-white tracking-tight">
              Day-Wise Manual Attendance Entry & Approval Register
            </h2>
            <p className="text-xs text-slate-400 mt-1">
              Select any date from the 1-month calendar to enter or modify day-wise presence, verify prior ODs, and submit for HOD digital verification.
            </p>
          </div>

          <div className="flex items-center gap-3">
            {/* Section Switcher */}
            <select
              value={selectedBatchCode}
              onChange={(e) => setSelectedBatchCode(e.target.value)}
              className="px-4 py-2.5 text-xs font-bold rounded-xl bg-[#121828] border border-slate-700 text-white focus:outline-none focus:border-academic-500"
            >
              {batches.map(b => (
                <option key={b.id} value={b.batchCode}>
                  {b.yearName} - Sec {b.section} ({b.batchCode}) · {b.totalStudents} Students
                </option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {/* 30-Day Interactive Calendar Ribbon */}
      <div className="p-6 rounded-3xl glass-panel border-slate-800 space-y-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <h3 className="text-sm font-bold text-white flex items-center gap-2">
              <CalendarIcon className="w-4 h-4 text-academic-400" />
              <span>{activeMonthView === '2026-08' ? 'August 2026' : 'September 2026'} Academic Calendar</span>
            </h3>
            <div className="flex items-center gap-1 bg-[#121828] rounded-xl p-1 border border-slate-800">
              <button
                onClick={() => setActiveMonthView('2026-08')}
                className={`px-3 py-1 rounded-lg text-xs font-bold transition-all ${
                  activeMonthView === '2026-08' ? 'bg-academic-600 text-white' : 'text-slate-400 hover:text-white'
                }`}
              >
                August (30 Days)
              </button>
              <button
                onClick={() => setActiveMonthView('2026-09')}
                className={`px-3 py-1 rounded-lg text-xs font-bold transition-all ${
                  activeMonthView === '2026-09' ? 'bg-academic-600 text-white' : 'text-slate-400 hover:text-white'
                }`}
              >
                September
              </button>
            </div>
          </div>

          {/* Calendar Legend */}
          <div className="flex flex-wrap items-center gap-3 text-[10px] font-bold">
            <span className="flex items-center gap-1.5 text-emerald-400">
              <div className="w-2.5 h-2.5 rounded-full bg-emerald-500" />
              <span>Verified by HOD</span>
            </span>
            <span className="flex items-center gap-1.5 text-amber-400">
              <div className="w-2.5 h-2.5 rounded-full bg-amber-500" />
              <span>Submitted (Pending HOD)</span>
            </span>
            <span className="flex items-center gap-1.5 text-slate-400">
              <div className="w-2.5 h-2.5 rounded-full bg-slate-600" />
              <span>Draft Entry</span>
            </span>
          </div>
        </div>

        {/* Calendar Day Tiles */}
        <div className="grid grid-cols-2 sm:grid-cols-4 md:grid-cols-6 lg:grid-cols-8 gap-2.5">
          {monthDates.map(dStr => {
            const isSelected = dStr === selectedDate;
            const sub = daySubmissions.find(s => s.batchCode === selectedBatchCode && s.date === dStr);
            const status = sub?.status || 'draft';
            const pct = sub?.dayPercentage || 88;
            const dayNum = dStr.split('-')[2];

            return (
              <button
                key={dStr}
                onClick={() => setSelectedDate(dStr)}
                className={`p-3 rounded-2xl border text-left transition-all relative ${
                  isSelected
                    ? 'bg-academic-600 text-white border-academic-400 shadow-glow-indigo scale-[1.02]'
                    : 'bg-[#121828] border-slate-800 hover:border-slate-700 text-slate-300'
                }`}
              >
                <div className="flex items-center justify-between">
                  <span className="text-xs font-black">{dayNum} {activeMonthView === '2026-08' ? 'Aug' : 'Sep'}</span>
                  <div className={`w-2 h-2 rounded-full ${
                    status === 'verified_by_hod' ? 'bg-emerald-400' :
                    status === 'submitted_to_hod' ? 'bg-amber-400' : 'bg-slate-500'
                  }`} />
                </div>
                <div className="mt-2 flex items-center justify-between text-[10px]">
                  <span className={isSelected ? 'text-white' : 'text-slate-400'}>{pct}%</span>
                  <span className="text-[9px] opacity-80 uppercase font-mono">
                    {status === 'verified_by_hod' ? 'Signed' : status === 'submitted_to_hod' ? 'Pending' : 'Draft'}
                  </span>
                </div>
              </button>
            );
          })}
        </div>
      </div>

      {/* Selected Day Entry Deck */}
      <div className="p-6 rounded-3xl glass-panel border-slate-800 space-y-5">
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 pb-4 border-b border-slate-800">
          <div>
            <div className="flex items-center gap-2">
              <h3 className="text-base font-bold text-white">
                Day Attendance Register: <span className="text-cyan-400">{selectedDate}</span> ({selectedBatchCode})
              </h3>
              {isVerifiedByHOD ? (
                <span className="px-2.5 py-0.5 rounded-full text-[10px] font-extrabold bg-emerald-950 text-emerald-300 border border-emerald-800 flex items-center gap-1">
                  <ShieldCheck className="w-3.5 h-3.5" /> Verified by {currentSubmission?.verifiedBy}
                </span>
              ) : isSubmittedToHOD ? (
                <span className="px-2.5 py-0.5 rounded-full text-[10px] font-extrabold bg-amber-950 text-amber-300 border border-amber-800 flex items-center gap-1">
                  <Clock className="w-3.5 h-3.5" /> Submitted to HOD for Verification
                </span>
              ) : (
                <span className="px-2.5 py-0.5 rounded-full text-[10px] font-extrabold bg-slate-800 text-slate-300 border border-slate-700">
                  Draft Entry (Advisor Editable)
                </span>
              )}
            </div>
            <p className="text-xs text-slate-400 mt-1">
              Showing {batchStudents.length} students · Day Aggregate: <strong className="text-emerald-400">{dayPercentage}%</strong> ({presentCount} Present, {absentCount} Cuts, {leaveCount} Authorized Leaves)
            </p>
          </div>

          {/* Action Buttons */}
          <div className="flex flex-wrap items-center gap-2.5">
            <button
              onClick={handleMarkAllDayPresent}
              className="px-3.5 py-2 text-xs font-bold rounded-xl bg-[#121828] hover:bg-slate-800 border border-slate-700 text-emerald-400 hover:text-emerald-300 flex items-center gap-1.5 transition-all"
            >
              <CheckCircle2 className="w-4 h-4" />
              <span>Mark All Present</span>
            </button>

            <button
              onClick={handleSaveDay}
              className="px-4 py-2 text-xs font-bold rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 border border-slate-700 flex items-center gap-1.5 transition-all"
            >
              <Save className="w-4 h-4" />
              <span>Save Draft</span>
            </button>

            <button
              onClick={handleSubmitToHOD}
              className="px-4 py-2 text-xs font-bold rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white shadow-sm flex items-center gap-1.5 transition-all"
            >
              <Send className="w-4 h-4" />
              <span>Submit to HOD</span>
            </button>

            {/* HOD Verification Button (Only for HOD roles) */}
            {(currentUserRole === 'hod1' || currentUserRole === 'hod2') && (
              <button
                onClick={handleVerifyHOD}
                className="px-4 py-2 text-xs font-bold rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white shadow-glow-emerald flex items-center gap-1.5 transition-all"
              >
                <ShieldCheck className="w-4 h-4" />
                <span>Verify & Sign Register</span>
              </button>
            )}
          </div>
        </div>

        {/* Student Search & Quick Filter */}
        <div className="flex items-center justify-between gap-4">
          <div className="relative w-72">
            <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="Search student or roll number..."
              value={studentSearch}
              onChange={(e) => setStudentSearch(e.target.value)}
              className="w-full pl-9 pr-4 py-2 text-xs rounded-xl bg-[#121828] border border-slate-700 text-white focus:outline-none"
            />
          </div>

          <div className="text-xs text-slate-400 font-semibold">
            Tap student card to toggle <span className="text-emerald-400 font-bold">Present</span> ↔ <span className="text-rose-400 font-bold">Absent Cut</span>
          </div>
        </div>

        {/* Student Cards Grid for the Day */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
          {displayedStudents.map(student => {
            const status = dayStatuses[student.id] || 'present';
            const isPresent = status === 'present';
            const isUninformed = status === 'absent_uninformed';
            const isOD = status === 'leave_od';
            const isCL = status === 'leave_prior_cl';
            const isML = status === 'leave_ml';
            const isLocked = isOD || isCL || isML;

            return (
              <div
                key={student.id}
                onClick={() => handleToggleStatus(student.id)}
                className={`p-3.5 rounded-2xl border transition-all cursor-pointer select-none flex items-center justify-between ${
                  isPresent
                    ? 'bg-[#121828]/80 border-slate-800 hover:border-emerald-500/50'
                    : isUninformed
                    ? 'bg-rose-950/30 border-rose-600 shadow-glow-rose'
                    : 'bg-indigo-950/30 border-indigo-500'
                }`}
              >
                <div className="flex items-center gap-3">
                  <img src={student.avatar} alt={student.name} className="w-9 h-9 rounded-full object-cover ring-2 ring-slate-700" />
                  <div>
                    <h4 className="text-xs font-bold text-white leading-tight">{student.name}</h4>
                    <span className="text-[10px] font-mono text-slate-400">{student.rollNo}</span>
                  </div>
                </div>

                <div>
                  {isPresent && (
                    <span className="text-[10px] font-extrabold px-2 py-0.5 rounded-full bg-emerald-950 text-emerald-300 border border-emerald-800">
                      ✓ Present
                    </span>
                  )}
                  {isUninformed && (
                    <span className="text-[10px] font-extrabold px-2 py-0.5 rounded-full bg-rose-950 text-rose-300 border border-rose-700">
                      ✕ Absent Cut
                    </span>
                  )}
                  {isOD && (
                    <span className="text-[10px] font-extrabold px-2 py-0.5 rounded-full bg-cyan-950 text-cyan-300 border border-cyan-800">
                      🔒 Sanctioned OD
                    </span>
                  )}
                  {isCL && (
                    <span className="text-[10px] font-extrabold px-2 py-0.5 rounded-full bg-blue-950 text-blue-300 border border-blue-800">
                      🔒 Prior CL
                    </span>
                  )}
                  {isML && (
                    <span className="text-[10px] font-extrabold px-2 py-0.5 rounded-full bg-purple-950 text-purple-300 border border-purple-800">
                      🔒 Medical ML
                    </span>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};
