package org.jvnet.hudson.plugins.platformlabeler;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.is;

import java.io.File;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.Arrays;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

class LsbReleaseFakeFileTest {
    @TempDir
    private File dataDir;

    private final String fakeDistributorId = "megasupercorp";
    private final String fakeRelease = "1.2.3";
    private LsbRelease fakeLsbRelease;

    @BeforeEach
    void initialize() throws Exception {
        List<String> data = Arrays.asList(
                "Unexpected line that should be ignored",
                "Distributor ID: " + fakeDistributorId,
                "Release: " + fakeRelease);
        File dataFile = new File(dataDir, "lsb_release_fake");
        Files.write(dataFile.toPath(), data, StandardCharsets.UTF_8);
        fakeLsbRelease = new LsbRelease(dataFile);
    }

    @Test
    void matchingFakeDistributorId() {
        assertThat(fakeLsbRelease.distributorId(), is(fakeDistributorId));
    }

    @Test
    void matchingFakeRelease() {
        assertThat(fakeLsbRelease.release(), is(fakeRelease));
    }
}
