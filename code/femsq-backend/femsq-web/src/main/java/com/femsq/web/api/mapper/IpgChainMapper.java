package com.femsq.web.api.mapper;

import com.femsq.database.model.IpgChain;
import com.femsq.web.api.dto.IpgChainDto;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;

/** Маппер для цепочек инвестиционных программ. */
@Component
public class IpgChainMapper {

    public IpgChainDto toDto(IpgChain chain, Map<Integer, String> stNetworkNames) {
        Objects.requireNonNull(chain, "chain");
        Objects.requireNonNull(stNetworkNames, "stNetworkNames");
        String stNetName = chain.stNetKey() == null ? null : stNetworkNames.get(chain.stNetKey());
        return new IpgChainDto(
                chain.chainKey(),
                chain.name(),
                chain.stNetKey(),
                stNetName,
                chain.latestIpgKey(),
                chain.year()
        );
    }

    public List<IpgChainDto> toDto(List<IpgChain> chains, Map<Integer, String> stNetworkNames) {
        Objects.requireNonNull(chains, "chains");
        return chains.stream()
                .map(chain -> toDto(chain, stNetworkNames))
                .collect(Collectors.toList());
    }
}
