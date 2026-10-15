package com.example.releasedockerdemo;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class ReleaseInfoController {

    @Value("${app.version:unknown}")
    private String appVersion;

    @GetMapping("/")
    public Map<String, String> releaseInfo() {
        return Map.of(
            "app",        "Release Docker Demo",
            "version",    appVersion,
            "java",       System.getProperty("java.version"),
            "status",     "running"
        );
    }

    @GetMapping("/health")
    public Map<String, String> health() {
        return Map.of("status", "UP");
    }
}
