package com.pinkslip.repositories;

import com.pinkslip.models.BiometricPunch;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.time.ZonedDateTime;
import java.util.List;

@Repository
public interface BiometricPunchRepository extends JpaRepository<BiometricPunch, Long> {
    @Query("SELECT b FROM BiometricPunch b WHERE b.student.section.sectionId = :sectionId AND b.punchTimestamp >= :startTime ORDER BY b.punchTimestamp DESC")
    List<BiometricPunch> findRecentPunchesBySection(@Param("sectionId") String sectionId, @Param("startTime") ZonedDateTime startTime);

    List<BiometricPunch> findTop50ByOrderByPunchTimestampDesc();
}
