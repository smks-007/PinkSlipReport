package com.pinkslip.models;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "sections")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Section {
    @Id
    @Column(length = 15)
    private String sectionId; // e.g. "II-AIDS-B"

    @Column(nullable = false)
    private Integer year; // 1, 2, 3, 4

    @Column(nullable = false, length = 1)
    private String sectionName; // A, B, C, D

    @Builder.Default
    @Column(length = 60)
    private String department = "Artificial Intelligence and Data Science";

    @Builder.Default
    private Integer totalStrength = 0;

    @Builder.Default
    @Column(length = 20)
    private String academicYear = "2026-2027";
}
