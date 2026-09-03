package com.pinkslip.repositories;

import com.pinkslip.models.Student;
import com.pinkslip.models.Section;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface StudentRepository extends JpaRepository<Student, Long> {
    Optional<Student> findByRollNumber(String rollNumber);
    Optional<Student> findByRegisterNumber(String registerNumber);
    List<Student> findBySection(Section section);
    List<Student> findBySectionSectionId(String sectionId);
}
