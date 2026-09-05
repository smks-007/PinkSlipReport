import React, { createContext, useContext, useState, useEffect } from 'react';
import { 
  UserRole, 
  User, 
  Batch, 
  Student, 
  LeaveRecord, 
  FacultyComplianceItem, 
  DepartmentSummary, 
  AttendanceStatus,
  LeaveApprovalStatus
} from '../types';
import { 
  mockUsers, 
  initialBatches, 
  initialStudents, 
  initialPendingLeaves, 
  initialComplianceList, 
  initialDepartmentSummary 
} from '../data/mockData';

export type ActiveTab = 'hod_cockpit' | 'period_marker' | 'leave_triage' | 'student_dossier' | 'cloud_naac';

interface AttendanceContextType {
  currentUserRole: UserRole;
  setCurrentUserRole: (role: UserRole) => void;
  currentUser: User;
  activeTab: ActiveTab;
  setActiveTab: (tab: ActiveTab) => void;
  
  // Data State
  batches: Batch[];
  students: Student[];
  pendingLeaves: LeaveRecord[];
  allLeaves: LeaveRecord[];
  complianceList: FacultyComplianceItem[];
  departmentSummary: DepartmentSummary;
  
  // Filters & Selected States
  selectedBatchCode: string;
  setSelectedBatchCode: (code: string) => void;
  selectedStudentId: string;
  setSelectedStudentId: (id: string) => void;
  selectedPeriodForMarking: number;
  setSelectedPeriodForMarking: (p: number) => void;
  selectedDateForMarking: string;
  setSelectedDateForMarking: (d: string) => void;
  
  // Actions
  savePeriodAttendance: (batchCode: string, periodNumber: number, date: string, studentStatuses: Record<string, AttendanceStatus>) => void;
  approveLeave: (leaveId: string, approverTitle: string, comments: string) => void;
  rejectLeave: (leaveId: string, approverTitle: string, comments: string) => void;
  applyNewLeave: (leaveData: Omit<LeaveRecord, 'id' | 'status' | 'appliedAt'>) => void;
  triggerReconciliation430PM: () => void;
  isReconciliationTriggered: boolean;
  toastMessage: string | null;
  showToast: (msg: string) => void;
  
  // Export Modal
  isNAACModalOpen: boolean;
  setIsNAACModalOpen: (open: boolean) => void;
}

const AttendanceContext = createContext<AttendanceContextType | undefined>(undefined);

