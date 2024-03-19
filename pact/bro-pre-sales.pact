(module bro-pre-sales GOVERNANCE
  (use free.util-time)
  (use free.util-math)

  ; Temporary
  (defconst TREASURY-ACCOUNT "treasury")
  (defconst LIQUIDITY-ACCOUNT "liquidity")

  (defconst TREASURY-GUARD (read-keyset 'treasury-g))
  (defconst LIQUIDITY-GUARD (read-keyset 'liquidity-g))

  ;-----------------------------------------------------------------------------
  ; Administrative and ops capabilities
  ;-----------------------------------------------------------------------------
  (defcap GOVERNANCE ()
    (enforce-keyset "BRO_NS.governance"))

  (defcap SALES-OPERATOR ()
    (enforce-keyset "BRO_NS.sales-operator"))



  (defconst TOTAL-BATCHES:integer 100)

  (defconst AMOUNT-PER-BATCH:decimal 0.4)

  (defconst PRICE-PER-BATCH:decimal 10.0)

  ; Dates must be adjusted before launch
  (defconst PHASE-0-START (time "2024-04-01T00:00:00Z"))

  (defconst PHASE-1-START (time "2024-04-08T00:00:00Z"))

  (defconst PHASE-2-START (time "2024-04-15T00:00:00Z"))

  (defconst END-OF-PRESALES (time "2024-04-22T00:00:00Z"))

  (defun in-phase-1:bool ()
    (and (is-past PHASE-0-START) (is-future PHASE-1-START)))

  (defun in-phase-2:bool ()
    (and (is-past PHASE-1-START) (is-future PHASE-2-START)))

  (defun in-phase-3:bool ()
    (and (is-past PHASE-2-START) (is-future END-OF-PRESALES)))

  (defun ended:bool ()
    (is-past END-OF-PRESALES))

  (defschema presale-global-sch
    sold:integer
    reserved:integer
  )

  (deftable global-table:{presale-global-sch})

  (defschema presale-account-sch
    account:string
    reserved:integer
    bought:integer
  )

  (deftable accounts-table:{presale-account-sch})

  (defcap SALES-INCOME () true)

  (defconst SALES-INCOME-GUARD (create-capability-guard (SALES-INCOME)))

  (defconst SALES-INCOME-ACCOUNT (create-principal SALES-INCOME-GUARD))

  (defcap BRO-RESERVE () true)

  (defconst BRO-RESERVE-GUARD (create-capability-guard (BRO-RESERVE)))

  (defconst BRO-RESERVE-ACCOUNT (create-principal BRO-RESERVE-GUARD))

  (defun bro-account-exist:bool (account:string)
    (= account (try "" (at 'account (bro.details account))))
  )

  (defun enforce-available-for-reservation:bool ()
    (with-read global-table "" {'sold:=sold, 'reserved:=reserved}
      (enforce (< (+ sold reserved) 100) "No tokens are available for reservation"))
  )


  (defun -safe:integer (x:integer y:integer)
    (if (>= x y) (- x y) 0))


  (defun available-for-free-sales:integer ()
    (with-read global-table "" {'sold:=sold, 'reserved:=reserved}
      (cond
        ((in-phase-2) (-safe 50 (+ sold reserved)))
        ((in-phase-3) (-safe 100 sold))
        0))
  )

  (defun enforce-at-least-one-for-sale:bool ()
    (let ((afr (available-for-free-sales)))
      (enforce (> afr 0) "No tokens for sale"))
  )

  (defun has-reservation:bool (account:string)
    (and (or (in-phase-1) (in-phase-2))
         (with-default-read accounts-table account {'reserved:0, 'bought:0} {'reserved:=reserved, 'bought:=bought}
            (and (= 0 bought) (= 1 reserved))))
  )

  (defun enforce-has-reservation:bool (account:string)
    (let ((hr (has-reservation account)))
      (enforce hr "Account has no reservation")))

  (defun reserve-batch:string (account:string)
    (enforce (or (in-phase-1) (in-phase-2)) "Reservation can only be done in Phase 1 or 2")
    (enforce-available-for-reservation)

    ; Check that this is the first reservation for this account
    (with-default-read accounts-table account {'reserved:0, 'bought:0} {'reserved:=reserved, 'bought:=bought}
      (enforce (and (= 0 bought) (= 0 reserved)) "Only 1 reservation per account"))

    (with-capability (SALES-OPERATOR)
      ; Increment the reservation count
      (with-read global-table "" {'reserved:=x}
        (update global-table "" {'reserved: (++ x)}))
      ; And yupdate the account
      (write accounts-table account {'account:account,
                                     'reserved:1,
                                     'bought:0}))
  )

  (defun buy:string (account:string guard:guard)
    ; Sales duration must not have been elapsed
    (enforce (not (ended)) "Pre-sales have ended")

    ; Two possibilities: either
    ;  - The account has reservation
    ;  - or there is some batch left
    (enforce-one "Not possible to buy: Sorry" [(enforce-has-reservation account)
                                               (enforce-at-least-one-for-sale)])

    (with-default-read accounts-table account {'bought:0, 'reserved:0} {'bought:=bought, 'reserved:=reserved}
      ; Check that in phase 2, account has never bought before
      (enforce (or (in-phase-3) (= 0 bought)) "Multiple purchase are only possible in phase 3")
      ; Increment the bought and optionnaly cancel reservation
      (write accounts-table account {'account:account,
                                     'bought:(++ bought),
                                     'reserved:0})
      ; Increment the global counters
      (with-read global-table "" {'sold:=sold, 'reserved:=global-reserved}
        (update global-table "" {'sold: (++ sold),
                                 'reserved: (- global-reserved reserved)})))

    ; Create the BRO account if it doesn't exist
    (if (not? (bro-account-exist) account)
        (bro.create-account account guard)
        "")

    ; Transfer KDAs
    (coin.transfer-create account SALES-INCOME-ACCOUNT SALES-INCOME-GUARD PRICE-PER-BATCH)
  )

  (defun to-bro-amount:decimal (x:integer)
    (* (dec x) AMOUNT-PER-BATCH))

  (defun to-kda-amount:decimal (x:integer)
    (* (dec x) PRICE-PER-BATCH))

  (defun end-sales:string ()
    (enforce (ended) "Pre-sales are not ended")
    (with-capability (SALES-OPERATOR)
      ; Transfer the amount of BRO for each account...
      ; Note 1: Accounts have been created during pre-sales (transfer is enough)
      ; Note 2: We use a (select) here. This spends 40k gas at least. But since it's only a one shot, it's ok
      (with-capability (BRO-RESERVE)
        (map (lambda (x:object{presale-account-sch})
                     (bind x {'bought:=batches, 'account:=account}
                        (install-capability (bro.TRANSFER BRO-RESERVE-ACCOUNT account (to-bro-amount batches)))
                        (bro.transfer BRO-RESERVE-ACCOUNT account (to-bro-amount batches))))
             (get-sales)))

      (with-read global-table "" {'sold:=sold}
        ; Transfer remaining to treasury (if not all sold)
        (if (< sold 100)
            (with-capability (BRO-RESERVE)
              (install-capability (bro.TRANSFER BRO-RESERVE-ACCOUNT TREASURY-ACCOUNT (to-bro-amount (- 100 sold))))
              (bro.transfer-create BRO-RESERVE-ACCOUNT TREASURY-ACCOUNT TREASURY-GUARD (to-bro-amount (- 100 sold))))
            "")

      ; Transfer the income (in KDA) to treasury (for DEX liquidity)
      (with-capability (SALES-INCOME)
        (install-capability (coin.TRANSFER SALES-INCOME-ACCOUNT LIQUIDITY-ACCOUNT (to-kda-amount sold)))
        (coin.transfer-create SALES-INCOME-ACCOUNT LIQUIDITY-ACCOUNT LIQUIDITY-GUARD (to-kda-amount sold))))
      "Pre-sales ended")
  )

  (defun get-counters ()
    (read global-table "")
  )

  (defun get-reservations:[object{presale-account-sch}] ()
    (if (or (in-phase-1) (in-phase-2))
        (select accounts-table (where 'reserved (< 0)))
        [])
  )

  (defun get-sales:[object{presale-account-sch}] ()
    (select accounts-table (where 'bought (< 0)))
  )

  (defun init:string ()
    (with-capability (GOVERNANCE)
      (insert global-table "" {'sold:0, 'reserved:0}))
    "Sales counters initialized"
  )
)
