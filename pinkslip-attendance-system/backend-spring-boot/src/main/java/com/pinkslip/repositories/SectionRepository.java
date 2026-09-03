package com.pinkslip.repositories;

import com.pinkslip.models.Section;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface SectionRepository extends JpaRepository<Section, String> {
    List<Section> findByYearOrderBySectionNameAsc(Integer year);
}
