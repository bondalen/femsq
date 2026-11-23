package com.femsq.web.api.graphql;

import com.femsq.database.model.StIpgNm;
import com.femsq.database.model.StIpgTreeNode;
import com.femsq.database.model.StNetworkFull;
import com.femsq.database.service.StIpgStructureService;
import com.femsq.web.api.dto.StIpgNmDto;
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
 * GraphQL Structure ИПГ (C2 §2.4.1): схемы, дерево fnSt, CRUD узлов/рёбер.
 */
@Controller
public class StIpgStructureGraphqlController {

    private static final Logger log = Logger.getLogger(StIpgStructureGraphqlController.class.getName());

    private final StIpgStructureService structureService;

    public StIpgStructureGraphqlController(StIpgStructureService structureService) {
        this.structureService = structureService;
    }

    @QueryMapping
    public List<StNetworkFullDto> stIpgNetworks() {
        return structureService.listIpgNetworks().stream()
                .map(this::toNetworkDto)
                .collect(Collectors.toList());
    }

    @QueryMapping
    public StNetworkFullDto stIpgNetwork(@Argument("id") int id) {
        return structureService.getNetwork(id)
                .map(this::toNetworkDto)
                .orElse(null);
    }

    @QueryMapping
    public List<StIpgTreeNodeDto> stIpgNetworkTree(
            @Argument("stNetKey") int stNetKey,
            @Argument("rootKey") Integer rootKey) {
        return structureService.getTree(stNetKey, rootKey).stream()
                .map(this::toTreeDto)
                .collect(Collectors.toList());
    }

    @QueryMapping
    public List<StIpgNmDto> stIpgNodeNames(@Argument("stiKey") int stiKey) {
        return structureService.listNodeNames(stiKey).stream()
                .map(this::toNmDto)
                .collect(Collectors.toList());
    }

    @MutationMapping
    public StNetworkFullDto createStIpgNetwork(
            @Argument("name") String name,
            @Argument("rootKey") int rootKey) {
        log.info(() -> "createStIpgNetwork name=" + name + " root=" + rootKey);
        return toNetworkDto(structureService.createIpgNetwork(name, rootKey));
    }

    @MutationMapping
    public StNetworkFullDto renameStIpgNetwork(
            @Argument("id") int id,
            @Argument("name") String name) {
        return toNetworkDto(structureService.renameNetwork(id, name));
    }

    @MutationMapping
    public StNetworkFullDto cloneStIpgNetwork(
            @Argument("sourceId") int sourceId,
            @Argument("newName") String newName) {
        log.info(() -> "cloneStIpgNetwork source=" + sourceId);
        return toNetworkDto(structureService.cloneNetwork(sourceId, newName));
    }

    @MutationMapping
    public StIpgTreeNodeDto createStIpgChildNode(
            @Argument("stNetKey") int stNetKey,
            @Argument("parentKey") int parentKey,
            @Argument("name") String name,
            @Argument("stpnNum") Integer stpnNum) {
        int childKey = structureService.createChildNode(stNetKey, parentKey, name, stpnNum);
        return structureService.getTree(stNetKey, null).stream()
                .filter(node -> childKey == node.childKey())
                .findFirst()
                .map(this::toTreeDto)
                .orElse(new StIpgTreeNodeDto(childKey, parentKey, stpnNum, null, null, name, null, null));
    }

    @MutationMapping
    public Boolean renameStIpgNode(
            @Argument("stiKey") int stiKey,
            @Argument("name") String name) {
        structureService.renameNode(stiKey, name);
        return Boolean.TRUE;
    }

    @MutationMapping
    public StIpgNmDto addStIpgNodeName(
            @Argument("stiKey") int stiKey,
            @Argument("name") String name) {
        int stinKey = structureService.addNodeName(stiKey, name);
        return new StIpgNmDto(stinKey, stiKey, name.trim());
    }

    @MutationMapping
    public Boolean attachStIpgEdge(
            @Argument("stNetKey") int stNetKey,
            @Argument("parentKey") int parentKey,
            @Argument("childKey") int childKey,
            @Argument("stpnNum") Integer stpnNum) {
        structureService.attachEdge(stNetKey, parentKey, childKey, stpnNum);
        return Boolean.TRUE;
    }

    @MutationMapping
    public Boolean moveStIpgEdge(
            @Argument("stNetKey") int stNetKey,
            @Argument("childKey") int childKey,
            @Argument("fromParentKey") int fromParentKey,
            @Argument("toParentKey") int toParentKey,
            @Argument("stpnNum") Integer stpnNum) {
        structureService.moveEdge(stNetKey, childKey, fromParentKey, toParentKey, stpnNum);
        return Boolean.TRUE;
    }

    @MutationMapping
    public Boolean detachStIpgEdge(
            @Argument("stNetKey") int stNetKey,
            @Argument("parentKey") int parentKey,
            @Argument("childKey") int childKey) {
        structureService.detachEdge(stNetKey, parentKey, childKey);
        return Boolean.TRUE;
    }

    @MutationMapping
    public Boolean deleteStIpgNode(
            @Argument("stNetKey") int stNetKey,
            @Argument("stiKey") int stiKey) {
        structureService.deleteNode(stNetKey, stiKey);
        return Boolean.TRUE;
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

    private StIpgNmDto toNmDto(StIpgNm name) {
        return new StIpgNmDto(name.stinKey(), name.stinIpg(), name.stinNm());
    }
}
