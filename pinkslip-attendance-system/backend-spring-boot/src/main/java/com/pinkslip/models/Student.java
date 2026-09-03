package com.pinkslip.models;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "students")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Student {
    @Id
    private Long studentId;

    @OneToOne
    @MapsId
    @JoinColumn(name = "student_id")
    private User user;

    @Column(unique = true, nullable = false, length = 20)
    private String rollNumber;

    @Column(unique = true, nullable = false, length = 20)
    private String registerNumber;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "section_id", nullable = false)
    private Section section;

    @Column(length = 100)
    private String guardianName;

    @Column(length = 20)
    private String guardianContact;

    @Builder.Default
    private Integer leavesTakenYtd = 0;

    @Column(columnDefinition = "TEXT")
    private String faceEncoding;
}
