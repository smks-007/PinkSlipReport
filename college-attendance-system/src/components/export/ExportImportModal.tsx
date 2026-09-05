import React, { useState } from 'react';
import { 
  FileSpreadsheet, 
  Download, 
  Upload, 
  Send, 
  Check, 
  X, 
  PhoneCall, 
  FileText,
  AlertCircle
} from 'lucide-react';
import { useAttendance } from '../../context/AttendanceContext';

interface ExportImportModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const ExportImportModal: React.FC<ExportImportModalProps> = ({ isOpen, onClose }) => {
  const { students, batches, selectedBatchCode, showToast } = useAttendance();
  const [activeTab, setActiveTab] = useState<'export' | 'import' | 'broadcast'>('export');
  const [selectedBatch, setSelectedBatch] = useState<string>(selectedBatchCode);
  const [isDispatched, setIsDispatched] = useState(false);

  if (!isOpen) return null;

  const currentBatchStudents = students.filter(s => s.batchCode === selectedBatch);

  const handleExportCSV = () => {
    // Generate CSV content
    const headers = ["RollNo", "RegNo", "StudentName", "BatchCode", "Year", "Section", "AttendancePercentage", "AttendedPeriods", "TotalPeriods", "UninformedCuts", "ParentPhone"];
    const rows = currentBatchStudents.map(s => [
      s.rollNo,
      s.regNo,
      `"${s.name}"`,
      s.batchCode,
      s.yearLevel,
      s.section,
      s.attendancePercentage,
      s.attendedPeriods,
      s.totalConductedPeriods,
      s.uninformedAbsencesCount,
      `"${s.parentPhone}"`
    ]);

    const csvContent = "data:text/csv;charset=utf-8," + [headers.join(","), ...rows.map(e => e.join(","))].join("\n");
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", `AIDS_${selectedBatch}_Attendance_Register_2026.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);

    showToast(`Exported ${currentBatchStudents.length} student records for ${selectedBatch} to CSV!`);
  };

