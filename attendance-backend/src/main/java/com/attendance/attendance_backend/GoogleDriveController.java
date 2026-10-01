package com.attendance.attendance_backend;

import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Map;

@RestController
@RequestMapping("/api/documents")
public class GoogleDriveController {
    private final GoogleDriveService driveService;

    public GoogleDriveController(GoogleDriveService driveService) {
        this.driveService = driveService;
    }

    @PostMapping(value = "/leave-letter", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<?> uploadLeaveLetter(
            @RequestPart("file") MultipartFile file,
            @RequestParam String slipId,
            @RequestParam String studentRollNumber) {
        try {
            return ResponseEntity.ok(driveService.uploadLeaveLetter(file, slipId, studentRollNumber));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        } catch (IllegalStateException e) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .body(Map.of("error", e.getMessage()));
        } catch (IOException e) {
            return ResponseEntity.internalServerError()
                    .body(Map.of("error", "Google Drive upload failed"));
        }
    }
}
