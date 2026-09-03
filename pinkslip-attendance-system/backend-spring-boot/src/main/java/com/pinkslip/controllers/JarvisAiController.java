package com.pinkslip.controllers;

import com.pinkslip.models.User;
import com.pinkslip.models.Role;
import com.pinkslip.services.JarvisAiService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/jarvis")
@CrossOrigin(origins = "*")
public class JarvisAiController {

    @Autowired
    private JarvisAiService jarvisAiService;

    @PostMapping("/query")
    public ResponseEntity<?> askJarvis(@RequestBody Map<String, String> payload) {
        String prompt = payload.getOrDefault("prompt", "");
        String sectionId = payload.getOrDefault("sectionId", "II-AIDS-B");
        User dummyUser = User.builder().userId(2L).role(Role.ADVISOR).fullName("Mrs. S. Muthulakshmi").build();
        return ResponseEntity.ok(jarvisAiService.processJarvisQuery(prompt, dummyUser, sectionId));
    }
}
