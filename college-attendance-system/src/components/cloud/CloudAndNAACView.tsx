import React from 'react';
import { 
  CloudRain, 
  Database, 
  FileSpreadsheet, 
  ShieldCheck, 
  Server, 
  Download, 
  Check, 
  Zap,
  BrainCircuit
} from 'lucide-react';
import { useAttendance } from '../../context/AttendanceContext';

export const CloudAndNAACView: React.FC = () => {
  const { isNAACModalOpen, setIsNAACModalOpen, batches, students, departmentSummary } = useAttendance();

  return (
    <div className="space-y-6">
      {/* Cloud Architecture Overview */}
      <div className="p-6 rounded-3xl glass-panel border-slate-800 space-y-6">
        <div>
          <span className="text-xs font-bold text-cyan-400 uppercase tracking-wider">
            Cloud Backend & Document Storage
          </span>
          <h2 className="text-xl font-extrabold text-white mt-1">
            AWS / Google Cloud Production Architecture — AIDS Department
          </h2>
          <p className="text-xs text-slate-400 mt-1 max-w-2xl">
            Secure cloud infrastructure storing 8-period granular records for {students.length} students across 10 sections of II, III, and IV year AIDS.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="p-4 rounded-2xl bg-[#121828] border border-slate-800 space-y-2">
            <div className="flex items-center gap-2 text-cyan-400">
              <CloudRain className="w-4 h-4" />
              <h4 className="text-xs font-bold text-white">AWS S3 / GCS Storage Bucket</h4>
            </div>
            <p className="text-[11px] text-slate-400">
              Stores encrypted student medical prescriptions, SIH/sports OD proofs, and parent consent forms with presigned URLs.
            </p>
            <div className="text-[10px] text-emerald-400 font-bold">● Bucket: smartcampus-aids-proofs-prod</div>
          </div>

          <div className="p-4 rounded-2xl bg-[#121828] border border-slate-800 space-y-2">
            <div className="flex items-center gap-2 text-indigo-400">
              <Database className="w-4 h-4" />
              <h4 className="text-xs font-bold text-white">PostgreSQL Multi-AZ DB</h4>
            </div>
            <p className="text-[11px] text-slate-400">
              Relational schema with 8-period granular indexing, unique constraints per (student_id, date, period_number).
            </p>
            <div className="text-[10px] text-emerald-400 font-bold">● Total AIDS Student Records: {students.length} · Latency: 8ms</div>
          </div>

          <div className="p-4 rounded-2xl bg-[#121828] border border-slate-800 space-y-2">
            <div className="flex items-center gap-2 text-amber-400">
              <Zap className="w-4 h-4" />
              <h4 className="text-xs font-bold text-white">EventBridge 4:30 PM Cron</h4>
            </div>
            <p className="text-[11px] text-slate-400">
              Automated daily trigger reconciling daily periods, identifying unauthorized cuts, and sending parent SMS alerts.
            </p>
            <div className="text-[10px] text-emerald-400 font-bold">● Schedule: cron(30 16 ? * MON-SAT *)</div>
          </div>
        </div>
      </div>

      {/* NAAC / NBA Accreditation Register Exporter Card */}
      <div className="p-6 rounded-3xl glass-panel border-academic-700/60 bg-gradient-to-r from-academic-950/40 to-transparent flex items-center justify-between">
        <div>
          <h3 className="text-base font-bold text-white">NAAC / NBA Consolidated Attendance Register</h3>
          <p className="text-xs text-slate-400 mt-1">
            Download the official AI & DS department attendance ledger with period-by-period matrices and digital signatures.
          </p>
        </div>
        <button
          onClick={() => setIsNAACModalOpen(true)}
          className="px-5 py-2.5 rounded-xl bg-academic-600 hover:bg-academic-500 text-white text-xs font-bold shadow-glow-indigo flex items-center gap-2"
        >
          <FileSpreadsheet className="w-4 h-4" />
          <span>Open NAAC Register Modal</span>
        </button>
      </div>

      {/* NAAC Modal */}
      {isNAACModalOpen && (
        <div className="fixed inset-0 z-50 overflow-y-auto bg-slate-950/80 backdrop-blur-md flex items-center justify-center p-4">
          <div className="w-full max-w-2xl rounded-3xl bg-[#0c101c] border border-slate-700 shadow-2xl p-6 space-y-5 animate-in zoom-in-95 duration-150">
            <div className="flex items-center justify-between pb-3 border-b border-slate-800">
              <div className="flex items-center gap-2.5">
                <FileSpreadsheet className="w-5 h-5 text-academic-400" />
                <h3 className="text-base font-bold text-white">NAAC & NBA Accreditation Attendance Report</h3>
              </div>
              <button
                onClick={() => setIsNAACModalOpen(false)}
                className="text-slate-400 hover:text-white"
              >
                ✕
              </button>
            </div>

            <div className="p-4 rounded-2xl bg-[#121828] border border-slate-800 text-xs text-slate-300 font-mono space-y-2">
              <div className="text-center font-bold text-white pb-2 border-b border-slate-700">
                DEPARTMENT OF ARTIFICIAL INTELLIGENCE & DATA SCIENCE (AIDS)<br />
                ACADEMIC YEAR 2026-2027 · CONSOLIDATED ATTENDANCE REGISTER
              </div>
              <div>• Total Registered AIDS Students: {students.length} (II, III & IV Year)</div>
              <div>• Sections: II AIDS A-D, III AIDS A-D, IV AIDS A-B (10 Sections)</div>
              <div>• Department Average Attendance: {departmentSummary.overallAttendancePercentage}%</div>
              <div>• Total Authorized Prior Leaves Verified: {departmentSummary.approvedLeavesToday} (CL / OD / ML)</div>
              <div>• Detention Risk (&lt;75%): {students.filter(s => s.attendancePercentage < 75).length} students</div>
              <div>• Status: Digitally Verified by Dr. K. Arulraj (HOD 1) & Dr. S. Meenakshi (HOD 2)</div>
            </div>

            <div className="flex items-center justify-end gap-3 pt-2">
              <button
                onClick={() => setIsNAACModalOpen(false)}
                className="px-4 py-2 text-xs font-semibold text-slate-400 hover:text-white"
              >
                Close
              </button>
              <button
                onClick={() => {
                  alert(`Consolidated NAAC/NBA AIDS Department Register (${students.length} Students) downloaded with digital cryptographic signature.`);
                  setIsNAACModalOpen(false);
                }}
                className="px-5 py-2.5 text-xs font-bold rounded-xl bg-academic-600 hover:bg-academic-500 text-white shadow-glow-indigo flex items-center gap-2"
              >
                <Download className="w-4 h-4" />
                <span>Download Signed PDF</span>
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
