package com.attendance.attendance_backend;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "google.drive")
public record GoogleDriveProperties(String credentialsJson, String folderId) {
    public boolean isConfigured() {
        return credentialsJson != null && !credentialsJson.isBlank()
                && folderId != null && !folderId.isBlank();
    }
}
