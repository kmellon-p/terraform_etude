package com.example.demo;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.secretsmanager.SecretsManagerClient;
import software.amazon.awssdk.services.secretsmanager.model.GetSecretValueRequest;
import software.amazon.awssdk.services.secretsmanager.model.GetSecretValueResponse;

@RestController
public class SecretsController {

    private final SecretsManagerClient client = SecretsManagerClient.builder()
            .region(Region.AP_NORTHEAST_2)
            .build();

    @GetMapping("/")
    public String getSecrets() {
        GetSecretValueResponse response = client.getSecretValue(
                GetSecretValueRequest.builder()
                        .secretId("etude-1/app-password")
                        .build()
        );
        return response.secretString();
    }
}