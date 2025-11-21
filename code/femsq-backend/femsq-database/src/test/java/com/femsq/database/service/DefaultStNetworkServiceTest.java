package com.femsq.database.service;

import static org.junit.jupiter.api.Assertions.*;

import com.femsq.database.dao.StNetworkDao;
import com.femsq.database.model.StNetwork;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class DefaultStNetworkServiceTest {

    private StubStNetworkDao stubDao;
    private StNetworkService service;

    @BeforeEach
    void setUp() {
        stubDao = new StubStNetworkDao();
        service = new DefaultStNetworkService(stubDao);
    }

    @Test
    void getAllDelegatesToDao() {
        List<StNetwork> networks = List.of(
                new StNetwork(1, "Стандартная"),
                new StNetwork(2, "2021-05, май")
        );
        stubDao.nextFindAll = networks;

        List<StNetwork> result = service.getAll();

        assertEquals(2, result.size());
        assertTrue(stubDao.findAllOrderedCalled);
    }

    private static final class StubStNetworkDao implements StNetworkDao {
        private List<StNetwork> nextFindAll = List.of();
        private boolean findAllOrderedCalled;

        @Override
        public List<StNetwork> findAllOrdered() {
            findAllOrderedCalled = true;
            return nextFindAll;
        }
    }
}
