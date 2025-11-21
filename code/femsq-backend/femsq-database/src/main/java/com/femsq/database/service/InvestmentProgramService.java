package com.femsq.database.service;

import com.femsq.database.model.InvestmentProgram;
import java.util.List;

/** Сервис для справочника инвестиционных программ. */
public interface InvestmentProgramService {

    List<InvestmentProgram> getAll();
}
