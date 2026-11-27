package com.femsq.web.api.graphql;

import com.femsq.database.model.StCostNm;
import com.femsq.database.model.StIpgTreeNode;
import com.femsq.database.model.StNetworkFull;
import com.femsq.database.service.StIpgStructureService;
import com.femsq.web.api.dto.StCostNmDto;
import com.femsq.web.api.dto.StIpgTreeNodeDto;
import com.femsq.web.api.dto.StNetworkFullDto;
import java.util.List;
import java.util.logging.Logger;
import java.util.stream.Collectors;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.MutationMapping;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.stereotype.Controller;

/**
 * GraphQL Structure затрат (C2 O2 §4.0.1): схемы {@code stnType=2}, дерево fnSt, CRUD узлов/рёбер.
 */
@Controller
public class StCostStructureGraphqlController {

    private static final Logger log = Logger.getLogger(StCostStructureGraphqlController.class.getName());
    private static final int ST_TYPE_COST = 2;

    private final StIpgStructureService structureService;

    public StCostStructureGraphqlController(StIpgStructureService structureService) {
        this.structureService = structureService;
    }

    @QueryMapping
    public List<StNetworkFullDto> stCostNetworks() {
        return structureService.listCostNetworks().stream()
                .map(this::toNetworkDto)
                .collect(Collectors.toList());
    }

    @QueryMapping
    public StNetworkFullDto stCostNetwork(@Argument("id") int id) {
        return structureService.getNetwork(id)
                .filter(network -> network.stnType() == ST_TYPE_COST)
                .map(this::toNetworkDto)
                .orElse(null);
    }

    @QueryMapping
    public List<StIpgTreeNodeDto> stCostNetworkTree(
            @Argument("stNetKey") int stNetKey,
            @Argument("rootKey") Integer rootKey) {
        requireCostNetwork(stNetKey);
        return structureService.getTree(stNetKey, rootKey).stream()
                .map(this::toTreeDto)
                .collect(Collectors.toList());
    }

    @QueryMapping
    public List<StCostNmDto> stCostNodeNames(@Argument("stcKey") int stcKey) {
        return structureService.listCostNodeNames(stcKey).stream()
                .map(this::toNmDto)
                .collect(Collectors.toList());
    }

    @MutationMapping
    public StNetworkFullDto createStCostNetwork(
            @Argument("name") String name,
            @Argument("rootKey") int rootKey) {
        log.info(() -> "createStCostNetwork name=" + name + " root=" + rootKey);
        return toNetworkDto(structureService.createCostNetwork(name, rootKey));
    }

    @MutationMapping
    public StNetworkFullDto renameStCostNetwork(
            @Argument("id") int id,
            @Argument("name") String name) {
        requireCostNetwork(id);
        return toNetworkDto(structureService.renameNetwork(id, name));
    }

    @MutationMapping
    public StNetworkFullDto cloneStCostNetwork(
            @Argument("sourceId") int sourceId,
            @Argument("newName") String newName) {
        requireCostNetwork(sourceId);
        log.info(() -> "cloneStCostNetwork source=" + sourceId);
        return toNetworkDto(structureService.cloneNetwork(sourceId, newName));
    }

    @MutationMapping
    public StIpgTreeNodeDto createStCostChildNode(
            @Argument("stNetKey") int stNetKey,
            @Argument("parentKey") int parentKey,
            @Argument("name") String name,
            @Argument("stpnNum") Integer stpnNum) {
        requireCostNetwork(stNetKey);
        int childKey = structureService.createChildNode(stNetKey, parentKey, name, stpnNum);
        return structureService.getTree(stNetKey, null).stream()
                .filter(node -> childKey == node.childKey())
                .findFirst()
                .map(this::toTreeDto)
                .orElse(new StIpgTreeNodeDto(childKey, parentKey, stpnNum, null, null, name, null, null));
    }

    @MutationMapping
    public Boolean renameStCostNode(
            @Argument("stcKey") int stcKey,
            @Argument("name") String name) {
        structureService.renameNode(stcKey, name);
        return Boolean.TRUE;
    }

    @MutationMapping
    public StCostNmDto addStCostNodeName(
            @Argument("stcKey") int stcKey,
            @Argument("name") String name) {
        int stcnKey = structureService.addCostNodeName(stcKey, name);
        return new StCostNmDto(stcnKey, stcKey, name.trim());
    }

    @MutationMapping
    public Boolean attachStCostEdge(
            @Argument("stNetKey") int stNetKey,
            @Argument("parentKey") int parentKey,
            @Argument("childKey") int childKey,
            @Argument("stpnNum") Integer stpnNum) {
        requireCostNetwork(stNetKey);
        structureService.attachEdge(stNetKey, parentKey, childKey, stpnNum);
        return Boolean.TRUE;
    }

    @MutationMapping
    public Boolean moveStCostEdge(
            @Argument("stNetKey") int stNetKey,
            @Argument("childKey") int childKey,
            @Argument("fromParentKey") int fromParentKey,
            @Argument("toParentKey") int toParentKey,
            @Argument("stpnNum") Integer stpnNum) {
        requireCostNetwork(stNetKey);
        structureService.moveEdge(stNetKey, childKey, fromParentKey, toParentKey, stpnNum);
        return Boolean.TRUE;
    }

    @MutationMapping
    public Boolean detachStCostEdge(
            @Argument("stNetKey") int stNetKey,
            @Argument("parentKey") int parentKey,
            @Argument("childKey") int childKey) {
        requireCostNetwork(stNetKey);
        structureService.detachEdge(stNetKey, parentKey, childKey);
        return Boolean.TRUE;
    }

    @MutationMapping
    public Boolean deleteStCostNode(
            @Argument("stNetKey") int stNetKey,
            @Argument("stcKey") int stcKey) {
        requireCostNetwork(stNetKey);
        structureService.deleteNode(stNetKey, stcKey);
        return Boolean.TRUE;
    }

    private void requireCostNetwork(int stNetKey) {
        StNetworkFull network = structureService.getNetwork(stNetKey)
                .orElseThrow(() -> new IllegalArgumentException("Схема не найдена: " + stNetKey));
        if (network.stnType() != ST_TYPE_COST) {
            throw new IllegalArgumentException(
                    "Ожидалась схема затрат stnType=2, получено stnType=" + network.stnType()
                            + " для stNetKey=" + stNetKey);
        }
    }

    private StNetworkFullDto toNetworkDto(StNetworkFull network) {
        return new StNetworkFullDto(
                network.stnKey(),
                network.stnType(),
                network.stnName(),
                network.stnRoot()
        );
    }

    private StIpgTreeNodeDto toTreeDto(StIpgTreeNode node) {
        return new StIpgTreeNodeDto(
                node.childKey(),
                node.parentKey(),
                node.stpnNum(),
                node.pnLevel(),
                node.stNum(),
                node.name(),
                node.stRelKey(),
                node.stNetPnKey()
        );
    }

    private StCostNmDto toNmDto(StCostNm name) {
        return new StCostNmDto(name.stcnKey(), name.stcnCost(), name.stcnNm());
    }
}
