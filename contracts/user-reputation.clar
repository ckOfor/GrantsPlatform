;; user-reputation.clar
;; Reputation system for the Decentralized Community Grants Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-USER-NOT-FOUND (err u101))
(define-constant ERR-INVALID-SCORE (err u102))

;; Data Maps
(define-map user-reputations
    { user: principal }
    {
        score: uint,
        proposals-created: uint,
        proposals-executed: uint,
        total-votes: uint
    }
)

;; Read-only functions
(define-read-only (get-user-reputation (user principal))
    (default-to
        { score: u0, proposals-created: u0, proposals-executed: u0, total-votes: u0 }
        (map-get? user-reputations { user: user })
    )
)

(define-read-only (get-contract-owner)
    contract-owner
)

;; Public functions
(define-public (initialize-user (user principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) ERR-NOT-AUTHORIZED)
        (ok (map-set user-reputations
            { user: user }
            { score: u100, proposals-created: u0, proposals-executed: u0, total-votes: u0 }
        ))
    )
)

(define-public (update-reputation-proposal-created (user principal))
    (let (
        (current-rep (get-user-reputation user))
    )
    (begin
        (asserts! (is-eq tx-sender contract-owner) ERR-NOT-AUTHORIZED)
        (ok (map-set user-reputations
            { user: user }
            (merge current-rep {
                score: (+ (get score current-rep) u10),
                proposals-created: (+ (get proposals-created current-rep) u1)
            })
        ))
    ))
)

(define-public (update-reputation-proposal-executed (user principal))
    (let (
        (current-rep (get-user-reputation user))
    )
    (begin
        (asserts! (is-eq tx-sender contract-owner) ERR-NOT-AUTHORIZED)
        (ok (map-set user-reputations
            { user: user }
            (merge current-rep {
                score: (+ (get score current-rep) u50),
                proposals-executed: (+ (get proposals-executed current-rep) u1)
            })
        ))
    ))
)

(define-public (update-reputation-voted (user principal))
    (let (
        (current-rep (get-user-reputation user))
    )
    (begin
        (asserts! (is-eq tx-sender contract-owner) ERR-NOT-AUTHORIZED)
        (ok (map-set user-reputations
            { user: user }
            (merge current-rep {
                score: (+ (get score current-rep) u5),
                total-votes: (+ (get total-votes current-rep) u1)
            })
        ))
    ))
)

(define-public (adjust-reputation-score (user principal) (adjustment int))
    (let (
        (current-rep (get-user-reputation user))
        (current-score (get score current-rep))
        (new-score (if (>= adjustment 0)
                       (+ current-score (to-uint adjustment))
                       (if (>= current-score (to-uint (- 0 adjustment)))
                           (- current-score (to-uint (- 0 adjustment)))
                           u0)))
    )
    (begin
        (asserts! (is-eq tx-sender contract-owner) ERR-NOT-AUTHORIZED)
        (ok (map-set user-reputations
            { user: user }
            (merge current-rep { score: new-score })
        ))
    ))
)


