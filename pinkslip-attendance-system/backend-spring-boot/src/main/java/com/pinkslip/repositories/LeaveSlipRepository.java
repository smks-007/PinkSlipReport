package com.pinkslip.repositories;

import com.pinkslip.models.LeaveSlip;
import com.pinkslip.models.SlipStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface LeaveSlipRepository extends JpaRepository<LeaveSlip, Long> {
    List<LeaveSlip> findByStatus(SlipStatus status);

    @Query("SELECT l FROM LeaveSlip l WHERE l.student.section.sectionId = :sectionId ORDER BY l.createdAt DESC")
    List<LeaveSlip> findBySectionId(@Param("sectionId") String sectionId);

    @Query("SELECT l FROM LeaveSlip l WHERE l.status = 'PENDING_HOD' ORDER BY l.forwardedToHodDate ASC")
    List<LeaveSlip> findAwaitingHodApproval();

    List<LeaveSlip> findByStudentStudentId(Long studentId);
}
