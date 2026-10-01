package com.attendance.attendance_backend;

import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport;
import com.google.api.client.http.InputStreamContent;
import com.google.api.client.json.gson.GsonFactory;
import com.google.api.services.drive.Drive;
import com.google.api.services.drive.DriveScopes;
import com.google.api.services.drive.model.File;
import com.google.auth.http.HttpCredentialsAdapter;
import com.google.auth.oauth2.GoogleCredentials;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.security.GeneralSecurityException;
import java.util.Collections;
import java.util.Map;

@Service
public class GoogleDriveService {
    private static final GsonFactory JSON_FACTORY = GsonFactory.getDefaultInstance();
    private final GoogleDriveProperties properties;

    public GoogleDriveService(GoogleDriveProperties properties) {
        this.properties = properties;
    }

    public Map<String, String> uploadLeaveLetter(MultipartFile upload, String slipId,
                                                  String studentRollNumber) throws IOException {
        if (!properties.isConfigured()) {
            throw new IllegalStateException("Google Drive is not configured on the backend");
        }
        if (upload.isEmpty()) {
            throw new IllegalArgumentException("The uploaded letter is empty");
        }
        if (upload.getSize() > 10 * 1024 * 1024) {
            throw new IllegalArgumentException("The uploaded letter exceeds the 10 MB limit");
        }

        Drive drive = driveClient();
        String safeName = (studentRollNumber + "_" + slipId + "_" + upload.getOriginalFilename())
                .replaceAll("[^a-zA-Z0-9._-]", "_");
        File metadata = new File()
                .setName(safeName)
                .setParents(Collections.singletonList(properties.folderId()))
                .setDescription("PinkSlipReport student leave letter; slip=" + slipId);
        InputStreamContent content = new InputStreamContent(
                upload.getContentType() == null ? "application/octet-stream" : upload.getContentType(),
                new ByteArrayInputStream(upload.getBytes()));
        content.setLength(upload.getSize());

        File created = drive.files().create(metadata, content)
                .setFields("id,name,mimeType,webViewLink,createdTime")
                .execute();
        return Map.of(
                "fileId", created.getId(),
                "fileName", created.getName(),
                "mimeType", created.getMimeType(),
                "webViewLink", created.getWebViewLink() == null ? "" : created.getWebViewLink());
    }

    public byte[] download(String fileId) throws IOException {
        if (!properties.isConfigured()) throw new IllegalStateException("Google Drive is not configured");
        return driveClient().files().get(fileId).executeMedia().getContent().readAllBytes();
    }

    private Drive driveClient() throws IOException {
        try {
            GoogleCredentials credentials = GoogleCredentials
                    .fromStream(new ByteArrayInputStream(properties.credentialsJson().getBytes()))
                    .createScoped(Collections.singleton(DriveScopes.DRIVE));
            return new Drive.Builder(
                    GoogleNetHttpTransport.newTrustedTransport(), JSON_FACTORY,
                    new HttpCredentialsAdapter(credentials))
                    .setApplicationName("PinkSlipReport")
                    .build();
        } catch (GeneralSecurityException e) {
            throw new IOException("Could not initialize Google Drive client", e);
        }
    }
}
