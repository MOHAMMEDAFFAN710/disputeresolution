
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Simple Dispute Resolution (beginner)
/// @notice Basic dispute -> proposals -> voting -> finalize flow.
/// @dev Constructor takes no inputs (so deployment has no input fields).
contract DisputeResolution {
    enum Status { Open, Resolved, Cancelled }

    struct Proposal {
        uint256 id;
        uint256 disputeId;
        address proposer;
        string text;
        uint256 votes;
    }

    struct Dispute {
        uint256 id;
        address creator;
        string description;
        Status status;
        uint256[] proposalIds; // ids of proposals for this dispute
    }

    // Counters
    uint256 private nextDisputeId = 1;
    uint256 private nextProposalId = 1;

    // Storage
    mapping(uint256 => Dispute) private disputes;
    mapping(uint256 => Proposal) private proposals;

    // track votes: disputeId => voter => bool (true if voted on this dispute)
    mapping(uint256 => mapping(address => bool)) private hasVoted;

    // Events
    event DisputeCreated(uint256 indexed disputeId, address indexed creator, string description);
    event ProposalCreated(uint256 indexed disputeId, uint256 indexed proposalId, address proposer, string text);
    event Voted(uint256 indexed disputeId, uint256 indexed proposalId, address voter);
    event DisputeFinalized(uint256 indexed disputeId, uint256 indexed winningProposalId);
    event DisputeCancelled(uint256 indexed disputeId);

    // -----------------------
    // Creation & proposals
    // -----------------------

    /// @notice Create a new dispute (no constructor input fields required).
    /// @param description Short description of the dispute.
    /// @return disputeId ID of the newly created dispute.
    function createDispute(string calldata description) external returns (uint256 disputeId) {
        disputeId = nextDisputeId++;
        Dispute storage d = disputes[disputeId];
        d.id = disputeId;
        d.creator = msg.sender;
        d.description = description;
        d.status = Status.Open;

        emit DisputeCreated(disputeId, msg.sender, description);
    }

    /// @notice Propose a resolution for an open dispute.
    /// @param disputeId ID of the dispute to propose for.
    /// @param text Short text describing the proposal.
    /// @return proposalId ID of the created proposal.
    function proposeResolution(uint256 disputeId, string calldata text) external returns (uint256 proposalId) {
        Dispute storage d = disputes[disputeId];
        require(d.id != 0, "Dispute does not exist");
        require(d.status == Status.Open, "Dispute not open");

        proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            disputeId: disputeId,
            proposer: msg.sender,
            text: text,
            votes: 0
        });

        d.proposalIds.push(proposalId);

        emit ProposalCreated(disputeId, proposalId, msg.sender, text);
    }

    // -----------------------
    // Voting
    // -----------------------

    /// @notice Vote for a proposal in a dispute (one vote per address per dispute).
    /// @param disputeId ID of the dispute.
    /// @param proposalId ID of the proposal to vote for.
    function vote(uint256 disputeId, uint256 proposalId) external {
        Dispute storage d = disputes[disputeId];
        require(d.id != 0, "Dispute does not exist");
        require(d.status == Status.Open, "Dispute not open");
        require(!hasVoted[disputeId][msg.sender], "Already voted on this dispute");

        Proposal storage p = proposals[proposalId];
        require(p.id != 0, "Proposal does not exist");
        require(p.disputeId == disputeId, "Proposal does not belong to this dispute");

        p.votes += 1;
        hasVoted[disputeId][msg.sender] = true;

        emit Voted(disputeId, proposalId, msg.sender);
    }
}
