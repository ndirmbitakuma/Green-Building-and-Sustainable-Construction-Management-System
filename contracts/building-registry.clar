;; Green Building Registry Contract
;; Manages building registration, ownership, and project lifecycle

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-BUILDING-NOT-FOUND (err u101))
(define-constant ERR-BUILDING-EXISTS (err u102))
(define-constant ERR-INVALID-PHASE (err u103))
(define-constant ERR-INVALID-INPUT (err u104))

;; Data Variables
(define-data-var next-building-id uint u1)

;; Building Status Enum
(define-constant STATUS-PLANNING u1)
(define-constant STATUS-DESIGN u2)
(define-constant STATUS-CONSTRUCTION u3)
(define-constant STATUS-COMPLETION u4)
(define-constant STATUS-OPERATIONAL u5)

;; Building Data Structure
(define-map buildings
  { building-id: uint }
  {
    name: (string-ascii 100),
    owner: principal,
    location: (string-ascii 200),
    building-type: (string-ascii 50),
    total-area: uint,
    status: uint,
    created-at: uint,
    updated-at: uint,
    target-certification: (string-ascii 50),
    sustainability-goals: (string-ascii 500)
  }
)

;; Project Phases Tracking
(define-map project-phases
  { building-id: uint, phase: uint }
  {
    phase-name: (string-ascii 100),
    start-date: uint,
    end-date: (optional uint),
    completion-percentage: uint,
    phase-notes: (string-ascii 500)
  }
)

;; Stakeholder Management
(define-map building-stakeholders
  { building-id: uint, stakeholder: principal }
  {
    role: (string-ascii 50),
    permissions: uint,
    added-at: uint
  }
)

;; Building Metrics
(define-map building-metrics
  { building-id: uint }
  {
    energy-target: uint,
    water-target: uint,
    waste-reduction-target: uint,
    carbon-footprint-target: uint,
    leed-target-points: uint
  }
)

;; Public Functions

;; Register a new building
(define-public (register-building
    (name (string-ascii 100))
    (location (string-ascii 200))
    (building-type (string-ascii 50))
    (total-area uint)
    (target-certification (string-ascii 50))
    (sustainability-goals (string-ascii 500)))
  (let ((building-id (var-get next-building-id)))
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> (len location) u0) ERR-INVALID-INPUT)
    (asserts! (> total-area u0) ERR-INVALID-INPUT)

    (map-set buildings
      { building-id: building-id }
      {
        name: name,
        owner: tx-sender,
        location: location,
        building-type: building-type,
        total-area: total-area,
        status: STATUS-PLANNING,
        created-at: block-height,
        updated-at: block-height,
        target-certification: target-certification,
        sustainability-goals: sustainability-goals
      }
    )

    ;; Initialize planning phase
    (map-set project-phases
      { building-id: building-id, phase: STATUS-PLANNING }
      {
        phase-name: "Planning & Design",
        start-date: block-height,
        end-date: none,
        completion-percentage: u0,
        phase-notes: "Initial project planning phase"
      }
    )

    ;; Add owner as primary stakeholder
    (map-set building-stakeholders
      { building-id: building-id, stakeholder: tx-sender }
      {
        role: "Owner",
        permissions: u255,
        added-at: block-height
      }
    )

    (var-set next-building-id (+ building-id u1))
    (ok building-id)
  )
)

