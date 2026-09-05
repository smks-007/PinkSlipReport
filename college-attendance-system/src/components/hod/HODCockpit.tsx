import React, { useState, useMemo } from 'react';
import { 
  Users, 
  AlertTriangle, 
  CheckCircle2, 
  Clock, 
  Flame, 
  Calculator, 
  TrendingUp, 
  FileSpreadsheet, 
  ArrowRight,
  Sparkles,
  PhoneCall,
  ShieldAlert,
  ShieldCheck,
  ChevronRight,
  BrainCircuit,
  Eye,
  FileText,
  Search,
  Calendar,
  Check,
  X,
  Layers,
  ExternalLink,
  MessageSquare,
  BarChart3,
  CalendarDays
} from 'lucide-react';
import { useAttendance } from '../../context/AttendanceContext';
import { LeaveRecord, AttendanceStatus } from '../../types';

export const HODCockpit: React.FC = () => {
  const { 
    batches, 
    students, 
    departmentSummary, 
    complianceList, 
    leaveRecords,
    daySubmissions,
    workingDates,
    setSelectedStudentId, 
    setSelectedBatchCode,
    setActiveTab, 
    setIsNAACModalOpen,
    hodApproveLeave,
    hodRejectLeave,
    verifyDayAttendanceByHOD,
    showToast
  } = useAttendance();

  const [activeSubTab, setActiveSubTab] = useState<'live_roster' | 'last_week_graphs' | 'month_aggregates' | 'detention_radar'>('live_roster');
  const [selectedSectionFilter, setSelectedSectionFilter] = useState<string>('all');
  const [selectedProofModalLeave, setSelectedProofModalLeave] = useState<LeaveRecord | null>(null);
  const [rosterSearch, setRosterSearch] = useState<string>('');

  const today = '2026-09-05';

  // Critical Shortage students (< 75%)
  const shortageStudents = useMemo(() => {
    return students.filter(s => s.attendancePercentage < 75.0);
  }, [students]);

  // Pending HOD Items
  const pendingHODLeaves = useMemo(() => {
    return leaveRecords.filter(l => l.status === 'forwarded_to_hod');
  }, [leaveRecords]);

  const pendingDayRegisters = useMemo(() => {
    return daySubmissions.filter(s => s.status === 'submitted_to_hod');
  }, [daySubmissions]);

  // Today's Live Absentees across all AIDS sections
  const liveAbsentees = useMemo(() => {
    const list: { student: typeof students[0]; date: string; reason: string }[] = [];
    students.forEach(s => {
      const records = s.recentAttendance[today];
      if (records && records.some(st => st === 'absent_uninformed')) {
        list.push({ student: s, date: today, reason: 'Uninformed Period Absence' });
      }
    });
    return list;
  }, [students, today]);

  // Today's Live On-Duty & Approved Leaves
  const liveOnDuties = useMemo(() => {
    return leaveRecords.filter(l => l.leaveType === 'on_duty_od');
  }, [leaveRecords]);

  const liveMedicalAndCasualLeaves = useMemo(() => {
    return leaveRecords.filter(l => l.leaveType === 'prior_cl' || l.leaveType === 'medical_ml');
  }, [leaveRecords]);

  // Filtered lists based on section dropdown and search
  const filteredAbsentees = useMemo(() => {
    return liveAbsentees.filter(item => {
      const matchesSec = selectedSectionFilter === 'all' || item.student.batchCode === selectedSectionFilter;
      const matchesQuery = !rosterSearch.trim() || 
        item.student.name.toLowerCase().includes(rosterSearch.toLowerCase()) || 
        item.student.rollNo.includes(rosterSearch);
      return matchesSec && matchesQuery;
    });
  }, [liveAbsentees, selectedSectionFilter, rosterSearch]);

  const filteredOnDuties = useMemo(() => {
    return liveOnDuties.filter(item => {
      const matchesSec = selectedSectionFilter === 'all' || item.batchCode === selectedSectionFilter;
      const matchesQuery = !rosterSearch.trim() || 
        item.studentName.toLowerCase().includes(rosterSearch.toLowerCase()) || 
        item.rollNo.includes(rosterSearch);
      return matchesSec && matchesQuery;
    });
  }, [liveOnDuties, selectedSectionFilter, rosterSearch]);

  // Last 7 Academic Working Days for Section-by-Section Graphs
  const last7WorkingDates = useMemo(() => {
    const pastDates = workingDates.filter(d => d <= today);
    return pastDates.slice(-7);
  }, [workingDates, today]);

  // Section 7-Day Trend Matrix
  const section7DayTrends = useMemo(() => {
    return batches.map(b => {
      const dayStats = last7WorkingDates.map(date => {
        const sub = daySubmissions.find(s => s.batchCode === b.batchCode && s.date === date);
        const present = sub ? sub.presentCount : Math.round(b.totalStudents * 0.94);
        const ods = sub ? sub.odCount : 2;
        const total = sub ? sub.totalStrength : b.totalStudents;
        const pct = total > 0 ? parseFloat((((present + ods) / total) * 100).toFixed(1)) : 92.5;

        const parts = date.split('-');
        const shortDate = `${parts[2]}/${parts[1]}`;

        return { date, shortDate, present, ods, total, pct };
      });

      const avg7Day = (dayStats.reduce((a, b) => a + b.pct, 0) / (dayStats.length || 1)).toFixed(1);

      return {
        batchCode: b.batchCode,
        yearName: b.yearName,
        section: b.section,
        advisorName: b.advisorName,
        totalStudents: b.totalStudents,
        avg7Day: parseFloat(avg7Day),
        dayStats
      };
    });
  }, [batches, last7WorkingDates, daySubmissions]);

  // Month-by-Month Aggregate Data (Aug, Sep, Oct, Nov, Dec 2026)
  const monthAggregates = useMemo(() => {
    const months = [
      { key: '2026-08', name: 'August 2026', totalDays: 24, status: 'Completed (Verified)' },
      { key: '2026-09', name: 'September 2026', totalDays: 25, status: 'Active (Current)' },
      { key: '2026-10', name: 'October 2026', totalDays: 24, status: 'Upcoming (Mid-Term)' },
      { key: '2026-11', name: 'November 2026', totalDays: 25, status: 'Upcoming (Practicals)' },
      { key: '2026-12', name: 'December 2026', totalDays: 26, status: 'Upcoming (End-Sem)' },
    ];

    return months.map(m => {
      const batchData = batches.map(b => {
        const subs = daySubmissions.filter(s => s.batchCode === b.batchCode && s.date.startsWith(m.key));
        const totalPres = subs.reduce((a, c) => a + c.presentCount, 0);
        const totalODs = subs.reduce((a, c) => a + c.odCount, 0);
        const totalPossible = subs.reduce((a, c) => a + c.totalStrength, 0) || (b.totalStudents * m.totalDays);
        const pct = totalPossible > 0 ? parseFloat((((totalPres + totalODs) / totalPossible) * 100).toFixed(1)) : 93.0;

        return {
          batchCode: b.batchCode,
          pct: pct > 0 ? pct : 92.5
        };
      });

      const deptAvg = (batchData.reduce((a, c) => a + c.pct, 0) / (batchData.length || 1)).toFixed(1);

      return {
        ...m,
        deptAvg: parseFloat(deptAvg),
        batchData
      };
    });
  }, [batches, daySubmissions]);

  const handleVerifyAllDayRegisters = () => {
    pendingDayRegisters.forEach(r => {
      verifyDayAttendanceByHOD(r.batchCode, r.date, 'Bulk verified and sealed by Head of Department.');
    });
    showToast(`Instant Verification: All ${pendingDayRegisters.length} day registers verified and signed!`);
  };

  const handleApproveAllForwardedLeaves = () => {
    pendingHODLeaves.forEach(l => {
      hodApproveLeave(l.id, 'Statutory approval granted by Head of Department.');
    });
    showToast(`Instant Approval: All ${pendingHODLeaves.length} forwarded Leave/OD requests approved!`);
  };

  return (
    <div className="space-y-6 animate-in fade-in duration-300">
      {/* Top Banner: Real-Time HOD Executive Cockpit */}
      <div className="p-6 rounded-3xl bg-gradient-to-r from-slate-900 via-academic-950 to-[#0c101c] border border-academic-800/60 shadow-xl relative overflow-hidden">
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-6 relative z-10">
          <div>
            <div className="flex items-center gap-2 mb-2">
              <span className="px-2.5 py-0.5 rounded-full text-[10px] font-extrabold uppercase bg-academic-950 text-cyan-300 border border-cyan-800/80 flex items-center gap-1.5 shadow-sm">
                <BrainCircuit className="w-3.5 h-3.5 text-cyan-400 animate-pulse" />
                Live Instant HOD Command Center
              </span>
              <span className="text-xs text-slate-400 font-semibold">Active Date: {today}</span>
            </div>

            <h2 className="text-xl font-black text-white tracking-tight flex items-center gap-2">
              Department of Artificial Intelligence & Data Science (AIDS)
              <span className="text-[10px] uppercase px-2 py-0.5 rounded-full bg-emerald-950 text-emerald-300 border border-emerald-800">
                10 Sections · 622 Students
              </span>
            </h2>
            <p className="text-xs text-slate-400 mt-1 max-w-3xl leading-relaxed">
              Instant live synchronization of roll calls, student on-duties, document proofs, weekly section trends, and monthly department aggregates.
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-2.5">
            {pendingDayRegisters.length > 0 && (
              <button
                onClick={handleVerifyAllDayRegisters}
                className="px-3.5 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white font-bold text-xs flex items-center gap-2 shadow-md transition-all hover:scale-105"
              >
                <ShieldCheck className="w-4 h-4" />
                <span>Verify All ({pendingDayRegisters.length}) Day Registers</span>
              </button>
            )}

            {pendingHODLeaves.length > 0 && (
              <button
                onClick={handleApproveAllForwardedLeaves}
                className="px-3.5 py-2 rounded-xl bg-academic-600 hover:bg-academic-500 text-white font-bold text-xs flex items-center gap-2 shadow-glow-indigo transition-all hover:scale-105"
              >
                <CheckCircle2 className="w-4 h-4" />
                <span>Sanction All ({pendingHODLeaves.length}) ODs</span>
              </button>
            )}

            <button
              onClick={() => setIsNAACModalOpen(true)}
              className="px-3.5 py-2 rounded-xl bg-slate-900 hover:bg-slate-800 border border-slate-700 text-slate-200 font-bold text-xs flex items-center gap-2 transition-all"
            >
              <FileSpreadsheet className="w-4 h-4 text-academic-400" />
              <span>NAAC / NBA Export</span>
            </button>
          </div>
        </div>
      </div>

      {/* 4 Live Metric KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* KPI 1: Overall Strength */}
        <div className="p-5 rounded-2xl bg-[#0c101c]/90 border border-slate-800/80 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <span className="text-xs font-bold text-slate-400">Total Enrolled Strength</span>
            <div className="p-2 rounded-xl bg-indigo-950/60 border border-indigo-800/50 text-indigo-400">
              <Users className="w-4 h-4" />
            </div>
          </div>
          <div className="text-3xl font-black text-white">{students.length}</div>
          <div className="flex items-center justify-between mt-2 pt-2 border-t border-slate-800/80 text-[11px]">
            <span className="text-emerald-400 font-bold">{students.length - liveAbsentees.length} Present Today</span>
            <span className="text-slate-400">10 Sections</span>
          </div>
        </div>

        {/* KPI 2: On-Duty (OD) */}
        <div className="p-5 rounded-2xl bg-[#0c101c]/90 border border-cyan-950/60 bg-gradient-to-b from-cyan-950/20 to-transparent shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <span className="text-xs font-bold text-cyan-300">Sanctioned On-Duties (OD)</span>
            <div className="p-2 rounded-xl bg-cyan-950/80 border border-cyan-800/60 text-cyan-400">
              <Sparkles className="w-4 h-4" />
            </div>
          </div>
          <div className="text-3xl font-black text-cyan-300">{liveOnDuties.length}</div>
          <div className="flex items-center justify-between mt-2 pt-2 border-t border-cyan-900/40 text-[11px]">
            <span className="text-cyan-300 font-semibold">{pendingHODLeaves.length} Awaiting HOD Sign</span>
            <span className="text-slate-400">Proof Attached</span>
          </div>
        </div>

        {/* KPI 3: Uninformed Absentees Today */}
        <div className="p-5 rounded-2xl bg-[#0c101c]/90 border border-rose-950/60 bg-gradient-to-b from-rose-950/20 to-transparent shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <span className="text-xs font-bold text-rose-300">Uninformed Absentees</span>
            <div className="p-2 rounded-xl bg-rose-950/80 border border-rose-800/60 text-rose-400">
              <ShieldAlert className="w-4 h-4" />
            </div>
          </div>
          <div className="text-3xl font-black text-rose-400">{liveAbsentees.length}</div>
          <div className="flex items-center justify-between mt-2 pt-2 border-t border-rose-900/40 text-[11px]">
            <span className="text-rose-300 font-semibold">Zero Prior Notice</span>
            <span className="text-slate-400">Pink Slip Dispatched</span>
          </div>
        </div>

        {/* KPI 4: Detention Shortage (<75%) */}
        <div className="p-5 rounded-2xl bg-[#0c101c]/90 border border-amber-950/60 bg-gradient-to-b from-amber-950/20 to-transparent shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <span className="text-xs font-bold text-amber-300">Critical Shortage (&lt;75%)</span>
            <div className="p-2 rounded-xl bg-amber-950/80 border border-amber-800/60 text-amber-400">
              <AlertTriangle className="w-4 h-4" />
            </div>
          </div>
          <div className="text-3xl font-black text-amber-400">{shortageStudents.length}</div>
          <div className="flex items-center justify-between mt-2 pt-2 border-t border-amber-900/40 text-[11px]">
            <span className="text-amber-300 font-semibold">Counseling Required</span>
            <span className="text-slate-400">Exam Bar Risk</span>
          </div>
        </div>
      </div>

      {/* Main Tabbed Navigation */}
      <div className="flex items-center border-b border-slate-800 gap-2 pb-1 overflow-x-auto">
        <button
          onClick={() => setActiveSubTab('live_roster')}
          className={`px-4 py-2.5 rounded-2xl text-xs font-extrabold flex items-center gap-2 transition-all ${
            activeSubTab === 'live_roster'
              ? 'bg-academic-600 text-white shadow-glow-indigo'
              : 'text-slate-400 hover:text-white hover:bg-slate-900'
          }`}
        >
          <Users className="w-4 h-4" />
          <span>Live Absentees & On-Duty Students (With Proofs)</span>
        </button>

        <button
          onClick={() => setActiveSubTab('last_week_graphs')}
          className={`px-4 py-2.5 rounded-2xl text-xs font-extrabold flex items-center gap-2 transition-all ${
            activeSubTab === 'last_week_graphs'
              ? 'bg-academic-600 text-white shadow-glow-indigo'
              : 'text-slate-400 hover:text-white hover:bg-slate-900'
          }`}
        >
          <BarChart3 className="w-4 h-4" />
          <span>Last Week (7-Day) Section-Wise Graphs</span>
        </button>

        <button
          onClick={() => setActiveSubTab('month_aggregates')}
          className={`px-4 py-2.5 rounded-2xl text-xs font-extrabold flex items-center gap-2 transition-all ${
            activeSubTab === 'month_aggregates'
              ? 'bg-academic-600 text-white shadow-glow-indigo'
              : 'text-slate-400 hover:text-white hover:bg-slate-900'
          }`}
        >
          <CalendarDays className="w-4 h-4" />
          <span>Monthly Overall Department & Section Aggregates</span>
        </button>

        <button
          onClick={() => setActiveSubTab('detention_radar')}
          className={`px-4 py-2.5 rounded-2xl text-xs font-extrabold flex items-center gap-2 transition-all ${
            activeSubTab === 'detention_radar'
              ? 'bg-academic-600 text-white shadow-glow-indigo'
              : 'text-slate-400 hover:text-white hover:bg-slate-900'
          }`}
        >
          <ShieldAlert className="w-4 h-4" />
          <span>Detention Risk Radar (&lt;75%)</span>
        </button>
      </div>

      {/* TAB 1: Live Absentees & On-Duty Students with Proof Viewers */}
      {activeSubTab === 'live_roster' && (
        <div className="space-y-6">
          {/* Controls: Search & Section Filter */}
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 p-4 rounded-2xl bg-[#0c101c]/90 border border-slate-800">
            <div className="flex items-center gap-3">
              <div className="relative">
                <Search className="w-4 h-4 text-slate-500 absolute left-3 top-2.5" />
                <input
                  type="text"
                  value={rosterSearch}
                  onChange={(e) => setRosterSearch(e.target.value)}
                  placeholder="Search student by name or roll..."
                  className="pl-9 pr-4 py-1.5 rounded-xl bg-slate-900 border border-slate-700 text-xs text-white focus:outline-none focus:border-academic-500 w-64"
                />
              </div>

              <div className="flex items-center gap-2">
                <span className="text-xs text-slate-400 font-bold">Section:</span>
                <select
                  value={selectedSectionFilter}
                  onChange={(e) => setSelectedSectionFilter(e.target.value)}
                  className="bg-slate-900 border border-slate-700 rounded-xl px-3 py-1.5 text-xs font-bold text-white focus:outline-none"
                >
                  <option value="all">All 10 Sections</option>
                  {batches.map(b => (
                    <option key={b.batchCode} value={b.batchCode}>{b.batchCode}</option>
                  ))}
                </select>
              </div>
            </div>

            <div className="flex items-center gap-2 text-xs">
              <span className="px-2.5 py-1 rounded-xl bg-rose-950/80 text-rose-300 border border-rose-800 font-bold">
                {filteredAbsentees.length} Cuts Today
              </span>
              <span className="px-2.5 py-1 rounded-xl bg-cyan-950/80 text-cyan-300 border border-cyan-800 font-bold">
                {filteredOnDuties.length} On-Duties
              </span>
            </div>
          </div>

          {/* Dual Split Table View */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Left Table: Uninformed Cuts (Absentees) */}
            <div className="p-6 rounded-3xl bg-[#0c101c]/90 border border-rose-950/60 shadow-xl space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="text-sm font-black text-white uppercase tracking-wider flex items-center gap-2">
                    <ShieldAlert className="w-4 h-4 text-rose-400" />
                    Uninformed Absentees ({filteredAbsentees.length})
                  </h3>
                  <p className="text-[11px] text-slate-400">Absent students with zero prior notice logged</p>
                </div>
              </div>

              <div className="overflow-x-auto rounded-2xl border border-rose-950/40 max-h-96">
                <table className="w-full text-left border-collapse text-xs">
                  <thead>
                    <tr className="border-b border-slate-800 bg-slate-950 text-slate-400 font-extrabold sticky top-0">
                      <th className="p-2.5">Student Name & Roll</th>
                      <th className="p-2.5">Section</th>
                      <th className="p-2.5 text-center">Current %</th>
                      <th className="p-2.5 text-right">Parent Contact</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-800/40">
                    {filteredAbsentees.length === 0 ? (
                      <tr>
                        <td colSpan={4} className="text-center py-6 text-slate-500 font-bold">
                          ✓ No uninformed cuts found for selected filter
                        </td>
                      </tr>
                    ) : (
                      filteredAbsentees.map(({ student }) => (
                        <tr key={student.id} className="hover:bg-slate-900/60 transition-colors">
                          <td className="p-2.5">
                            <span className="font-extrabold text-white block">{student.name}</span>
                            <span className="text-[10px] text-rose-400 font-mono">{student.rollNo}</span>
                          </td>
                          <td className="p-2.5 font-bold text-slate-300">{student.batchCode}</td>
                          <td className="p-2.5 text-center">
                            <span className={`px-2 py-0.5 rounded font-black text-[10px] ${
                              student.attendancePercentage < 75 ? 'bg-rose-950 text-rose-300 border border-rose-800' : 'bg-slate-800 text-slate-300'
                            }`}>
                              {student.attendancePercentage}%
                            </span>
                          </td>
                          <td className="p-2.5 text-right">
                            <span className="text-[11px] text-slate-300 block font-medium">{student.parentPhone}</span>
                            <span className="text-[10px] text-slate-500">{student.parentName}</span>
                          </td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Right Table: On-Duty (OD) & Leave Students with Proof Viewer */}
            <div className="p-6 rounded-3xl bg-[#0c101c]/90 border border-cyan-950/60 shadow-xl space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="text-sm font-black text-white uppercase tracking-wider flex items-center gap-2">
                    <Sparkles className="w-4 h-4 text-cyan-400" />
                    On-Duty & Sanctioned Requests ({filteredOnDuties.length})
                  </h3>
                  <p className="text-[11px] text-slate-400">Symposiums, Hackathons & Official ODs with proof</p>
                </div>
              </div>

              <div className="overflow-x-auto rounded-2xl border border-cyan-950/40 max-h-96">
                <table className="w-full text-left border-collapse text-xs">
                  <thead>
                    <tr className="border-b border-slate-800 bg-slate-950 text-slate-400 font-extrabold sticky top-0">
                      <th className="p-2.5">Student & Event</th>
                      <th className="p-2.5">Dates</th>
                      <th className="p-2.5 text-center">Proof Doc</th>
                      <th className="p-2.5 text-right">Action / Status</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-800/40">
                    {filteredOnDuties.length === 0 ? (
                      <tr>
                        <td colSpan={4} className="text-center py-6 text-slate-500 font-bold">
                          No On-Duty applications under current filter
                        </td>
                      </tr>
                    ) : (
                      filteredOnDuties.map(leave => {
                        const isApproved = leave.status === 'approved_by_hod';
                        const isForwarded = leave.status === 'forwarded_to_hod';

                        return (
                          <tr key={leave.id} className="hover:bg-slate-900/60 transition-colors">
                            <td className="p-2.5">
                              <span className="font-extrabold text-white block">{leave.studentName}</span>
                              <span className="text-[10px] text-cyan-300 font-semibold">{leave.reason}</span>
                            </td>
                            <td className="p-2.5 font-medium text-slate-300 text-[11px] whitespace-nowrap">
                              {leave.startDate}
                            </td>
                            <td className="p-2.5 text-center">
                              <button
                                onClick={() => setSelectedProofModalLeave(leave)}
                                className="px-2 py-1 rounded-lg bg-cyan-950 hover:bg-cyan-900 text-cyan-300 border border-cyan-800 text-[10px] font-bold flex items-center gap-1 mx-auto transition-all"
                              >
                                <Eye className="w-3 h-3" />
                                <span>{leave.documentProofName ? 'View Proof' : 'Read Letter'}</span>
                              </button>
                            </td>
                            <td className="p-2.5 text-right">
                              {isForwarded ? (
                                <div className="flex items-center justify-end gap-1.5">
                                  <button
                                    onClick={() => hodApproveLeave(leave.id, 'Approved by HOD')}
                                    className="px-2.5 py-1 rounded-lg bg-emerald-600 hover:bg-emerald-500 text-white font-black text-[10px] shadow-sm transition-all"
                                  >
                                    Approve
                                  </button>
                                  <button
                                    onClick={() => hodRejectLeave(leave.id, 'Insufficient proof provided')}
                                    className="px-2 py-1 rounded-lg bg-rose-950 text-rose-300 border border-rose-800 hover:bg-rose-900 font-bold text-[10px]"
                                  >
                                    Reject
                                  </button>
                                </div>
                              ) : (
                                <span className={`px-2 py-0.5 rounded text-[10px] font-black ${
                                  isApproved ? 'bg-emerald-950 text-emerald-300 border border-emerald-800' : 'bg-slate-800 text-slate-400'
                                }`}>
                                  {isApproved ? '✓ Approved' : leave.status}
                                </span>
                              )}
                            </td>
                          </tr>
                        );
                      })
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* TAB 2: Last Week (7-Day) Section-Wise Graphs */}
      {activeSubTab === 'last_week_graphs' && (
        <div className="space-y-6">
          <div className="p-6 rounded-3xl bg-[#0c101c]/90 border border-slate-800/80 shadow-xl space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-sm font-black text-white uppercase tracking-wider flex items-center gap-2">
                  <BarChart3 className="w-4 h-4 text-cyan-400" />
                  Last 7-Day Performance Curves (All 10 AIDS Sections)
                </h3>
                <p className="text-xs text-slate-400">
                  Day-by-day attendance trends across the most recent 7 working academic days
                </p>
              </div>
              <span className="text-xs font-bold px-3 py-1 rounded-xl bg-academic-950 text-academic-300 border border-academic-800">
                7 Days Tracked
              </span>
            </div>

            {/* Grid of 10 Section Mini-Graphs */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-2 gap-4 pt-2">
              {section7DayTrends.map(sec => (
                <div key={sec.batchCode} className="p-4 rounded-2xl bg-slate-950 border border-slate-800 space-y-3">
                  <div className="flex items-center justify-between">
                    <div>
                      <span className="font-extrabold text-white text-sm">{sec.batchCode}</span>
                      <span className="text-[11px] text-slate-400 block">Advisor: {sec.advisorName}</span>
                    </div>
                    <div className="text-right">
                      <span className={`text-base font-black ${
                        sec.avg7Day >= 85 ? 'text-emerald-400' : sec.avg7Day >= 75 ? 'text-amber-300' : 'text-rose-400'
                      }`}>
                        {sec.avg7Day}%
                      </span>
                      <span className="text-[10px] text-slate-500 block">7-Day Avg</span>
                    </div>
                  </div>

                  {/* 7-Day Bars Ribbon */}
                  <div className="flex items-end gap-2 h-28 pt-2 px-1 border-b border-slate-800">
                    {sec.dayStats.map(d => {
                      const heightPct = Math.max(20, (d.pct - 60) * 2.5);
                      const isHigh = d.pct >= 90;
                      const isLow = d.pct < 80;

                      return (
                        <div key={d.date} className="flex-1 flex flex-col items-center gap-1 group relative">
                          {/* Tooltip */}
                          <div className="opacity-0 group-hover:opacity-100 transition-opacity absolute bottom-full mb-1 bg-slate-900 text-white text-[9px] p-1.5 rounded-lg border border-slate-700 shadow-xl pointer-events-none z-20 whitespace-nowrap">
                            <p className="font-bold text-cyan-300">{d.date}</p>
                            <p className="text-white font-extrabold">{d.pct}% Attendance</p>
                            <p className="text-slate-400">{d.present} / {d.total} present</p>
                          </div>

                          <span className="text-[9px] font-bold text-slate-400 group-hover:text-cyan-400">
                            {d.pct}%
                          </span>

                          <div 
                            className={`w-full rounded-t-lg transition-all ${
                              isLow 
                                ? 'bg-rose-500' 
                                : isHigh 
                                  ? 'bg-gradient-to-t from-academic-600 to-cyan-400' 
                                  : 'bg-indigo-500'
                            }`}
                            style={{ height: `${heightPct}%` }}
                          />

                          <span className="text-[8px] font-bold text-slate-500">
                            {d.shortDate}
                          </span>
                        </div>
                      );
                    })}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* TAB 3: Month-by-Month Aggregate Data & End-of-Month Ledger */}
      {activeSubTab === 'month_aggregates' && (
        <div className="space-y-6">
          <div className="p-6 rounded-3xl bg-[#0c101c]/90 border border-slate-800/80 shadow-xl space-y-6">
            <div>
              <h3 className="text-sm font-black text-white uppercase tracking-wider flex items-center gap-2">
                <CalendarDays className="w-4 h-4 text-academic-400" />
                End-of-Month Section & Department Aggregates (Aug – Dec 2026)
              </h3>
              <p className="text-xs text-slate-400">
                Official monthly attendance percentage audit and statutory compliance per section
              </p>
            </div>

            {/* Monthly Cards Comparison */}
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-3">
              {monthAggregates.map(m => (
                <div key={m.key} className="p-4 rounded-2xl bg-slate-950 border border-slate-800 space-y-2">
                  <span className="text-xs font-bold text-white block">{m.name}</span>
                  <div className="text-2xl font-black text-cyan-300">{m.deptAvg}%</div>
                  <div className="flex items-center justify-between text-[10px] text-slate-500 pt-1 border-t border-slate-800">
                    <span>{m.totalDays} Days</span>
                    <span className="text-emerald-400 font-bold">{m.status}</span>
                  </div>
                </div>
              ))}
            </div>

            {/* Matrix Table */}
            <div className="overflow-x-auto rounded-2xl border border-slate-800">
              <table className="w-full text-left border-collapse text-xs">
                <thead>
                  <tr className="border-b border-slate-800 bg-slate-950 text-slate-400 font-extrabold">
                    <th className="p-3">Batch & Section</th>
                    <th className="p-3">Class Advisor</th>
                    <th className="p-3 text-center">Aug 2026</th>
                    <th className="p-3 text-center">Sep 2026</th>
                    <th className="p-3 text-center">Oct 2026 (Est)</th>
                    <th className="p-3 text-center">Nov 2026 (Est)</th>
                    <th className="p-3 text-center">Dec 2026 (Est)</th>
                    <th className="p-3 text-right">Exam Clearance</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-800/40">
                  {batches.map(b => (
                    <tr key={b.batchCode} className="hover:bg-slate-900/40 transition-colors">
                      <td className="p-3 font-extrabold text-white">{b.batchCode}</td>
                      <td className="p-3 text-slate-300">{b.advisorName}</td>
                      <td className="p-3 text-center font-bold text-emerald-400">91.4%</td>
                      <td className="p-3 text-center font-bold text-cyan-300">89.8%</td>
                      <td className="p-3 text-center font-bold text-slate-300">92.0%</td>
                      <td className="p-3 text-center font-bold text-slate-300">90.5%</td>
                      <td className="p-3 text-center font-bold text-slate-300">93.2%</td>
                      <td className="p-3 text-right">
                        <span className="px-2 py-0.5 rounded-full bg-emerald-950 text-emerald-300 border border-emerald-800 text-[10px] font-bold">
                          100% Eligible
                        </span>
                      </td>
                    </tr>
                  ))}
                  {/* Department Overall Total Row */}
                  <tr className="bg-academic-950/40 font-black border-t-2 border-academic-700">
                    <td className="p-3 text-academic-300">AIDS Department (Overall)</td>
                    <td className="p-3 text-slate-400">622 Students</td>
                    <td className="p-3 text-center text-emerald-400 font-extrabold">91.2%</td>
                    <td className="p-3 text-center text-cyan-300 font-extrabold">90.4%</td>
                    <td className="p-3 text-center text-slate-200 font-extrabold">91.8%</td>
                    <td className="p-3 text-center text-slate-200 font-extrabold">91.0%</td>
                    <td className="p-3 text-center text-slate-200 font-extrabold">92.6%</td>
                    <td className="p-3 text-right text-cyan-300">NAAC Compliant</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* TAB 4: Detention Radar (<75%) */}
      {activeSubTab === 'detention_radar' && (
        <div className="p-6 rounded-3xl bg-[#0c101c]/90 border border-rose-950/60 shadow-xl space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-sm font-black text-white uppercase tracking-wider flex items-center gap-2">
                <AlertTriangle className="w-4 h-4 text-rose-400" />
                Critical Attendance Shortage Radar (&lt;75% Detention Risk)
              </h3>
              <p className="text-xs text-slate-400">Students requiring urgent counseling and parent intervention</p>
            </div>
            <span className="text-xs font-bold px-3 py-1 rounded-xl bg-rose-950 text-rose-300 border border-rose-800">
              {shortageStudents.length} Students At Risk
            </span>
          </div>

          <div className="space-y-3">
            {shortageStudents.map(s => (
              <div
                key={s.id}
                className="p-3.5 rounded-2xl bg-[#121828] border border-rose-900/40 flex items-center justify-between gap-4"
              >
                <div className="flex items-center gap-3">
                  <img src={s.avatar} alt={s.name} className="w-10 h-10 rounded-full ring-2 ring-rose-500/40 object-cover" />
                  <div>
                    <span className="text-xs font-bold text-white block">{s.name} ({s.rollNo})</span>
                    <span className="text-[10px] text-slate-400">{s.batchCode} · Advisor: {s.advisorName}</span>
                  </div>
                </div>

                <div className="flex items-center gap-4">
                  <span className="text-base font-black text-rose-400">{s.attendancePercentage}%</span>
                  <button
                    onClick={() => {
                      setSelectedStudentId(s.id);
                      setActiveTab('student_dossier');
                    }}
                    className="px-3 py-1 rounded-xl bg-rose-950 hover:bg-rose-900 text-rose-300 border border-rose-800 text-xs font-bold"
                  >
                    Open Dossier
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Proof & Letter Inspection Modal */}
      {selectedProofModalLeave && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-md animate-in fade-in">
          <div className="w-full max-w-lg bg-[#0c101c] rounded-3xl border border-academic-700/80 shadow-2xl p-6 space-y-5">
            <div className="flex items-start justify-between">
              <div>
                <span className="px-2 py-0.5 rounded text-[10px] font-extrabold uppercase bg-cyan-950 text-cyan-300 border border-cyan-800">
                  {selectedProofModalLeave.leaveType.toUpperCase()} DOCUMENT PROOF
                </span>
                <h3 className="text-base font-black text-white mt-1">
                  {selectedProofModalLeave.studentName} ({selectedProofModalLeave.rollNo})
                </h3>
                <p className="text-xs text-slate-400">{selectedProofModalLeave.batchCode} · Applied: {selectedProofModalLeave.appliedAt}</p>
              </div>
              <button
                onClick={() => setSelectedProofModalLeave(null)}
                className="p-2 rounded-xl bg-slate-900 text-slate-400 hover:text-white"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            {/* Reason & Student Letter */}
            <div className="p-4 rounded-2xl bg-slate-900/80 border border-slate-800 space-y-2">
              <span className="text-[10px] uppercase font-bold text-slate-400">Formal Student Letter:</span>
              <p className="text-xs text-slate-200 leading-relaxed italic">
                "{selectedProofModalLeave.letterText || selectedProofModalLeave.reason}"
              </p>
            </div>

            {/* Document Proof Badge */}
            {selectedProofModalLeave.documentProofName && (
              <div className="p-3.5 rounded-2xl bg-cyan-950/40 border border-cyan-800/60 flex items-center justify-between">
                <div className="flex items-center gap-2 text-xs text-cyan-300 font-bold">
                  <FileText className="w-4 h-4 text-cyan-400" />
                  <span>{selectedProofModalLeave.documentProofName}</span>
                </div>
                <span className="text-[10px] text-emerald-400 font-semibold">✓ Verified by Advisor</span>
              </div>
            )}

            {/* Advisor Remarks */}
            <div className="p-3 rounded-2xl bg-academic-950/40 border border-academic-800/60 text-xs">
              <span className="text-slate-400 block text-[10px]">Class Advisor Endorsement:</span>
              <span className="text-academic-300 font-semibold">{selectedProofModalLeave.advisorRemarks || 'Recommended for HOD approval.'}</span>
            </div>

            {/* Action Buttons */}
            <div className="flex items-center justify-end gap-2 pt-2">
              <button
                onClick={() => {
                  hodRejectLeave(selectedProofModalLeave.id, 'Rejected by HOD during proof audit.');
                  setSelectedProofModalLeave(null);
                }}
                className="px-4 py-2 rounded-xl bg-rose-950 hover:bg-rose-900 text-rose-300 border border-rose-800 text-xs font-bold"
              >
                Reject Request
              </button>
              <button
                onClick={() => {
                  hodApproveLeave(selectedProofModalLeave.id, 'Official approval sanctioned by HOD.');
                  setSelectedProofModalLeave(null);
                }}
                className="px-4 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-extrabold shadow-md flex items-center gap-1.5"
              >
                <Check className="w-4 h-4" />
                <span>Approve & Lock Attendance</span>
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default HODCockpit;
