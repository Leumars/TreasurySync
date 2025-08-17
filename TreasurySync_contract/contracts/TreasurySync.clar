
;; title: TreasurySync
;; version: 1.0.0
;; summary: Synthetic Assets for US Treasury Securities
;; description: Creates synthetic exposure to traditional US Treasury assets through tokenized representation

;; traits
;;

;; token definitions
(define-fungible-token syn-treasury-token)

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_INSUFFICIENT_BALANCE (err u402))
(define-constant ERR_INVALID_AMOUNT (err u403))
(define-constant ERR_ASSET_NOT_FOUND (err u404))
(define-constant ERR_ORACLE_PRICE_STALE (err u405))
(define-constant ERR_MINT_LIMIT_EXCEEDED (err u406))

;; Minimum collateral ratio (150% = 15000 basis points)
(define-constant MIN_COLLATERAL_RATIO u15000)
(define-constant BASIS_POINTS u10000)

;; Maximum supply of synthetic treasury tokens (1 billion tokens)
(define-constant MAX_SUPPLY u1000000000000000)

;; data vars
(define-data-var contract-admin principal CONTRACT_OWNER)
(define-data-var total-collateral uint u0)
(define-data-var treasury-price uint u100000000) ;; Price in microSTX (initial: $100)
(define-data-var last-price-update uint u0)
(define-data-var price-oracle principal CONTRACT_OWNER)
(define-data-var minting-enabled bool true)

;; data maps
;; User collateral positions
(define-map user-collateral principal uint)

;; User synthetic token balances (tracked separately for additional functionality)
(define-map user-synthetic-balance principal uint)

;; Treasury asset metadata
(define-map treasury-assets 
  { asset-id: uint }
  {
    name: (string-ascii 50),
    symbol: (string-ascii 10),
    maturity-date: uint,
    yield-rate: uint, ;; basis points
    is-active: bool
  }
)

;; Asset ID counter
(define-data-var next-asset-id uint u1)

;; public functions

;; Initialize a new treasury asset
(define-public (create-treasury-asset (name (string-ascii 50)) (symbol (string-ascii 10)) (maturity-date uint) (yield-rate uint))
  (let ((asset-id (var-get next-asset-id)))
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR_UNAUTHORIZED)
    (map-set treasury-assets 
      { asset-id: asset-id }
      {
        name: name,
        symbol: symbol,
        maturity-date: maturity-date,
        yield-rate: yield-rate,
        is-active: true
      }
    )
    (var-set next-asset-id (+ asset-id u1))
    (ok asset-id)
  )
)

;; Deposit STX as collateral
(define-public (deposit-collateral (amount uint))
  (let ((current-collateral (default-to u0 (map-get? user-collateral tx-sender))))
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set user-collateral tx-sender (+ current-collateral amount))
    (var-set total-collateral (+ (var-get total-collateral) amount))
    (ok true)
  )
)

;; Mint synthetic treasury tokens
(define-public (mint-synthetic-tokens (amount uint))
  (let (
    (user-collateral-amount (default-to u0 (map-get? user-collateral tx-sender)))
    (treasury-price-val (var-get treasury-price))
    (required-collateral (* (* amount treasury-price-val) MIN_COLLATERAL_RATIO))
    (required-collateral-adjusted (/ required-collateral BASIS_POINTS))
    (current-supply (ft-get-supply syn-treasury-token))
  )
    (asserts! (var-get minting-enabled) ERR_UNAUTHORIZED)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (<= (+ current-supply amount) MAX_SUPPLY) ERR_MINT_LIMIT_EXCEEDED)
    (asserts! (>= user-collateral-amount required-collateral-adjusted) ERR_INSUFFICIENT_BALANCE)
    
    ;; Mint the tokens
    (try! (ft-mint? syn-treasury-token amount tx-sender))
    
    ;; Update user balance tracking
    (let ((current-balance (default-to u0 (map-get? user-synthetic-balance tx-sender))))
      (map-set user-synthetic-balance tx-sender (+ current-balance amount))
    )
    
    (ok amount)
  )
)

;; Burn synthetic tokens and release collateral
(define-public (burn-synthetic-tokens (amount uint))
  (let (
    (user-balance (ft-get-balance syn-treasury-token tx-sender))
    (treasury-price-val (var-get treasury-price))
    (collateral-to-release (* (* amount treasury-price-val) MIN_COLLATERAL_RATIO))
    (collateral-to-release-adjusted (/ collateral-to-release BASIS_POINTS))
    (user-collateral-amount (default-to u0 (map-get? user-collateral tx-sender)))
  )
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (>= user-balance amount) ERR_INSUFFICIENT_BALANCE)
    (asserts! (>= user-collateral-amount collateral-to-release-adjusted) ERR_INSUFFICIENT_BALANCE)
    
    ;; Burn the tokens
    (try! (ft-burn? syn-treasury-token amount tx-sender))
    
    ;; Update user balance tracking
    (let ((current-balance (default-to u0 (map-get? user-synthetic-balance tx-sender))))
      (map-set user-synthetic-balance tx-sender (- current-balance amount))
    )
    
    ;; Release collateral
    (map-set user-collateral tx-sender (- user-collateral-amount collateral-to-release-adjusted))
    (var-set total-collateral (- (var-get total-collateral) collateral-to-release-adjusted))
    
    (try! (as-contract (stx-transfer? collateral-to-release-adjusted tx-sender tx-sender)))
    
    (ok amount)
  )
)

