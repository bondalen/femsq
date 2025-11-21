package com.femsq.database.service;

import static org.junit.jupiter.api.Assertions.*;

import com.femsq.database.dao.InvestmentProgramDao;
import com.femsq.database.model.InvestmentProgram;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class DefaultInvestmentProgramServiceTest {

    private StubInvestmentProgramDao stubDao;
    private InvestmentProgramService service;

    @BeforeEach
    void setUp() {
        stubDao = new StubInvestmentProgramDao();
        service = new DefaultInvestmentProgramService(stubDao);
    }

    @Test
    void getAllDelegatesToDao() {
        List<InvestmentProgram> programs = List.of(
                new InvestmentProgram(1, "Газпром, ПАО, 2021 № 1. Утверждённая"),
                new InvestmentProgram(2, "Газпром, ПАО, 2022 № 1. Утверждённая")
        );
        stubDao.nextFindAll = programs;

        List<InvestmentProgram> result = service.getAll();

        assertEquals(2, result.size());
        assertTrue(stubDao.findAllWithDisplayNameCalled);
    }

    private static final class StubInvestmentProgramDao implements InvestmentProgramDao {
        private List<InvestmentProgram> nextFindAll = List.of();
        private boolean findAllWithDisplayNameCalled;

        @Override
        public List<InvestmentProgram> findAllWithDisplayName() {
            findAllWithDisplayNameCalled = true;
            return nextFindAll;
        }
    }
}
