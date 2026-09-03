package com.pinkslip.repositories;

import com.pinkslip.models.StaffAdvisor;
import com.pinkslip.models.Section;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface StaffAdvisorRepository extends JpaRepository<StaffAdvisor, Long> {
    Optional<StaffAdvisor> findByAssignedSection(Section section);
    Optional<StaffAdvisor> findByAssignedSectionSectionId(String sectionId);
    Optional<StaffAdvisor> findByStaffCode(String staffCode);
}
