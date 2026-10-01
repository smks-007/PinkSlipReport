package com.attendance.attendance_backend;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@EnableConfigurationProperties(GoogleDriveProperties.class)
public class GoogleDriveConfig {
}
