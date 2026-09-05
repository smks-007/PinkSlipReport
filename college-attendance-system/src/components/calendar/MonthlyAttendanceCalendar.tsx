import React, { useState, useMemo } from 'react';
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
  Sparkles,
  CalendarDays,
  Grid
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

  const [selectedDate, setSelectedDate] = useState<string>('2026-09-05');
  const [studentSearch, setStudentSearch] = useState<string>('');
  const [selectedMonth, setSelectedMonth] = useState<string>('2026-09'); // '2026-09', '2026-10', '2026-11', '2026-12', '2026-08'

  const monthsList = [
    { key: '2026-08', label: 'August 2026', short: 'Aug 2026', badge: 'Past Academic Month' },
    { key: '2026-09', label: 'September 2026', short: 'Sep 2026', badge: 'Current Active Month' },
    { key: '2026-10', label: 'October 2026', short: 'Oct 2026', badge: 'Mid-Term Reviews' },
    { key: '2026-11', label: 'November 2026', short: 'Nov 2026', badge: 'Model Practicals' },
    { key: '2026-12', label: 'December 2026', short: 'Dec 2026', badge: 'End-Sem Finals' },
  ];

  const batchStudents = students.filter(s => s.batchCode === selectedBatchCode);

  // Filter working dates by selected month
  const monthDates = useMemo(() => {
    return workingDates.filter(d => d.startsWith(selectedMonth));
  }, [workingDates, selectedMonth]);

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
      showToast('Status locked: Approved Leave / On-Duty cannot be overridden without HOD revocation.');
      return;
    }
    const next: AttendanceStatus = cur === 'present' ? 'absent_uninformed' : 'present';
    setDayStatuses(prev => ({ ...prev, [studentId]: next }));
  };

  const handleSetSpecificStatus = (studentId: string, status: AttendanceStatus) => {
    const cur = dayStatuses[studentId];
    if (cur === 'leave_prior_cl' || cur === 'leave_od' || cur === 'leave_ml') {
      showToast('Status locked: Approved Leave / On-Duty cannot be overridden.');
      return;
    }
    setDayStatuses(prev => ({ ...prev, [studentId]: status }));
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
    showToast(`All students in ${selectedBatchCode} marked present for ${selectedDate}.`);
  };

  const handleSaveDraft = () => {
    saveDayAttendance(selectedBatchCode, selectedDate, dayStatuses);
  };

  const handleSubmitToHOD = () => {
    saveDayAttendance(selectedBatchCode, selectedDate, dayStatuses);
    submitDayAttendanceToHOD(selectedBatchCode, selectedDate, 'Daily attendance roll finalized by Class Advisor.');
  };

  const handleHODVerification = () => {
    verifyDayAttendanceByHOD(selectedBatchCode, selectedDate, 'Verified against biometric and leave records by HOD.');
  };

  const presentCount = Object.values(dayStatuses).filter(st => st === 'present').length;
  const cutCount = Object.values(dayStatuses).filter(st => st === 'absent_uninformed').length;
  const odCount = Object.values(dayStatuses).filter(st => st === 'leave_od').length;
  const leaveCount = Object.values(dayStatuses).filter(st => st === 'leave_prior_cl' || st === 'leave_ml').length;
  const dayPercentage = batchStudents.length > 0 
    ? (((presentCount + odCount) / batchStudents.length) * 100).toFixed(1)
    : '0.0';

  // Month Statistics
  const monthSubmissions = daySubmissions.filter(
    s => s.batchCode === selectedBatchCode && s.date.startsWith(selectedMonth)
  );
  const verifiedCount = monthSubmissions.filter(s => s.status === 'verified_by_hod').length;
  const pendingCount = monthSubmissions.filter(s => s.status !== 'verified_by_hod').length;

  return (
    <div className="space-y-6 animate-in fade-in duration-300">
      {/* Top Banner & Month Selector */}
      <div className="bg-gradient-to-r from-slate-900 via-academic-950 to-[#0c101c] p-6 rounded-3xl border border-academic-800/60 shadow-xl flex flex-col lg:flex-row lg:items-center justify-between gap-6">
        <div className="space-y-2">
          <div className="flex items-center gap-3">
            <div className="p-3 rounded-2xl bg-academic-600/20 border border-academic-500/40 text-academic-400 shadow-glow-indigo">
              <CalendarDays className="w-6 h-6" />
            </div>
            <div>
              <h1 className="text-xl font-black text-white flex items-center gap-2">
                2026 Academic Attendance Calendar (Sep – Dec 2026)
                <span className="text-[10px] uppercase font-extrabold px-2.5 py-0.5 rounded-full bg-cyan-950 text-cyan-300 border border-cyan-800">
                  {workingDates.length} Working Days · 10 AIDS Sections
                </span>
              </h1>
              <p className="text-xs text-slate-400">
                Manual day-wise entry, On-Duty pre-locking, HOD digital signatures, and monthly audit trail.
              </p>
            </div>
          </div>
        </div>

        {/* Section Picker */}
        <div className="flex items-center gap-3">
          <div className="bg-[#121828] p-1 rounded-2xl border border-slate-800 flex items-center gap-2 px-3 py-1.5">
            <UserCheck className="w-4 h-4 text-academic-400" />
            <span className="text-xs font-bold text-slate-400">Class:</span>
            <select
              value={selectedBatchCode}
              onChange={(e) => setSelectedBatchCode(e.target.value)}
              className="bg-transparent text-xs font-black text-white focus:outline-none cursor-pointer"
            >
              {batches.map(b => (
                <option key={b.batchCode} value={b.batchCode} className="bg-slate-900">
                  {b.batchCode} ({b.yearName} Sec {b.section} - {b.totalStudents} Students)
                </option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {/* Month Tabs Ribbon */}
      <div className="flex items-center gap-2 overflow-x-auto pb-1">
        {monthsList.map(m => {
          const isSelected = selectedMonth === m.key;
          return (
            <button
              key={m.key}
              onClick={() => {
                setSelectedMonth(m.key);
                const firstDateInMonth = workingDates.find(d => d.startsWith(m.key));
                if (firstDateInMonth) setSelectedDate(firstDateInMonth);
              }}
              className={`flex-1 min-w-[170px] p-3.5 rounded-2xl border text-left transition-all relative overflow-hidden ${
                isSelected
                  ? 'bg-gradient-to-r from-academic-600/30 to-indigo-600/10 border-academic-500/80 shadow-glow-indigo'
                  : 'bg-[#0c101c]/80 border-slate-800/80 hover:bg-slate-900/60'
              }`}
            >
              <div className="flex items-center justify-between">
                <span className={`text-xs font-black ${isSelected ? 'text-white' : 'text-slate-300'}`}>
                  {m.label}
                </span>
                {isSelected && (
                  <span className="w-2 h-2 rounded-full bg-cyan-400 animate-ping" />
                )}
              </div>
              <span className={`text-[10px] block mt-1 font-bold ${
                isSelected ? 'text-cyan-300' : 'text-slate-500'
              }`}>
                {m.badge}
              </span>
            </button>
          );
        })}
      </div>

      {/* Date Ribbon for Selected Month */}
      <div className="p-4 rounded-3xl bg-[#0c101c]/90 border border-slate-800/80 space-y-3">
        <div className="flex items-center justify-between text-xs">
          <div className="flex items-center gap-2">
            <CalendarIcon className="w-4 h-4 text-academic-400" />
            <span className="font-extrabold text-white">
              Working Days in {monthsList.find(m => m.key === selectedMonth)?.label} ({monthDates.length} Days)
            </span>
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={() => {
                const today = '2026-09-05';
                if (workingDates.includes(today)) {
                  setSelectedMonth('2026-09');
                  setSelectedDate(today);
                }
              }}
              className="px-3 py-1 rounded-xl bg-cyan-950 text-cyan-300 border border-cyan-800 text-[11px] font-bold hover:bg-cyan-900 transition-all"
            >
              Jump to Today (05 Sep)
            </button>
          </div>
        </div>

        {/* Horizontal Dates Ribbon */}
        <div className="flex gap-2 overflow-x-auto pb-2 scrollbar-thin">
          {monthDates.map(dStr => {
            const isSelected = selectedDate === dStr;
            const submission = daySubmissions.find(
              s => s.batchCode === selectedBatchCode && s.date === dStr
            );
            const isVerified = submission?.status === 'verified_by_hod';
            const isSubmitted = submission?.status === 'submitted_to_hod';
            const isToday = dStr === '2026-09-05';

            const dateParts = dStr.split('-');
            const dayNum = dateParts[2];
            const monthNum = dateParts[1];

            return (
              <button
                key={dStr}
                onClick={() => setSelectedDate(dStr)}
                className={`flex-shrink-0 w-16 p-2 rounded-2xl border text-center transition-all flex flex-col items-center gap-1 ${
                  isSelected
                    ? 'bg-academic-600 text-white border-academic-400 shadow-glow-indigo scale-105 z-10'
                    : 'bg-[#121828] text-slate-400 border-slate-800 hover:bg-slate-800 hover:text-white'
                }`}
              >
                <span className="text-[10px] font-bold uppercase">
                  {isToday ? 'Today' : `${dayNum}/${monthNum}`}
                </span>
                <span className="text-base font-black leading-none">{dayNum}</span>
                <span className={`w-2 h-2 rounded-full mt-0.5 ${
                  isVerified 
                    ? 'bg-emerald-400' 
                    : isSubmitted 
                      ? 'bg-amber-400' 
                      : 'bg-slate-600'
                }`} title={isVerified ? 'Verified by HOD' : isSubmitted ? 'Submitted to HOD' : 'Draft Entry'} />
              </button>
            );
          })}
        </div>
      </div>

      {/* Day Overview & Action Command Bar */}
      <div className="grid grid-cols-1 lg:grid-cols-4 gap-4">
        {/* KPI 1: Present */}
        <div className="p-4 rounded-2xl bg-[#0c101c]/90 border border-slate-800 flex items-center justify-between">
          <div>
            <span className="text-xs font-bold text-slate-400">Present Today</span>
            <div className="text-2xl font-black text-emerald-400">{presentCount} / {batchStudents.length}</div>
            <span className="text-[10px] text-slate-500">{dayPercentage}% Attendance Rate</span>
          </div>
          <div className="p-3 rounded-xl bg-emerald-950/60 border border-emerald-800 text-emerald-400">
            <CheckCircle2 className="w-5 h-5" />
          </div>
        </div>

        {/* KPI 2: On-Duty (OD) */}
        <div className="p-4 rounded-2xl bg-[#0c101c]/90 border border-slate-800 flex items-center justify-between">
          <div>
            <span className="text-xs font-bold text-slate-400">On-Duty (Sanctioned)</span>
            <div className="text-2xl font-black text-cyan-300">{odCount}</div>
            <span className="text-[10px] text-cyan-400/80">Symposium & Contests</span>
          </div>
          <div className="p-3 rounded-xl bg-cyan-950/60 border border-cyan-800 text-cyan-400">
            <Sparkles className="w-5 h-5" />
          </div>
        </div>

        {/* KPI 3: Casual / Medical Leaves */}
        <div className="p-4 rounded-2xl bg-[#0c101c]/90 border border-slate-800 flex items-center justify-between">
          <div>
            <span className="text-xs font-bold text-slate-400">Approved Leaves</span>
            <div className="text-2xl font-black text-blue-400">{leaveCount}</div>
            <span className="text-[10px] text-slate-400">Doctor / Family Sanctioned</span>
          </div>
          <div className="p-3 rounded-xl bg-blue-950/60 border border-blue-800 text-blue-400">
            <FileText className="w-5 h-5" />
          </div>
        </div>

        {/* KPI 4: Uninformed Absences */}
        <div className="p-4 rounded-2xl bg-[#0c101c]/90 border border-rose-950/60 bg-rose-950/20 flex items-center justify-between">
          <div>
            <span className="text-xs font-bold text-rose-300">Uninformed Cuts</span>
            <div className="text-2xl font-black text-rose-400">{cutCount}</div>
            <span className="text-[10px] text-rose-300/80">Pink Slip Dispatched</span>
          </div>
          <div className="p-3 rounded-xl bg-rose-950/80 border border-rose-800 text-rose-400">
            <AlertTriangle className="w-5 h-5" />
          </div>
        </div>
      </div>

      {/* Main Roll Call Ledger & Actions */}
      <div className="p-6 rounded-3xl bg-[#0c101c]/90 border border-slate-800/80 shadow-xl space-y-6">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-2">
              <h3 className="text-base font-black text-white">
                Roster Attendance Ledger for {selectedDate}
              </h3>
              <span className={`px-2.5 py-0.5 rounded-full text-[10px] font-black uppercase ${
                isVerifiedByHOD
                  ? 'bg-emerald-950 text-emerald-300 border border-emerald-800'
                  : isSubmittedToHOD
                    ? 'bg-amber-950 text-amber-300 border border-amber-800'
                    : 'bg-slate-800 text-slate-300'
              }`}>
                {isVerifiedByHOD ? '✓ Verified by HOD' : isSubmittedToHOD ? '⏳ Awaiting HOD Signoff' : 'Draft Mode'}
              </span>
            </div>
            <p className="text-xs text-slate-400">
              {selectedBatchCode} · Advisor: <strong>{batches.find(b => b.batchCode === selectedBatchCode)?.advisorName}</strong>
            </p>
          </div>

          {/* Quick Search & Bulk Actions */}
          <div className="flex flex-wrap items-center gap-2">
            <div className="relative">
              <Search className="w-3.5 h-3.5 text-slate-500 absolute left-3 top-3" />
              <input
                type="text"
                value={studentSearch}
                onChange={(e) => setStudentSearch(e.target.value)}
                placeholder="Search student or roll no..."
                className="pl-8 pr-3 py-1.5 rounded-xl bg-slate-900 border border-slate-700 text-xs text-white focus:outline-none focus:border-academic-500"
              />
            </div>

            <button
              onClick={handleMarkAllDayPresent}
              className="px-3 py-1.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-bold transition-all"
            >
              Mark All Present
            </button>

            <button
              onClick={handleSaveDraft}
              className="px-3.5 py-1.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-bold flex items-center gap-1.5 transition-all"
            >
              <Save className="w-3.5 h-3.5 text-slate-400" />
              <span>Save Draft</span>
            </button>

            <button
              onClick={handleSubmitToHOD}
              className="px-3.5 py-1.5 rounded-xl bg-academic-600 hover:bg-academic-500 text-white text-xs font-bold flex items-center gap-1.5 shadow-glow-indigo transition-all"
            >
              <Send className="w-3.5 h-3.5" />
              <span>Submit to HOD</span>
            </button>

            {/* HOD Verification Action */}
            {(currentUserRole === 'hod1' || currentUserRole === 'hod2') && (
              <button
                onClick={handleHODVerification}
                className="px-4 py-1.5 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-extrabold flex items-center gap-1.5 shadow-md transition-all animate-in zoom-in-95"
              >
                <ShieldCheck className="w-4 h-4" />
                <span>Verify & Sign</span>
              </button>
            )}
          </div>
        </div>

        {/* Student Table */}
        <div className="overflow-x-auto rounded-2xl border border-slate-800/80">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="border-b border-slate-800 bg-slate-950/60 text-slate-400 font-extrabold">
                <th className="py-3 px-3 w-12 text-center">#</th>
                <th className="py-3 px-3">Student Name</th>
                <th className="py-3 px-3">Roll Number</th>
                <th className="py-3 px-3 text-center">Overall %</th>
                <th className="py-3 px-3 text-center">{selectedDate} Status</th>
                <th className="py-3 px-3 text-right">Quick Badges</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/50">
              {displayedStudents.map((stu, index) => {
                const status = dayStatuses[stu.id] || 'present';
                const isLocked = status === 'leave_prior_cl' || status === 'leave_od' || status === 'leave_ml';

                return (
                  <tr key={stu.id} className="hover:bg-slate-900/40 transition-colors">
                    <td className="py-2.5 px-3 text-center text-slate-500 font-bold">{index + 1}</td>
                    <td className="py-2.5 px-3">
                      <span className="font-extrabold text-white block">{stu.name}</span>
                      <span className="text-[10px] text-slate-500">{stu.parentName} · {stu.parentPhone}</span>
                    </td>
                    <td className="py-2.5 px-3 font-bold text-cyan-400">{stu.rollNo}</td>
                    <td className="py-2.5 px-3 text-center">
                      <span className={`px-2 py-0.5 rounded-md font-extrabold text-[11px] ${
                        stu.attendancePercentage >= 85 
                          ? 'text-emerald-400 bg-emerald-950/50' 
                          : stu.attendancePercentage >= 75 
                            ? 'text-amber-400 bg-amber-950/50'
                            : 'text-rose-400 bg-rose-950/50'
                      }`}>
                        {stu.attendancePercentage}%
                      </span>
                    </td>
                    <td className="py-2.5 px-3 text-center">
                      <button
                        onClick={() => handleToggleStatus(stu.id)}
                        disabled={isLocked}
                        className={`px-3 py-1 rounded-xl text-xs font-black transition-all ${
                          status === 'present'
                            ? 'bg-emerald-950 text-emerald-300 border border-emerald-800 hover:bg-emerald-900'
                            : status === 'leave_od'
                              ? 'bg-indigo-950 text-indigo-300 border border-indigo-800'
                              : status === 'leave_prior_cl' || status === 'leave_ml'
                                ? 'bg-blue-950 text-blue-300 border border-blue-800'
                                : 'bg-rose-950 text-rose-300 border border-rose-800 hover:bg-rose-900'
                        }`}
                      >
                        {status === 'present' && '🟢 Present'}
                        {status === 'absent_uninformed' && '🔴 Absent (Cut)'}
                        {status === 'leave_od' && '🟣 On-Duty (OD)'}
                        {status === 'leave_prior_cl' && '🔵 Prior Leave (CL)'}
                        {status === 'leave_ml' && '🩺 Medical (ML)'}
                      </button>
                    </td>
                    <td className="py-2.5 px-3 text-right">
                      <div className="flex items-center justify-end gap-1.5">
                        <button
                          onClick={() => handleSetSpecificStatus(stu.id, 'present')}
                          className="px-2 py-0.5 rounded text-[10px] font-bold bg-slate-800 hover:bg-emerald-900 text-slate-300"
                        >
                          P
                        </button>
                        <button
                          onClick={() => handleSetSpecificStatus(stu.id, 'absent_uninformed')}
                          className="px-2 py-0.5 rounded text-[10px] font-bold bg-slate-800 hover:bg-rose-900 text-slate-300"
                        >
                          A
                        </button>
                        <button
                          onClick={() => handleSetSpecificStatus(stu.id, 'leave_od')}
                          className="px-2 py-0.5 rounded text-[10px] font-bold bg-slate-800 hover:bg-indigo-900 text-slate-300"
                        >
                          OD
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
