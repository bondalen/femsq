package com.femsq.database.service;

import com.femsq.database.config.ConfigurationFileManager;
import com.femsq.database.config.ConfigurationValidator;
import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.dao.JdbcStIpgStructureDao;
import com.femsq.database.model.StCostNm;
import com.femsq.database.model.StIpgTreeNode;
import com.femsq.database.model.StNetworkFull;
import java.util.Arrays;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Приёмка §4.0.3: схемы затрат, {@code fnSt(3,214)}, канон 212/195/172/187, CRUD smoke с cleanup.
 *
 * <p>Запуск из {@code femsq-database}: {@code mvn -q exec:java
 * -Dexec.mainClass=com.femsq.database.service.StCostStructureSmokeMain
 * -Dexec.classpathScope=test}
 */
public final class StCostStructureSmokeMain {

    private static final int COST_NET = 3;
    private static final int ROOT = 214;
    private static final int CANON_TOTAL = 212;
    private static final int[] CANON_PARTS = {195, 172, 187};
    /** Безопасный родитель для temp-узла (Прочие). */
    private static final int SMOKE_PARENT = 187;

    private StCostStructureSmokeMain() {
    }

    public static void main(String[] args) throws Exception {
        DatabaseConfigurationService config = new DatabaseConfigurationService(
                new ConfigurationFileManager(),
                new ConfigurationValidator());
        try (ConnectionFactory connections = new ConnectionFactory(config)) {
            JdbcStIpgStructureDao dao = new JdbcStIpgStructureDao(connections, config);

            List<StNetworkFull> nets = dao.findNetworksByType(2);
            System.out.println("costNetworks=" + nets.size());
            for (StNetworkFull net : nets) {
                System.out.printf("  stNet=%d type=%d root=%d name=%s%n",
                        net.stnKey(), net.stnType(), net.stnRoot(), net.stnName());
            }
            if (nets.stream().noneMatch(net -> net.stnKey() == COST_NET && net.stnRoot() == ROOT)) {
                throw new IllegalStateException("Ожидалась схема stNet=3 root=214");
            }

            List<StIpgTreeNode> tree = dao.findTree(COST_NET, ROOT);
            System.out.println("fnSt(3,214) nodes=" + tree.size());
            assertCanon(tree);

            for (int key : new int[]{ROOT, CANON_TOTAL, 195, 172, 187}) {
                List<StCostNm> names = dao.findCostNodeNames(key);
                String primary = names.isEmpty() ? "—" : names.get(0).stcnNm();
                System.out.printf("  stc=%d names=%d primary=%s%n", key, names.size(), primary);
            }

            String token = "femsq-403-" + System.currentTimeMillis();
            System.out.println("CRUD smoke under parent=" + SMOKE_PARENT + " name=" + token);
            int child = dao.createChildNode(COST_NET, SMOKE_PARENT, token, null);
            System.out.println("  created stc=" + child);
            dao.renameNode(child, token + "-ren");
            int nmKey = dao.addCostNodeName(child, token + "-alias");
            System.out.println("  renamed; alias stcnKey=" + nmKey);
            List<StCostNm> afterNames = dao.findCostNodeNames(child);
            if (afterNames.size() < 2) {
                throw new IllegalStateException("Ожидались ≥2 имени после alias");
            }
            dao.detachEdgeFromNetwork(COST_NET, SMOKE_PARENT, child);
            System.out.println("  detached");
            dao.deleteNode(COST_NET, child);
            System.out.println("  deleted stc=" + child);

            List<StIpgTreeNode> after = dao.findTree(COST_NET, ROOT);
            assertCanon(after);
            if (after.stream().anyMatch(node -> node.childKey() == child)) {
                throw new IllegalStateException("Temp-узел остался в дереве: " + child);
            }
            System.out.println("PASS §4.0.3 stCost structure smoke");
        }
    }

    /**
     * Минимум канона: 212 в дереве и ≥1 прямое ребро 212→{195,172,187}.
     */
    private static void assertCanon(List<StIpgTreeNode> tree) {
        Set<Integer> keys = tree.stream().map(StIpgTreeNode::childKey).collect(Collectors.toSet());
        if (!keys.contains(CANON_TOTAL)) {
            throw new IllegalStateException("Нет узла 212 в fnSt");
        }
        long linked = Arrays.stream(CANON_PARTS)
                .filter(part -> tree.stream().anyMatch(
                        node -> node.childKey() == part && node.parentKey() != null
                                && node.parentKey() == CANON_TOTAL))
                .count();
        System.out.printf("canon: total=%s linkedParts=%d/3%n", keys.contains(CANON_TOTAL), linked);
        if (linked < 1) {
            throw new IllegalStateException("Канон не satisfied: нет рёбер 212→части");
        }
    }
}
