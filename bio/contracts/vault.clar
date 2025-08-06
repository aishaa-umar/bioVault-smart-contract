;; BioVault: Decentralized Biological Information Trading Hub
;; A secure, transparent marketplace enabling individuals to monetize their biological information
;; while providing researchers and healthcare providers with verified genomic datasets.
;; This platform ensures data privacy, fair compensation, and regulatory compliance
;; through blockchain-based smart contracts and decentralized governance.

;; SYSTEM CONFIGURATION & ERROR CODES

;; System administration
(define-constant SYSTEM_OWNER tx-sender)
(define-constant TRADING_FEE_RATE u8) ;; 8% platform commission
(define-constant MAX_COMMISSION_LIMIT u25) ;; Maximum 25% commission cap
(define-constant MIN_LISTING_COST u1000) ;; Minimum 1000 microSTX
(define-constant MAX_RATING_VALUE u5)
(define-constant MIN_RATING_VALUE u1)
(define-constant MAX_RECORD_ID u99999999) ;; Maximum dataset ID for validation
(define-constant MIN_TEXT_LENGTH u1)
(define-constant MAX_URI_LENGTH u512)
(define-constant MAX_CATEGORY_LENGTH u100)
(define-constant MAX_TIER_LENGTH u30)
(define-constant MAX_TECH_LENGTH u150)
(define-constant MAX_PURPOSE_LENGTH u300)
(define-constant MAX_COMMENT_LENGTH u1000)

;; Comprehensive error handling system
(define-constant ERR_ADMIN_REQUIRED (err u200))
(define-constant ERR_RECORD_NOT_FOUND (err u201))
(define-constant ERR_ACCESS_DENIED (err u202))
(define-constant ERR_INSUFFICIENT_PAYMENT (err u203))
(define-constant ERR_DUPLICATE_RECORD (err u204))
(define-constant ERR_INVALID_PRICE (err u205))
(define-constant ERR_RECORD_UNAVAILABLE (err u206))
(define-constant ERR_DUPLICATE_PURCHASE (err u207))
(define-constant ERR_INVALID_INPUT (err u208))
(define-constant ERR_SYSTEM_SUSPENDED (err u209))
(define-constant ERR_RATING_OUT_OF_RANGE (err u210))
(define-constant ERR_UNAUTHORIZED_REVIEW (err u211))
(define-constant ERR_INVALID_RECORD_ID (err u212))
(define-constant ERR_INVALID_TEXT_LENGTH (err u213))
(define-constant ERR_INVALID_HASH (err u214))
(define-constant ERR_INVALID_ADDRESS (err u215))

;; SYSTEM STATE MANAGEMENT

;; Global system variables
(define-data-var hub-active-status bool true)
(define-data-var current-fee-rate uint TRADING_FEE_RATE)
(define-data-var next-record-id uint u1000) ;; Start from 1000
(define-data-var total-hub-trades uint u0)
(define-data-var total-hub-earnings uint u0)

;; COMPREHENSIVE DATA STRUCTURES

;; Primary biological data registry with comprehensive metadata
(define-map bio-data-registry
    { record-id: uint }
    {
        record-owner: principal,
        data-hash: (buff 32),
        metadata-uri: (string-ascii 512),
        listing-price: uint,
        data-category: (string-ascii 100),
        access-level: (string-ascii 30),
        is-active: bool,
        creation-height: uint,
        purchase-count: uint,
        is-verified: bool,
        sample-count: uint,
        tech-platform: (string-ascii 150)
    }
)

;; Comprehensive user profiles with enhanced metrics
(define-map user-profiles
    { user-address: principal }
    {
        reputation-points: uint,
        records-created: uint,
        purchases-made: uint,
        is-verified: bool,
        join-height: uint,
        total-earnings: uint,
        specialty-field: (string-ascii 100),
        organization: (string-ascii 200)
    }
)

;; Enhanced access permissions with detailed transaction history
(define-map access-grants
    { record-id: uint, buyer-address: principal }
    {
        purchase-height: uint,
        has-access: bool,
        payment-amount: uint,
        expiry-height: (optional uint),
        usage-intent: (string-ascii 300)
    }
)

