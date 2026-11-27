package com.femsq.database.service;

import com.femsq.database.model.StCostNm;
import com.femsq.database.model.StIpgNm;
import com.femsq.database.model.StIpgTreeNode;
import com.femsq.database.model.StNetworkFull;
import java.util.List;
import java.util.Optional;

/**
 * Сервис структуры ИПГ / затрат (схемы / дерево / CRUD узлов).
 */
public interface StIpgStructureService {

    List<StNetworkFull> listIpgNetworks();

    /** Схемы структуры затрат ({@code stnType=2}). */
    List<StNetworkFull> listCostNetworks();

    Optional<StNetworkFull> getNetwork(int stnKey);

    List<StIpgTreeNode> getTree(int stNetKey, Integer rootKey);

    StNetworkFull createIpgNetwork(String name, int rootKey);

    /** Создать схему затрат ({@code stnType=2}). */
    StNetworkFull createCostNetwork(String name, int rootKey);

    StNetworkFull renameNetwork(int stnKey, String name);

    StNetworkFull cloneNetwork(int sourceKey, String newName);

    int createChildNode(int stNetKey, int parentKey, String name, Integer stpnNum);

    void renameNode(int stiKey, String name);

    List<StIpgNm> listNodeNames(int stiKey);

    List<StCostNm> listCostNodeNames(int stcKey);

    int addNodeName(int stiKey, String name);

    int addCostNodeName(int stcKey, String name);

    void attachEdge(int stNetKey, int parentKey, int childKey, Integer stpnNum);

    void moveEdge(int stNetKey, int childKey, int fromParentKey, int toParentKey, Integer stpnNum);

    void detachEdge(int stNetKey, int parentKey, int childKey);

    void deleteNode(int stNetKey, int stiKey);
}
