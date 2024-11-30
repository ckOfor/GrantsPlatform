import { describe, it, expect, beforeEach } from 'vitest';

// Mock implementation of the user-reputation contract
const UserReputationContract = {
  userReputations: new Map(),
  contractOwner: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
  
  initializeUser(user, sender) {
    if (sender !== this.contractOwner) throw new Error('ERR-NOT-AUTHORIZED');
    this.userReputations.set(user, { score: 100, proposalsCreated: 0, proposalsExecuted: 0, totalVotes: 0 });
    return { success: true };
  },
  
  updateReputationProposalCreated(user, sender) {
    if (sender !== this.contractOwner) throw new Error('ERR-NOT-AUTHORIZED');
    const currentRep = this.getUserReputation(user);
    currentRep.score += 10;
    currentRep.proposalsCreated += 1;
    this.userReputations.set(user, currentRep);
    return { success: true };
  },
  
  updateReputationProposalExecuted(user, sender) {
    if (sender !== this.contractOwner) throw new Error('ERR-NOT-AUTHORIZED');
    const currentRep = this.getUserReputation(user);
    currentRep.score += 50;
    currentRep.proposalsExecuted += 1;
    this.userReputations.set(user, currentRep);
    return { success: true };
  },
  
  updateReputationVoted(user, sender) {
    if (sender !== this.contractOwner) throw new Error('ERR-NOT-AUTHORIZED');
    const currentRep = this.getUserReputation(user);
    currentRep.score += 5;
    currentRep.totalVotes += 1;
    this.userReputations.set(user, currentRep);
    return { success: true };
  },
  
  adjustReputationScore(user, adjustment, sender) {
    if (sender !== this.contractOwner) throw new Error('ERR-NOT-AUTHORIZED');
    const currentRep = this.getUserReputation(user);
    const newScore = currentRep.score + adjustment;
    if (newScore < 0) throw new Error('ERR-INVALID-SCORE');
    currentRep.score = newScore;
    this.userReputations.set(user, currentRep);
    return { success: true };
  },
  
  getUserReputation(user) {
    return this.userReputations.get(user) || { score: 0, proposalsCreated: 0, proposalsExecuted: 0, totalVotes: 0 };
  }
};

describe('User Reputation Contract', () => {
  const testUser = 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG';
  const unauthorizedUser = 'ST3PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM';
  
  beforeEach(() => {
    UserReputationContract.userReputations.clear();
  });
  
  describe('Initialize User', () => {
    it('should initialize a new user with default reputation', () => {
      const result = UserReputationContract.initializeUser(testUser, UserReputationContract.contractOwner);
      expect(result.success).toBe(true);
      const reputation = UserReputationContract.getUserReputation(testUser);
      expect(reputation.score).toBe(100);
      expect(reputation.proposalsCreated).toBe(0);
      expect(reputation.proposalsExecuted).toBe(0);
      expect(reputation.totalVotes).toBe(0);
    });
    
    it('should not allow unauthorized initialization', () => {
      expect(() => UserReputationContract.initializeUser(testUser, unauthorizedUser)).toThrow('ERR-NOT-AUTHORIZED');
    });
  });
  
  describe('Update Reputation', () => {
    beforeEach(() => {
      UserReputationContract.initializeUser(testUser, UserReputationContract.contractOwner);
    });
    
    it('should update reputation when proposal is created', () => {
      UserReputationContract.updateReputationProposalCreated(testUser, UserReputationContract.contractOwner);
      const reputation = UserReputationContract.getUserReputation(testUser);
      expect(reputation.score).toBe(110);
      expect(reputation.proposalsCreated).toBe(1);
    });
    
    it('should update reputation when proposal is executed', () => {
      UserReputationContract.updateReputationProposalExecuted(testUser, UserReputationContract.contractOwner);
      const reputation = UserReputationContract.getUserReputation(testUser);
      expect(reputation.score).toBe(150);
      expect(reputation.proposalsExecuted).toBe(1);
    });
    
    it('should update reputation when user votes', () => {
      UserReputationContract.updateReputationVoted(testUser, UserReputationContract.contractOwner);
      const reputation = UserReputationContract.getUserReputation(testUser);
      expect(reputation.score).toBe(105);
      expect(reputation.totalVotes).toBe(1);
    });
    
    it('should not allow unauthorized reputation updates', () => {
      expect(() => UserReputationContract.updateReputationProposalCreated(testUser, unauthorizedUser)).toThrow('ERR-NOT-AUTHORIZED');
      expect(() => UserReputationContract.updateReputationProposalExecuted(testUser, unauthorizedUser)).toThrow('ERR-NOT-AUTHORIZED');
      expect(() => UserReputationContract.updateReputationVoted(testUser, unauthorizedUser)).toThrow('ERR-NOT-AUTHORIZED');
    });
  });
  
  describe('Adjust Reputation Score', () => {
    beforeEach(() => {
      UserReputationContract.initializeUser(testUser, UserReputationContract.contractOwner);
    });
    
    it('should allow positive score adjustment', () => {
      UserReputationContract.adjustReputationScore(testUser, 50, UserReputationContract.contractOwner);
      const reputation = UserReputationContract.getUserReputation(testUser);
      expect(reputation.score).toBe(150);
    });
    
    it('should allow negative score adjustment', () => {
      UserReputationContract.adjustReputationScore(testUser, -50, UserReputationContract.contractOwner);
      const reputation = UserReputationContract.getUserReputation(testUser);
      expect(reputation.score).toBe(50);
    });
    
    it('should not allow score to go below zero', () => {
      expect(() => UserReputationContract.adjustReputationScore(testUser, -150, UserReputationContract.contractOwner)).toThrow('ERR-INVALID-SCORE');
    });
    
    it('should not allow unauthorized score adjustments', () => {
      expect(() => UserReputationContract.adjustReputationScore(testUser, 50, unauthorizedUser)).toThrow('ERR-NOT-AUTHORIZED');
    });
  });
  
  describe('Get User Reputation', () => {
    it('should return default values for non-existent user', () => {
      const reputation = UserReputationContract.getUserReputation('ST3PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM');
      expect(reputation.score).toBe(0);
      expect(reputation.proposalsCreated).toBe(0);
      expect(reputation.proposalsExecuted).toBe(0);
      expect(reputation.totalVotes).toBe(0);
    });
  });
});
