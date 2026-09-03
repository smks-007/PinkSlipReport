package com.pinkslip.services;

import com.pinkslip.models.*;
import com.pinkslip.repositories.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.ZonedDateTime;
import java.util.List;

@Service
public class PinkSlipWorkflowService {

    @Autowired
    private LeaveSlipRepository leaveSlipRepository;

    @Autowired
    private StudentRepository studentRepository;

    public List<LeaveSlip> getSlipsForSection(String sectionId) {
        return leaveSlipRepository.findBySectionId(sectionId);
    }

    public List<LeaveSlip> getSlipsAwaitingHod() {
        return leaveSlipRepository.findAwaitingHodApproval();
    }

    @Transactional
    public LeaveSlip submitLeaveSlipByStudent(Long studentId, String reason, LocalDate fromDate, LocalDate toDate, boolean isInformed) {
        Student student = studentRepository.findById(studentId)
                .orElseThrow(() -> new IllegalArgumentException("Student not found"));

        LeaveSlip slip = LeaveSlip.builder()
                .student(student)
                .reason(reason)
                .fromDate(fromDate)
                .toDate(toDate)
                .isInformed(isInformed)
                .dueDate(fromDate.plusDays(3))
                .status(SlipStatus.SUBMITTED)
                .letterSubmittedToAdvisorDate(ZonedDateTime.now())
                .build();

        return leaveSlipRepository.save(slip);
    }

    @Transactional
    public LeaveSlip forwardToHodByAdvisor(Long slipId, String remarks) {
        LeaveSlip slip = leaveSlipRepository.findById(slipId)
                .orElseThrow(() -> new IllegalArgumentException("Slip not found"));

        slip.setAdvisorRemarks(remarks);
        slip.setForwardedToHodDate(ZonedDateTime.now());
        slip.setStatus(SlipStatus.PENDING_HOD);
        return leaveSlipRepository.save(slip);
    }

    @Transactional
    public LeaveSlip reviewSlipByHod(Long slipId, boolean approve, String remarks, User hodUser) {
        if (hodUser.getRole() != Role.HOD) {
            throw new SecurityException("Access Denied: Only HOD can approve or reject Pink Slips.");
        }

        LeaveSlip slip = leaveSlipRepository.findById(slipId)
                .orElseThrow(() -> new IllegalArgumentException("Slip not found"));

        if (approve) {
            slip.setStatus(SlipStatus.APPROVED);
            slip.setApprovedByHodDate(ZonedDateTime.now());
        } else {
            slip.setStatus(SlipStatus.REJECTED);
        }
        slip.setHodRemarks(remarks);
        return leaveSlipRepository.save(slip);
    }
}
