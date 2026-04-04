package com.femsq.web.audit;

import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.femsq.database.model.RaA;
import com.femsq.database.model.RaDir;
import com.femsq.database.model.RaF;
import com.femsq.database.service.RaAService;
import com.femsq.database.service.RaDirService;
import com.femsq.database.service.RaExecutionService;
import com.femsq.database.service.RaFService;
import com.femsq.web.audit.runtime.AuditExecutionRegistry;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.api.io.TempDir;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

/**
 * Регрессия: {@link Error} в обработчике файла не должен оставлять ревизию в RUNNING без markFailed.
 */
@ExtendWith(MockitoExtension.class)
class AuditExecutionServiceImplThrowableTest {

    @Mock
    private RaAService raAService;
    @Mock
    private RaDirService raDirService;
    @Mock
    private RaExecutionService raExecutionService;
    @Mock
    private RaFService raFService;
    @Mock
    private AuditExecutionRegistry auditExecutionRegistry;

    @Test
    void executeAudit_whenProcessorThrowsError_callsMarkFailedNotMarkCompleted(@TempDir Path tempDir) throws Exception {
        long auditId = 999L;
        Path dataFile = tempDir.resolve("stub.xlsx");
        Files.createFile(dataFile);

        RaA audit = new RaA(
                auditId,
                "test-audit",
                LocalDateTime.now(),
                "",
                1,
                1,
                true,
                LocalDateTime.now(),
                LocalDateTime.now());
        when(raAService.getById(auditId)).thenReturn(Optional.of(audit));
        when(raExecutionService.getLatestByAuditId((int) auditId)).thenReturn(Optional.empty());
        when(raDirService.getById(1)).thenReturn(Optional.of(new RaDir(1, "dir", tempDir.toString(), null, null)));

        RaF raF = new RaF(1L, "stub.xlsx", 1, 5, true, true, null, null, null, null);
        when(raFService.getByDirId(1)).thenReturn(List.of(raF));

        AuditFileProcessor throwingProcessor = new AuditFileProcessor() {
            @Override
            public boolean supports(Integer type) {
                return Integer.valueOf(5).equals(type);
            }

            @Override
            public void process(AuditExecutionContext context, AuditFile file) {
                throw new AssertionError("simulated async Error");
            }
        };

        AuditExecutionServiceImpl service = new AuditExecutionServiceImpl(
                raAService,
                raDirService,
                raExecutionService,
                raFService,
                List.of(throwingProcessor),
                auditExecutionRegistry);

        service.executeAudit(auditId);

        verify(auditExecutionRegistry).markFailed(eq(auditId), anyString());
        verify(auditExecutionRegistry, never()).markCompleted(anyLong());
    }
}
