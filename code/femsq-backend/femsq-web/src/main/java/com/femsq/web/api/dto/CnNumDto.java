package com.femsq.web.api.dto;

/**
 * DTO номера договора.
 */
public record CnNumDto(
        Integer cnnKey,
        String cnnNum,
        Integer cnnCn,
        Integer cnnType,
        String cnnTypeName,
        String cnnNote
) {
}
