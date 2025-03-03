;; Constants
(define-constant CANVAS_SIZE u32)
(define-constant ERR_NOT_FOUND (err u100))
(define-constant ERR_UNAUTHORIZED (err u101))
(define-constant ERR_INVALID_COORDINATES (err u102))
(define-constant ERR_INVALID_COLOR (err u103))
(define-constant ERR_CANVAS_LOCKED (err u104))
(define-constant ERR_MAX_CONTRIBUTORS (err u105))

;; Events
(define-data-var last-event-id uint u0)
(define-map events
  uint
  {
    event-type: (string-ascii 24),
    canvas-id: uint,
    user: principal,
    timestamp: uint
  }
)

;; Define NFT for artworks
(define-non-fungible-token pixel-artwork uint)

;; Data structures
(define-map canvases
  uint
  {
    name: (string-ascii 64),
    owner: principal,
    contributors: (list 10 principal),
    locked: bool,
    created-at: uint
  }
)

(define-map pixels
  { canvas-id: uint, x: uint, y: uint }
  { color: (string-ascii 6), last-modified: uint }
)

;; Canvas ID counter
(define-data-var canvas-id-nonce uint u0)

;; Helper functions
(define-private (emit-event (event-type (string-ascii 24)) (canvas-id uint))
  (let ((event-id (+ (var-get last-event-id) u1)))
    (map-set events event-id
      {
        event-type: event-type,
        canvas-id: canvas-id,
        user: tx-sender,
        timestamp: block-height
      }
    )
    (var-set last-event-id event-id)
    (ok event-id)
  )
)

(define-private (validate-color (color (string-ascii 6)))
  (let ((len (len color)))
    (and
      (is-eq len u6)
      (match (string-to-uint16? color 16) hex-val true false)
    )
  )
)

;; Create new canvas
(define-public (create-canvas (name (string-ascii 64)))
  (let ((new-id (+ (var-get canvas-id-nonce) u1)))
    (map-set canvases new-id
      {
        name: name,
        owner: tx-sender,
        contributors: (list tx-sender),
        locked: false,
        created-at: block-height
      }
    )
    (var-set canvas-id-nonce new-id)
    (emit-event "canvas_created" new-id)
    (ok new-id)
  )
)

;; Update pixel
(define-public (update-pixel (canvas-id uint) (x uint) (y uint) (color (string-ascii 6)))
  (let ((canvas (unwrap! (map-get? canvases canvas-id) ERR_NOT_FOUND)))
    (asserts! (not (get locked canvas)) ERR_CANVAS_LOCKED)
    (asserts! (or
      (is-eq (get owner canvas) tx-sender)
      (is-some (index-of? (get contributors canvas) tx-sender))
    ) ERR_UNAUTHORIZED)
    (asserts! (and (<= x CANVAS_SIZE) (<= y CANVAS_SIZE)) ERR_INVALID_COORDINATES)
    (asserts! (validate-color color) ERR_INVALID_COLOR)
    (map-set pixels { canvas-id: canvas-id, x: x, y: y }
      { color: color, last-modified: block-height }
    )
    (emit-event "pixel_updated" canvas-id)
    (ok true)
  )
)

;; Add contributor
(define-public (add-contributor (canvas-id uint) (contributor principal))
  (let (
    (canvas (unwrap! (map-get? canvases canvas-id) ERR_NOT_FOUND))
    (current-contributors (get contributors canvas))
  )
    (asserts! (is-eq (get owner canvas) tx-sender) ERR_UNAUTHORIZED)
    (asserts! (< (len current-contributors) u10) ERR_MAX_CONTRIBUTORS)
    (asserts! (is-none (index-of? current-contributors contributor)) ERR_UNAUTHORIZED)
    (map-set canvases canvas-id
      (merge canvas { contributors: (append current-contributors contributor) })
    )
    (emit-event "contributor_added" canvas-id)
    (ok true)
  )
)

;; Lock canvas
(define-public (lock-canvas (canvas-id uint))
  (let ((canvas (unwrap! (map-get? canvases canvas-id) ERR_NOT_FOUND)))
    (asserts! (is-eq (get owner canvas) tx-sender) ERR_UNAUTHORIZED)
    (map-set canvases canvas-id
      (merge canvas { locked: true })
    )
    (emit-event "canvas_locked" canvas-id)
    (ok true)
  )
)

;; Get pixel data
(define-read-only (get-pixel (canvas-id uint) (x uint) (y uint))
  (map-get? pixels { canvas-id: canvas-id, x: x, y: y })
)

;; Get canvas info
(define-read-only (get-canvas (canvas-id uint))
  (map-get? canvases canvas-id)
)

;; Get canvas events
(define-read-only (get-event (event-id uint))
  (map-get? events event-id)
)

;; Mint artwork as NFT
(define-public (mint-artwork (canvas-id uint) (recipient principal))
  (let ((canvas (unwrap! (map-get? canvases canvas-id) ERR_NOT_FOUND)))
    (asserts! (is-eq (get owner canvas) tx-sender) ERR_UNAUTHORIZED)
    (asserts! (not (get locked canvas)) ERR_CANVAS_LOCKED)
    (try! (lock-canvas canvas-id))
    (emit-event "artwork_minted" canvas-id)
    (nft-mint? pixel-artwork canvas-id recipient)
  )
)
