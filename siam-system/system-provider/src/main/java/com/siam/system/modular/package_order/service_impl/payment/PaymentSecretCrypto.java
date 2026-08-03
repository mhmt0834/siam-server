package com.siam.system.modular.package_order.service_impl.payment;

import com.siam.package_common.exception.StoneCustomerException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.Cipher;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.util.Base64;

@Component
public class PaymentSecretCrypto {

    private static final String VERSION = "v1:";
    private static final int IV_LENGTH = 12;
    private static final int TAG_LENGTH = 128;

    private final SecureRandom secureRandom = new SecureRandom();
    private final byte[] masterKey;

    public PaymentSecretCrypto(@Value("${PAYMENT_CONFIG_MASTER_KEY:}") String encodedMasterKey) {
        if (encodedMasterKey == null || encodedMasterKey.trim().isEmpty()) {
            this.masterKey = null;
            return;
        }
        try {
            byte[] decoded = Base64.getDecoder().decode(encodedMasterKey.trim());
            if (decoded.length != 32) {
                throw new IllegalArgumentException();
            }
            this.masterKey = decoded;
        } catch (IllegalArgumentException e) {
            throw new IllegalStateException("PAYMENT_CONFIG_MASTER_KEY 必须是 Base64 编码的 32 字节密钥");
        }
    }

    public String encrypt(Integer shopId, String field, String plaintext) {
        requireReady();
        if (plaintext == null) {
            return null;
        }
        try {
            byte[] iv = new byte[IV_LENGTH];
            secureRandom.nextBytes(iv);
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.ENCRYPT_MODE, new SecretKeySpec(masterKey, "AES"),
                    new GCMParameterSpec(TAG_LENGTH, iv));
            cipher.updateAAD(aad(shopId, field));
            byte[] encrypted = cipher.doFinal(plaintext.getBytes(StandardCharsets.UTF_8));
            return VERSION + Base64.getEncoder().encodeToString(
                    ByteBuffer.allocate(iv.length + encrypted.length).put(iv).put(encrypted).array());
        } catch (Exception e) {
            throw new StoneCustomerException("支付配置加密失败");
        }
    }

    public String decrypt(Integer shopId, String field, String ciphertext) {
        requireReady();
        if (ciphertext == null || !ciphertext.startsWith(VERSION)) {
            throw new StoneCustomerException("支付配置密文格式错误");
        }
        try {
            byte[] payload = Base64.getDecoder().decode(ciphertext.substring(VERSION.length()));
            if (payload.length <= IV_LENGTH) {
                throw new IllegalArgumentException();
            }
            byte[] iv = new byte[IV_LENGTH];
            byte[] encrypted = new byte[payload.length - IV_LENGTH];
            System.arraycopy(payload, 0, iv, 0, IV_LENGTH);
            System.arraycopy(payload, IV_LENGTH, encrypted, 0, encrypted.length);
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.DECRYPT_MODE, new SecretKeySpec(masterKey, "AES"),
                    new GCMParameterSpec(TAG_LENGTH, iv));
            cipher.updateAAD(aad(shopId, field));
            return new String(cipher.doFinal(encrypted), StandardCharsets.UTF_8);
        } catch (Exception e) {
            throw new StoneCustomerException("支付配置解密失败，请检查主密钥");
        }
    }

    public void requireReady() {
        if (masterKey == null) {
            throw new StoneCustomerException("服务端未配置 PAYMENT_CONFIG_MASTER_KEY");
        }
    }

    private byte[] aad(Integer shopId, String field) {
        return ("shop-wechat-config:" + shopId + ":" + field).getBytes(StandardCharsets.UTF_8);
    }
}
