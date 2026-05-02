package com.example.demo;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.secretsmanager.SecretsManagerClient;
import software.amazon.awssdk.services.secretsmanager.model.GetSecretValueRequest;
import software.amazon.awssdk.services.secretsmanager.model.GetSecretValueResponse;

@RestController
public class SecretsController {

    private final SecretsManagerClient client;
    private final String secretId;

    public SecretsController(
            @Value("${app.aws.region:ap-northeast-2}") String region,
            @Value("${app.aws.secret-name:etude-2/app-password}") String secretId) {
        this.client = SecretsManagerClient.builder()
                .region(Region.of(region))
                .build();
        this.secretId = secretId;
    }

    @GetMapping("/")
    public String hello() {
        return "etude-2 ok";
    }

    @GetMapping("/health")
    public String health() {
        return "ok";
    }

    @GetMapping("/secret")
    public String getSecret() {
        GetSecretValueResponse response = client.getSecretValue(
                GetSecretValueRequest.builder()
                        .secretId(secretId)
                        .build()
        );
        return response.secretString();
    }
}