;; Withdraw excess collateral
(define-public (withdraw-collateral (amount uint))
  (let (
    (user-collateral-amount (default-to u0 (map-get? user-collateral tx-sender)))
    (user-synthetic-amount (default-to u0 (map-get? user-synthetic-balance tx-sender)))
    (treasury-price-val (var-get treasury-price))
    (required-collateral (* (* user-synthetic-amount treasury-price-val) MIN_COLLATERAL_RATIO))
    (required-collateral-adjusted (/ required-collateral BASIS_POINTS))
    (available-collateral (- user-collateral-amount required-collateral-adjusted))
  )
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (>= available-collateral amount) ERR_INSUFFICIENT_BALANCE)
    
    (map-set user-collateral tx-sender (- user-collateral-amount amount))
    (var-set total-collateral (- (var-get total-collateral) amount))
    
    (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
    
    (ok amount)
  )
)

;; Update treasury price (oracle function)
(define-public (update-treasury-price (new-price uint))
  (begin
    (asserts! (is-eq tx-sender (var-get price-oracle)) ERR_UNAUTHORIZED)
    (asserts! (> new-price u0) ERR_INVALID_AMOUNT)
    (var-set treasury-price new-price)
    (var-set last-price-update block-height)
    (ok new-price)
  )
)

;; Admin functions
(define-public (set-contract-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR_UNAUTHORIZED)
    (var-set contract-admin new-admin)
    (ok new-admin)
  )
)

(define-public (set-price-oracle (new-oracle principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR_UNAUTHORIZED)
    (var-set price-oracle new-oracle)
    (ok new-oracle)
  )
)

(define-public (toggle-minting (enabled bool))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR_UNAUTHORIZED)
    (var-set minting-enabled enabled)
    (ok enabled)
  )
)

;; read only functions

;; Get user collateral amount
(define-read-only (get-user-collateral (user principal))
  (default-to u0 (map-get? user-collateral user))
)

;; Get user synthetic token balance
(define-read-only (get-user-synthetic-balance (user principal))
  (default-to u0 (map-get? user-synthetic-balance user))
)

;; Get treasury asset information
(define-read-only (get-treasury-asset (asset-id uint))
  (map-get? treasury-assets { asset-id: asset-id })
)

;; Get current treasury price
(define-read-only (get-treasury-price)
  (var-get treasury-price)
)

;; Get total collateral in the system
(define-read-only (get-total-collateral)
  (var-get total-collateral)
)

;; Calculate collateral ratio for a user
(define-read-only (get-user-collateral-ratio (user principal))
  (let (
    (user-collateral-amount (get-user-collateral user))
    (user-synthetic-amount (get-user-synthetic-balance user))
    (treasury-price-val (var-get treasury-price))
  )
    (if (is-eq user-synthetic-amount u0)
      u0
      (/ (* (* user-collateral-amount BASIS_POINTS) BASIS_POINTS) 
         (* user-synthetic-amount treasury-price-val))
    )
  )
)

;; Check if user can mint additional tokens
(define-read-only (get-max-mintable-tokens (user principal))
  (let (
    (user-collateral-amount (get-user-collateral user))
    (treasury-price-val (var-get treasury-price))
    (max-value (* user-collateral-amount BASIS_POINTS))
    (max-tokens (/ max-value (* treasury-price-val MIN_COLLATERAL_RATIO)))
    (current-synthetic (get-user-synthetic-balance user))
  )
    (if (> max-tokens current-synthetic)
      (- max-tokens current-synthetic)
      u0
    )
  )
)

;; Get contract metadata
(define-read-only (get-contract-info)
  {
    admin: (var-get contract-admin),
    price-oracle: (var-get price-oracle),
    minting-enabled: (var-get minting-enabled),
    total-supply: (ft-get-supply syn-treasury-token),
    max-supply: MAX_SUPPLY,
    min-collateral-ratio: MIN_COLLATERAL_RATIO
  }
)

;; private functions

;; Helper function to check if price is stale (older than 100 blocks)
(define-private (is-price-stale)
  (> (- block-height (var-get last-price-update)) u100)
)
