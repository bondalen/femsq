package com.femsq.web.api.mapper;

import com.femsq.database.model.CstAg;
import com.femsq.web.api.dto.CstAgCreateRequest;
import com.femsq.web.api.dto.CstAgDto;
import com.femsq.web.api.dto.CstAgUpdateRequest;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;

/**
 * Маппер {@link CstAg}.
 */
@Component
public class CstAgMapper {

    public CstAgDto toDto(CstAg agent) {
        Objects.requireNonNull(agent, "agent");
        return new CstAgDto(
                agent.cstaKey(),
                agent.cstaAg(),
                agent.cstaCst(),
                agent.cstaOidOld(),
                agent.cstaInvestor(),
                agent.agentLabel()
        );
    }

    public List<CstAgDto> toDto(List<CstAg> agents) {
        Objects.requireNonNull(agents, "agents");
        return agents.stream().map(this::toDto).collect(Collectors.toList());
    }

    public CstAg toDomain(CstAgCreateRequest request) {
        Objects.requireNonNull(request, "request");
        return new CstAg(null, request.cstaAg(), request.cstaCst(), request.cstaOidOld(), request.cstaInvestor(), null);
    }

    public CstAg toDomain(int cstaKey, CstAgUpdateRequest request) {
        Objects.requireNonNull(request, "request");
        return new CstAg(cstaKey, request.cstaAg(), request.cstaCst(), request.cstaOidOld(), request.cstaInvestor(), null);
    }
}
