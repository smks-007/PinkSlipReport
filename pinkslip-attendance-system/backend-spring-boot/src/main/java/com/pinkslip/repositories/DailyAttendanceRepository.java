package com.pinkslip.repositories;

import com.pinkslip.models.DailyAttendance;
import com.pinkslip.models.Student;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface DailyAttendanceRepository extends JpaRepository<DailyAttendance, Long> {
    Optional<DailyAttendance> findByStudentAndAttendanceDate(Student student, LocalDate attendanceDate);
    
    @Query("SELECT d FROM DailyAttendance d WHERE d.student.section.sectionId = :sectionId AND d.attendanceDate = :date")
    List<DailyAttendance> findBySectionIdAndDate(@Param("sectionId") String sectionId, @Param("date") LocalDate date);

    @Query("SELECT d FROM DailyAttendance d WHERE d.attendanceDate = :date")
    List<DailyAttendance> findAllByDate(@Param("date") LocalDate date);
}