;; Sophisticated review and rating system
(define-map quality-reviews
    { record-id: uint, reviewer-address: principal }
    {
        rating-score: uint,
        review-text: (string-utf8 1000),
        review-height: uint,
        reviewer-verified: bool,
        helpful-votes: uint
    }
)

;; Advanced analytics and tracking
(define-map record-metrics
    { metric-record-id: uint }
    {
        revenue-total: uint,
        avg-rating: uint,
        review-total: uint,
        last-activity: uint,
        popularity-score: uint
    }
)

;; INPUT VALIDATION FUNCTIONS

;; Validate record identifier range
(define-private (check-record-id (record-id uint))
    (and (> record-id u0) (<= record-id MAX_RECORD_ID))
)

;; Validate string lengths and content
(define-private (check-uri (uri (string-ascii 512)))
    (and (>= (len uri) MIN_TEXT_LENGTH) (<= (len uri) MAX_URI_LENGTH))
)

(define-private (check-category (category (string-ascii 100)))
    (and (>= (len category) MIN_TEXT_LENGTH) (<= (len category) MAX_CATEGORY_LENGTH))
)

(define-private (check-tier (tier (string-ascii 30)))
    (and (>= (len tier) MIN_TEXT_LENGTH) (<= (len tier) MAX_TIER_LENGTH))
)

(define-private (check-technology (tech (string-ascii 150)))
    (and (>= (len tech) MIN_TEXT_LENGTH) (<= (len tech) MAX_TECH_LENGTH))
)

(define-private (check-purpose (purpose (string-ascii 300)))
    (and (>= (len purpose) MIN_TEXT_LENGTH) (<= (len purpose) MAX_PURPOSE_LENGTH))
)

(define-private (check-comment (text (string-utf8 1000)))
    (and (>= (len text) MIN_TEXT_LENGTH) (<= (len text) MAX_COMMENT_LENGTH))
)

;; Validate hash format (check if buffer is exactly 32 bytes)
(define-private (check-hash (hash (buff 32)))
    (is-eq (len hash) u32)
)