;; Update building status
(define-public (update-building-status (building-id uint) (new-status uint))
  (let ((building (unwrap! (map-get? buildings { building-id: building-id }) ERR-BUILDING-NOT-FOUND)))
    (asserts! (is-authorized building-id tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (and (>= new-status u1) (<= new-status u5)) ERR-INVALID-PHASE)

    (map-set buildings
      { building-id: building-id }
      (merge building {
        status: new-status,
        updated-at: block-height
      })
    )
    (ok true)
  )
)

;; Add project phase
(define-public (add-project-phase
    (building-id uint)
    (phase uint)
    (phase-name (string-ascii 100))
    (phase-notes (string-ascii 500)))
  (let ((building (unwrap! (map-get? buildings { building-id: building-id }) ERR-BUILDING-NOT-FOUND)))
    (asserts! (is-authorized building-id tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (and (>= phase u1) (<= phase u5)) ERR-INVALID-PHASE)

    (map-set project-phases
      { building-id: building-id, phase: phase }
      {
        phase-name: phase-name,
        start-date: block-height,
        end-date: none,
        completion-percentage: u0,
        phase-notes: phase-notes
      }
    )
    (ok true)
  )
)

;; Update phase completion
(define-public (update-phase-completion
    (building-id uint)
    (phase uint)
    (completion-percentage uint))
  (let ((phase-data (unwrap! (map-get? project-phases { building-id: building-id, phase: phase }) ERR-BUILDING-NOT-FOUND)))
    (asserts! (is-authorized building-id tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (<= completion-percentage u100) ERR-INVALID-INPUT)

    (map-set project-phases
      { building-id: building-id, phase: phase }
      (merge phase-data {
        completion-percentage: completion-percentage,
        end-date: (if (is-eq completion-percentage u100) (some block-height) none)
      })
    )
    (ok true)
  )
)

;; Add stakeholder
(define-public (add-stakeholder
    (building-id uint)
    (stakeholder principal)
    (role (string-ascii 50))
    (permissions uint))
  (let ((building (unwrap! (map-get? buildings { building-id: building-id }) ERR-BUILDING-NOT-FOUND)))
    (asserts! (is-authorized building-id tx-sender) ERR-NOT-AUTHORIZED)

    (map-set building-stakeholders
      { building-id: building-id, stakeholder: stakeholder }
      {
        role: role,
        permissions: permissions,
        added-at: block-height
      }
    )
    (ok true)
  )
)

;; Set building sustainability targets
(define-public (set-sustainability-targets
    (building-id uint)
    (energy-target uint)
    (water-target uint)
    (waste-reduction-target uint)
    (carbon-footprint-target uint)
    (leed-target-points uint))
  (let ((building (unwrap! (map-get? buildings { building-id: building-id }) ERR-BUILDING-NOT-FOUND)))
    (asserts! (is-authorized building-id tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (<= leed-target-points u110) ERR-INVALID-INPUT)

    (map-set building-metrics
      { building-id: building-id }
      {
        energy-target: energy-target,
        water-target: water-target,
        waste-reduction-target: waste-reduction-target,
        carbon-footprint-target: carbon-footprint-target,
        leed-target-points: leed-target-points
      }
    )
    (ok true)
  )
)

;; Read-only Functions

;; Get building information
(define-read-only (get-building (building-id uint))
  (map-get? buildings { building-id: building-id })
)

;; Get project phase information
(define-read-only (get-project-phase (building-id uint) (phase uint))
  (map-get? project-phases { building-id: building-id, phase: phase })
)

;; Get stakeholder information
(define-read-only (get-stakeholder (building-id uint) (stakeholder principal))
  (map-get? building-stakeholders { building-id: building-id, stakeholder: stakeholder })
)

;; Get building metrics
(define-read-only (get-building-metrics (building-id uint))
  (map-get? building-metrics { building-id: building-id })
)

;; Get next building ID
(define-read-only (get-next-building-id)
  (var-get next-building-id)
)

;; Check if building exists
(define-read-only (building-exists (building-id uint))
  (is-some (map-get? buildings { building-id: building-id }))
)

;; Private Functions

;; Check if user is authorized to modify building
(define-private (is-authorized (building-id uint) (user principal))
  (or
    (is-eq user CONTRACT-OWNER)
    (match (map-get? buildings { building-id: building-id })
      building (is-eq user (get owner building))
      false
    )
    (match (map-get? building-stakeholders { building-id: building-id, stakeholder: user })
      stakeholder (> (get permissions stakeholder) u0)
      false
    )
  )
)
