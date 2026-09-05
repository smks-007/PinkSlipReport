import React, { useState } from 'react';
import { 
  Sparkles, 
  Send, 
  Bot, 
  User, 
  AlertTriangle, 
  TrendingUp, 
  ShieldCheck, 
  Calendar, 
  CheckCircle2, 
  Zap, 
  X,
  Copy,
  Check
} from 'lucide-react';
import { useAttendance } from '../../context/AttendanceContext';

interface Message {
  id: string;
  sender: 'user' | 'jarvis';
  text: string;
  timestamp: string;
  actionType?: 'shortage_list' | 'sms_draft' | 'period_trend' | 'recovery_sim';
  data?: any;
}

export const JarvisAiAdvisor: React.FC<{ isOpen: boolean; onClose: () => void }> = ({ isOpen, onClose }) => {
  const { students, batches, departmentSummary, selectedBatchCode, setSelectedStudentId, setActiveTab } = useAttendance();

  const [inputQuery, setInputQuery] = useState('');
  const [copiedId, setCopiedId] = useState<string | null>(null);
  const [messages, setMessages] = useState<Message[]>([
    {
      id: 'm1',
      sender: 'jarvis',
      text: `Hello! I am Jarvis AI, the Autonomous Attendance & Accreditation Intelligence Agent for the AIDS Department. I'm actively monitoring all 622 students across 10 sections.\n\nHow can I assist you with detention risks, parent SMS drafting, or NAAC audit analysis today?`,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    }
  ]);

  if (!isOpen) return null;

  const shortageStudents = students.filter(s => s.attendancePercentage < 75.0);

  const quickPrompts = [
    {
      label: "🚨 Top Detention Risks",
      query: "Show top critical attendance shortage students below 75%"
    },
    {
      label: "📱 Draft Parent Cut Alert (Tamil & English)",
      query: "Draft a bilingual SMS alert for uninformed cuts today"
    },
    {
      label: "📊 Batch Performance Comparison",
      query: "Compare attendance across II, III and IV year sections"
    },
    {
      label: "📈 4:30 PM Absent Forecast",
      query: "What is today's absent reconciliation forecast?"
    }
  ];

  const handleSend = (textToSend?: string) => {
    const q = (textToSend || inputQuery).trim();
    if (!q) return;

    const userMsg: Message = {
      id: 'usr-' + Date.now(),
      sender: 'user',
      text: q,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    };

    setMessages(prev => [...prev, userMsg]);
    setInputQuery('');

    // Generate intelligent response based on query
    setTimeout(() => {
      let replyText = '';
      let actionType: Message['actionType'];
      let data: any;

      const lowerQ = q.toLowerCase();

      if (lowerQ.includes('shortage') || lowerQ.includes('detention') || lowerQ.includes('risk') || lowerQ.includes('below 75')) {
        actionType = 'shortage_list';
        data = shortageStudents.slice(0, 6);
        replyText = `Identified **${shortageStudents.length} students** across AIDS Department currently below the mandatory 75% NAAC/University threshold.\n\nHere are the most critical cases requiring urgent advisor counseling:`;
      } else if (lowerQ.includes('sms') || lowerQ.includes('draft') || lowerQ.includes('parent') || lowerQ.includes('whatsapp')) {
        actionType = 'sms_draft';
        replyText = `Here is the standardized bilingual SMS / WhatsApp alert template ready for the automated 4:30 PM EventBridge dispatch:\n\n` +
          `**English Version:**\n` +
          `"Dear Parent, your ward [Student Name] ([Roll No]) was marked UNINFORMED ABSENT in Period 5 at AIDS Department on 02-09-2026. Cumulative attendance is [Percentage]%. Please contact Class Advisor: [Advisor Phone]. - SmartCampus AI"\n\n` +
          `**தமிழ் வடிவம் (Tamil):**\n` +
          `"அன்புள்ள பெற்றோருக்கு, உங்கள் மகன்/மகள் [பெயர்] இன்று (02-09-2026) முன்அறிவிப்பின்றி வகுப்பிற்கு வரவில்லை. தற்போதைய வருகைப்பதிவு [சதவீதம்]%. வகுப்பு ஆலோசகரை தொடர்பு கொள்ளவும்: [தொலைபேசி]."`;
      } else if (lowerQ.includes('compare') || lowerQ.includes('batch') || lowerQ.includes('performance')) {
        replyText = `**AIDS Cross-Section Performance Index:**\n\n` +
          `• **II Year (2025 Batch):** 89.2% Avg (Highest: II-AIDS-A @ 91.0%)\n` +
          `• **III Year (2024 Batch):** 85.8% Avg (Highest: III-AIDS-B @ 88.4%)\n` +
          `• **IV Year (2023 Batch):** 86.4% Avg (Placement ODs active: 18 students)\n\n` +
          `*Recommendation:* Period 5 (post-lunch) shows a 4.2% dropoff compared to morning Period 1. Advisor spot-checks advised for 2nd year labs.`;
      } else {
        replyText = `Department Pulse Analysis for **${batches.length} AIDS Sections**:\n` +
          `• Total Strength: ${students.length} students\n` +
          `• Overall Attendance Today: ${departmentSummary.overallAttendancePercentage}%\n` +
          `• Approved Prior Leaves: ${departmentSummary.approvedLeavesToday} (CL/OD/ML)\n` +
          `• Uninformed Cut Flags: ${departmentSummary.uninformedAbsenteesToday} students\n\n` +
          `You can drill down into any student dossier or run the 1-Click 4:30 PM reconciliation anytime.`;
      }

      const botMsg: Message = {
        id: 'bot-' + Date.now(),
        sender: 'jarvis',
        text: replyText,
        timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        actionType,
        data
      };

      setMessages(prev => [...prev, botMsg]);
    }, 400);
  };

  const copyToClipboard = (text: string, id: string) => {
    navigator.clipboard.writeText(text);
    setCopiedId(id);
    setTimeout(() => setCopiedId(null), 2000);
  };

  return (
    <div className="fixed inset-0 z-50 overflow-hidden bg-slate-950/80 backdrop-blur-md flex items-center justify-center p-4 animate-in fade-in duration-200">
      <div className="w-full max-w-3xl h-[85vh] rounded-3xl bg-[#0b0f19] border border-academic-700/60 shadow-2xl flex flex-col overflow-hidden">
        {/* Header */}
        <div className="p-4 px-6 border-b border-slate-800 bg-[#0e1424] flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-2xl bg-gradient-to-tr from-academic-600 via-indigo-600 to-cyan-400 flex items-center justify-center text-white shadow-glow-indigo">
              <Sparkles className="w-5 h-5" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h3 className="text-base font-bold text-white">Jarvis AI Attendance Copilot</h3>
                <span className="px-2 py-0.5 rounded-full text-[10px] font-extrabold uppercase bg-cyan-950 text-cyan-300 border border-cyan-800">
                  LLM Agent
                </span>
              </div>
              <p className="text-[11px] text-slate-400">
                Predictive Risk Analytics · Bilingual Parent Alerts · NAAC Compliance
              </p>
            </div>
          </div>

          <button
            onClick={onClose}
            className="p-2 rounded-xl bg-[#121828] hover:bg-slate-800 text-slate-400 hover:text-white transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Message Stream */}
        <div className="flex-1 overflow-y-auto p-6 space-y-4">
          {messages.map(m => (
            <div
              key={m.id}
              className={`flex gap-3 ${m.sender === 'user' ? 'justify-end' : 'justify-start'}`}
            >
              {m.sender === 'jarvis' && (
                <div className="w-8 h-8 rounded-xl bg-academic-600/30 border border-academic-500/40 text-academic-300 flex items-center justify-center flex-shrink-0 mt-1">
                  <Bot className="w-4 h-4" />
                </div>
              )}

              <div className={`max-w-xl p-4 rounded-2xl text-xs space-y-2 ${
                m.sender === 'user'
                  ? 'bg-academic-600 text-white rounded-tr-none'
                  : 'bg-[#121828] border border-slate-800 text-slate-200 rounded-tl-none leading-relaxed'
              }`}>
                <div className="whitespace-pre-line">{m.text}</div>

                {/* Interactive Shortage Cards */}
                {m.actionType === 'shortage_list' && m.data && (
                  <div className="space-y-2 pt-2 border-t border-slate-700/80">
                    {m.data.map((st: any) => (
                      <div
                        key={st.id}
                        onClick={() => {
                          setSelectedStudentId(st.id);
                          setActiveTab('student_dossier');
                          onClose();
                        }}
                        className="p-2.5 rounded-xl bg-[#0a0d16] border border-rose-900/60 hover:border-rose-500 cursor-pointer flex items-center justify-between transition-all"
                      >
                        <div className="flex items-center gap-2">
                          <img src={st.avatar} alt={st.name} className="w-7 h-7 rounded-full object-cover ring-1 ring-rose-500" />
                          <div>
                            <span className="font-bold text-white block">{st.name} ({st.rollNo})</span>
                            <span className="text-[10px] text-slate-400">{st.batchCode} · {st.uninformedAbsencesCount} Cuts</span>
                          </div>
                        </div>
                        <div className="text-right">
                          <span className="text-xs font-black text-rose-400">{st.attendancePercentage}%</span>
                          <span className="text-[9px] text-cyan-400 block">Inspect Dossier →</span>
                        </div>
                      </div>
                    ))}
                  </div>
                )}

                {/* Interactive SMS Copy */}
                {m.actionType === 'sms_draft' && (
                  <div className="pt-2 flex justify-end">
                    <button
                      onClick={() => copyToClipboard(m.text, m.id)}
                      className="px-3 py-1 rounded-lg bg-slate-800 hover:bg-slate-700 text-cyan-300 font-bold text-[10px] flex items-center gap-1.5 transition-colors"
                    >
                      {copiedId === m.id ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
                      <span>{copiedId === m.id ? 'Copied to Clipboard!' : 'Copy Alert Template'}</span>
                    </button>
                  </div>
                )}

                <span className="text-[9px] text-slate-500 block text-right">{m.timestamp}</span>
              </div>

              {m.sender === 'user' && (
                <div className="w-8 h-8 rounded-xl bg-slate-800 text-slate-300 flex items-center justify-center flex-shrink-0 mt-1">
                  <User className="w-4 h-4" />
                </div>
              )}
            </div>
          ))}
        </div>

        {/* Quick Suggestion Chips */}
        <div className="px-6 py-2 bg-[#0c101c] border-t border-slate-800/80 flex items-center gap-2 overflow-x-auto">
          {quickPrompts.map((chip, idx) => (
            <button
              key={idx}
              onClick={() => handleSend(chip.query)}
              className="px-3 py-1.5 rounded-xl bg-[#121828] hover:bg-slate-800 border border-slate-700 text-slate-300 hover:text-white text-[11px] font-semibold whitespace-nowrap transition-all"
            >
              {chip.label}
            </button>
          ))}
        </div>

        {/* Input Bar */}
        <div className="p-4 px-6 border-t border-slate-800 bg-[#0e1424]">
          <form
            onSubmit={(e) => {
              e.preventDefault();
              handleSend();
            }}
            className="flex items-center gap-3"
          >
            <input
              type="text"
              value={inputQuery}
              onChange={(e) => setInputQuery(e.target.value)}
              placeholder="Ask Jarvis anything about AIDS attendance, cut alerts, or student risk..."
              className="flex-1 px-4 py-2.5 rounded-xl bg-[#121828] border border-slate-700 text-white text-xs placeholder-slate-500 focus:outline-none focus:border-academic-500"
            />
            <button
              type="submit"
              className="px-4 py-2.5 rounded-xl bg-academic-600 hover:bg-academic-500 text-white font-bold text-xs shadow-glow-indigo transition-all flex items-center gap-2"
            >
              <Send className="w-4 h-4" />
              <span>Ask</span>
            </button>
          </form>
        </div>
      </div>
    </div>
  );
};
