package com.pinkslip.models;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "staff_advisors")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StaffAdvisor {
    @Id
    private Long staffId;

    @OneToOne
    @MapsId
    @JoinColumn(name = "staff_id")
    private User user;

    @Column(unique = true, nullable = false, length = 20)
    private String staffCode;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assigned_section")
    private Section assignedSection;

    @Builder.Default
    @Column(length = 50)
    private String designation = "Assistant Professor";

    @Column(length = 50)
    private String cabinLocation;
}
