package com.femsq.web.api.mapper;

import com.femsq.database.model.IpgChainRelation;
import com.femsq.web.api.dto.IpgChainRelationDto;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;

/** Маппер для связей цепочек инвестиционных программ. */
@Component
public class IpgChainRelationMapper {

    public IpgChainRelationDto toDto(
            IpgChainRelation relation,
            Map<Integer, String> investmentProgramNames,
            Map<Integer, String> planGroupNames) {
        Objects.requireNonNull(relation, "relation");
        Objects.requireNonNull(investmentProgramNames, "investmentProgramNames");
        Objects.requireNonNull(planGroupNames, "planGroupNames");
        String ipgName = investmentProgramNames.get(relation.investmentProgramKey());
        String planGroupName = relation.planGroupKey() == null ? null : planGroupNames.get(relation.planGroupKey());
        return new IpgChainRelationDto(
                relation.relationKey(),
                relation.chainKey(),
                relation.investmentProgramKey(),
                ipgName,
                relation.planGroupKey(),
                planGroupName
        );
    }

    public List<IpgChainRelationDto> toDto(
            List<IpgChainRelation> relations,
            Map<Integer, String> investmentProgramNames,
            Map<Integer, String> planGroupNames) {
        Objects.requireNonNull(relations, "relations");
        return relations.stream()
                .map(rel -> toDto(rel, investmentProgramNames, planGroupNames))
                .collect(Collectors.toList());
    }
}
