(module bro-treasury GOVERNANCE
  (implements DEX_NS.swap-callable-v1)
  (use DEX_NS.exchange [get-pair-key get-pair-by-key reserve-for add-liquidity swap remove-liquidity FEE])
  (use bro-registry [get-bro-account])
  (use free.util-math)
  (use free.util-time)
  (use free.util-lists)

  ;-----------------------------------------------------------------------------
  ; Administrative and ops capabilities
  ;-----------------------------------------------------------------------------
  (defcap GOVERNANCE ()
    (enforce-keyset "BRO_NS.governance"))

  (defcap INIT ()
    (compose-capability (GOVERNANCE))
    (compose-capability (LIQUIDITY)))

  (defcap BOT-OPERATOR ()
    (enforce-keyset "BRO_NS.bot"))

  (defcap TIPPING ()
    (compose-capability (BOT-OPERATOR))
    (compose-capability (TREASURY)))

  (defcap OPERATE-DEX ()
    (compose-capability (BOT-OPERATOR))
    (compose-capability (LIQUIDITY)))



  ;-----------------------------------------------------------------------------
  ; Caps and internal accounts management
  ;-----------------------------------------------------------------------------
  (defcap TREASURY () true)
  (defconst TREASURY-GUARD (create-capability-guard (TREASURY)))
  (defconst TREASURY-ACCOUNT (create-principal TREASURY-GUARD))

  (defcap LIQUIDITY () true)
  (defconst LIQUIDITY-GUARD (create-capability-guard (LIQUIDITY)))
  (defconst LIQUIDITY-ACCOUNT (create-principal LIQUIDITY-GUARD))


  ;-----------------------------------------------------------------------------
  ; Constants (tips)
  ;-----------------------------------------------------------------------------
  (defconst TIP-AMOUNT:decimal 0.001)

  ; Maximum COUNT of tips per PER
  (defconst TIPS-COUNT 10)
  (defconst TIPS-PER (hours 1))

  ; Using a defconst for the DEX key saves gas
  (defconst DEX-KEY (get-pair-key coin bro))

  ;-----------------------------------------------------------------------------
  ; Schemas and Tables
  ;-----------------------------------------------------------------------------
  (defschema liquidity-management-sch
    liquidity-target:decimal
    init:bool
  )

  (deftable liquidity-management:{liquidity-management-sch})

  (defschema tips-counters-sch
    total:decimal
    cnt:integer
    timer:[time]
  )
  (deftable tips-counters:{tips-counters-sch})

  ;-----------------------------------------------------------------------------
  ; Utility functions
  ;-----------------------------------------------------------------------------
  (defun div:decimal (num:decimal den:decimal)
    @doc "Divide and limit numbers of decimal (gas optimisation)"
    (floor (/ num den) 24))

  (defun get-pair ()
    (get-pair-by-key DEX-KEY))

  (defun dex-reserves:[decimal] ()
    @doc "Returns the Reserve of the DEXs to an array [Rbro $KDA]"
    (let ((pair (get-pair)))
      [(reserve-for pair bro), (reserve-for pair coin)]))

  (defun dex-account:string ()
    @doc "Returns the DEX's pair account"
    (at 'account (get-pair)))

  (defun liquidity-ratio:decimal ()
    @doc "Returns the ratio (Geom Mean of liquidity) / (LP totak supply)"
    (div (sqrt (prod (dex-reserves)))
         (DEX_NS.tokens.total-supply DEX-KEY)))

  (defun current-balance:decimal ()
    @doc "Return our LP token balance"
    (DEX_NS.tokens.get-balance DEX-KEY LIQUIDITY-ACCOUNT))

  (defun current-liquidity:decimal ()
    @doc "Returns the total liquidity we own"
    (* (current-balance) (liquidity-ratio)))

  (defun liquidity-to-remove:decimal ()
    @doc "Compute the liquidity to remove to meet our target 'intitial liquidity \
        \ Note: We don't take into account eckoDEX fees (minted through mint-fee) \
        \ Not a big deal: this may add a small hysteresis => But on the long term, it's OK"
    (with-read liquidity-management "" {'liquidity-target:=target}
      (floor (- (current-balance) (div target (liquidity-ratio)))
             (DEX_NS.tokens.precision DEX-KEY))))

  (defun kda-to-bro:decimal (x:decimal)
    @doc "Compute the amount of BRO we can have from a given amount of KDA"
    (let ((res (dex-reserves)))
      (floor (- (at 0 res) (div (prod res)
                                (+ (* x (- 1.0 FEE)) (at 1 res))))
             (bro.precision)))
  )

  (defun kda-balance:decimal ()
    @doc "KDA balance of the liquidity account"
    (coin.get-balance LIQUIDITY-ACCOUNT))

  (defun bro-balance:decimal ()
    @doc "BRO balance of the liquidity account"
    (bro.get-balance LIQUIDITY-ACCOUNT))

  (defun get-tips-counters:object{tips-counters-sch} ()
    @doc "Return tips counter"
    (read tips-counters ""))

  ;-----------------------------------------------------------------------------
  ; Private functions
  ;-----------------------------------------------------------------------------
  ; Function automatically called by the DEX (interface callable-v1) during the swap
  (defun swap-call:bool (token-in:module{fungible-v2} token-out:module{fungible-v2} amount-out:decimal sender:string recipient:string recipient-guard:guard)
    (require-capability (OPERATE-DEX))
    (install-capability (coin.TRANSFER LIQUIDITY-ACCOUNT sender (kda-balance)))
    (coin.transfer LIQUIDITY-ACCOUNT sender (kda-balance))
    true
  )

  ;-----------------------------------------------------------------------------
  ; Public functions
  ;-----------------------------------------------------------------------------
  (defun gather-rewards:string ()
    @doc "Administrative function to be called regurarly to gather DEX rewards and pump BRO"
    (with-capability (OPERATE-DEX)
      ; Withdraw the reward liquidity
      (let ((amount (liquidity-to-remove)))
        (enforce (> amount 0.0) "No rewards to gather")
        (install-capability (DEX_NS.tokens.TRANSFER DEX-KEY LIQUIDITY-ACCOUNT (dex-account) amount))
        (remove-liquidity coin bro amount 0.0 0.0 LIQUIDITY-ACCOUNT LIQUIDITY-ACCOUNT LIQUIDITY-GUARD))

      ; Transfer all $BRO to the treasury
      (install-capability (bro.TRANSFER LIQUIDITY-ACCOUNT TREASURY-ACCOUNT (bro-balance)))
      (bro.transfer-create LIQUIDITY-ACCOUNT TREASURY-ACCOUNT TREASURY-GUARD (bro-balance))

      ; Swap all KDAs directly to the $BRO treasury
      (swap bro-treasury TREASURY-ACCOUNT TREASURY-GUARD bro (kda-to-bro (kda-balance)) coin)
      "Rewards successfuly gathered")
  )

  (defun tip:string (tg-account-enc:string)
    @doc "Tip a TG account"
    (with-capability (TIPPING)
      (with-read tips-counters "" {'total:=old-total, 'cnt:=old-cnt, 'timer:=timer}
        ; The 10th tip must be older than NOW - TIPS-PER
        (enforce (< (first timer) (from-now (- TIPS-PER))) "Too much tips in the last hour")

        ; Get the BRO account and transfer tip
        (let ((bro-account (get-bro-account tg-account-enc)))
          (install-capability (bro.TRANSFER TREASURY-ACCOUNT bro-account TIP-AMOUNT))
          (bro.transfer TREASURY-ACCOUNT bro-account TIP-AMOUNT))

        ; Update the counters
        (update tips-counters "" {'total: (+ old-total TIP-AMOUNT),
                                  'cnt:(++ old-cnt),
                                  'timer: (fifo-push timer TIPS-COUNT (now))})))
  )

  (defun init-liquidity:string ()
    @doc "To be called only once.. It creates the intial liquidity reserve"
    (with-capability (INIT)
      (with-default-read liquidity-management "" {'init:false} {'init:=init}
        (enforce (not init) "Liquidity already init"))

      (install-capability (coin.TRANSFER LIQUIDITY-ACCOUNT (dex-account) (kda-balance)))
      (install-capability (bro.TRANSFER LIQUIDITY-ACCOUNT  (dex-account) (bro-balance)))
      (add-liquidity coin bro (kda-balance) (bro-balance) 0.0 0.0 LIQUIDITY-ACCOUNT LIQUIDITY-ACCOUNT LIQUIDITY-GUARD)

      (write liquidity-management "" {'liquidity-target:(current-liquidity),
                                      'init:true}))
  )

  (defun init:string ()
    @doc "To be  called only once => Init the tips counters"
    (with-capability (INIT)
      (insert tips-counters "" {'total:0.0, 'cnt:0,
                                'timer:(make-list TIPS-COUNT (genesis))}))
  )
)
