package com.pinkslip.controllers;

import com.pinkslip.models.Role;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/auth")
@CrossOrigin(origins = "*")
public class AuthController {

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody Map<String, String> request) {
        String email = request.get("email");
        String password = request.get("password");

        Map<String, Object> response = new HashMap<>();
        if ("hod.aids@vsb.ac.in".equalsIgnoreCase(email)) {
            response.put("token", "JWT_TOKEN_HOD_DEMO");
            response.put("role", Role.HOD);
            response.put("name", "Dr. R. Balamurugan");
            response.put("department", "AI & DS");
            response.put("college", "V.S.B. Engineering College");
            return ResponseEntity.ok(response);
        } else if ("muthulakshmi.aids@vsb.ac.in".equalsIgnoreCase(email) || email.contains("advisor")) {
            response.put("token", "JWT_TOKEN_ADVISOR_DEMO");
            response.put("role", Role.ADVISOR);
            response.put("name", "Mrs. S. Muthulakshmi");
            response.put("assignedSection", "II-AIDS-B");
            response.put("sectionLabel", "II AI&DS - Section B");
            response.put("college", "V.S.B. Engineering College");
            return ResponseEntity.ok(response);
        } else {
            response.put("token", "JWT_TOKEN_STUDENT_DEMO");
            response.put("role", Role.STUDENT);
            response.put("name", "Lithesh Hari R");
            response.put("rollNumber", "25243100");
            response.put("sectionLabel", "II AI&DS - Section B");
            return ResponseEntity.ok(response);
        }
    }
}
