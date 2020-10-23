#!/usr/bin/env bash
# @author nightsparc
# @date 2019-06-14
# @brief Create a full backup of the desired gpg2 key
# @details
# The script creats a full backuf of the specified key.
# A full backup includes:
# 1) revocation certificate
# 2) public master key
# 3) private master key
# 4) private subkeys (if any)
# @see
# - https://blogs.itemis.com/de/openpgp-im-berufsalltag-teil-4-schl%C3%BCssel-generieren

KEY2EXPORT=$1

# Generate backup copy of revocation certificate
gpg2 --output Widerrufszertifikat_GnuPG-Key_0x$KEY2EXPORT.rev --gen-revoke $KEY2EXPORT
# Export public master key
gpg2 --export --armor $KEY2EXPORT > GnuPG-Key_0x$KEY2EXPORT.pub.asc
# Export private master key
gpg2 --export-secret-keys --armor $KEY2EXPORT > GnuPG-Key_0x$KEY2EXPORT.MASTER.priv.asc
# Export private subkeys. There are no public subkeys.
gpg2 --export-secret-subkeys --armor $KEY2EXPORT > GnuPG-Key_0x$KEY2EXPORT.SUB.priv.asc
