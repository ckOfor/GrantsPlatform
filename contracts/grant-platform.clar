;; Decentralized Community Grants Platform
;; Written in Clarity for Stacks blockchain

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-INVALID-AMOUNT (err u2))
(define-constant ERR-PROPOSAL-NOT-FOUND (err u3))
(define-constant ERR-VOTING-ENDED (err u4))
(define-constant ERR-ALREADY-VOTED (err u5))
(define-constant VOTING_PERIOD u144) ;; ~1 day in blocks
(define-constant MIN_PROPOSAL_AMOUNT u100000) ;; in microSTX
(define-constant QUORUM_THRESHOLD u500) ;; 50.0%

;; Data Maps
(define-map proposals
    { proposal-id: uint }
    {
        creator: principal,
        title: (string-ascii 50),
        description: (string-ascii 500),
        amount: uint,
        votes-for: uint,
        votes-against: uint,
        status: (string-ascii 20),
        created-at: uint,
        recipient: principal
    }
)