package com.pinkslip.services;

import com.pinkslip.models.*;
import com.pinkslip.repositories.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.ZonedDateTime;
import java.util.List;

@Service
public class BiometricSyncService {

    @Autowired
    private BiometricPunchRepository biometricPunchRepository;

    @Autowired
    private AuditLogRepository auditLogRepository;

    public List<BiometricPunch> getRecentPunches() {
        return biometricPunchRepository.findTop50ByOrderByPunchTimestampDesc();
    }

    public List<BiometricPunch> getRecentPunchesForSection(String sectionId) {
        return biometricPunchRepository.findRecentPunchesBySection(sectionId, ZonedDateTime.now().minusDays(1));
    }

    @Transactional
    public void deleteBiometricPunchByHod(Long punchId, User hodUser, String reason) {
        if (hodUser.getRole() != Role.HOD) {
            throw new SecurityException("Access Denied: Only HOD possesses authority to delete biometric attendance records.");
        }

        BiometricPunch punch = biometricPunchRepository.findById(punchId)
                .orElseThrow(() -> new IllegalArgumentException("Biometric record not found"));

        // Audit Trail
        AuditLog audit = AuditLog.builder()
                .actor(hodUser)
                .action("DELETE_BIOMETRIC_PUNCH")
                .targetTable("biometric_punches")
                .targetId(String.valueOf(punchId))
                .oldData("Student: " + punch.getStudent().getRollNumber() + " at " + punch.getPunchTimestamp())
                .newData("Reason for deletion: " + reason)
                .build();
        auditLogRepository.save(audit);

        biometricPunchRepository.delete(punch);
    }

    @Transactional
    public BiometricPunch overrideBiometricPunchByHod(Long punchId, User hodUser, String newType, String reason) {
        if (hodUser.getRole() != Role.HOD) {
            throw new SecurityException("Access Denied: Only HOD possesses authority to override biometric raw logs.");
        }

        BiometricPunch punch = biometricPunchRepository.findById(punchId)
                .orElseThrow(() -> new IllegalArgumentException("Biometric record not found"));

        punch.setPunchType(newType);
        punch.setIsOverridden(true);
        punch.setOverrideReason(reason);
        punch.setModifiedBy(hodUser);

        AuditLog audit = AuditLog.builder()
                .actor(hodUser)
                .action("OVERRIDE_BIOMETRIC_PUNCH")
                .targetTable("biometric_punches")
                .targetId(String.valueOf(punchId))
                .oldData("Type: " + punch.getPunchType())
                .newData("NewType: " + newType + " | Reason: " + reason)
                .build();
        auditLogRepository.save(audit);

        return biometricPunchRepository.save(punch);
    }
}
