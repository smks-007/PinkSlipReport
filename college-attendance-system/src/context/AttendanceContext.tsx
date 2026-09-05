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
  LeaveApprovalStatus,
  DayAttendanceSubmission,
  NotificationItem
} from '../types';
import { 
  mockUsers, 
  initialBatches, 
  initialStudents, 
  initialLeaveRecords, 
  initialDaySubmissions,
  initialNotifications,
  initialComplianceList, 
  initialDepartmentSummary,
  workingDates 
} from '../data/mockData';

export type ActiveTab = 
  | 'hod_cockpit' 
  | 'monthly_calendar' 
  | 'period_marker' 
  | 'leave_workflow' 
  | 'student_dossier' 
  | 'dept_analytics' 
  | 'cloud_naac';

interface AttendanceContextType {
  currentUserRole: UserRole;
  setCurrentUserRole: (role: UserRole) => void;
  currentUser: User;
  activeTab: ActiveTab;
  setActiveTab: (tab: ActiveTab) => void;
  
  // Data State
  batches: Batch[];
  students: Student[];
  leaveRecords: LeaveRecord[];
  pendingLeaves: LeaveRecord[];
  allLeaves: LeaveRecord[];
  daySubmissions: DayAttendanceSubmission[];
  notifications: NotificationItem[];
  complianceList: FacultyComplianceItem[];
  departmentSummary: DepartmentSummary;
  workingDates: string[];
  
  // Filters & Selected States
  selectedBatchCode: string;
  setSelectedBatchCode: (code: string) => void;
  selectedStudentId: string;
  setSelectedStudentId: (id: string) => void;
  selectedPeriodForMarking: number;
  setSelectedPeriodForMarking: (p: number) => void;
  selectedDateForMarking: string;
  setSelectedDateForMarking: (d: string) => void;
  
  // 1-Month Day-Wise Attendance Entry & HOD Verification
  savePeriodAttendance: (batchCode: string, periodNumber: number, date: string, studentStatuses: Record<string, AttendanceStatus>) => void;
  saveDayAttendance: (batchCode: string, date: string, studentDayStatuses: Record<string, AttendanceStatus>) => void;
  submitDayAttendanceToHOD: (batchCode: string, date: string, remarks?: string) => void;
  verifyDayAttendanceByHOD: (batchCode: string, date: string, remarks?: string) => void;
  
  // 2-Tier Leave & On-Duty Approval Workflow (Student -> Advisor -> HOD)
  studentSubmitLeave: (leaveData: Omit<LeaveRecord, 'id' | 'status' | 'appliedAt'>) => void;
  advisorForwardLeaveToHOD: (leaveId: string, advisorRemarks: string) => void;
  advisorRejectLeave: (leaveId: string, advisorRemarks: string) => void;
  hodApproveLeave: (leaveId: string, hodRemarks: string) => void;
  hodRejectLeave: (leaveId: string, hodRemarks: string) => void;
  
  // Notification Management
  markNotificationAsRead: (id: string) => void;
  clearAllNotifications: () => void;
  
  // System Tools
  triggerReconciliation430PM: () => void;
  isReconciliationTriggered: boolean;
  toastMessage: string | null;
  showToast: (msg: string) => void;
  isNAACModalOpen: boolean;
  setIsNAACModalOpen: (open: boolean) => void;
}

const AttendanceContext = createContext<AttendanceContextType | undefined>(undefined);

