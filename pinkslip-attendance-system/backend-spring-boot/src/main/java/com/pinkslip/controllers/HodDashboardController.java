package com.pinkslip.controllers;

import com.pinkslip.models.*;
import com.pinkslip.services.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/hod")
@CrossOrigin(origins = "*")
public class HodDashboardController {

    @Autowired
    private AttendanceService attendanceService;

    @Autowired
    private PinkSlipWorkflowService pinkSlipWorkflowService;

    @Autowired
    private BiometricSyncService biometricSyncService;

    @GetMapping("/metrics")
    public ResponseEntity<?> getDepartmentMetrics() {
        return ResponseEntity.ok(attendanceService.getHodDepartmentMetrics(LocalDate.now()));
    }

    @GetMapping("/pending-slips")
    public ResponseEntity<List<LeaveSlip>> getAwaitingHodSlips() {
        return ResponseEntity.ok(pinkSlipWorkflowService.getSlipsAwaitingHod());
    }

    @PostMapping("/slips/{slipId}/review")
    public ResponseEntity<?> reviewSlip(@PathVariable Long slipId, @RequestBody Map<String, Object> body) {
        boolean approve = Boolean.TRUE.equals(body.get("approve"));
        String remarks = (String) body.getOrDefault("remarks", "Reviewed by HOD");
        User hodUser = User.builder().userId(1L).role(Role.HOD).fullName("Dr. R. Balamurugan").build();
        return ResponseEntity.ok(pinkSlipWorkflowService.reviewSlipByHod(slipId, approve, remarks, hodUser));
    }

    @DeleteMapping("/biometric/{punchId}")
    public ResponseEntity<?> deleteBiometricPunch(@PathVariable Long punchId, @RequestParam(defaultValue = "Manual delete by HOD") String reason) {
        User hodUser = User.builder().userId(1L).role(Role.HOD).fullName("Dr. R. Balamurugan").build();
        biometricSyncService.deleteBiometricPunchByHod(punchId, hodUser, reason);
        return ResponseEntity.ok(Map.of("message", "Biometric record successfully deleted by HOD with audit logged."));
    }
}
