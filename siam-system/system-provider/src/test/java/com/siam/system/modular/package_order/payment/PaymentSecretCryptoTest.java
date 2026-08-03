package com.siam.system.modular.package_order.payment;

import com.siam.package_common.exception.StoneCustomerException;
import com.siam.system.modular.package_order.service_impl.payment.PaymentSecretCrypto;
import org.junit.Test;

import java.security.SecureRandom;
import java.util.Base64;

import static org.junit.Assert.assertEquals;

public class PaymentSecretCryptoTest {

    @Test
    public void encryptsAndBindsCiphertextToShop() {
        byte[] key = new byte[32];
        new SecureRandom().nextBytes(key);
        PaymentSecretCrypto crypto = new PaymentSecretCrypto(Base64.getEncoder().encodeToString(key));

        String encrypted = crypto.encrypt(1, "apiV3Key", "12345678901234567890123456789012");
        assertEquals("12345678901234567890123456789012",
                crypto.decrypt(1, "apiV3Key", encrypted));

        try {
            crypto.decrypt(2, "apiV3Key", encrypted);
            throw new AssertionError("Ciphertext must not decrypt for another shop");
        } catch (StoneCustomerException expected) {
            // Expected: AAD prevents moving one merchant's secret to another merchant.
        }
    }
}