;; Validate principal address (ensure it's not the zero principal and is valid)
(define-private (check-address (address principal))
    (and 
        (not (is-eq address 'SP000000000000000000002Q6VF78))  ;; Not zero principal
        (not (is-eq address tx-sender))  ;; Not same as caller for verification functions
    )
)

;; UTILITY AND VALIDATION FUNCTIONS

;; Administrative privilege verification
(define-private (is-admin)
    (is-eq tx-sender SYSTEM_OWNER)
)

;; System operational status check
(define-private (is-hub-active)
    (var-get hub-active-status)
)

;; Enhanced price validation with minimum requirements
(define-private (check-price (price uint))
    (>= price MIN_LISTING_COST)
)

;; Review score validation within acceptable range
(define-private (check-rating (rating uint))
    (and (>= rating MIN_RATING_VALUE) 
         (<= rating MAX_RATING_VALUE))
)

;; Comprehensive user profile initialization with enhanced defaults
(define-private (setup-user-profile (user-addr principal))
    (match (map-get? user-profiles { user-address: user-addr })
        existing-user (ok true)
        (begin
            (map-set user-profiles
                { user-address: user-addr }
                {
                    reputation-points: u750, ;; Starting reputation
                    records-created: u0,
                    purchases-made: u0,
                    is-verified: false,
                    join-height: block-height,
                    total-earnings: u0,
                    specialty-field: "general-user",
                    organization: "independent-researcher"
                }
            )
            (ok true)
        )
    )
)

;; CORE MARKETPLACE FUNCTIONALITY

;; Register comprehensive biological dataset with enhanced metadata
(define-public (create-bio-record
    (data-signature (buff 32))
    (uri-location (string-ascii 512))
    (price-microstx uint)
    (bio-category (string-ascii 100))
    (tier-level (string-ascii 30))
    (sample-size uint)
    (tech-used (string-ascii 150))
    (intended-use (string-ascii 300))
)
    (let (
        (new-record-id (var-get next-record-id))
        (fee-amount (/ (* price-microstx (var-get current-fee-rate)) u100))
    )
        (asserts! (is-hub-active) ERR_SYSTEM_SUSPENDED)
        (asserts! (check-price price-microstx) ERR_INVALID_PRICE)
        (asserts! (check-hash data-signature) ERR_INVALID_HASH)
        (asserts! (check-uri uri-location) ERR_INVALID_TEXT_LENGTH)
        (asserts! (check-category bio-category) ERR_INVALID_TEXT_LENGTH)
        (asserts! (check-tier tier-level) ERR_INVALID_TEXT_LENGTH)
        (asserts! (check-technology tech-used) ERR_INVALID_TEXT_LENGTH)
        (asserts! (check-purpose intended-use) ERR_INVALID_TEXT_LENGTH)
        (asserts! (> sample-size u0) ERR_INVALID_INPUT)
        
        ;; Initialize user profile if needed
        (unwrap-panic (setup-user-profile tx-sender))
        
        ;; Register comprehensive biological record
        (map-set bio-data-registry
            { record-id: new-record-id }
            {
                record-owner: tx-sender,
                data-hash: data-signature,
                metadata-uri: uri-location,
                listing-price: price-microstx,
                data-category: bio-category,
                access-level: tier-level,
                is-active: true,
                creation-height: block-height,
                purchase-count: u0,
                is-verified: false,
                sample-count: sample-size,
                tech-platform: tech-used
            }
        )
        
        ;; Initialize metrics tracking
        (map-set record-metrics
            { metric-record-id: new-record-id }
            {
                revenue-total: u0,
                avg-rating: u0,
                review-total: u0,
                last-activity: u0,
                popularity-score: u100
            }
        )
        
        ;; Update user contribution metrics
        (match (map-get? user-profiles { user-address: tx-sender })
            current-profile
            (map-set user-profiles
                { user-address: tx-sender }
                (merge current-profile 
                    { records-created: (+ (get records-created current-profile) u1) }
                )
            )
            false
        )
        
        ;; Increment record identifier for next registration
        (var-set next-record-id (+ new-record-id u1))
        
        (ok new-record-id)
    )
)

;; Enhanced biological data access purchase with comprehensive tracking
(define-public (buy-data-access 
    (target-record-id uint)
    (usage-statement (string-ascii 300))
)
    (let (
        (record-info (unwrap! (map-get? bio-data-registry { record-id: target-record-id }) ERR_RECORD_NOT_FOUND))
        (record-price (get listing-price record-info))
        (fee-amount (/ (* record-price (var-get current-fee-rate)) u100))
        (seller-payment (- record-price fee-amount))
        (owner-addr (get record-owner record-info))
    )
        (asserts! (is-hub-active) ERR_SYSTEM_SUSPENDED)
        (asserts! (check-record-id target-record-id) ERR_INVALID_RECORD_ID)
        (asserts! (check-purpose usage-statement) ERR_INVALID_TEXT_LENGTH)
        (asserts! (get is-active record-info) ERR_RECORD_UNAVAILABLE)
        (asserts! (not (is-eq tx-sender owner-addr)) ERR_ACCESS_DENIED)
        
        ;; Verify no previous purchase exists
        (asserts! (is-none (map-get? access-grants 
                         { record-id: target-record-id, buyer-address: tx-sender })) 
                 ERR_DUPLICATE_PURCHASE)
        
        ;; Initialize buyer profile if necessary
        (unwrap-panic (setup-user-profile tx-sender))
        
        ;; Execute secure payment transfer to record owner
        (try! (stx-transfer? seller-payment tx-sender owner-addr))
        
        ;; Transfer platform fee to administrator
        (try! (stx-transfer? fee-amount tx-sender SYSTEM_OWNER))
        
        ;; Grant comprehensive data access authorization
        (map-set access-grants
            { record-id: target-record-id, buyer-address: tx-sender }
            {
                purchase-height: block-height,
                has-access: true,
                payment-amount: record-price,
                expiry-height: none, ;; Permanent access by default
                usage-intent: usage-statement
            }
        )
        
        ;; Update comprehensive record statistics
        (map-set bio-data-registry
            { record-id: target-record-id }
            (merge record-info 
                { purchase-count: (+ (get purchase-count record-info) u1) }
            )
        )
        
        ;; Update seller earnings and buyer purchase history
        (match (map-get? user-profiles { user-address: owner-addr })
            seller-profile
            (map-set user-profiles
                { user-address: owner-addr }
                (merge seller-profile 
                    { total-earnings: (+ (get total-earnings seller-profile) seller-payment) }
                )
            )
            false
        )
        
        (match (map-get? user-profiles { user-address: tx-sender })
            buyer-profile
            (map-set user-profiles
                { user-address: tx-sender }
                (merge buyer-profile 
                    { purchases-made: (+ (get purchases-made buyer-profile) u1) }
                )
            )
            false
        )
        
        ;; Update platform-wide analytics
        (var-set total-hub-trades (+ (var-get total-hub-trades) u1))
        (var-set total-hub-earnings (+ (var-get total-hub-earnings) fee-amount))
        
        ;; Update record performance metrics
        (match (map-get? record-metrics { metric-record-id: target-record-id })
            current-metrics
            (map-set record-metrics
                { metric-record-id: target-record-id }
                (merge current-metrics {
                    revenue-total: (+ (get revenue-total current-metrics) record-price),
                    last-activity: block-height,
                    popularity-score: (+ (get popularity-score current-metrics) u10)
                })
            )
            false
        )
        
        (ok true)
    )
)

;; Submit comprehensive record quality review with enhanced validation
(define-public (submit-quality-review
    (reviewed-record-id uint)
    (quality-rating uint)
    (review-comment (string-utf8 1000))
)
    (let (
        (reviewer-profile (unwrap! (map-get? user-profiles { user-address: tx-sender }) ERR_ACCESS_DENIED))
    )
        (asserts! (is-hub-active) ERR_SYSTEM_SUSPENDED)
        (asserts! (check-record-id reviewed-record-id) ERR_INVALID_RECORD_ID)
        (asserts! (check-rating quality-rating) ERR_RATING_OUT_OF_RANGE)
        (asserts! (check-comment review-comment) ERR_INVALID_TEXT_LENGTH)
        
        ;; Verify reviewer has purchased access to the record
        (asserts! (is-some (map-get? access-grants 
                          { record-id: reviewed-record-id, buyer-address: tx-sender }))
                 ERR_UNAUTHORIZED_REVIEW)
        
        ;; Verify record exists
        (asserts! (is-some (map-get? bio-data-registry { record-id: reviewed-record-id })) 
                 ERR_RECORD_NOT_FOUND)
        
        ;; Submit comprehensive quality review
        (map-set quality-reviews
            { record-id: reviewed-record-id, reviewer-address: tx-sender }
            {
                rating-score: quality-rating,
                review-text: review-comment,
                review-height: block-height,
                reviewer-verified: (get is-verified reviewer-profile),
                helpful-votes: u0
            }
        )
        
        ;; Update record metrics with new review
        (match (map-get? record-metrics { metric-record-id: reviewed-record-id })
            current-metrics
            (let (
                (updated-count (+ (get review-total current-metrics) u1))
                (current-avg (get avg-rating current-metrics))
                (new-avg (/ (+ (* current-avg (get review-total current-metrics)) quality-rating) updated-count))
            )
                (map-set record-metrics
                    { metric-record-id: reviewed-record-id }
                    (merge current-metrics {
                        avg-rating: new-avg,
                        review-total: updated-count
                    })
                )
            )
            false
        )
        
        (ok true)
    )
)

;; RECORD MANAGEMENT FUNCTIONS

;; Update record pricing with enhanced validation
(define-public (update-record-price 
    (target-record-id uint) 
    (new-price uint)
)
    (let (
        (record-details (unwrap! (map-get? bio-data-registry { record-id: target-record-id }) ERR_RECORD_NOT_FOUND))
    )
        (asserts! (is-hub-active) ERR_SYSTEM_SUSPENDED)
        (asserts! (check-record-id target-record-id) ERR_INVALID_RECORD_ID)
        (asserts! (is-eq tx-sender (get record-owner record-details)) ERR_ACCESS_DENIED)
        (asserts! (check-price new-price) ERR_INVALID_PRICE)
        
        (map-set bio-data-registry
            { record-id: target-record-id }
            (merge record-details { listing-price: new-price })
        )
        
        (ok true)
    )
)

;; Toggle record marketplace availability
(define-public (toggle-record-status (target-record-id uint))
    (let (
        (record-details (unwrap! (map-get? bio-data-registry { record-id: target-record-id }) ERR_RECORD_NOT_FOUND))
    )
        (asserts! (check-record-id target-record-id) ERR_INVALID_RECORD_ID)
        (asserts! (is-eq tx-sender (get record-owner record-details)) ERR_ACCESS_DENIED)
        
        (map-set bio-data-registry
            { record-id: target-record-id }
            (merge record-details { is-active: (not (get is-active record-details)) })
        )
        
        (ok true)
    )
)

;; ADMINISTRATIVE SYSTEM FUNCTIONS

;; Verify user identity (administrative function)
(define-public (verify-user-identity (target-user-addr principal))
    (let (
        (user-details (unwrap! (map-get? user-profiles { user-address: target-user-addr }) ERR_RECORD_NOT_FOUND))
    )
        (asserts! (is-admin) ERR_ADMIN_REQUIRED)
        (asserts! (check-address target-user-addr) ERR_INVALID_ADDRESS)
        
        (map-set user-profiles
            { user-address: target-user-addr }
            (merge user-details { is-verified: true })
        )
        
        (ok true)
    )
)

;; Adjust system fee rate
(define-public (update-fee-rate (new-fee-rate uint))
    (begin
        (asserts! (is-admin) ERR_ADMIN_REQUIRED)
        (asserts! (<= new-fee-rate MAX_COMMISSION_LIMIT) ERR_INVALID_INPUT)
        
        (var-set current-fee-rate new-fee-rate)
        (ok true)
    )
)

;; Control hub operational status
(define-public (toggle-hub-status)
    (begin
        (asserts! (is-admin) ERR_ADMIN_REQUIRED)
        (var-set hub-active-status (not (var-get hub-active-status)))
        (ok true)
    )
)

;; Verify record quality (administrative function)
(define-public (certify-record-quality (target-record-id uint))
    (let (
        (record-details (unwrap! (map-get? bio-data-registry { record-id: target-record-id }) ERR_RECORD_NOT_FOUND))
    )
        (asserts! (is-admin) ERR_ADMIN_REQUIRED)
        (asserts! (check-record-id target-record-id) ERR_INVALID_RECORD_ID)
        
        (map-set bio-data-registry
            { record-id: target-record-id }
            (merge record-details { is-verified: true })
        )
        
        (ok true)
    )
)

;; COMPREHENSIVE READ-ONLY QUERY FUNCTIONS

;; Retrieve complete biological record information
(define-read-only (get-record-details (record-id uint))
    (map-get? bio-data-registry { record-id: record-id })
)

;; Retrieve comprehensive user profile
(define-read-only (get-user-profile (user-addr principal))
    (map-get? user-profiles { user-address: user-addr })
)

;; Verify data access authorization status
(define-read-only (has-data-access (record-id uint) (user-addr principal))
    (is-some (map-get? access-grants { record-id: record-id, buyer-address: user-addr }))
)

;; Retrieve detailed access authorization information
(define-read-only (get-access-details (record-id uint) (user-addr principal))
    (map-get? access-grants { record-id: record-id, buyer-address: user-addr })
)

;; Retrieve record quality review information
(define-read-only (get-quality-review (record-id uint) (reviewer-addr principal))
    (map-get? quality-reviews { record-id: record-id, reviewer-address: reviewer-addr })
)

;; Retrieve record performance metrics
(define-read-only (get-record-metrics (record-id uint))
    (map-get? record-metrics { metric-record-id: record-id })
)

;; Get current system fee rate
(define-read-only (get-current-fee-rate)
    (var-get current-fee-rate)
)

;; Get next sequential record identifier
(define-read-only (get-next-record-id)
    (var-get next-record-id)
)

;; Check hub operational status
(define-read-only (get-hub-status)
    (var-get hub-active-status)
)

;; Retrieve system owner address
(define-read-only (get-system-owner)
    SYSTEM_OWNER
)

;; Get comprehensive system statistics
(define-read-only (get-hub-statistics)
    {
        total-trades: (var-get total-hub-trades),
        total-earnings: (var-get total-hub-earnings),
        current-fee-rate: (var-get current-fee-rate),
        next-record-id: (var-get next-record-id),
        hub-status: (var-get hub-active-status)
    }
)