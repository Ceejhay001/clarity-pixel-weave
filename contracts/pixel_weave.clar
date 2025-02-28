;; Constants
(define-constant CANVAS_SIZE u32)
(define-constant ERR_NOT_FOUND (err u100))
(define-constant ERR_UNAUTHORIZED (err u101))
(define-constant ERR_INVALID_COORDINATES (err u102))

;; Define NFT for artworks
(define-non-fungible-token pixel-artwork uint)

;; Data structures
(define-map canvases
  uint
  {
    name: (string-ascii 64),
    owner: principal,
    contributors: (list 10 principal),
    locked: bool
  }
)

(define-map pixels
  { canvas-id: uint, x: uint, y: uint }
  { color: (string-ascii 6), last-modified: uint }
)

;; Canvas ID counter
(define-data-var canvas-id-nonce uint u0)

;; Create new canvas
(define-public (create-canvas (name (string-ascii 64)) (owner principal))
  (let ((new-id (+ (var-get canvas-id-nonce) u1)))
    (map-set canvases new-id
      {
        name: name,
        owner: owner,
        contributors: (list owner),
        locked: false
      }
    )
    (var-set canvas-id-nonce new-id)
    (ok new-id)
  )
)

;; Update pixel
(define-public (update-pixel (canvas-id uint) (x uint) (y uint) (color (string-ascii 6)) (user principal))
  (let ((canvas (unwrap! (map-get? canvases canvas-id) ERR_NOT_FOUND)))
    (asserts! (or
      (is-eq (get owner canvas) user)
      (is-some (index-of? (get contributors canvas) user))
    ) ERR_UNAUTHORIZED)
    (asserts! (and (<= x CANVAS_SIZE) (<= y CANVAS_SIZE)) ERR_INVALID_COORDINATES)
    (map-set pixels { canvas-id: canvas-id, x: x, y: y }
      { color: color, last-modified: block-height }
    )
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

;; Mint artwork as NFT
(define-public (mint-artwork (canvas-id uint) (recipient principal))
  (let ((canvas (unwrap! (map-get? canvases canvas-id) ERR_NOT_FOUND)))
    (asserts! (is-eq (get owner canvas) tx-sender) ERR_UNAUTHORIZED)
    (nft-mint? pixel-artwork canvas-id recipient)
  )
)
