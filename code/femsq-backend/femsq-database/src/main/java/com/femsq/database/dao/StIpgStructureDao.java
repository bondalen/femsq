package com.femsq.database.dao;

import com.femsq.database.model.StCostNm;
import com.femsq.database.model.StIpgNm;
import com.femsq.database.model.StIpgTreeNode;
import com.femsq.database.model.StNetworkFull;
import java.util.List;
import java.util.Optional;

/**
 * DAO структуры ИПГ / затрат: схемы {@code stNet}, дерево {@code fnSt}, узлы/рёбра.
 * {@code stnType=1} → {@code stIpg}/{@code stIpgNm}; {@code stnType=2} → {@code stCost}/{@code stCostNm}.
 */
public interface StIpgStructureDao {

    /**
     * Схемы заданного типа ({@code 1}=ИПГ, {@code 2}=затраты).
     */
    List<StNetworkFull> findNetworksByType(int stnType);

    /**
     * Схема по ключу.
     */
    Optional<StNetworkFull> findNetworkByKey(int stnKey);

    /**
     * Обход {@code ags.fnSt(stNetKey, rootKey)}.
     */
    List<StIpgTreeNode> findTree(int stNetKey, int rootKey);

    /**
     * Создать схему type=1 (или указанного типа).
     */
    StNetworkFull createNetwork(int stnType, String name, int rootKey);

    /**
     * Переименовать схему.
     */
    StNetworkFull updateNetworkName(int stnKey, String name);

    /**
     * Клон схемы: новый {@code stNet} + копия {@code stNetPn} (узлы shared).
     */
    StNetworkFull cloneNetwork(int sourceKey, String newName);

    /**
     * Создать узел под родителем в схеме ({@code stnType=1|2}).
     *
     * @return ключ нового узла ({@code stKey}/{@code stiKey}/{@code stcKey})
     */
    int createChildNode(int stNetKey, int parentKey, String name, Integer stpnNum);

    /**
     * Переименовать узел (первичное {@code stIpgNm} или {@code stCostNm} по {@code st.stType}).
     */
    void renameNode(int stiKey, String name);

    /**
     * Все имена узла ИПГ ({@code stIpgNm}).
     */
    List<StIpgNm> findNodeNames(int stiKey);

    /**
     * Все имена узла затрат ({@code stCostNm}).
     */
    List<StCostNm> findCostNodeNames(int stcKey);

    /**
     * Добавить alias-имя узла ИПГ (не затирая существующие).
     *
     * @return ключ новой строки {@code stinKey}
     */
    int addNodeName(int stiKey, String name);

    /**
     * Добавить alias-имя узла затрат.
     *
     * @return ключ новой строки {@code stcnKey}
     */
    int addCostNodeName(int stcKey, String name);

    /**
     * Включить существующий узел как ребёнка parent в схеме (findOrCreate stRel + stNetPn).
     */
    void attachEdgeToNetwork(int stNetKey, int parentKey, int childKey, Integer stpnNum);

    /**
     * Перенос ребёнка в схеме: detach от fromParent + attach к toParent (одна транзакция).
     */
    void moveEdgeInNetwork(int stNetKey, int childKey, int fromParentKey, int toParentKey, Integer stpnNum);

    /**
     * Удалить вхождение ребра в схему; при отсутствии других net — удалить {@code stRel}.
     * Не трогает вершины.
     */
    void detachEdgeFromNetwork(int stNetKey, int parentKey, int childKey);

    /**
     * Удалить узел (строгая политика: нет детей в схеме, нет ipgStPn, не в других схемах).
     */
    void deleteNode(int stNetKey, int stiKey);
}
