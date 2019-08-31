Volatile Password Generator
===========================

This is another project using [ZeitControl](https://zeitcontrol.de) produced
smartcards to protect personal privacy.

## Background

There has been a number of technologies to protect privacy. Most of them
reduces to a password: whether full disk encryption, or password managers,
most of these requires a strong master passphrase.

If we say it's easy to remember a strong passphrase, or if we cannot, then plus
a keyfile -- most solutions are ignoring the physical threat of doing so.
Malicious physical attackers, e.g. intelligence agents, repressive police
forces, usually claim they have plenty of methods to get that secret out of
one's mouth: tortures, or threats on beloved relationships, etc. No surprise,
just don't underestimate the human cruelty. And no news, this has happened and
is happening again.

### How to defend?

The answer given here is simple. They assume that password resides in your
brain, but that doesn't have to be true. If we use a strongest password
that most people will find impossible to remember, and thus must rely on
a device, then those "methods" are just useless.

But if that device is easily cracked?

That's what this project tries to address: a password generator, that is strong
enough for daily use, but easily self-destroyed on user's command.
Specifically, one false password attempt will lead to permanent data loss.

## How is this card designed?

Simply said, the card acts as a password generator. It generates upon request
a password based on 2 factors:

1. a random secret kept on card
2. a nonce, or a label, that's given by the user(or user's program)

The second factor is always known and we'll ignore its discussion. The
interesting part is this on-chip random secret. It will never stored as
plaintext in EEPROM(smartcard's non-volatile storage). It's encrypted somehow
with user's unlocking password.

The trick is here: each time the user trys to unlock the card, by providing its
password, the card will decrypt the secret and re-encrypt it with another
key. The secret is not simply encrypted with user's password: instead, the
encryption is done with a random key generated from user's password and some
random salt. Thus the decryption and re-encryption is done with 2 different
keys, although knowing the user unlocking password both keys can be generated
(as we keep a record of the youngest random salt on chip).

During the time, the user may unlock and use the card over months, or years.
Each usage is a loop on a chain that can never be reversed.

If the same password is given continously between unlocks, same results will be
produced. However, if a wrong password is given, the decryption must fail into
a random result, which, after being re-encrypted, can never be used to recover
the previous on-chip secret, even if same password is entered again.

Therefore under external pressure the user may just give out a random or
plausible password. The attacker does not have the chance to prove or
disapprove it: the only chance to verify this is by using it, and most likely
he/she will miss the target permanently.
