import { describe, it, expect, beforeEach, vi } from 'vitest';

// Mocking Clarinet and Stacks blockchain environment
const mockContractCall = vi.fn();
const mockBlockHeight = vi.fn(() => 1000);

// Replace with your actual function that simulates contract calls
const clarity = {
  call: mockContractCall,
  getBlockHeight: mockBlockHeight,
};

describe('Decentralized Community Grants Platform', () => {
  beforeEach(() => {
    vi.clearAllMocks(); // Clear mocks before each test
  });
  
  it('should allow a user to create a proposal after staking tokens', async () => {
    // Arrange
    const userPrincipal = 'ST1USER...';
    const title = 'Proposal Title';
    const description = 'This is a sample proposal description.';
    const amount = 50000;
    const recipient = 'ST2RECIPIENT...';
    
    // Mock staking tokens and create-proposal logic
    mockContractCall
        .mockResolvedValueOnce({ ok: true }) // Simulating successful token staking
        .mockResolvedValueOnce({ proposalId: 1 }); // Simulating proposal creation
    
    // Act: Simulate staking and creating a proposal
    const stakeResult = await clarity.call('stake-tokens', [userPrincipal, 100000]);
    const proposalResult = await clarity.call('create-proposal', [title, description, amount, recipient]);
    
    // Assert: Check if the proposal was created successfully
    expect(stakeResult.ok).toBe(true);
    expect(proposalResult.proposalId).toBe(1);
  });
  
});