export const AttendanceProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [currentUserRole, setCurrentUserRole] = useState<UserRole>('hod1');
  const [activeTab, setActiveTab] = useState<ActiveTab>('hod_cockpit');
  
  const [batches, setBatches] = useState<Batch[]>(() => {
    const saved = localStorage.getItem('sc_aids_batches_v2');
    return saved ? JSON.parse(saved) : initialBatches;
  });
  
  const [students, setStudents] = useState<Student[]>(() => {
    const saved = localStorage.getItem('sc_aids_students_v2');
    return saved ? JSON.parse(saved) : initialStudents;
  });
  
  const [pendingLeaves, setPendingLeaves] = useState<LeaveRecord[]>(() => {
    const saved = localStorage.getItem('sc_aids_pending_leaves_v2');
    return saved ? JSON.parse(saved) : initialPendingLeaves;
  });

  const [allLeaves, setAllLeaves] = useState<LeaveRecord[]>([
    ...initialPendingLeaves,
    ...initialStudents.flatMap(s => s.leaveHistory)
  ]);

  const [complianceList, setComplianceList] = useState<FacultyComplianceItem[]>(initialComplianceList);
  const [departmentSummary, setDepartmentSummary] = useState<DepartmentSummary>(initialDepartmentSummary);

  const [selectedBatchCode, setSelectedBatchCode] = useState<string>('II-AIDS-A');
  const [selectedStudentId, setSelectedStudentId] = useState<string>('s-25243001');
  const [selectedPeriodForMarking, setSelectedPeriodForMarking] = useState<number>(5);
  const [selectedDateForMarking, setSelectedDateForMarking] = useState<string>('2026-09-02');

  const [isReconciliationTriggered, setIsReconciliationTriggered] = useState<boolean>(false);
  const [toastMessage, setToastMessage] = useState<string | null>(null);
  const [isNAACModalOpen, setIsNAACModalOpen] = useState<boolean>(false);

  useEffect(() => {
    localStorage.setItem('sc_aids_batches_v2', JSON.stringify(batches));
  }, [batches]);

  useEffect(() => {
    localStorage.setItem('sc_aids_students_v2', JSON.stringify(students));
  }, [students]);

  useEffect(() => {
    localStorage.setItem('sc_aids_pending_leaves_v2', JSON.stringify(pendingLeaves));
  }, [pendingLeaves]);

  const currentUser = mockUsers[currentUserRole] || mockUsers.hod1;

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3500);
  };

  // 1. Mark & Save Attendance for 8-period slot ("if updated don't update it")
  const savePeriodAttendance = (
    batchCode: string, 
    periodNumber: number, 
    date: string, 
    studentStatuses: Record<string, AttendanceStatus>
  ) => {
    let anyChanges = false;

    // Update student records
    setStudents(prev => prev.map(student => {
      if (student.batchCode !== batchCode) return student;
      const targetStatus = studentStatuses[student.id] || 'present';
      
      const prevDateRecords = student.recentAttendance[date] || Array(8).fill('present');
      const oldStatus = prevDateRecords[periodNumber - 1];

      // If updated, don't update it / skip redundant recalculation
      if (oldStatus === targetStatus) {
        return student;
      }

      anyChanges = true;
      const updatedDateRecords = [...prevDateRecords];
      updatedDateRecords[periodNumber - 1] = targetStatus;

      // Delta calculation
      const wasAttending = oldStatus === 'present' || oldStatus === 'leave_od';
      const isAttending = targetStatus === 'present' || targetStatus === 'leave_od';
      
      let newAttended = student.attendedPeriods;
      if (!wasAttending && isAttending) {
        newAttended += 1;
      } else if (wasAttending && !isAttending) {
        newAttended = Math.max(0, newAttended - 1);
      }

      let newUninformed = student.uninformedAbsencesCount;
      if (oldStatus === 'absent_uninformed' && targetStatus !== 'absent_uninformed') {
        newUninformed = Math.max(0, newUninformed - 1);
      } else if (oldStatus !== 'absent_uninformed' && targetStatus === 'absent_uninformed') {
        newUninformed += 1;
      }

      const totalConducted = student.totalConductedPeriods;
      const newPercentage = Number(((newAttended / Math.max(1, totalConducted)) * 100).toFixed(1));

      return {
        ...student,
        attendedPeriods: newAttended,
        attendancePercentage: newPercentage,
        uninformedAbsencesCount: newUninformed,
        recentAttendance: {
          ...student.recentAttendance,
          [date]: updatedDateRecords
        }
      };
    }));

    // Update Faculty Compliance List
    setComplianceList(prev => prev.map(c => {
      if (c.periodNumber === periodNumber && c.batchCode === batchCode) {
        const presentCount = Object.values(studentStatuses).filter(s => s === 'present' || s === 'leave_od').length;
        return {
          ...c,
          isSubmitted: true,
          submittedAt: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
          presentCount,
          totalCount: Object.keys(studentStatuses).length || 60
        };
      }
      return c;
    }));

    // Recalculate Batches Realtime
    setBatches(prev => prev.map(b => {
      if (b.batchCode !== batchCode) return b;
      const batchStudents = students.filter(s => s.batchCode === batchCode);
      const presentCount = Object.values(studentStatuses).filter(s => s === 'present' || s === 'leave_od').length;
      const uninformedCount = Object.values(studentStatuses).filter(s => s === 'absent_uninformed').length;
      const leavesCount = Object.values(studentStatuses).filter(s => s === 'leave_prior_cl' || s === 'leave_od' || s === 'leave_ml').length;
      const avg = Number((batchStudents.reduce((acc, s) => acc + s.attendancePercentage, 0) / Math.max(1, batchStudents.length)).toFixed(1));

      return {
        ...b,
        presentToday: presentCount,
        uninformedToday: uninformedCount,
        approvedLeavesToday: leavesCount,
        avgAttendance: avg
      };
    }));

    if (anyChanges) {
      showToast(`Period ${periodNumber} verified & saved for ${batchCode}!`);
    } else {
      showToast(`Period ${periodNumber} is already up to date for ${batchCode}. No changes required.`);
    }
  };

  // 2. Approve Leave
  const approveLeave = (leaveId: string, approverTitle: string, comments: string) => {
    const leave = pendingLeaves.find(l => l.id === leaveId);
    if (!leave) return;

    const updatedLeave: LeaveRecord = {
      ...leave,
      status: currentUserRole === 'hod1' || currentUserRole === 'hod2' ? 'approved_by_hod' : 'approved_by_advisor',
      reviewedBy: `${currentUser.name} (${approverTitle})`,
      reviewerComments: comments || 'Approved prior notice leave.',
      reviewedAt: new Date().toLocaleString()
    };

    setPendingLeaves(prev => prev.filter(l => l.id !== leaveId));
    setAllLeaves(prev => [updatedLeave, ...prev.filter(l => l.id !== leaveId)]);

    // Add to student's history
    setStudents(prev => prev.map(s => {
      if (s.id === leave.studentId) {
        return {
          ...s,
          priorLeavesCount: leave.leaveType === 'prior_cl' ? s.priorLeavesCount + 1 : s.priorLeavesCount,
          onDutyCount: leave.leaveType === 'on_duty_od' ? s.onDutyCount + 1 : s.onDutyCount,
          medicalLeavesCount: leave.leaveType === 'medical_ml' ? s.medicalLeavesCount + 1 : s.medicalLeavesCount,
          leaveHistory: [updatedLeave, ...s.leaveHistory]
        };
      }
      return s;
    }));

    showToast(`Leave application for ${leave.studentName} approved as ${leave.leaveType.toUpperCase()}!`);
  };

  // 3. Reject Leave
  const rejectLeave = (leaveId: string, approverTitle: string, comments: string) => {
    const leave = pendingLeaves.find(l => l.id === leaveId);
    if (!leave) return;

    const updatedLeave: LeaveRecord = {
      ...leave,
      status: 'rejected',
      reviewedBy: `${currentUser.name} (${approverTitle})`,
      reviewerComments: comments || 'Insufficient justification / late notice.',
      reviewedAt: new Date().toLocaleString()
    };

    setPendingLeaves(prev => prev.filter(l => l.id !== leaveId));
    setAllLeaves(prev => [updatedLeave, ...prev.filter(l => l.id !== leaveId)]);
    showToast(`Leave application for ${leave.studentName} rejected.`);
  };

  // 4. Apply New Leave
  const applyNewLeave = (leaveData: Omit<LeaveRecord, 'id' | 'status' | 'appliedAt'>) => {
    const newLeave: LeaveRecord = {
      ...leaveData,
      id: 'lv-' + Date.now(),
      status: 'pending',
      appliedAt: new Date().toLocaleString()
    };

    setPendingLeaves(prev => [newLeave, ...prev]);
    setAllLeaves(prev => [newLeave, ...prev]);
    showToast('Prior leave application submitted to Class Advisor for verification!');
  };

  // 5. Automated 4:30 PM Absent Reconciliation
  const triggerReconciliation430PM = () => {
    setIsReconciliationTriggered(true);
    showToast('⚡ Daily 4:30 PM Absent Reconciliation Completed for AIDS Department! Parent SMS & WhatsApp alerts dispatched.');
  };

  return (
    <AttendanceContext.Provider value={{
      currentUserRole,
      setCurrentUserRole,
      currentUser,
      activeTab,
      setActiveTab,
      batches,
      students,
      pendingLeaves,
      allLeaves,
      complianceList,
      departmentSummary,
      selectedBatchCode,
      setSelectedBatchCode,
      selectedStudentId,
      setSelectedStudentId,
      selectedPeriodForMarking,
      setSelectedPeriodForMarking,
      selectedDateForMarking,
      setSelectedDateForMarking,
      savePeriodAttendance,
      approveLeave,
      rejectLeave,
      applyNewLeave,
      triggerReconciliation430PM,
      isReconciliationTriggered,
      toastMessage,
      showToast,
      isNAACModalOpen,
      setIsNAACModalOpen
    }}>
      {children}
    </AttendanceContext.Provider>
  );
};

export const useAttendance = () => {
  const ctx = useContext(AttendanceContext);
  if (!ctx) throw new Error('useAttendance must be used within AttendanceProvider');
  return ctx;
};
