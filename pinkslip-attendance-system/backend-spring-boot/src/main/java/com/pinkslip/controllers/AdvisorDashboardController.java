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
@RequestMapping("/advisor")
@CrossOrigin(origins = "*")
public class AdvisorDashboardController {

    @Autowired
    private AttendanceService attendanceService;

    @Autowired
    private PinkSlipWorkflowService pinkSlipWorkflowService;

    @GetMapping("/metrics")
    public ResponseEntity<?> getAdvisorMetrics(@RequestParam(defaultValue = "II-AIDS-B") String sectionId) {
        return ResponseEntity.ok(attendanceService.getAdvisorDashboardMetrics(sectionId, LocalDate.now()));
    }

    @GetMapping("/slips")
    public ResponseEntity<List<LeaveSlip>> getSectionSlips(@RequestParam(defaultValue = "II-AIDS-B") String sectionId) {
        return ResponseEntity.ok(pinkSlipWorkflowService.getSlipsForSection(sectionId));
    }

    @PostMapping("/slips/{slipId}/forward")
    public ResponseEntity<?> forwardToHod(@PathVariable Long slipId, @RequestBody Map<String, String> body) {
        String remarks = body.getOrDefault("remarks", "Verified against attendance register. Forwarded to HOD.");
        return ResponseEntity.ok(pinkSlipWorkflowService.forwardToHodByAdvisor(slipId, remarks));
    }
}
