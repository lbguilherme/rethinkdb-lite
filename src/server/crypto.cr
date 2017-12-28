require "openssl"
require "openssl/*"

lib LibCrypto
  fun pkcs5_pbkdf2_hmac = PKCS5_PBKDF2_HMAC(
    pass : LibC::Char*, passlen : LibC::Int,
    salt : UInt8*, saltlen : LibC::Int,
    iter : LibC::Int,
    digest : EVP_MD,
    keylen : LibC::Int, out : UInt8*
  ) : LibC::Int
end

def pbkdf2_hmac_sha256(password, salt, iter)
  hash = Bytes.new(32)

  LibCrypto.pkcs5_pbkdf2_hmac(
    password, password.size,
    salt, salt.size,
    iter,
    LibCrypto.evp_sha256,
    hash.size, hash
  )

  hash
end

def hmac_sha256(data, key)
  OpenSSL::HMAC.digest(:sha256, data, key)
end

def sha256(data)
  digest = OpenSSL::Digest.new("SHA256")
  digest.update(data)
  digest.digest
end
