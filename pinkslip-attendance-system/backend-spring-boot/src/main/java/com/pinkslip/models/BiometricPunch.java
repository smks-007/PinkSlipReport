package com.pinkslip.models;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.ZonedDateTime;

@Entity
@Table(name = "biometric_punches")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BiometricPunch {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long punchId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "student_id", nullable = false)
    private Student student;

    @Column(nullable = false)
    private ZonedDateTime punchTimestamp;

    @Column(nullable = false, length = 10)
    private String punchType; // "IN" or "OUT"

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private PunchSource source;

    @Builder.Default
    @Column(length = 50)
    private String deviceId = "BIO-GATE-01";

    @Builder.Default
    @Column(precision = 5, scale = 2)
    private BigDecimal confidenceScore = new BigDecimal("98.50");

    @Builder.Default
    private Boolean isOverridden = false;

    @Column(columnDefinition = "TEXT")
    private String overrideReason;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "modified_by")
    private User modifiedBy;
}
