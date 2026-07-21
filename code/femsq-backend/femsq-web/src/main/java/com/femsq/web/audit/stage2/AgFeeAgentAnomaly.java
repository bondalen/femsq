package com.femsq.web.audit.stage2;

/**
 * Аномалия резолюции агента (эквивалент {@code ags.ogAgFeePnTestAgentNo}).
 *
 * @param senderName имя агента из Excel ({@code oafptOafSender})
 * @param keyCount   число найденных {@code ogaKey} (0 = отсутствует, &gt;1 = неоднозначность)
 */
public record AgFeeAgentAnomaly(String senderName, int keyCount) {
}
