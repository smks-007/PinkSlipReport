package com.pinkslip.models;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZonedDateTime;

@Entity
@Table(name = "daily_attendance", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"student_id", "attendance_date"})
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DailyAttendance {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long attendanceId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "student_id", nullable = false)
    private Student student;

    @Column(nullable = false)
    private LocalDate attendanceDate;

    @Builder.Default
    @Column(nullable = false)
    private Boolean isPresent = false;

    @Enumerated(EnumType.STRING)
    private LeaveType leaveType;

    private LocalTime inTime;
    private LocalTime outTime;

    @Enumerated(EnumType.STRING)
    @Builder.Default
    private PunchSource punchMethod = PunchSource.BIOMETRIC_FINGERPRINT;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "marked_by")
    private User markedBy;

    @Builder.Default
    private ZonedDateTime markedAt = ZonedDateTime.now();

    @Builder.Default
    private ZonedDateTime updatedAt = ZonedDateTime.now();
}
