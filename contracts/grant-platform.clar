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

(define-map votes
    { proposal-id: uint, voter: principal }
    { vote: bool }
)

(define-map user-stakes
    { user: principal }
    { amount: uint }
)

;; Data Variables
(define-data-var proposal-counter uint u0)
(define-data-var treasury-balance uint u0)

;; Read-only functions
(define-read-only (get-proposal (proposal-id uint))
    (map-get? proposals { proposal-id: proposal-id })
)

(define-read-only (get-user-stake (user principal))
    (default-to
        { amount: u0 }
        (map-get? user-stakes { user: user })
    )
)

(define-read-only (get-treasury-balance)
    (var-get treasury-balance)
)

;; Public functions
(define-public (stake-tokens (amount uint))
    (let (
        (current-stake (get-user-stake tx-sender))
        (new-amount (+ amount (get amount current-stake)))
    )
    (if (>= amount MIN_PROPOSAL_AMOUNT)
        (begin
            (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
            (var-set treasury-balance (+ (var-get treasury-balance) amount))
            (map-set user-stakes
                { user: tx-sender }
                { amount: new-amount }
            )
            (ok true)
        )
        ERR-INVALID-AMOUNT
    ))
)

(define-public (create-proposal (title (string-ascii 50)) (description (string-ascii 500)) (amount uint) (recipient principal))
    (let (
        (proposal-id (+ (var-get proposal-counter) u1))
        (user-stake (get amount (get-user-stake tx-sender)))
    )
    (if (>= user-stake MIN_PROPOSAL_AMOUNT)
        (begin
            (map-set proposals
                { proposal-id: proposal-id }
                {
                    creator: tx-sender,
                    title: title,
                    description: description,
                    amount: amount,
                    votes-for: u0,
                    votes-against: u0,
                    status: "active",
                    created-at: block-height,
                    recipient: recipient
                }
            )
            (var-set proposal-counter proposal-id)
            (ok proposal-id)
        )
        ERR-NOT-AUTHORIZED
    ))
)

(define-public (vote (proposal-id uint) (vote-for bool))
    (let (
        (proposal (unwrap! (get-proposal proposal-id) ERR-PROPOSAL-NOT-FOUND))
        (user-stake (get amount (get-user-stake tx-sender)))
        (vote-record (map-get? votes { proposal-id: proposal-id, voter: tx-sender }))
    )
    (asserts! (>= user-stake u0) ERR-NOT-AUTHORIZED)
    (asserts! (is-none vote-record) ERR-ALREADY-VOTED)
    (asserts!
        (<= (- block-height (get created-at proposal)) VOTING_PERIOD)
        ERR-VOTING-ENDED
    )

    (map-set votes
        { proposal-id: proposal-id, voter: tx-sender }
        { vote: vote-for }
    )

    (map-set proposals
        { proposal-id: proposal-id }
        (merge proposal {
            votes-for: (if vote-for
                (+ (get votes-for proposal) u1)
                (get votes-for proposal)
            ),
            votes-against: (if (not vote-for)
                (+ (get votes-against proposal) u1)
                (get votes-against proposal)
            )
        })
    )
    (ok true))
)

(define-public (execute-proposal (proposal-id uint))
    (let (
        (proposal (unwrap! (get-proposal proposal-id) ERR-PROPOSAL-NOT-FOUND))
        (total-votes (+ (get votes-for proposal) (get votes-against proposal)))
        (approval-percentage (* (get votes-for proposal) u1000 (/ total-votes)))
    )
    (asserts!
        (>= (- block-height (get created-at proposal)) VOTING_PERIOD)
        ERR-VOTING-ENDED
    )
    (if (and
            (>= approval-percentage (* QUORUM_THRESHOLD u10))
            (>= (var-get treasury-balance) (get amount proposal))
        )
        (begin
            (try! (as-contract (stx-transfer? (get amount proposal) tx-sender (get recipient proposal))))
            (var-set treasury-balance (- (var-get treasury-balance) (get amount proposal)))
            (map-set proposals
                { proposal-id: proposal-id }
                (merge proposal { status: "executed" })
            )
            (ok true)
        )
        (begin
            (map-set proposals
                { proposal-id: proposal-id }
                (merge proposal { status: "rejected" })
            )
            (ok false)
        )
    ))
)
