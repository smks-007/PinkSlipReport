import React, { useState } from 'react';
import { 
  FileCheck2,
  CheckCircle2, 
  Send, 
  Check, 
  X, 
  FileText, 
  ExternalLink, 
  PhoneCall, 
  Upload, 
  UserCheck, 
  Clock, 
  AlertTriangle, 
  ShieldCheck, 
  ChevronRight, 
  Bell, 
  Sparkles,
  ArrowRight,
  MessageSquare,
  Building2,
  Lock
} from 'lucide-react';
import { useAttendance } from '../../context/AttendanceContext';
import { LeaveType, LeaveRecord } from '../../types';

export const LeaveWorkflowCenter: React.FC = () => {
  const { 
    leaveRecords, 
    studentSubmitLeave, 
    advisorForwardLeaveToHOD, 
    advisorRejectLeave, 
    hodApproveLeave, 
    hodRejectLeave, 
    students,
    batches,
    notifications,
    currentUserRole,
    currentUser,
    markNotificationAsRead,
    clearAllNotifications
  } = useAttendance();

  const [activeWorkflowTab, setActiveWorkflowTab] = useState<'student_portal' | 'advisor_inbox' | 'hod_cockpit' | 'notifications'>('student_portal');
  const [selectedBatchFilter, setSelectedBatchFilter] = useState<string>('all');

  // Student Form State
  const [studentId, setStudentId] = useState<string>(students[0]?.id || 's-25243001');
  const [leaveType, setLeaveType] = useState<LeaveType>('on_duty_od');
  const [startDate, setStartDate] = useState<string>('2026-09-08');
  const [endDate, setEndDate] = useState<string>('2026-09-09');
  const [startPeriod, setStartPeriod] = useState<number>(1);
  const [endPeriod, setEndPeriod] = useState<number>(8);
  const [reason, setReason] = useState<string>('');
  const [letterText, setLetterText] = useState<string>('');
  const [docName, setDocName] = useState<string>('Event_Permission_Proof.pdf');
  const [parentConsent, setParentConsent] = useState<boolean>(true);

  // Review Dialog states
  const [advisorNote, setAdvisorNote] = useState<string>('');
  const [hodNote, setHodNote] = useState<string>('');
  const [selectedLeaveForPreview, setSelectedLeaveForPreview] = useState<LeaveRecord | null>(null);

  const selectedStudent = students.find(s => s.id === studentId) || students[0];

  // Auto-fill template letter when leave type changes
  const handleLeaveTypeChange = (type: LeaveType) => {
    setLeaveType(type);
    if (type === 'on_duty_od') {
      setLetterText(
        `Respected Head of the Department and Class Advisor,\n\nI am writing to request On-Duty (OD) attendance for participating in the upcoming technical symposium / project hackathon. I have attached the official selection letter.\n\nKindly approve my OD attendance.\n\nYours obediently,\n${selectedStudent.name} (${selectedStudent.rollNo})`
      );
      setDocName('Symposium_Selection_Letter.pdf');
    } else if (type === 'medical_ml') {
      setLetterText(
        `Respected Class Advisor,\n\nI was unwell and advised clinical rest by the medical officer. The doctor's fitness certificate and prescription are attached.\n\nKindly approve Medical Leave (ML).\n\nYours faithfully,\n${selectedStudent.name} (${selectedStudent.rollNo})`
      );
      setDocName('Doctor_Medical_Certificate.pdf');
    } else {
      setLetterText(
        `Respected Class Advisor,\n\nI request Casual Leave (CL) for a family ceremony in my hometown. My parents have given prior consent.\n\nThanking you,\n${selectedStudent.name} (${selectedStudent.rollNo})`
      );
      setDocName('Parent_Consent_Letter.pdf');
    }
  };

  const handleStudentSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!reason.trim()) return;

    studentSubmitLeave({
      studentId: selectedStudent.id,
      studentName: selectedStudent.name,
      rollNo: selectedStudent.rollNo,
      batchCode: selectedStudent.batchCode,
      leaveType,
      startDate,
      endDate,
      startPeriod,
      endPeriod,
      totalDays: startDate === endDate ? 1 : 2,
      reason,
      letterText: letterText || reason,
      documentProofName: docName,
      documentProofUrl: 'https://smartcampus-s3.amazonaws.com/proofs/' + docName,
      parentConsent
    });

    setReason('');
    setActiveWorkflowTab('advisor_inbox');
  };

  // Filter queues
  const advisorPendingList = leaveRecords.filter(l => 
    l.status === 'pending_advisor' &&
    (selectedBatchFilter === 'all' || l.batchCode === selectedBatchFilter)
  );

  const hodPendingList = leaveRecords.filter(l => 
    l.status === 'forwarded_to_hod' &&
    (selectedBatchFilter === 'all' || l.batchCode === selectedBatchFilter)
  );

  const historyList = leaveRecords.filter(l => 
    (l.status === 'approved_by_hod' || l.status.startsWith('rejected')) &&
    (selectedBatchFilter === 'all' || l.batchCode === selectedBatchFilter)
  );

  const unreadNotifCount = notifications.filter(n => !n.read).length;

  return (
    <div className="space-y-6">
      {/* Workflow Navigation Banner */}
      <div className="p-6 rounded-3xl glass-panel border-slate-800 bg-gradient-to-r from-academic-600/15 via-indigo-600/10 to-transparent">
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <span className="px-2.5 py-0.5 rounded-full text-[10px] font-extrabold uppercase bg-academic-950 text-academic-300 border border-academic-700/80 flex items-center gap-1.5">
                <ShieldCheck className="w-3.5 h-3.5 text-cyan-400" />
                2-Tier Approval Pipeline
              </span>
              <span className="text-xs text-slate-400 font-semibold">Student ➔ Class Advisor ➔ HOD Approval</span>
            </div>
            <h2 className="text-xl font-extrabold text-white tracking-tight">
              On-Duty (OD) & Leave Application Workflow Center
            </h2>
            <p className="text-xs text-slate-400 mt-1">
              Students submit with typed letters and document proofs ➔ Class Advisor verifies & forwards ➔ HOD gives final digital signoff.
            </p>
          </div>

          {/* Section Filter */}
          <div className="flex items-center gap-3">
            <select
              value={selectedBatchFilter}
              onChange={(e) => setSelectedBatchFilter(e.target.value)}
              className="px-3.5 py-2 text-xs font-bold rounded-xl bg-[#121828] border border-slate-700 text-white focus:outline-none"
            >
              <option value="all">All AIDS Sections (10)</option>
              {batches.map(b => (
                <option key={b.id} value={b.batchCode}>{b.batchCode}</option>
              ))}
            </select>
          </div>
        </div>

        {/* 4 Pipeline Tabs */}
        <div className="flex flex-wrap items-center gap-2 mt-5 pt-4 border-t border-slate-800/80">
          <button
            onClick={() => setActiveWorkflowTab('student_portal')}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-2 ${
              activeWorkflowTab === 'student_portal'
                ? 'bg-academic-600 text-white shadow-glow-indigo'
                : 'bg-[#121828] text-slate-400 hover:text-white border border-slate-800'
            }`}
          >
            <span>1. Student Apply Portal</span>
          </button>

          <button
            onClick={() => setActiveWorkflowTab('advisor_inbox')}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-2 ${
              activeWorkflowTab === 'advisor_inbox'
                ? 'bg-indigo-600 text-white shadow-glow-indigo'
                : 'bg-[#121828] text-slate-400 hover:text-white border border-slate-800'
            }`}
          >
            <span>2. Class Advisor Inbox</span>
            {advisorPendingList.length > 0 && (
              <span className="px-2 py-0.2 rounded-full text-[10px] bg-amber-950 text-amber-300 border border-amber-800">
                {advisorPendingList.length} Pending
              </span>
            )}
          </button>

          <button
            onClick={() => setActiveWorkflowTab('hod_cockpit')}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-2 ${
              activeWorkflowTab === 'hod_cockpit'
                ? 'bg-emerald-600 text-white shadow-glow-emerald'
                : 'bg-[#121828] text-slate-400 hover:text-white border border-slate-800'
            }`}
          >
            <span>3. HOD Final Sanction</span>
            {hodPendingList.length > 0 && (
              <span className="px-2 py-0.2 rounded-full text-[10px] bg-cyan-950 text-cyan-300 border border-cyan-800">
                {hodPendingList.length} Forwarded
              </span>
            )}
          </button>

          <button
            onClick={() => setActiveWorkflowTab('notifications')}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-2 ${
              activeWorkflowTab === 'notifications'
                ? 'bg-cyan-600 text-white shadow-glow-indigo'
                : 'bg-[#121828] text-slate-400 hover:text-white border border-slate-800'
            }`}
          >
            <Bell className="w-3.5 h-3.5" />
            <span>4. Live Notification Audit</span>
            {unreadNotifCount > 0 && (
              <span className="px-1.5 py-0.2 rounded-full text-[10px] bg-rose-600 text-white font-bold">
                {unreadNotifCount}
              </span>
            )}
          </button>
        </div>
      </div>

      {/* TAB 1: Student Application Portal */}
      {activeWorkflowTab === 'student_portal' && (
        <div className="max-w-3xl mx-auto p-6 rounded-3xl glass-panel border-slate-800 space-y-5">
          <div className="flex items-center justify-between pb-3 border-b border-slate-800">
            <div>
              <h3 className="text-base font-bold text-white">Student On-Duty & Leave Submission Portal</h3>
              <p className="text-xs text-slate-400 mt-0.5">
                Type formal letter words directly and attach certificates for advisor review.
              </p>
            </div>
            <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-slate-800 text-cyan-300 font-bold">
              Stage 1: Student ➔ Advisor
            </span>
          </div>

          <form onSubmit={handleStudentSubmit} className="space-y-4 text-xs">
            <div>
              <label className="block font-bold text-slate-400 mb-1">Applying Student</label>
              <select
                value={studentId}
                onChange={(e) => setStudentId(e.target.value)}
                className="w-full p-2.5 text-xs font-bold rounded-xl bg-[#121828] border border-slate-700 text-white focus:outline-none"
              >
                {students.map(s => (
                  <option key={s.id} value={s.id}>
                    {s.name} ({s.rollNo} · {s.batchCode}) · Advisor: {s.advisorName}
                  </option>
                ))}
              </select>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div>
                <label className="block font-bold text-slate-400 mb-1">Category of Absence</label>
                <select
                  value={leaveType}
                  onChange={(e) => handleLeaveTypeChange(e.target.value as LeaveType)}
                  className="w-full p-2.5 text-xs font-bold rounded-xl bg-[#121828] border border-slate-700 text-white focus:outline-none"
                >
                  <option value="on_duty_od">On-Duty Leave (OD - Event / Symposium / Placement)</option>
                  <option value="prior_cl">Prior Casual Leave (CL - Personal / Family)</option>
                  <option value="medical_ml">Medical Leave (ML - Doctor Certified)</option>
                </select>
              </div>

              <div>
                <label className="block font-bold text-slate-400 mb-1">Event / Absence Title</label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Smart India Hackathon Grand Finale / Viral Fever"
                  value={reason}
                  onChange={(e) => setReason(e.target.value)}
                  className="w-full p-2.5 text-xs rounded-xl bg-[#121828] border border-slate-700 text-white focus:outline-none"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block font-bold text-slate-400 mb-1">Start Date</label>
                <input
                  type="date"
                  value={startDate}
                  onChange={(e) => setStartDate(e.target.value)}
                  className="w-full p-2.5 text-xs font-bold rounded-xl bg-[#121828] border border-slate-700 text-white focus:outline-none"
                />
              </div>
              <div>
                <label className="block font-bold text-slate-400 mb-1">End Date</label>
                <input
                  type="date"
                  value={endDate}
                  onChange={(e) => setEndDate(e.target.value)}
                  className="w-full p-2.5 text-xs font-bold rounded-xl bg-[#121828] border border-slate-700 text-white focus:outline-none"
                />
              </div>
            </div>

            {/* Formal Typed Letter Words */}
            <div>
              <label className="block font-bold text-slate-400 mb-1">
                Formal Request Letter (Typed Words to Advisor & HOD)
              </label>
              <textarea
                rows={5}
                required
                value={letterText}
                onChange={(e) => setLetterText(e.target.value)}
                placeholder="Type your formal letter here..."
                className="w-full p-3 text-xs rounded-xl bg-[#121828] border border-slate-700 text-white font-mono leading-relaxed focus:outline-none focus:border-academic-500"
              />
            </div>

            {/* Document Proof Attachment */}
            <div>
              <label className="block font-bold text-slate-400 mb-1">
                Attach Document / Certificate Proof (PDF / Image)
              </label>
              <div className="p-3.5 rounded-2xl border border-dashed border-slate-700 bg-[#121828] flex items-center justify-between">
                <div className="flex items-center gap-2.5 text-cyan-400">
                  <FileText className="w-5 h-5" />
                  <span className="font-mono font-bold text-slate-200">{docName}</span>
                </div>
                <button
                  type="button"
                  onClick={() => setDocName(`Proof_Certificate_${Date.now()}.pdf`)}
                  className="px-3 py-1.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-cyan-300 font-bold text-xs border border-slate-700 transition-colors"
                >
                  Change File
                </button>
              </div>
            </div>

            <div className="flex items-center gap-2 pt-1">
              <input
                type="checkbox"
                id="consentCheck"
                checked={parentConsent}
                onChange={(e) => setParentConsent(e.target.checked)}
                className="rounded text-academic-600 focus:ring-academic-500"
              />
              <label htmlFor="consentCheck" className="text-xs text-slate-300 cursor-pointer">
                Parent / Guardian has been informed and given explicit consent.
              </label>
            </div>

            <button
              type="submit"
              className="w-full py-3 rounded-2xl bg-academic-600 hover:bg-academic-500 text-white font-bold text-xs shadow-glow-indigo transition-all flex items-center justify-center gap-2 mt-2"
            >
              <Send className="w-4 h-4" />
              <span>Submit Request to Class Advisor ({selectedStudent.advisorName})</span>
            </button>
          </form>
        </div>
      )}

      {/* TAB 2: Class Advisor Verification Inbox */}
      {activeWorkflowTab === 'advisor_inbox' && (
        <div className="space-y-4">
          <div className="p-4 rounded-2xl bg-indigo-950/20 border border-indigo-700/50 flex items-center justify-between text-xs text-indigo-300">
            <div className="flex items-center gap-2">
              <UserCheck className="w-5 h-5 text-indigo-400" />
              <span>
                <strong>Stage 2 (Class Advisor Inbox):</strong> Verify student request, review attached letter/proof, and 1-Click Forward to HOD for final sanction.
              </span>
            </div>
            <span className="font-bold text-white">{advisorPendingList.length} Awaiting Advisor Action</span>
          </div>

          {advisorPendingList.length === 0 ? (
            <div className="p-12 rounded-3xl glass-panel border-slate-800 text-center text-slate-400">
              <CheckCircle2 className="w-10 h-10 mx-auto text-emerald-400 mb-2" />
              <h4 className="text-sm font-bold text-white">Advisor Inbox Clean</h4>
              <p className="text-xs text-slate-500 mt-1">No pending student requests awaiting advisor verification for this section.</p>
            </div>
          ) : (
            advisorPendingList.map(leave => (
              <div
                key={leave.id}
                className="p-6 rounded-3xl glass-panel border-slate-800 hover:border-indigo-500/50 transition-all space-y-4"
              >
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3 border-b border-slate-800">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-2xl bg-indigo-500/10 text-indigo-400 flex items-center justify-center font-black">
                      {leave.leaveType === 'on_duty_od' ? 'OD' : leave.leaveType === 'medical_ml' ? 'ML' : 'CL'}
                    </div>
                    <div>
                      <div className="flex items-center gap-2">
                        <h4 className="text-sm font-bold text-white">{leave.studentName}</h4>
                        <span className="text-xs font-mono px-1.5 py-0.5 rounded bg-slate-800 text-cyan-300">{leave.rollNo}</span>
                        <span className="text-[10px] font-extrabold uppercase px-2 py-0.5 rounded-full bg-indigo-950 text-indigo-300 border border-indigo-800">
                          {leave.leaveType.toUpperCase()}
                        </span>
                      </div>
                      <p className="text-xs text-slate-400">{leave.batchCode} · Applied: {leave.appliedAt}</p>
                    </div>
                  </div>

                  <div className="text-right text-xs">
                    <span className="font-bold text-white block">{leave.startDate} to {leave.endDate}</span>
                    <span className="text-[11px] text-slate-400">Periods {leave.startPeriod}-{leave.endPeriod} ({leave.totalDays} Day)</span>
                  </div>
                </div>

                {/* Typed Formal Letter Box */}
                {leave.letterText && (
                  <div className="p-4 rounded-2xl bg-[#0a0d16] border border-slate-800 text-xs text-slate-300 space-y-1">
                    <span className="text-[10px] font-bold uppercase text-slate-400 block">Student's Typed Letter:</span>
                    <p className="whitespace-pre-line font-mono text-[11px] text-slate-300 leading-relaxed">
                      {leave.letterText}
                    </p>
                  </div>
                )}

                {/* Proof Document Link */}
                {leave.documentProofName && (
                  <div className="flex items-center justify-between p-3 rounded-xl bg-[#121828] border border-slate-800 text-xs">
                    <div className="flex items-center gap-2 text-cyan-400">
                      <FileText className="w-4 h-4" />
                      <span>{leave.documentProofName} (Verified in S3 Bucket)</span>
                    </div>
                    <a
                      href={leave.documentProofUrl || '#'}
                      target="_blank"
                      rel="noreferrer"
                      className="text-cyan-400 font-bold hover:underline flex items-center gap-1"
                    >
                      <span>Preview Certificate</span>
                      <ExternalLink className="w-3.5 h-3.5" />
                    </a>
                  </div>
                )}

                {/* Advisor Action Toolbar */}
                <div className="flex items-center justify-between pt-2 border-t border-slate-800">
                  <span className="text-xs text-slate-400">
                    Parent Consent: <strong className="text-emerald-400 font-semibold">✓ Confirmed</strong>
                  </span>

                  <div className="flex items-center gap-2.5">
                    <button
                      onClick={() => advisorRejectLeave(leave.id, 'Insufficient proof document attached.')}
                      className="px-3.5 py-2 text-xs font-bold rounded-xl bg-rose-950 hover:bg-rose-900 border border-rose-800 text-rose-300 flex items-center gap-1.5 transition-all"
                    >
                      <X className="w-3.5 h-3.5" />
                      <span>Reject Application</span>
                    </button>

                    <button
                      onClick={() => advisorForwardLeaveToHOD(leave.id, 'Verified student credentials and attached proof. Forwarded for HOD sanction.')}
                      className="px-4 py-2 text-xs font-bold rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white shadow-glow-indigo flex items-center gap-1.5 transition-all"
                    >
                      <Check className="w-3.5 h-3.5" />
                      <span>Approve & Forward to HOD →</span>
                    </button>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      )}

      {/* TAB 3: HOD Executive Sanction Cockpit */}
      {activeWorkflowTab === 'hod_cockpit' && (
        <div className="space-y-4">
          <div className="p-4 rounded-2xl bg-emerald-950/20 border border-emerald-700/50 flex items-center justify-between text-xs text-emerald-300">
            <div className="flex items-center gap-2">
              <ShieldCheck className="w-5 h-5 text-emerald-400" />
              <span>
                <strong>Stage 3 (HOD Final Approval):</strong> Requests verified by Class Advisors. Upon HOD approval, attendance is officially pre-locked in the system.
              </span>
            </div>
            <span className="font-bold text-white">{hodPendingList.length} Forwarded Requests</span>
          </div>

          {hodPendingList.length === 0 ? (
            <div className="p-12 rounded-3xl glass-panel border-slate-800 text-center text-slate-400">
              <CheckCircle2 className="w-10 h-10 mx-auto text-emerald-400 mb-2" />
              <h4 className="text-sm font-bold text-white">All Forwarded Requests Sanctioned</h4>
              <p className="text-xs text-slate-500 mt-1">No requests currently awaiting HOD final signoff.</p>
            </div>
          ) : (
            hodPendingList.map(leave => (
              <div
                key={leave.id}
                className="p-6 rounded-3xl glass-panel border-emerald-900/60 bg-gradient-to-b from-emerald-950/10 to-transparent space-y-4"
              >
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3 border-b border-slate-800">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-2xl bg-emerald-500/10 text-emerald-400 flex items-center justify-center font-black">
                      {leave.leaveType === 'on_duty_od' ? 'OD' : leave.leaveType === 'medical_ml' ? 'ML' : 'CL'}
                    </div>
                    <div>
                      <div className="flex items-center gap-2">
                        <h4 className="text-sm font-bold text-white">{leave.studentName}</h4>
                        <span className="text-xs font-mono px-1.5 py-0.5 rounded bg-slate-800 text-cyan-300">{leave.rollNo}</span>
                        <span className="text-[10px] font-extrabold uppercase px-2 py-0.5 rounded-full bg-emerald-950 text-emerald-300 border border-emerald-800">
                          {leave.leaveType.toUpperCase()}
                        </span>
                      </div>
                      <p className="text-xs text-slate-400">{leave.batchCode} · Verified by Advisor: <strong className="text-cyan-400">{leave.advisorName}</strong></p>
                    </div>
                  </div>

                  <div className="text-right text-xs">
                    <span className="font-bold text-white block">{leave.startDate} to {leave.endDate}</span>
                    <span className="text-[11px] text-slate-400">({leave.totalDays} Day)</span>
                  </div>
                </div>

                {/* Advisor Recommendation Note */}
                <div className="p-3.5 rounded-xl bg-indigo-950/30 border border-indigo-800/60 text-xs text-indigo-300">
                  <span className="font-bold block text-indigo-400 text-[10px] uppercase">Advisor Verification Remarks:</span>
                  <span>"{leave.advisorRemarks || 'Verified by Class Advisor.'}" ({leave.advisorReviewedAt})</span>
                </div>

                {/* Typed Letter & Proof */}
                {leave.letterText && (
                  <div className="p-3.5 rounded-xl bg-[#0a0d16] border border-slate-800 text-xs text-slate-300 font-mono">
                    <p className="whitespace-pre-line text-[11px]">{leave.letterText}</p>
                  </div>
                )}

                {/* HOD Action Toolbar */}
                <div className="flex items-center justify-between pt-2 border-t border-slate-800">
                  <span className="text-xs text-cyan-400 font-semibold flex items-center gap-1.5">
                    <Lock className="w-3.5 h-3.5" /> Auto-Locks Attendance on Approval
                  </span>

                  <div className="flex items-center gap-2.5">
                    <button
                      onClick={() => hodRejectLeave(leave.id, 'Disapproved by HOD.')}
                      className="px-3.5 py-2 text-xs font-bold rounded-xl bg-rose-950 hover:bg-rose-900 border border-rose-800 text-rose-300 flex items-center gap-1.5 transition-all"
                    >
                      <X className="w-3.5 h-3.5" />
                      <span>Disapprove</span>
                    </button>

                    <button
                      onClick={() => hodApproveLeave(leave.id, 'Approved. On-Duty attendance sanctioned.')}
                      className="px-5 py-2 text-xs font-bold rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white shadow-glow-emerald flex items-center gap-1.5 transition-all"
                    >
                      <Check className="w-4 h-4" />
                      <span>Sanction & Approve {leave.leaveType.toUpperCase()}</span>
                    </button>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      )}

      {/* TAB 4: Live Notifications & Approval Audit Stream */}
      {activeWorkflowTab === 'notifications' && (
        <div className="space-y-4">
          <div className="flex items-center justify-between p-4 rounded-2xl glass-panel border-slate-800 text-xs">
            <div className="flex items-center gap-2 text-white font-bold">
              <Bell className="w-4 h-4 text-cyan-400" />
              <span>Real-Time Workflow Notification Stream & Audit Trail</span>
            </div>
            <button
              onClick={clearAllNotifications}
              className="px-3 py-1 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 text-[11px] font-bold transition-colors"
            >
              Mark All Read
            </button>
          </div>

          <div className="space-y-2.5">
            {notifications.map(notif => (
              <div
                key={notif.id}
                onClick={() => markNotificationAsRead(notif.id)}
                className={`p-4 rounded-2xl border transition-all cursor-pointer flex items-start justify-between gap-4 ${
                  notif.read ? 'bg-[#121828]/60 border-slate-800 text-slate-400' : 'bg-[#121828] border-cyan-700/60 text-slate-200 shadow-sm'
                }`}
              >
                <div className="flex items-start gap-3">
                  <div className={`w-8 h-8 rounded-xl flex items-center justify-center flex-shrink-0 mt-0.5 ${
                    notif.type === 'success' ? 'bg-emerald-500/20 text-emerald-400' :
                    notif.type === 'warning' ? 'bg-amber-500/20 text-amber-400' :
                    notif.type === 'error' ? 'bg-rose-500/20 text-rose-400' : 'bg-cyan-500/20 text-cyan-400'
                  }`}>
                    {notif.type === 'success' ? <Check className="w-4 h-4" /> :
                     notif.type === 'warning' ? <AlertTriangle className="w-4 h-4" /> :
                     notif.type === 'error' ? <X className="w-4 h-4" /> : <Bell className="w-4 h-4" />}
                  </div>

                  <div>
                    <h5 className="text-xs font-bold text-white">{notif.title}</h5>
                    <p className="text-[11px] text-slate-300 mt-0.5 leading-relaxed">{notif.message}</p>
                    <span className="text-[9px] text-slate-500 block mt-1">{notif.createdAt}</span>
                  </div>
                </div>

                {!notif.read && (
                  <div className="w-2 h-2 rounded-full bg-cyan-400 mt-2 flex-shrink-0" />
                )}
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};
