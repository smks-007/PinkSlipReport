package com.pinkslip.models;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.ZonedDateTime;

@Entity
@Table(name = "leave_slips")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LeaveSlip {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long slipId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "student_id", nullable = false)
    private Student student;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String reason;

    @Column(nullable = false)
    private LocalDate fromDate;

    @Column(nullable = false)
    private LocalDate toDate;

    @Builder.Default
    private Boolean isInformed = true;

    @Column(columnDefinition = "TEXT")
    private String letterDocumentUrl;

    private ZonedDateTime letterSubmittedToAdvisorDate;
    private ZonedDateTime forwardedToHodDate;
    private LocalDate dueDate;

    @Enumerated(EnumType.STRING)
    @Builder.Default
    private SlipStatus status = SlipStatus.SUBMITTED;

    @Column(columnDefinition = "TEXT")
    private String advisorRemarks;

    @Column(columnDefinition = "TEXT")
    private String hodRemarks;

    private ZonedDateTime approvedByHodDate;

    @Builder.Default
    private ZonedDateTime createdAt = ZonedDateTime.now();
}
