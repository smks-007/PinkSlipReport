import React, { useState } from 'react';
import { 
  FileCheck2, 
  ShieldAlert, 
  Plus, 
  Check, 
  X, 
  FileText, 
  ExternalLink, 
  PhoneCall, 
  MessageSquare, 
  Send, 
  AlertTriangle, 
  Upload, 
  UserCheck,
  Filter
} from 'lucide-react';
import { useAttendance } from '../../context/AttendanceContext';
import { LeaveType } from '../../types';

export const LeaveTriageCenter: React.FC = () => {
  const { 
    pendingLeaves, 
    allLeaves, 
    approveLeave, 
    rejectLeave, 
    applyNewLeave, 
    students,
    batches,
    currentUserRole 
  } = useAttendance();

  const [activeSubTab, setActiveSubTab] = useState<'pending' | 'uninformed' | 'apply'>('pending');
  const [selectedBatchFilter, setSelectedBatchFilter] = useState<string>('all');

  // Form State for applying new leave
  const [studentId, setStudentId] = useState(students[0]?.id || 's-25243001');
  const [leaveType, setLeaveType] = useState<LeaveType>('prior_cl');
  const [startDate, setStartDate] = useState('2026-09-03');
  const [endDate, setEndDate] = useState('2026-09-03');
  const [startPeriod, setStartPeriod] = useState(1);
  const [endPeriod, setEndPeriod] = useState(8);
  const [reason, setReason] = useState('');
  const [docName, setDocName] = useState('Proof_Document.pdf');
  const [parentConsent, setParentConsent] = useState(true);

  const selectedStudent = students.find(s => s.id === studentId) || students[0];

  const handleApplySubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!reason.trim()) return;

    applyNewLeave({
      studentId: selectedStudent.id,
      studentName: selectedStudent.name,
      rollNo: selectedStudent.rollNo,
      batchCode: selectedStudent.batchCode,
      leaveType,
      startDate,
      endDate,
      startPeriod,
      endPeriod,
      totalDays: 1,
      reason,
      documentProofName: docName,
      documentProofUrl: 'https://smartcampus-s3.amazonaws.com/proofs/' + docName,
      parentConsent
    });

    setReason('');
    setActiveSubTab('pending');
  };

  // Filter uninformed absentees (red flags)
  const uninformedAbsentees = students.filter(s => 
    s.uninformedAbsencesCount > 0 &&
    (selectedBatchFilter === 'all' || s.batchCode === selectedBatchFilter)
  );

  const filteredPendingLeaves = pendingLeaves.filter(l => 
    selectedBatchFilter === 'all' || l.batchCode === selectedBatchFilter
  );

  return (
    <div className="space-y-6">
      {/* Sub Tabs */}
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 p-4 rounded-3xl glass-panel border-slate-800">
        <div>
          <h2 className="text-base font-bold text-white tracking-tight">
            AIDS Department — Prior Leave vs Uninformed Absence Triage
          </h2>
          <p className="text-xs text-slate-400 mt-0.5">
            Differentiate authorized prior casual/OD/medical leaves from unapproved cuts across 2nd, 3rd & 4th years.
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-3">
          {/* Batch Filter */}
          <select
            value={selectedBatchFilter}
            onChange={(e) => setSelectedBatchFilter(e.target.value)}
            className="px-3 py-1.5 text-xs font-bold rounded-xl bg-[#121828] border border-slate-700 text-white focus:outline-none"
          >
            <option value="all">All AIDS Sections</option>
            {batches.map(b => (
              <option key={b.id} value={b.batchCode}>{b.batchCode}</option>
            ))}
          </select>

          <div className="flex items-center gap-1.5 p-1 bg-[#121828] rounded-xl text-xs font-bold border border-slate-800">
            <button
              onClick={() => setActiveSubTab('pending')}
              className={`px-3.5 py-1.5 rounded-lg transition-all ${
                activeSubTab === 'pending'
                  ? 'bg-academic-600 text-white shadow-sm'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              Pending ({filteredPendingLeaves.length})
            </button>
            <button
              onClick={() => setActiveSubTab('uninformed')}
              className={`px-3.5 py-1.5 rounded-lg transition-all ${
                activeSubTab === 'uninformed'
                  ? 'bg-rose-600 text-white shadow-sm'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              Uninformed Cuts ({uninformedAbsentees.length})
            </button>
            <button
              onClick={() => setActiveSubTab('apply')}
              className={`px-3.5 py-1.5 rounded-lg transition-all ${
                activeSubTab === 'apply'
                  ? 'bg-cyan-600 text-white shadow-sm'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              + Apply Leave
            </button>
          </div>
        </div>
      </div>

      {/* Tab 1: Pending Approvals Queue */}
      {activeSubTab === 'pending' && (
        <div className="space-y-4">
          {filteredPendingLeaves.length === 0 ? (
            <div className="p-12 rounded-3xl glass-panel border-slate-800 text-center text-slate-400">
              <UserCheck className="w-10 h-10 mx-auto text-emerald-400 mb-2" />
              <h3 className="text-sm font-bold text-white">All Prior Leave Requests Reviewed</h3>
              <p className="text-xs text-slate-500 mt-1">No pending applications awaiting Class Advisor / HOD approval for selected filter.</p>
            </div>
          ) : (
            filteredPendingLeaves.map(leave => (
              <div
                key={leave.id}
                className="p-5 rounded-3xl glass-panel border-slate-800 hover:border-academic-500/40 transition-all space-y-4"
              >
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-2xl bg-academic-500/10 text-academic-400 flex items-center justify-center font-black">
                      {leave.leaveType === 'on_duty_od' ? 'OD' : leave.leaveType === 'medical_ml' ? 'ML' : 'CL'}
                    </div>
                    <div>
                      <div className="flex items-center gap-2">
                        <h4 className="text-sm font-bold text-white">{leave.studentName}</h4>
                        <span className="text-[10px] font-mono px-1.5 py-0.5 rounded bg-slate-800 text-slate-300">{leave.rollNo}</span>
                        <span className="text-[10px] font-extrabold uppercase px-2 py-0.5 rounded-full bg-academic-950 text-cyan-300 border border-cyan-800">
                          {leave.leaveType.toUpperCase()}
                        </span>
                      </div>
                      <p className="text-xs text-slate-400">{leave.batchCode} · Applied: {leave.appliedAt}</p>
                    </div>
                  </div>

                  <div className="text-right">
                    <span className="text-xs font-bold text-white block">
                      {leave.startDate} to {leave.endDate}
                    </span>
                    <span className="text-[10px] text-slate-400">Periods {leave.startPeriod} to {leave.endPeriod} ({leave.totalDays} Day)</span>
                  </div>
                </div>

                <div className="p-3.5 rounded-2xl bg-[#121828] border border-slate-800 text-xs text-slate-300 leading-relaxed">
                  <span className="font-bold text-slate-400 block mb-1">Reason:</span>
                  {leave.reason}
                </div>

                {leave.documentProofName && (
                  <div className="flex items-center justify-between p-3 rounded-xl bg-academic-950/40 border border-academic-900 text-xs text-academic-300">
                    <div className="flex items-center gap-2">
                      <FileText className="w-4 h-4 text-cyan-400" />
                      <span>{leave.documentProofName} (AWS S3 Cloud Verified)</span>
                    </div>
                    <a
                      href={leave.documentProofUrl || '#'}
                      target="_blank"
                      rel="noreferrer"
                      className="text-[11px] font-bold text-cyan-400 hover:underline flex items-center gap-1"
                    >
                      <span>Preview Doc</span>
                      <ExternalLink className="w-3 h-3" />
                    </a>
                  </div>
                )}

                {/* Actions */}
                <div className="flex items-center justify-between pt-2 border-t border-slate-800/80">
                  <span className="text-[11px] text-emerald-400 font-semibold flex items-center gap-1">
                    <Check className="w-3.5 h-3.5" /> Parent Consent Verified
                  </span>

                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => rejectLeave(leave.id, 'HOD / Advisor', 'Rejected')}
                      className="px-3.5 py-2 text-xs font-bold rounded-xl bg-rose-950 hover:bg-rose-900 border border-rose-800 text-rose-300 flex items-center gap-1.5 transition-all"
                    >
                      <X className="w-3.5 h-3.5" />
                      <span>Reject</span>
                    </button>

                    <button
                      onClick={() => approveLeave(leave.id, 'HOD / Advisor', 'Approved with Prior Notice')}
                      className="px-4 py-2 text-xs font-bold rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white shadow-glow-emerald flex items-center gap-1.5 transition-all"
                    >
                      <Check className="w-3.5 h-3.5" />
                      <span>Approve as {leave.leaveType.toUpperCase()}</span>
                    </button>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      )}

      {/* Tab 2: Uninformed Absence Investigation Log */}
      {activeSubTab === 'uninformed' && (
        <div className="space-y-4">
          <div className="p-4 rounded-2xl bg-rose-950/20 border border-rose-900/50 flex items-center gap-3 text-xs text-rose-300">
            <AlertTriangle className="w-5 h-5 flex-shrink-0 text-rose-400" />
            <span>
              Showing {uninformedAbsentees.length} AIDS students marked absent with <strong>zero prior notice</strong>. Automated SMS/WhatsApp notifications are scheduled for daily 4:30 PM dispatch.
            </span>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 max-h-[600px] overflow-y-auto pr-1">
            {uninformedAbsentees.map(s => (
              <div
                key={s.id}
                className="p-5 rounded-3xl glass-panel border-rose-900/40 bg-gradient-to-b from-rose-950/10 to-transparent space-y-3"
              >
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <img src={s.avatar} alt={s.name} className="w-10 h-10 rounded-full ring-2 ring-rose-500/40 object-cover" />
                    <div>
                      <h4 className="text-xs font-bold text-white">{s.name}</h4>
                      <span className="text-[10px] font-mono text-slate-400">{s.rollNo} · {s.batchCode}</span>
                    </div>
                  </div>

                  <span className="text-xs font-black text-rose-400 bg-rose-950 px-2.5 py-1 rounded-full border border-rose-800">
                    {s.uninformedAbsencesCount} Cuts
                  </span>
                </div>

                <div className="p-3 rounded-xl bg-[#121828] border border-slate-800 text-[11px] text-slate-300 space-y-1">
                  <div className="flex justify-between">
                    <span className="text-slate-400">Guardian Name:</span>
                    <span className="font-semibold">{s.parentName}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-400">Contact Number:</span>
                    <span className="font-semibold text-cyan-400">{s.parentPhone}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-400">Current Aggregate:</span>
                    <span className="font-bold text-rose-400">{s.attendancePercentage}%</span>
                  </div>
                </div>

                <div className="flex items-center gap-2 pt-1">
                  <a
                    href={`tel:${s.parentPhone}`}
                    className="flex-1 py-2 rounded-xl bg-[#121828] hover:bg-slate-800 border border-slate-700 text-slate-200 text-xs font-bold flex items-center justify-center gap-1.5 transition-colors"
                  >
                    <PhoneCall className="w-3.5 h-3.5 text-cyan-400" />
                    <span>Call Guardian</span>
                  </a>
                  <button
                    onClick={() => alert(`Automated SMS & WhatsApp reminder triggered to ${s.parentPhone}`)}
                    className="flex-1 py-2 rounded-xl bg-rose-600 hover:bg-rose-500 text-white text-xs font-bold flex items-center justify-center gap-1.5 shadow-glow-rose transition-all"
                  >
                    <Send className="w-3.5 h-3.5" />
                    <span>Send Cut Alert</span>
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Tab 3: New Prior Leave Application Form */}
      {activeSubTab === 'apply' && (
        <div className="max-w-2xl mx-auto p-6 rounded-3xl glass-panel border-slate-800">
          <h3 className="text-base font-bold text-white mb-4">Submit Prior Leave Application</h3>

          <form onSubmit={handleApplySubmit} className="space-y-4">
            <div>
              <label className="block text-xs font-bold text-slate-400 mb-1">Select AIDS Student</label>
              <select
                value={studentId}
                onChange={(e) => setStudentId(e.target.value)}
                className="w-full p-2.5 text-xs font-bold rounded-xl bg-[#121828] border border-slate-700 text-white"
              >
                {students.map(s => (
                  <option key={s.id} value={s.id}>{s.name} ({s.rollNo} · {s.batchCode})</option>
                ))}
              </select>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-bold text-slate-400 mb-1">Leave Category</label>
                <select
                  value={leaveType}
                  onChange={(e) => setLeaveType(e.target.value as LeaveType)}
                  className="w-full p-2.5 text-xs font-bold rounded-xl bg-[#121828] border border-slate-700 text-white"
                >
                  <option value="prior_cl">Prior Casual Leave (CL)</option>
                  <option value="on_duty_od">On-Duty Leave (OD - Event / Symposium)</option>
                  <option value="medical_ml">Medical Leave (ML - Doctor Verified)</option>
                </select>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-400 mb-1">Date</label>
                <input
                  type="date"
                  value={startDate}
                  onChange={(e) => {
                    setStartDate(e.target.value);
                    setEndDate(e.target.value);
                  }}
                  className="w-full p-2.5 text-xs font-bold rounded-xl bg-[#121828] border border-slate-700 text-white"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-bold text-slate-400 mb-1">Start Period</label>
                <select
                  value={startPeriod}
                  onChange={(e) => setStartPeriod(Number(e.target.value))}
                  className="w-full p-2.5 text-xs font-bold rounded-xl bg-[#121828] border border-slate-700 text-white"
                >
                  {[1,2,3,4,5,6,7,8].map(p => (
                    <option key={p} value={p}>Period {p}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-xs font-bold text-slate-400 mb-1">End Period</label>
                <select
                  value={endPeriod}
                  onChange={(e) => setEndPeriod(Number(e.target.value))}
                  className="w-full p-2.5 text-xs font-bold rounded-xl bg-[#121828] border border-slate-700 text-white"
                >
                  {[1,2,3,4,5,6,7,8].map(p => (
                    <option key={p} value={p}>Period {p}</option>
                  ))}
                </select>
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-400 mb-1">Reason / Justification</label>
              <textarea
                rows={3}
                required
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                placeholder="Explain the reason for leave..."
                className="w-full p-3 text-xs rounded-xl bg-[#121828] border border-slate-700 text-white"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-400 mb-1">
                Upload Proof Document (AWS S3 Bucket Upload Simulation)
              </label>
              <div className="p-3 rounded-xl border border-dashed border-slate-700 bg-[#121828] flex items-center justify-between text-xs text-slate-300">
                <div className="flex items-center gap-2">
                  <Upload className="w-4 h-4 text-cyan-400" />
                  <span>{docName}</span>
                </div>
                <button
                  type="button"
                  onClick={() => setDocName('Medical_Certificate_' + Date.now() + '.pdf')}
                  className="px-3 py-1 text-[10px] font-bold rounded bg-slate-800 text-cyan-400 border border-slate-700"
                >
                  Choose File
                </button>
              </div>
            </div>

            <div className="flex items-center gap-2 pt-2">
              <input
                type="checkbox"
                id="consent"
                checked={parentConsent}
                onChange={(e) => setParentConsent(e.target.checked)}
                className="rounded text-academic-600 focus:ring-academic-500"
              />
              <label htmlFor="consent" className="text-xs text-slate-300 cursor-pointer">
                Parent / Guardian has been informed and confirmed consent.
              </label>
            </div>

            <button
              type="submit"
              className="w-full py-3 rounded-xl bg-academic-600 hover:bg-academic-500 text-white font-bold text-xs shadow-glow-indigo transition-all mt-4"
            >
              Submit Prior Notice Application
            </button>
          </form>
        </div>
      )}
    </div>
  );
};
