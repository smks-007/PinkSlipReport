import React, { useState } from 'react';
import { 
  UserCheck, 
  Calendar, 
  FileText, 
  CheckCircle2, 
  XCircle, 
  AlertTriangle, 
  Sparkles, 
  ExternalLink,
  ShieldCheck,
  Search,
  Filter,
  FileSpreadsheet
} from 'lucide-react';
import { useAttendance } from '../../context/AttendanceContext';
import { PinkSlipPassModal } from './PinkSlipPassModal';

export const StudentDossier: React.FC = () => {
  const { students, selectedStudentId, setSelectedStudentId, batches } = useAttendance();

  const [selectedBatchFilter, setSelectedBatchFilter] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [isPinkSlipModalOpen, setIsPinkSlipModalOpen] = useState(false);

  const filteredStudents = students.filter(s => {
    const matchesBatch = selectedBatchFilter === 'all' || s.batchCode === selectedBatchFilter;
    const matchesSearch = !searchQuery.trim() || 
      s.name.toLowerCase().includes(searchQuery.toLowerCase()) || 
      s.rollNo.includes(searchQuery) ||
      s.regNo.includes(searchQuery);
    return matchesBatch && matchesSearch;
  });

  const student = students.find(s => s.id === selectedStudentId) || filteredStudents[0] || students[0];

  const statusColors = {
    present: 'bg-emerald-500/20 text-emerald-300 border-emerald-500/50',
    leave_od: 'bg-cyan-500/20 text-cyan-300 border-cyan-500/50',
    leave_prior_cl: 'bg-blue-500/20 text-blue-300 border-blue-500/50',
    leave_ml: 'bg-purple-500/20 text-purple-300 border-purple-500/50',
    absent_uninformed: 'bg-rose-500/20 text-rose-300 border-rose-500/50'
  };

  const statusLabels = {
    present: 'P',
    leave_od: 'OD',
    leave_prior_cl: 'CL',
    leave_ml: 'ML',
    absent_uninformed: 'A'
  };

  return (
    <div className="space-y-6">
      {/* Student Selector Toolbar */}
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 p-4 rounded-3xl glass-panel border-slate-800">
        <div>
          <h2 className="text-base font-bold text-white tracking-tight">
            AIDS Student 360° Attendance & Leave Dossier
          </h2>
          <p className="text-xs text-slate-400 mt-0.5">
            Full chronological logbook of every single absence, proof attachment & 8-period heatmap.
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-3">
          {/* Batch Selector Filter */}
          <select
            value={selectedBatchFilter}
            onChange={(e) => setSelectedBatchFilter(e.target.value)}
            className="px-3 py-2 text-xs font-bold rounded-xl bg-[#121828] border border-slate-700 text-white focus:outline-none"
          >
            <option value="all">All Sections ({students.length} Students)</option>
            {batches.map(b => (
              <option key={b.id} value={b.batchCode}>
                {b.yearName} - Sec {b.section} ({b.batchCode})
              </option>
            ))}
          </select>

          {/* Student Selector */}
          <div className="relative">
            <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
            <select
              value={student?.id || ''}
              onChange={(e) => setSelectedStudentId(e.target.value)}
              className="pl-9 pr-8 py-2 text-xs font-bold rounded-xl bg-[#121828] border border-slate-700 text-white focus:outline-none max-w-xs"
            >
              {filteredStudents.map(s => (
                <option key={s.id} value={s.id}>
                  {s.name} ({s.rollNo} · {s.batchCode})
                </option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {student && (
        <>
          {/* Student Profile Card */}
          <div className="p-6 rounded-3xl glass-panel border-slate-800 grid grid-cols-1 lg:grid-cols-12 gap-6 items-center">
            <div className="lg:col-span-8 flex flex-col sm:flex-row items-start sm:items-center gap-5">
              <img
                src={student.avatar}
                alt={student.name}
                className="w-20 h-20 rounded-2xl object-cover ring-4 ring-academic-500/30 shadow-glow-indigo"
              />
              <div>
                <div className="flex items-center gap-2.5">
                  <h3 className="text-lg font-black text-white">{student.name}</h3>
                  <span className="text-xs font-mono font-bold px-2 py-0.5 rounded bg-slate-800 text-cyan-300">
                    E.Code: {student.rollNo}
                  </span>
                </div>
                <p className="text-xs text-slate-400 mt-1">
                  Reg No: {student.regNo} · {student.batchCode} ({student.yearLevel === 2 ? '2nd Year' : student.yearLevel === 3 ? '3rd Year' : '4th Year'}) · Advisor: {student.advisorName}
                </p>
                <div className="flex flex-wrap gap-2 mt-3 text-[11px] text-slate-300">
                  <span className="px-2.5 py-0.5 rounded-lg bg-[#121828] border border-slate-800">
                    👨‍👩‍👦 {student.parentName}
                  </span>
                  <span className="px-2.5 py-0.5 rounded-lg bg-[#121828] border border-slate-800 text-cyan-400">
                    📞 {student.parentPhone}
                  </span>
                  <span className="px-2.5 py-0.5 rounded-lg bg-[#121828] border border-slate-800 text-slate-400">
                    ✉️ {student.parentEmail}
                  </span>
                </div>
              </div>
            </div>

            {/* Overall Percentage Stat & Generate Pink Slip CTA */}
            <div className="lg:col-span-4 p-4 rounded-2xl bg-[#121828] border border-slate-800 text-center space-y-2">
              <span className="text-xs font-bold text-slate-400 block uppercase tracking-wider">Overall Aggregate</span>
              <div className={`text-3xl font-black ${
                student.attendancePercentage < 75 ? 'text-rose-400' : 'text-emerald-400'
              }`}>
                {student.attendancePercentage}%
              </div>
              <span className="text-[11px] text-slate-400 block">
                {student.attendedPeriods} / {student.totalConductedPeriods} Periods Attended
              </span>

              <button
                onClick={() => setIsPinkSlipModalOpen(true)}
                className="w-full py-2 rounded-xl bg-academic-600 hover:bg-academic-500 text-white font-bold text-xs shadow-glow-indigo transition-all flex items-center justify-center gap-1.5 mt-2"
              >
                <FileText className="w-3.5 h-3.5" />
                <span>Generate Digital Pink Slip Pass</span>
              </button>
            </div>
          </div>

          {/* 8-Period Heatmap Calendar */}
          <div className="p-6 rounded-3xl glass-panel border-slate-800 space-y-4">
            <div className="flex items-center justify-between">
              <h4 className="text-sm font-bold text-white flex items-center gap-2">
                <Calendar className="w-4 h-4 text-academic-400" />
                <span>8-Period Attendance Matrix (Recent Academic Days)</span>
              </h4>

              {/* Legend */}
              <div className="flex flex-wrap items-center gap-2 text-[10px] font-bold">
                <span className="px-2 py-0.5 rounded bg-emerald-950 text-emerald-300 border border-emerald-800">P = Present</span>
                <span className="px-2 py-0.5 rounded bg-blue-950 text-blue-300 border border-blue-800">CL = Prior Leave</span>
                <span className="px-2 py-0.5 rounded bg-cyan-950 text-cyan-300 border border-cyan-800">OD = On-Duty</span>
                <span className="px-2 py-0.5 rounded bg-purple-950 text-purple-300 border border-purple-800">ML = Medical</span>
                <span className="px-2 py-0.5 rounded bg-rose-950 text-rose-300 border border-rose-800">A = Uninformed Cut</span>
              </div>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs border-collapse">
                <thead>
                  <tr className="border-b border-slate-800 text-[11px] text-slate-400 font-bold">
                    <th className="py-2.5 px-3">Date</th>
                    {[1,2,3,4,5,6,7,8].map(p => (
                      <th key={p} className="py-2.5 px-2 text-center">Period {p}</th>
                    ))}
                    <th className="py-2.5 px-3 text-right">Daily Summary</th>
                  </tr>
                </thead>
                <tbody>
                  {Object.entries(student.recentAttendance).map(([date, periods]) => {
                    const dayPresents = periods.filter(p => p === 'present' || p === 'leave_od').length;
                    return (
                      <tr key={date} className="border-b border-slate-800/60 hover:bg-[#121828]/50">
                        <td className="py-2.5 px-3 font-semibold text-white">{date}</td>
                        {periods.map((st, idx) => (
                          <td key={idx} className="py-2.5 px-1.5 text-center">
                            <span className={`inline-block w-8 py-1 rounded-lg text-[10px] font-extrabold border ${statusColors[st]}`}>
                              {statusLabels[st]}
                            </span>
                          </td>
                        ))}
                        <td className="py-2.5 px-3 text-right font-bold text-slate-300">
                          {dayPresents}/8 Periods ({((dayPresents/8)*100).toFixed(0)}%)
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>

          {/* Subject-wise Breakdown & Leave History */}
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
            {/* Subject-wise bars */}
            <div className="lg:col-span-5 p-6 rounded-3xl glass-panel border-slate-800 space-y-4">
              <h4 className="text-sm font-bold text-white">Subject-wise Attendance Breakdown</h4>
              <div className="space-y-3">
                {student.subjectAttendance.map((sub, i) => (
                  <div key={i} className="space-y-1">
                    <div className="flex justify-between text-xs font-semibold">
                      <span className="text-slate-300">{sub.subjectName} ({sub.subjectCode})</span>
                      <span className={sub.percentage < 75 ? 'text-rose-400 font-bold' : 'text-emerald-400 font-bold'}>
                        {sub.percentage}%
                      </span>
                    </div>
                    <div className="w-full h-2 rounded-full bg-slate-800 overflow-hidden relative">
                      <div
                        style={{ width: `${sub.percentage}%` }}
                        className={`h-full rounded-full ${sub.percentage < 75 ? 'bg-rose-500' : 'bg-academic-500'}`}
                      />
                      <div className="absolute top-0 bottom-0 left-[75%] w-0.5 bg-white/50" title="75% Min Threshold" />
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Leave Logbook */}
            <div className="lg:col-span-7 p-6 rounded-3xl glass-panel border-slate-800 space-y-4">
              <h4 className="text-sm font-bold text-white">Full Chronological Leave History Log</h4>
              {student.leaveHistory.length === 0 ? (
                <div className="p-8 text-center text-xs text-slate-500">No prior leaves logged.</div>
              ) : (
                <div className="space-y-3">
                  {student.leaveHistory.map(l => (
                    <div key={l.id} className="p-3.5 rounded-2xl bg-[#121828] border border-slate-800 text-xs space-y-2">
                      <div className="flex justify-between items-start">
                        <div>
                          <span className="text-[10px] font-extrabold uppercase px-2 py-0.5 rounded bg-slate-800 text-cyan-300">
                            {l.leaveType.toUpperCase()}
                          </span>
                          <h5 className="font-bold text-white mt-1">{l.reason}</h5>
                        </div>
                        <span className="text-[10px] text-slate-400">{l.startDate}</span>
                      </div>

                      {l.documentProofName && (
                        <div className="flex items-center justify-between text-[11px] text-cyan-400">
                          <span>📄 {l.documentProofName}</span>
                          <span className="text-emerald-400 font-semibold">✓ {l.hodName || l.advisorName || 'Approved by HOD'}</span>
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>

          {/* Digital Pink Slip Modal */}
          <PinkSlipPassModal
            isOpen={isPinkSlipModalOpen}
            onClose={() => setIsPinkSlipModalOpen(false)}
            student={student}
          />
        </>
      )}
    </div>
  );
};