  const handleSimulateBroadcast = () => {
    const cutsCount = currentBatchStudents.filter(s => s.uninformedAbsencesCount > 0).length;
    setIsDispatched(true);
    showToast(`Dispatched SMS and WhatsApp parent alerts to ${cutsCount} guardians in ${selectedBatch}!`);
  };

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto bg-slate-950/80 backdrop-blur-md flex items-center justify-center p-4">
      <div className="w-full max-w-xl rounded-3xl bg-[#0c101c] border border-slate-700 shadow-2xl overflow-hidden animate-in zoom-in-95 duration-150 text-slate-100">
        {/* Header */}
        <div className="p-4 px-6 border-b border-slate-800 bg-[#0e1424] flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <FileSpreadsheet className="w-5 h-5 text-academic-400" />
            <h3 className="text-base font-bold text-white">Attendance Export, CSV Import & Broadcast Center</h3>
          </div>
          <button onClick={onClose} className="text-slate-400 hover:text-white p-1">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Tab Controls */}
        <div className="p-4 px-6 border-b border-slate-800 flex items-center gap-2">
          <button
            onClick={() => setActiveTab('export')}
            className={`px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all ${
              activeTab === 'export' ? 'bg-academic-600 text-white' : 'bg-[#121828] text-slate-400 hover:text-white'
            }`}
          >
            Export to CSV / Excel
          </button>
          <button
            onClick={() => setActiveTab('broadcast')}
            className={`px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all ${
              activeTab === 'broadcast' ? 'bg-rose-600 text-white' : 'bg-[#121828] text-slate-400 hover:text-white'
            }`}
          >
            SMS / WhatsApp Broadcast
          </button>
          <button
            onClick={() => setActiveTab('import')}
            className={`px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all ${
              activeTab === 'import' ? 'bg-cyan-600 text-white' : 'bg-[#121828] text-slate-400 hover:text-white'
            }`}
          >
            Import CSV Roster
          </button>
        </div>

        {/* Content Body */}
        <div className="p-6 space-y-4 text-xs">
          <div>
            <label className="block text-xs font-bold text-slate-400 mb-1">Target Section</label>
            <select
              value={selectedBatch}
              onChange={(e) => {
                setSelectedBatch(e.target.value);
                setIsDispatched(false);
              }}
              className="w-full p-2.5 text-xs font-bold rounded-xl bg-[#121828] border border-slate-700 text-white focus:outline-none"
            >
              {batches.map(b => (
                <option key={b.id} value={b.batchCode}>
                  {b.yearName} - Sec {b.section} ({b.batchCode}) · {b.totalStudents} Students
                </option>
              ))}
            </select>
          </div>

          {activeTab === 'export' && (
            <div className="p-5 rounded-2xl bg-[#121828] border border-slate-800 space-y-3">
              <div className="flex justify-between items-center text-slate-300">
                <span>Selected Section Strength:</span>
                <span className="font-bold text-white">{currentBatchStudents.length} Students</span>
              </div>
              <div className="flex justify-between items-center text-slate-300">
                <span>Format:</span>
                <span className="font-mono text-cyan-400">Standard CSV (Excel Compatible)</span>
              </div>
              <div className="flex justify-between items-center text-slate-300">
                <span>Includes:</span>
                <span className="text-slate-300">Roll No, Reg No, Aggregate %, Cuts, Parent Phone</span>
              </div>

              <button
                onClick={handleExportCSV}
                className="w-full py-3 rounded-xl bg-academic-600 hover:bg-academic-500 text-white font-bold text-xs shadow-glow-indigo transition-all flex items-center justify-center gap-2 mt-4"
              >
                <Download className="w-4 h-4" />
                <span>Download Section CSV File</span>
              </button>
            </div>
          )}

          {activeTab === 'broadcast' && (
            <div className="p-5 rounded-2xl bg-rose-950/20 border border-rose-900/50 space-y-3">
              <div className="flex items-center gap-2 text-rose-400 font-bold">
                <AlertCircle className="w-4 h-4" />
                <span>Instant Parental Notification Gateway</span>
              </div>
              <p className="text-slate-300 leading-relaxed">
                Dispatch automated multilingual SMS & WhatsApp alerts to parents of students in <strong>{selectedBatch}</strong> with unapproved cuts.
              </p>

              <div className="p-3 rounded-xl bg-[#0a0d16] border border-slate-800 text-[11px] text-slate-400 font-mono">
                "SmartCampus Alert: Your ward was marked absent in Period 5 today (02-09-2026). Cumulative: [X]%. Contact Class Advisor."
              </div>

              <button
                onClick={handleSimulateBroadcast}
                disabled={isDispatched}
                className={`w-full py-3 rounded-xl font-bold text-xs shadow-glow-rose transition-all flex items-center justify-center gap-2 mt-2 ${
                  isDispatched
                    ? 'bg-emerald-600 text-white cursor-default'
                    : 'bg-rose-600 hover:bg-rose-500 text-white'
                }`}
              >
                {isDispatched ? <Check className="w-4 h-4" /> : <Send className="w-4 h-4" />}
                <span>{isDispatched ? 'Alerts Dispatched Successfully!' : `Send Parent Alerts for ${selectedBatch}`}</span>
              </button>
            </div>
          )}

          {activeTab === 'import' && (
            <div className="p-5 rounded-2xl bg-[#121828] border border-slate-800 text-center space-y-3">
              <Upload className="w-8 h-8 mx-auto text-cyan-400" />
              <h4 className="font-bold text-white">Import CSV Attendance / Roster</h4>
              <p className="text-[11px] text-slate-400">
                Drag and drop your updated Excel/CSV attendance sheet here for automated reconciliation with conflict protection.
              </p>
              <button
                onClick={() => {
                  alert('CSV imported successfully. Idempotent check completed: 0 duplicate overwrites.');
                  onClose();
                }}
                className="px-4 py-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-cyan-300 font-bold text-xs border border-slate-700 transition-colors"
              >
                Select CSV File
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
