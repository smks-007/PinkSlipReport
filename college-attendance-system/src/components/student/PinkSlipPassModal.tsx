import React from 'react';
import { 
  FileText, 
  ShieldCheck, 
  Download, 
  Printer, 
  X, 
  CheckCircle2, 
  AlertTriangle,
  QrCode,
  GraduationCap
} from 'lucide-react';
import { Student } from '../../types';

interface PinkSlipPassModalProps {
  isOpen: boolean;
  onClose: () => void;
  student: Student;
}

export const PinkSlipPassModal: React.FC<PinkSlipPassModalProps> = ({ isOpen, onClose, student }) => {
  if (!isOpen) return null;

  const isEligible = student.attendancePercentage >= 75.0;

  const handlePrint = () => {
    window.print();
  };

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto bg-slate-950/80 backdrop-blur-md flex items-center justify-center p-4">
      <div className="w-full max-w-2xl rounded-3xl bg-[#0c101c] border border-slate-700 shadow-2xl overflow-hidden animate-in zoom-in-95 duration-150 text-slate-100">
        {/* Modal Top Bar */}
        <div className="p-4 px-6 border-b border-slate-800 bg-[#0e1424] flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <FileText className="w-5 h-5 text-academic-400" />
            <h3 className="text-base font-bold text-white">
              Official Digital Clearance & Separation Pass ("Pink Slip")
            </h3>
          </div>
          <button onClick={onClose} className="text-slate-400 hover:text-white p-1">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Certificate Paper Body */}
        <div className="p-8 bg-slate-900/60 border border-slate-800 m-6 rounded-2xl relative overflow-hidden text-slate-200">
          {/* Watermark */}
          <div className="absolute inset-0 flex items-center justify-center opacity-5 pointer-events-none select-none">
            <GraduationCap className="w-96 h-96 text-white" />
          </div>

          {/* Header */}
          <div className="text-center pb-4 border-b-2 border-slate-700 relative z-10">
            <h2 className="text-base font-black uppercase tracking-wider text-white">
              SMARTCAMPUS UNIVERSITY OF TECHNOLOGY
            </h2>
            <p className="text-xs font-bold text-academic-400 mt-0.5">
              DEPARTMENT OF ARTIFICIAL INTELLIGENCE & DATA SCIENCE (AIDS)
            </p>
            <p className="text-[10px] text-slate-400">
              Academic Year 2026-2027 · End-Semester Exam Attendance Clearance Slip
            </p>
          </div>

          {/* Student & Status Info */}
          <div className="my-5 grid grid-cols-2 gap-4 text-xs relative z-10">
            <div className="space-y-1.5">
              <div>
                <span className="text-slate-400 block text-[10px]">Student Name:</span>
                <span className="font-bold text-white text-sm">{student.name}</span>
              </div>
              <div>
                <span className="text-slate-400 block text-[10px]">Enrollment Code / Reg No:</span>
                <span className="font-mono font-bold text-cyan-300">{student.rollNo} / {student.regNo}</span>
              </div>
              <div>
                <span className="text-slate-400 block text-[10px]">Section / Year:</span>
                <span className="font-bold text-slate-200">{student.batchCode} ({student.yearLevel === 2 ? '2nd Year' : student.yearLevel === 3 ? '3rd Year' : '4th Year'})</span>
              </div>
            </div>

            <div className="space-y-1.5 text-right">
              <div>
                <span className="text-slate-400 block text-[10px]">Class Advisor:</span>
                <span className="font-bold text-white">{student.advisorName}</span>
              </div>
              <div>
                <span className="text-slate-400 block text-[10px]">Total Periods Attended:</span>
                <span className="font-bold text-slate-200">{student.attendedPeriods} / {student.totalConductedPeriods}</span>
              </div>
              <div>
                <span className="text-slate-400 block text-[10px]">Cumulative Percentage:</span>
                <span className={`text-lg font-black ${isEligible ? 'text-emerald-400' : 'text-rose-400'}`}>
                  {student.attendancePercentage}%
                </span>
              </div>
            </div>
          </div>

          {/* Clearance Verdict */}
          <div className={`p-4 rounded-xl border text-center my-4 relative z-10 ${
            isEligible 
              ? 'bg-emerald-950/40 border-emerald-700/80 text-emerald-300' 
              : 'bg-rose-950/40 border-rose-700/80 text-rose-300'
          }`}>
            <div className="flex items-center justify-center gap-2 text-sm font-black uppercase">
              {isEligible ? <CheckCircle2 className="w-5 h-5 text-emerald-400" /> : <AlertTriangle className="w-5 h-5 text-rose-400" />}
              <span>{isEligible ? 'Verified & Cleared for End-Sem Examination' : 'Detention Alert: Attendance Below 75%'}</span>
            </div>
            <p className="text-[11px] mt-1 opacity-90">
              {isEligible 
                ? 'All department prior notice leaves and laboratory attendances have been authenticated.'
                : 'Mandatory HOD counseling and compensatory assignments required before hall ticket issuance.'}
            </p>
          </div>

          {/* QR Verification & Signatures */}
          <div className="pt-4 border-t border-slate-700/80 flex items-center justify-between text-xs relative z-10">
            <div className="flex items-center gap-3">
              <div className="w-14 h-14 bg-white p-1 rounded-lg flex items-center justify-center">
                <QrCode className="w-12 h-12 text-slate-900" />
              </div>
              <div className="text-[10px] text-slate-400">
                <span className="font-mono text-cyan-300 block">AUTH-CERT-{student.rollNo}-2026</span>
                <span>Scan for NAAC cryptographic blockchain validation</span>
              </div>
            </div>

            <div className="text-center space-y-1">
              <div className="font-serif italic text-sm text-cyan-300 font-bold">K. Arulraj</div>
              <div className="text-[10px] text-slate-400 border-t border-slate-600 pt-0.5">
                Head of Department (AIDS)
              </div>
            </div>
          </div>
        </div>

        {/* Footer Controls */}
        <div className="p-4 px-6 border-t border-slate-800 bg-[#0e1424] flex items-center justify-between">
          <span className="text-xs text-slate-400">Generated on 02-09-2026</span>
          <div className="flex items-center gap-3">
            <button
              onClick={onClose}
              className="px-4 py-2 text-xs font-semibold text-slate-400 hover:text-white"
            >
              Close
            </button>
            <button
              onClick={handlePrint}
              className="px-4 py-2 text-xs font-bold rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 flex items-center gap-1.5 transition-colors"
            >
              <Printer className="w-4 h-4" />
              <span>Print Slip</span>
            </button>
            <button
              onClick={() => {
                alert(`Digital Pink Slip for ${student.name} (${student.rollNo}) downloaded as cryptographically signed PDF.`);
                onClose();
              }}
              className="px-5 py-2 text-xs font-bold rounded-xl bg-academic-600 hover:bg-academic-500 text-white shadow-glow-indigo flex items-center gap-2"
            >
              <Download className="w-4 h-4" />
              <span>Download PDF</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
