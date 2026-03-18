import { ApolloClient, InMemoryCache, createHttpLink } from '@apollo/client/core';

const httpLink = createHttpLink({ uri: '/graphql' });

export const apolloClient = new ApolloClient({
  link: httpLink,
  cache: new InMemoryCache({
    typePolicies: {
      Audit: {
        keyFields: ['adtKey']
      },
      AuditDirectory: {
        keyFields: ['key']
      },
      AuditType: {
        keyFields: ['atKey']
      },
      AuditFile: {
        keyFields: ['afKey']
      },
      FileType: {
        keyFields: ['ftKey']
      },
      Organization: {
        keyFields: ['ogKey']
      },
      Agent: {
        keyFields: ['ogAgKey']
      },
      InvestmentChain: {
        keyFields: ['chainKey']
      },
      InvestmentChainRelation: {
        keyFields: ['relationKey']
      },
      StNetwork: {
        keyFields: ['stNetKey']
      },
      InvestmentProgramLookup: {
        keyFields: ['ipgKey']
      },
      InvestmentPlanGroupLookup: {
        keyFields: ['planGroupKey']
      }
    }
  })
});

