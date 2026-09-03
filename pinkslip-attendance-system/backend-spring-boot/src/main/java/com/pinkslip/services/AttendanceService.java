package com.pinkslip.services;

import com.pinkslip.models.*;
import com.pinkslip.repositories.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.*;

@Service
public class AttendanceService {

    @Autowired
    private DailyAttendanceRepository dailyAttendanceRepository;

    @Autowired
    private StudentRepository studentRepository;

    @Autowired
    private SectionRepository sectionRepository;

    @Autowired
    private LeaveSlipRepository leaveSlipRepository;

    public Map<String, Object> getAdvisorDashboardMetrics(String sectionId, LocalDate date) {
        Section section = sectionRepository.findById(sectionId)
                .orElseThrow(() -> new IllegalArgumentException("Section not found: " + sectionId));

        List<Student> students = studentRepository.findBySection(section);
        int totalStrength = students.size() > 0 ? students.size() : section.getTotalStrength();

        List<DailyAttendance> records = dailyAttendanceRepository.findBySectionIdAndDate(sectionId, date);
        long presentCount = records.stream().filter(DailyAttendance::getIsPresent).count();
        long absentCount = totalStrength - presentCount;
        double attendancePercentage = totalStrength > 0 ? ((double) presentCount / totalStrength) * 100.0 : 0.0;

        List<LeaveSlip> pendingSlips = leaveSlipRepository.findBySectionId(sectionId);
        long pendingHodCount = pendingSlips.stream().filter(s -> s.getStatus() == SlipStatus.PENDING_HOD).count();
        long readyReturnCount = pendingSlips.stream().filter(s -> s.getStatus() == SlipStatus.APPROVED).count();

        Map<String, Object> metrics = new HashMap<>();
        metrics.put("sectionId", sectionId);
        metrics.put("totalStrength", totalStrength);
        metrics.put("presentCount", presentCount);
        metrics.put("absentCount", absentCount);
        metrics.put("attendancePercentage", Math.round(attendancePercentage * 100.0) / 100.0);
        metrics.put("pendingSlipsCount", pendingHodCount);
        metrics.put("readyReturnCount", readyReturnCount);
        return metrics;
    }

    public Map<String, Object> getHodDepartmentMetrics(LocalDate date) {
        List<Section> allSections = sectionRepository.findAll();
        int totalStudents = allSections.stream().mapToInt(Section::getTotalStrength).sum();
        List<DailyAttendance> allRecords = dailyAttendanceRepository.findAllByDate(date);

        long totalPresent = allRecords.stream().filter(DailyAttendance::getIsPresent).count();
        double deptPercentage = totalStudents > 0 ? ((double) totalPresent / totalStudents) * 100.0 : 0.0;

        List<LeaveSlip> awaitingHod = leaveSlipRepository.findAwaitingHodApproval();

        Map<String, Object> hodMetrics = new HashMap<>();
        hodMetrics.put("totalDepartmentStudents", totalStudents);
        hodMetrics.put("totalPresent", totalPresent);
        hodMetrics.put("departmentAttendancePercentage", Math.round(deptPercentage * 10.0) / 10.0);
        hodMetrics.put("awaitingHodCount", awaitingHod.size());
        hodMetrics.put("totalSections", allSections.size()); // 14 sections
        return hodMetrics;
    }

    @Transactional
    public DailyAttendance updateAttendanceByAdvisor(Long studentId, LocalDate date, boolean isPresent, LeaveType leaveType, User advisor) {
        Student student = studentRepository.findById(studentId)
                .orElseThrow(() -> new IllegalArgumentException("Student not found"));

        DailyAttendance attendance = dailyAttendanceRepository.findByStudentAndAttendanceDate(student, date)
                .orElseGet(() -> DailyAttendance.builder()
                        .student(student)
                        .attendanceDate(date)
                        .build());

        attendance.setIsPresent(isPresent);
        attendance.setLeaveType(leaveType);
        attendance.setMarkedBy(advisor);
        attendance.setPunchMethod(PunchSource.MANUAL_OVERRIDE);
        return dailyAttendanceRepository.save(attendance);
    }
}
