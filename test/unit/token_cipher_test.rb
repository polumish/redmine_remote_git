require File.expand_path('../../test_helper', __FILE__)

class TokenCipherTest < ActiveSupport::TestCase
  C = RedmineRemoteGit::TokenCipher

  def test_round_trip
    enc = C.encrypt('glpat-secret-123')
    assert enc.start_with?('rgt1:'), 'has version marker'
    refute_includes enc, 'glpat-secret-123', 'ciphertext not plaintext'
    assert_equal 'glpat-secret-123', C.decrypt(enc)
  end

  def test_nil_and_blank
    assert_nil C.encrypt(nil)
    assert_nil C.encrypt('')
    assert_nil C.decrypt(nil)
  end

  def test_unique_iv_per_call
    refute_equal C.encrypt('same'), C.encrypt('same'), 'random IV per encryption'
  end
end
