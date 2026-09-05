import { User, Batch, Student, LeaveRecord, FacultyComplianceItem, DepartmentSummary } from '../types';
import aidsRawData from './mockData.json';

export const mockUsers: Record<string, User> = {
  hod1: {
    id: 'u-hod1',
    name: 'Dr. K. Arulraj, Ph.D.',
    role: 'hod1',
    title: 'Head of Department (Admin & Planning)',
    department: 'Artificial Intelligence & Data Science',
    email: 'hod.aids@smartcampus.edu',
    avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
    phone: '+91 94432 10001'
  },
  hod2: {
    id: 'u-hod2',
    name: 'Dr. S. Meenakshi, Ph.D.',
    role: 'hod2',
    title: 'Academic HOD & Accreditation Incharge',
    department: 'Artificial Intelligence & Data Science',
    email: 'academic.hod.aids@smartcampus.edu',
    avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80',
    phone: '+91 94432 10002'
  },
  advisor_2a: {
    id: 'u-adv-2a',
    name: 'Dr. N. Balamurugan',
    role: 'advisor',
    title: 'Class Advisor (II AIDS A - 2025 Batch)',
    department: 'Artificial Intelligence & Data Science',
    email: 'balamurugan.n@smartcampus.edu',
    avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80',
    phone: '+91 98840 33221'
  },
  advisor_2b: {
    id: 'u-adv-2b',
    name: 'Prof. P. Kavitha',
    role: 'advisor',
    title: 'Class Advisor (II AIDS B - 2025 Batch)',
    department: 'Artificial Intelligence & Data Science',
    email: 'kavitha.p@smartcampus.edu',
    avatar: 'https://images.unsplash.com/photo-1573497019940-1c28c88b4f3e?w=150&auto=format&fit=crop&q=80',
    phone: '+91 98840 44332'
  },
  advisor_2c: {
    id: 'u-adv-2c',
    name: 'Dr. G. Revathi',
    role: 'advisor',
    title: 'Class Advisor (II AIDS C - 2025 Batch)',
    department: 'Artificial Intelligence & Data Science',
    email: 'revathi.g@smartcampus.edu',
    avatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150&auto=format&fit=crop&q=80',
    phone: '+91 98840 55667'
  },
  advisor_2d: {
    id: 'u-adv-2d',
    name: 'Prof. K. Santhanam',
    role: 'advisor',
    title: 'Class Advisor (II AIDS D - 2025 Batch)',
    department: 'Artificial Intelligence & Data Science',
    email: 'santhanam.k@smartcampus.edu',
    avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&auto=format&fit=crop&q=80',
    phone: '+91 98840 66778'
  },
  advisor_3a: {
    id: 'u-adv-3a',
    name: 'Prof. R. Venkatesh',
    role: 'advisor',
    title: 'Class Advisor & Year Coordinator (III AIDS A - 2024 Batch)',
    department: 'Artificial Intelligence & Data Science',
    email: 'venkatesh.r@smartcampus.edu',
    avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
    phone: '+91 98840 22113'
  },
  advisor_3b: {
    id: 'u-adv-3b',
    name: 'Dr. T. Sundaram',
    role: 'advisor',
    title: 'Class Advisor (III AIDS B - 2024 Batch)',
    department: 'Artificial Intelligence & Data Science',
    email: 'sundaram.t@smartcampus.edu',
    avatar: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150&auto=format&fit=crop&q=80',
    phone: '+91 98840 77889'
  },
  advisor_3c: {
    id: 'u-adv-3c',
    name: 'Dr. M. Anitha',
    role: 'advisor',
    title: 'Class Advisor (III AIDS C - 2024 Batch)',
    department: 'Artificial Intelligence & Data Science',
    email: 'anitha.m@smartcampus.edu',
    avatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&auto=format&fit=crop&q=80',
    phone: '+91 98410 33445'
  },
  advisor_3d: {
    id: 'u-adv-3d',
    name: 'Dr. S. Karthikeyan',
    role: 'advisor',
    title: 'Class Advisor (III AIDS D - 2024 Batch)',
    department: 'Artificial Intelligence & Data Science',
    email: 'karthikeyan.s@smartcampus.edu',
    avatar: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150&auto=format&fit=crop&q=80',
    phone: '+91 98410 88990'
  },
  advisor_4a: {
    id: 'u-adv-4a',
    name: 'Dr. K. Arulraj',
    role: 'advisor',
    title: 'Senior Advisor (IV AIDS A - 2023 Batch)',
    department: 'Artificial Intelligence & Data Science',
    email: 'arulraj.k@smartcampus.edu',
    avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
    phone: '+91 94432 10001'
  },
  advisor_4b: {
    id: 'u-adv-4b',
    name: 'Dr. S. Meenakshi',
    role: 'advisor',
    title: 'Senior Advisor (IV AIDS B - 2023 Batch)',
    department: 'Artificial Intelligence & Data Science',
    email: 'meenakshi.s@smartcampus.edu',
    avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80',
    phone: '+91 94432 10002'
  },
  faculty: {
    id: 'u-fac1',
    name: 'Dr. N. Balamurugan',
    role: 'faculty',
    title: 'Associate Professor (Machine Learning & Deep Learning)',
    department: 'Artificial Intelligence & Data Science',
    email: 'balamurugan.n@smartcampus.edu',
    avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80',
    phone: '+91 98410 33445'
  },
  student: {
    id: 's-25243001',
    name: 'ABINAYA G',
    role: 'student',
    title: 'Student (II AIDS A · E.Code: 25243001)',
    department: 'Artificial Intelligence & Data Science',
    email: '25243001@student.smartcampus.edu',
    avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
    phone: '+91 94432 10001'
  }
};

export const periodTimeSlots: { periodNumber: number; timeRange: string }[] = [
  { periodNumber: 1, timeRange: '08:45 - 09:35 AM' },
  { periodNumber: 2, timeRange: '09:35 - 10:25 AM' },
  { periodNumber: 3, timeRange: '10:45 - 11:35 AM' },
  { periodNumber: 4, timeRange: '11:35 - 12:25 PM' },
  { periodNumber: 5, timeRange: '01:15 - 02:05 PM' },
  { periodNumber: 6, timeRange: '02:05 - 02:55 PM' },
  { periodNumber: 7, timeRange: '03:05 - 03:55 PM' },
  { periodNumber: 8, timeRange: '03:55 - 04:45 PM' }
];

export const initialBatches: Batch[] = aidsRawData.batches as Batch[];
export const initialStudents: Student[] = aidsRawData.students as Student[];
export const initialPendingLeaves: LeaveRecord[] = aidsRawData.pendingLeaves as LeaveRecord[];
export const initialComplianceList: FacultyComplianceItem[] = aidsRawData.complianceList as FacultyComplianceItem[];
export const initialDepartmentSummary: DepartmentSummary = aidsRawData.departmentSummary as DepartmentSummary;