export const AttendanceProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [currentUserRole, setCurrentUserRole] = useState<UserRole>('hod1');
  const [activeTab, setActiveTab] = useState<ActiveTab>('hod_cockpit');
  
  const [batches, setBatches] = useState<Batch[]>(() => {
    const saved = localStorage.getItem('sc_aids_batches_v3');
    return saved ? JSON.parse(saved) : initialBatches;
  });
  
  const [students, setStudents] = useState<Student[]>(() => {
    const saved = localStorage.getItem('sc_aids_students_v3');
    return saved ? JSON.parse(saved) : initialStudents;
  });
  
  const [leaveRecords, setLeaveRecords] = useState<LeaveRecord[]>(() => {
    const saved = localStorage.getItem('sc_aids_leave_records_v3');
    return saved ? JSON.parse(saved) : initialLeaveRecords;
  });

  const [daySubmissions, setDaySubmissions] = useState<DayAttendanceSubmission[]>(() => {
    const saved = localStorage.getItem('sc_aids_day_submissions_v3');
    return saved ? JSON.parse(saved) : initialDaySubmissions;
  });

  const [notifications, setNotifications] = useState<NotificationItem[]>(() => {
    const saved = localStorage.getItem('sc_aids_notifications_v3');
    return saved ? JSON.parse(saved) : initialNotifications;
  });

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
    localStorage.setItem('sc_aids_batches_v3', JSON.stringify(batches));
  }, [batches]);

  useEffect(() => {
    localStorage.setItem('sc_aids_students_v3', JSON.stringify(students));
  }, [students]);

  useEffect(() => {
    localStorage.setItem('sc_aids_leave_records_v3', JSON.stringify(leaveRecords));
  }, [leaveRecords]);

  useEffect(() => {
    localStorage.setItem('sc_aids_day_submissions_v3', JSON.stringify(daySubmissions));
  }, [daySubmissions]);

  useEffect(() => {
    localStorage.setItem('sc_aids_notifications_v3', JSON.stringify(notifications));
  }, [notifications]);

  const currentUser = mockUsers[currentUserRole] || mockUsers.hod1;

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3500);
  };

  // 1. Save Period Attendance
  const savePeriodAttendance = (
    batchCode: string, 
    periodNumber: number, 
    date: string, 
    studentStatuses: Record<string, AttendanceStatus>
  ) => {
    let anyChanges = false;

    setStudents(prev => prev.map(student => {
      if (student.batchCode !== batchCode) return student;
      const targetStatus = studentStatuses[student.id] || 'present';
      
      const prevDateRecords = student.recentAttendance[date] || Array(8).fill('present');
      const oldStatus = prevDateRecords[periodNumber - 1];

      if (oldStatus === targetStatus) return student;

      anyChanges = true;
      const updatedDateRecords = [...prevDateRecords];
      updatedDateRecords[periodNumber - 1] = targetStatus;

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

    if (anyChanges) {
      showToast(`Period ${periodNumber} attendance saved for ${batchCode} on ${date}!`);
    } else {
      showToast(`Period ${periodNumber} is already up to date. No changes needed.`);
    }
  };

  // 2. Full Day-Wise Attendance Entry
  const saveDayAttendance = (
    batchCode: string, 
    date: string, 
    studentDayStatuses: Record<string, AttendanceStatus>
  ) => {
    setStudents(prev => prev.map(student => {
      if (student.batchCode !== batchCode) return student;
      const targetDayStatus = studentDayStatuses[student.id] || 'present';
      
      return {
        ...student,
        recentAttendance: {
          ...student.recentAttendance,
          [date]: Array(8).fill(targetDayStatus)
        }
      };
    }));

    // Update Day Submission
    setDaySubmissions(prev => {
      const existingIdx = prev.findIndex(s => s.batchCode === batchCode && s.date === date);
      const batchStudents = students.filter(s => s.batchCode === batchCode);
      const tot = batchStudents.length || 60;
      const pCount = Object.values(studentDayStatuses).filter(st => st === 'present').length;
      const odCount = Object.values(studentDayStatuses).filter(st => st === 'leave_od').length;
      const aCount = Object.values(studentDayStatuses).filter(st => st === 'absent_uninformed').length;
      const lCount = Object.values(studentDayStatuses).filter(st => st === 'leave_prior_cl' || st === 'leave_ml').length;
      const dayPct = Number((((pCount + odCount) / Math.max(1, tot)) * 100).toFixed(1));

      const subItem: DayAttendanceSubmission = {
        id: `sub-${batchCode.toLowerCase()}-${date}`,
        date,
        batchCode,
        status: 'draft',
        submittedBy: currentUser.name,
        submittedAt: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        presentCount: pCount,
        absentCount: aCount,
        odCount,
        leavesCount: lCount,
        totalStrength: tot,
        dayPercentage: dayPct,
        remarks: 'Manual day-wise entry recorded by Class Advisor.'
      };

      if (existingIdx >= 0) {
        const copy = [...prev];
        copy[existingIdx] = subItem;
        return copy;
      }
      return [subItem, ...prev];
    });

    showToast(`Full-day attendance entered for ${batchCode} on ${date}. Ready to submit to HOD.`);
  };

  // 3. Submit Day's Register to HOD for Verification
  const submitDayAttendanceToHOD = (batchCode: string, date: string, remarks?: string) => {
    setDaySubmissions(prev => prev.map(s => {
      if (s.batchCode === batchCode && s.date === date) {
        return {
          ...s,
          status: 'submitted_to_hod',
          submittedBy: currentUser.name,
          submittedAt: new Date().toLocaleString(),
          remarks: remarks || s.remarks
        };
      }
      return s;
    }));

    // Push notification to HOD
    const newNotif: NotificationItem = {
      id: 'notif-' + Date.now(),
      recipientRole: 'hod',
      batchCode,
      title: `Day Register Submitted: ${batchCode}`,
      message: `${currentUser.name} submitted the attendance register for ${date} (${batchCode}) for official HOD verification.`,
      type: 'info',
      createdAt: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      read: false
    };
    setNotifications(prev => [newNotif, ...prev]);

    showToast(`Attendance register for ${date} (${batchCode}) submitted to HOD for verification.`);
  };

  // 4. HOD Verify & Lock Day's Register
  const verifyDayAttendanceByHOD = (batchCode: string, date: string, remarks?: string) => {
    setDaySubmissions(prev => prev.map(s => {
      if (s.batchCode === batchCode && s.date === date) {
        return {
          ...s,
          status: 'verified_by_hod',
          verifiedBy: currentUser.name,
          verifiedAt: new Date().toLocaleString(),
          remarks: remarks || 'Verified and approved by Head of Department.'
        };
      }
      return s;
    }));

    // Push notification to Advisor & Students
    const newNotif: NotificationItem = {
      id: 'notif-' + Date.now(),
      recipientRole: 'advisor',
      batchCode,
      title: `Day Register Verified by HOD`,
      message: `The attendance register for ${date} (${batchCode}) has been verified and digitally signed by ${currentUser.name}.`,
      type: 'success',
      createdAt: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      read: false
    };
    setNotifications(prev => [newNotif, ...prev]);

    showToast(`Register for ${date} (${batchCode}) verified & locked with HOD digital signature.`);
  };

  // ================= 2-TIER LEAVE / ON-DUTY WORKFLOW =================

  // Stage 1: Student submits leave or OD with typed letter words / attached proof
  const studentSubmitLeave = (leaveData: Omit<LeaveRecord, 'id' | 'status' | 'appliedAt'>) => {
    const newLeave: LeaveRecord = {
      ...leaveData,
      id: 'lv-' + Date.now(),
      status: 'pending_advisor',
      appliedAt: new Date().toLocaleString()
    };

    setLeaveRecords(prev => [newLeave, ...prev]);

    // Push notification to Class Advisor
    const newNotif: NotificationItem = {
      id: 'notif-' + Date.now(),
      recipientRole: 'advisor',
      batchCode: leaveData.batchCode,
      recipientStudentId: leaveData.studentId,
      title: `New ${leaveData.leaveType.toUpperCase()} Application`,
      message: `${leaveData.studentName} (${leaveData.rollNo} · ${leaveData.batchCode}) submitted a ${leaveData.leaveType.toUpperCase()} request for ${leaveData.startDate}. Awaiting advisor review.`,
      type: 'warning',
      createdAt: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      read: false,
      relatedLeaveId: newLeave.id
    };
    setNotifications(prev => [newNotif, ...prev]);

    showToast(`Leave/OD application submitted to Class Advisor for verification!`);
  };

  // Stage 2A: Class Advisor approves and forwards to HOD
  const advisorForwardLeaveToHOD = (leaveId: string, advisorRemarks: string) => {
    const leave = leaveRecords.find(l => l.id === leaveId);
    if (!leave) return;

    const updatedLeave: LeaveRecord = {
      ...leave,
      status: 'forwarded_to_hod',
      advisorName: currentUser.name,
      advisorRemarks: advisorRemarks || 'Verified student credentials and attached proof. Recommended for HOD approval.',
      advisorReviewedAt: new Date().toLocaleString()
    };

    setLeaveRecords(prev => prev.map(l => l.id === leaveId ? updatedLeave : l));

    // Push notification to HOD
    const notifHOD: NotificationItem = {
      id: 'notif-hod-' + Date.now(),
      recipientRole: 'hod',
      batchCode: leave.batchCode,
      title: `OD/Leave Forwarded by ${currentUser.name}`,
      message: `${currentUser.name} verified and forwarded ${leave.leaveType.toUpperCase()} for ${leave.studentName} (${leave.rollNo} · ${leave.batchCode}) to HOD for final signoff.`,
      type: 'info',
      createdAt: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      read: false,
      relatedLeaveId: leaveId
    };

    // Push notification to Student
    const notifStudent: NotificationItem = {
      id: 'notif-stu-' + Date.now(),
      recipientRole: 'student',
      recipientStudentId: leave.studentId,
      title: `Application Forwarded to HOD`,
      message: `Your ${leave.leaveType.toUpperCase()} application has been approved by your Class Advisor (${currentUser.name}) and forwarded to the Head of Department for final approval.`,
      type: 'info',
      createdAt: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      read: false,
      relatedLeaveId: leaveId
    };

    setNotifications(prev => [notifHOD, notifStudent, ...prev]);
    showToast(`Leave application verified and forwarded to HOD for final approval!`);
  };

  // Stage 2B: Class Advisor rejects leave
  const advisorRejectLeave = (leaveId: string, advisorRemarks: string) => {
    const leave = leaveRecords.find(l => l.id === leaveId);
    if (!leave) return;

    const updatedLeave: LeaveRecord = {
      ...leave,
      status: 'rejected_by_advisor',
      advisorName: currentUser.name,
      advisorRemarks: advisorRemarks || 'Insufficient justification / proof document invalid.',
      advisorReviewedAt: new Date().toLocaleString()
    };

    setLeaveRecords(prev => prev.map(l => l.id === leaveId ? updatedLeave : l));

    // Notify Student
    const notifStudent: NotificationItem = {
      id: 'notif-stu-' + Date.now(),
      recipientRole: 'student',
      recipientStudentId: leave.studentId,
      title: `Leave Application Rejected by Advisor`,
      message: `Your ${leave.leaveType.toUpperCase()} request for ${leave.startDate} was rejected by Class Advisor: "${advisorRemarks || 'Insufficient proof'}".`,
      type: 'error',
      createdAt: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      read: false,
      relatedLeaveId: leaveId
    };
    setNotifications(prev => [notifStudent, ...prev]);
    showToast(`Leave request rejected by Class Advisor.`);
  };

  // Stage 3A: HOD Final Approval -> Pre-locks attendance and updates student history
  const hodApproveLeave = (leaveId: string, hodRemarks: string) => {
    const leave = leaveRecords.find(l => l.id === leaveId);
    if (!leave) return;

    const updatedLeave: LeaveRecord = {
      ...leave,
      status: 'approved_by_hod',
      hodName: currentUser.name,
      hodRemarks: hodRemarks || 'Approved. On-Duty/Leave attendance sanctioned.',
      hodReviewedAt: new Date().toLocaleString()
    };

    setLeaveRecords(prev => prev.map(l => l.id === leaveId ? updatedLeave : l));

    // Pre-lock student attendance for the requested dates
    const lockStatus: AttendanceStatus = 
      leave.leaveType === 'on_duty_od' ? 'leave_od' :
      leave.leaveType === 'medical_ml' ? 'leave_ml' : 'leave_prior_cl';

    setStudents(prev => prev.map(s => {
      if (s.id === leave.studentId) {
        const updatedRecent = { ...s.recentAttendance };
        // Apply for startDate to endDate
        updatedRecent[leave.startDate] = Array(8).fill(lockStatus);
        if (leave.endDate && leave.endDate !== leave.startDate) {
          updatedRecent[leave.endDate] = Array(8).fill(lockStatus);
        }

        return {
          ...s,
          priorLeavesCount: leave.leaveType === 'prior_cl' ? s.priorLeavesCount + 1 : s.priorLeavesCount,
          onDutyCount: leave.leaveType === 'on_duty_od' ? s.onDutyCount + 1 : s.onDutyCount,
          medicalLeavesCount: leave.leaveType === 'medical_ml' ? s.medicalLeavesCount + 1 : s.medicalLeavesCount,
          recentAttendance: updatedRecent,
          leaveHistory: [updatedLeave, ...s.leaveHistory]
        };
      }
      return s;
    }));

    // Notify Student
    const notifStudent: NotificationItem = {
      id: 'notif-stu-' + Date.now(),
      recipientRole: 'student',
      recipientStudentId: leave.studentId,
      title: `🎉 ${leave.leaveType.toUpperCase()} Approved by HOD!`,
      message: `Your ${leave.leaveType.toUpperCase()} application for ${leave.startDate} has been officially approved by ${currentUser.name}. Attendance has been pre-locked.`,
      type: 'success',
      createdAt: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      read: false,
      relatedLeaveId: leaveId
    };

    // Notify Advisor
    const notifAdvisor: NotificationItem = {
      id: 'notif-adv-' + Date.now(),
      recipientRole: 'advisor',
      batchCode: leave.batchCode,
      title: `HOD Sanctioned: ${leave.studentName}`,
      message: `${currentUser.name} officially approved the ${leave.leaveType.toUpperCase()} request for ${leave.studentName} (${leave.rollNo} · ${leave.batchCode}).`,
      type: 'success',
      createdAt: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      read: false,
      relatedLeaveId: leaveId
    };

    setNotifications(prev => [notifStudent, notifAdvisor, ...prev]);
    showToast(`HOD approved ${leave.leaveType.toUpperCase()} for ${leave.studentName}! Attendance auto-locked.`);
  };

  // Stage 3B: HOD Rejection
  const hodRejectLeave = (leaveId: string, hodRemarks: string) => {
    const leave = leaveRecords.find(l => l.id === leaveId);
    if (!leave) return;

    const updatedLeave: LeaveRecord = {
      ...leave,
      status: 'rejected_by_hod',
      hodName: currentUser.name,
      hodRemarks: hodRemarks || 'Rejected by HOD.',
      hodReviewedAt: new Date().toLocaleString()
    };

    setLeaveRecords(prev => prev.map(l => l.id === leaveId ? updatedLeave : l));

    // Notify Student & Advisor
    const notifStudent: NotificationItem = {
      id: 'notif-stu-' + Date.now(),
      recipientRole: 'student',
      recipientStudentId: leave.studentId,
      title: `Application Rejected by HOD`,
      message: `Your ${leave.leaveType.toUpperCase()} request was rejected by HOD: "${hodRemarks || 'Disapproved by Department Head'}".`,
      type: 'error',
      createdAt: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      read: false,
      relatedLeaveId: leaveId
    };

    const notifAdvisor: NotificationItem = {
      id: 'notif-adv-' + Date.now(),
      recipientRole: 'advisor',
      batchCode: leave.batchCode,
      title: `HOD Disapproved Application`,
      message: `HOD rejected ${leave.leaveType.toUpperCase()} request for ${leave.studentName} (${leave.rollNo}): "${hodRemarks || 'Disapproved'}".`,
      type: 'warning',
      createdAt: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      read: false,
      relatedLeaveId: leaveId
    };

    setNotifications(prev => [notifStudent, notifAdvisor, ...prev]);
    showToast(`Application rejected by HOD.`);
  };

  // Notifications helper
  const markNotificationAsRead = (id: string) => {
    setNotifications(prev => prev.map(n => n.id === id ? { ...n, read: true } : n));
  };

  const clearAllNotifications = () => {
    setNotifications(prev => prev.map(n => ({ ...n, read: true })));
    showToast('All notifications marked as read.');
  };

  // Automated 4:30 PM Absent Reconciliation
  const triggerReconciliation430PM = () => {
    setIsReconciliationTriggered(true);
    showToast(`⚡ Daily 4:30 PM Absent Reconciliation Completed for AIDS Department! Parent SMS & WhatsApp alerts dispatched.`);
  };

  const pendingLeaves = leaveRecords.filter(l => l.status === 'pending_advisor' || l.status === 'forwarded_to_hod');
  const allLeaves = leaveRecords;

  return (
    <AttendanceContext.Provider value={{
      currentUserRole,
      setCurrentUserRole,
      currentUser,
      activeTab,
      setActiveTab,
      batches,
      students,
      leaveRecords,
      pendingLeaves,
      allLeaves,
      daySubmissions,
      notifications,
      complianceList,
      departmentSummary,
      workingDates,
      selectedBatchCode,
      setSelectedBatchCode,
      selectedStudentId,
      setSelectedStudentId,
      selectedPeriodForMarking,
      setSelectedPeriodForMarking,
      selectedDateForMarking,
      setSelectedDateForMarking,
      savePeriodAttendance,
      saveDayAttendance,
      submitDayAttendanceToHOD,
      verifyDayAttendanceByHOD,
      studentSubmitLeave,
      advisorForwardLeaveToHOD,
      advisorRejectLeave,
      hodApproveLeave,
      hodRejectLeave,
      markNotificationAsRead,
      clearAllNotifications,
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
