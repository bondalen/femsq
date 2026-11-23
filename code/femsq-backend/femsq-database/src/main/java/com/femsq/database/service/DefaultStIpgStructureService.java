package com.femsq.database.service;

import com.femsq.database.dao.StIpgStructureDao;
import com.femsq.database.model.StIpgNm;
import com.femsq.database.model.StIpgTreeNode;
import com.femsq.database.model.StNetworkFull;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Logger;

/**
 * Реализация {@link StIpgStructureService}.
 */
public class DefaultStIpgStructureService implements StIpgStructureService {

    private static final Logger log = Logger.getLogger(DefaultStIpgStructureService.class.getName());
    private static final int ST_TYPE_IPG = 1;

    private final StIpgStructureDao structureDao;

    public DefaultStIpgStructureService(StIpgStructureDao structureDao) {
        this.structureDao = Objects.requireNonNull(structureDao, "structureDao");
    }

    @Override
    public List<StNetworkFull> listIpgNetworks() {
        return structureDao.findNetworksByType(ST_TYPE_IPG);
    }

    @Override
    public Optional<StNetworkFull> getNetwork(int stnKey) {
        return structureDao.findNetworkByKey(stnKey);
    }

    @Override
    public List<StIpgTreeNode> getTree(int stNetKey, Integer rootKey) {
        StNetworkFull network = structureDao.findNetworkByKey(stNetKey)
                .orElseThrow(() -> new IllegalArgumentException("Схема не найдена: " + stNetKey));
        int root = rootKey != null ? rootKey : network.stnRoot();
        log.fine(() -> "fnSt tree net=" + stNetKey + " root=" + root);
        return structureDao.findTree(stNetKey, root);
    }

    @Override
    public StNetworkFull createIpgNetwork(String name, int rootKey) {
        return structureDao.createNetwork(ST_TYPE_IPG, name, rootKey);
    }

    @Override
    public StNetworkFull renameNetwork(int stnKey, String name) {
        return structureDao.updateNetworkName(stnKey, name);
    }

    @Override
    public StNetworkFull cloneNetwork(int sourceKey, String newName) {
        return structureDao.cloneNetwork(sourceKey, newName);
    }

    @Override
    public int createChildNode(int stNetKey, int parentKey, String name, Integer stpnNum) {
        return structureDao.createChildNode(stNetKey, parentKey, name, stpnNum);
    }

    @Override
    public void renameNode(int stiKey, String name) {
        structureDao.renameNode(stiKey, name);
    }

    @Override
    public List<StIpgNm> listNodeNames(int stiKey) {
        return structureDao.findNodeNames(stiKey);
    }

    @Override
    public int addNodeName(int stiKey, String name) {
        return structureDao.addNodeName(stiKey, name);
    }

    @Override
    public void attachEdge(int stNetKey, int parentKey, int childKey, Integer stpnNum) {
        structureDao.attachEdgeToNetwork(stNetKey, parentKey, childKey, stpnNum);
    }

    @Override
    public void moveEdge(
            int stNetKey, int childKey, int fromParentKey, int toParentKey, Integer stpnNum) {
        structureDao.moveEdgeInNetwork(stNetKey, childKey, fromParentKey, toParentKey, stpnNum);
    }

    @Override
    public void detachEdge(int stNetKey, int parentKey, int childKey) {
        structureDao.detachEdgeFromNetwork(stNetKey, parentKey, childKey);
    }

    @Override
    public void deleteNode(int stNetKey, int stiKey) {
        structureDao.deleteNode(stNetKey, stiKey);
    }
}
