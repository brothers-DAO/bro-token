# BRO Registry: FAQ for brothers

### Why register?
1 - To prove that you own the required $BRO balance; otherwise, you will be kicked from the Brothers channel.

2 - To be able to receive rewards via tipping.

Only members of Brother's Channel can register.

### How do I register my account?
Just send:
`/register k:xxx.xxxx` in the brothers channel.

For better privacy, you can contact the BRO bot in PM.

The bot will answer `Registering @me-tg` and then `Register successful @me-tg`.

### How do I check that my registration is OK?

Contact the bot in PM and send: `/status`.
The bot will confirm your registration and $BRO balance status.


### How to change my Kadena account ?

Simply override your registration and send a `/register` command using your new Kadena account.

### What happens if I have a new Telegram account?
The registry uses the Telegram internal ID. If you only update your TG @username, it will be ok.

But if you switch to a completely new TG account, either:

- Create a new Kadena account
- or contact the admins. They are able to cancel your previous Kadena account reservation.

### Somebody has already "squatted" my Kadena account
Contact the admins. They are able to resolve such a dispute.

### Can I steal/squat somebody else's account?
Theoretically, yes, if you do this before the legit user.

But this is a bad idea, because:

- Somebody else will receive your rewards.
- Once the legit user complains, you will be identified and judged by the Brother's court.

### Privacy concerns
For better reliability, the registry data is stored on-chain, but in an encrypted form.
(module `n_582fed11af00dc626812cd7890bb88e72067f28c.bro-registry`).

Your TG id is not searchable in the Kadena explorer. And external people have no possibility to decrypt the database.

The bot owners have full access to the the link "TG-account -> Kadena-account", through their encryption password.

Brother's members have still the possibility to deduce your Kadena account by drawing a parallel between TG tipping events and on-chain events.

If you want total privacy, uses another Kadena account than your regular one, to store and receive your $BRO rewards.
