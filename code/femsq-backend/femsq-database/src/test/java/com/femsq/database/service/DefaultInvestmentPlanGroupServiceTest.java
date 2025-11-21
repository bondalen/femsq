package com.femsq.database.service;

import static org.junit.jupiter.api.Assertions.*;

import com.femsq.database.dao.InvestmentPlanGroupDao;
import com.femsq.database.model.InvestmentPlanGroup;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class DefaultInvestmentPlanGroupServiceTest {

    private StubInvestmentPlanGroupDao stubDao;
    private InvestmentPlanGroupService service;

    @BeforeEach
    void setUp() {
        stubDao = new StubInvestmentPlanGroupDao();
        service = new DefaultInvestmentPlanGroupService(stubDao);
    }

    @Test
    void getAllDelegatesToDao() {
        List<InvestmentPlanGroup> groups = List.of(
                new InvestmentPlanGroup(1, "2021. 2 Корр. по I-му кварталу. Группа планов на июнь 2021"),
                new InvestmentPlanGroup(2, "2022. 1 Утверждённая. Группа планов на январь 2022-го года")
        );
        stubDao.nextFindAll = groups;

        List<InvestmentPlanGroup> result = service.getAll();

        assertEquals(2, result.size());
        assertTrue(stubDao.findAllWithDisplayNameCalled);
    }

    private static final class StubInvestmentPlanGroupDao implements InvestmentPlanGroupDao {
        private List<InvestmentPlanGroup> nextFindAll = List.of();
        private boolean findAllWithDisplayNameCalled;

        @Override
        public List<InvestmentPlanGroup> findAllWithDisplayName() {
            findAllWithDisplayNameCalled = true;
            return nextFindAll;
        }
    }
}
