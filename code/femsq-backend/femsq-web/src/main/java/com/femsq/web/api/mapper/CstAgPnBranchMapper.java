package com.femsq.web.api.mapper;

import com.femsq.database.model.CstAgPnBranch;
import com.femsq.web.api.dto.CstAgPnBranchCreateRequest;
import com.femsq.web.api.dto.CstAgPnBranchDto;
import com.femsq.web.api.dto.CstAgPnBranchUpdateRequest;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;

/**
 * Маппер {@link CstAgPnBranch}.
 */
@Component
public class CstAgPnBranchMapper {

    public CstAgPnBranchDto toDto(CstAgPnBranch branch) {
        Objects.requireNonNull(branch, "branch");
        return new CstAgPnBranchDto(
                branch.cstapbKey(),
                branch.cstapbCstAgPn(),
                branch.cstapbBranch(),
                branch.cstapbStart(),
                branch.cstapbEnd(),
                branch.branchName()
        );
    }

    public List<CstAgPnBranchDto> toDto(List<CstAgPnBranch> branches) {
        Objects.requireNonNull(branches, "branches");
        return branches.stream().map(this::toDto).collect(Collectors.toList());
    }

    public CstAgPnBranch toDomain(CstAgPnBranchCreateRequest request) {
        Objects.requireNonNull(request, "request");
        return new CstAgPnBranch(
                null,
                request.cstapbCstAgPn(),
                request.cstapbBranch(),
                request.cstapbStart(),
                request.cstapbEnd(),
                null
        );
    }

    public CstAgPnBranch toDomain(int cstapbKey, CstAgPnBranchUpdateRequest request) {
        Objects.requireNonNull(request, "request");
        return new CstAgPnBranch(
                cstapbKey,
                request.cstapbCstAgPn(),
                request.cstapbBranch(),
                request.cstapbStart(),
                request.cstapbEnd(),
                null
        );
    }
}
