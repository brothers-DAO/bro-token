(module bro-registry GOVERNANCE
  (use free.util-strings)

  ;-----------------------------------------------------------------------------
  ; Administrative and ops capabilities
  ;-----------------------------------------------------------------------------
  (defcap GOVERNANCE ()
    (enforce-keyset "BRO_NS.governance"))

  (defcap BOT-OPERATOR ()
    (enforce-keyset "BRO_NS.bot"))

  ;-----------------------------------------------------------------------------
  ; Main table
  ;-----------------------------------------------------------------------------
  (defschema account-sch
    bro-account:string
    enabled:bool)

  (deftable accounts:{account-sch})

  ;-----------------------------------------------------------------------------
  ; No duplicate table
  ;-----------------------------------------------------------------------------
  ; This table prevents people from using the same Kadena account for several TG accounts
  (defschema account-locked-sch
    locked:bool)

  (deftable account-locked-table:{account-locked-sch})

  ;-----------------------------------------------------------------------------
  ; Utility and pure functions
  ;-----------------------------------------------------------------------------
  (defun encrypt-tg-account:string (tg-account:string password:string)
    @doc "Reference function to create encrypted tg accounts"
    (+ "enc_" (hash (+ tg-account password)))
  )

  (defun enforce-encrypted:bool (tg-account:string)
    @doc "Verify that the TG account name follow the encryption format"
    (enforce (and? (starts-with* "enc_") (compose (length) (= 47)) tg-account)
             "Account not encrypted")
  )

  (defun enforce-looks-base64:bool (account-b64:string)
    @doc "Verify that the Kadena account is Base 64"
    (enforce (not? (contains-chars ":+=$") account-b64) "The account is not in Base64")
  )

  (defun enforce-is-account-registered:bool (tg-account:string)
    @doc "Check if the TG account is registered"
    (with-default-read accounts tg-account {'enabled:false} {'enabled:=enabled}
      (enforce enabled "Account already registered"))
  )

  (defun enforce-account-not-locked:bool (account:string)
    @doc "Check if the Kadena account is registered"
    (with-default-read account-locked-table account {'locked:false} {'locked:=locked}
      (enforce (not locked) "Kadena account already registered"))
  )

  ;-----------------------------------------------------------------------------
  ; Private functions
  ;-----------------------------------------------------------------------------
  (defun free-kadena-account:string (tg-account:string)
    @doc "Unregister a Kadena account => ie Make it reusable"
    (require-capability (BOT-OPERATOR))
    (with-default-read accounts tg-account {'bro-account:""} {'bro-account:=bro-account}
      (if (!= "" bro-account)
          (update account-locked-table bro-account {'locked:false})
          ""))
  )

  ;-----------------------------------------------------------------------------
  ; Public functions
  ;-----------------------------------------------------------------------------
  (defun register:string (tg-account-enc:string bro-account-b64:string)
    @doc "Register an encrypted account corresponding to a Kadena account"
    ; Verify the format of both accounts
    (enforce-encrypted tg-account-enc)
    (enforce-looks-base64 bro-account-b64)

    ; Verify that someone has not already taken the Kadena account
    (enforce-account-not-locked bro-account-b64)

    (with-capability (BOT-OPERATOR)
      ; Free the previous Kadena account
      (free-kadena-account tg-account-enc)
      ; Register the TG account
      (write accounts tg-account-enc {'bro-account:bro-account-b64,
                                     'enabled:true})
      ; And lock the Kadena account
      (write account-locked-table bro-account-b64 {'locked:true}))

  )

  (defun unregister:string (tg-account-enc:string)
    @doc "Un-Register an encrypted account"
    ; Don't unregister an non-registered account
    (enforce-is-account-registered tg-account-enc)

    (with-capability (BOT-OPERATOR)
      ; Free the Kadena account
      (free-kadena-account tg-account-enc)
      ; Disable (= unregister) the TG account
      (update accounts tg-account-enc {'enabled:false}))
  )

  (defun get-bro-account:string (tg-account-enc:string)
    @doc "Retrieve the bro account from an encrypted TG account name"
    (with-default-read accounts tg-account-enc {'bro-account:"", 'enabled:false}
                                               {'bro-account:=bro-account, 'enabled:=enabled}
      (enforce enabled "The Account was not registered")
      (base64-decode bro-account))
  )

  ;-----------------------------------------------------------------------------
  ; Local callable functions
  ;-----------------------------------------------------------------------------
  (defun list-accounts:list ()
    @doc "Returns the list of accounts registered in the system"
    (fold-db accounts (lambda (k obj) (where 'enabled (= true) obj))
                      (lambda (k obj) {'tg-account-enc:k, 'bro-account:(at 'bro-account obj)}))
  )
)
