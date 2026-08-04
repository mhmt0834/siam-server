package com.siam.system.security;

import com.siam.package_common.exception.StoneCustomerException;
import com.siam.package_common.util.AliyunOss;
import com.siam.package_common.util.OSSUtils;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnitRunner;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.util.ReflectionTestUtils;

import java.io.InputStream;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.matches;
import static org.mockito.Mockito.verify;

@RunWith(MockitoJUnitRunner.class)
public class OSSUtilsTest {

    @Mock
    private AliyunOss aliyunOss;

    private OSSUtils ossUtils;

    @Before
    public void setUp() {
        ossUtils = new OSSUtils();
        ReflectionTestUtils.setField(ossUtils, "aliyunOSS", aliyunOss);
    }

    @Test
    public void shouldUploadAllowedImageWithGeneratedObjectName() throws Exception {
        MockMultipartFile image = new MockMultipartFile(
                "file", "menu.JPG", "image/jpeg", new byte[]{1, 2, 3});

        ossUtils.uploadImage(image, "merchant", 7);

        verify(aliyunOss).uploadFile(any(InputStream.class),
                matches("data/images/merchant/7/siam_[0-9]+\\.jpg"));
    }

    @Test(expected = StoneCustomerException.class)
    public void shouldRejectExecutableDisguisedAsUpload() {
        MockMultipartFile file = new MockMultipartFile(
                "file", "payload.exe", "application/octet-stream", new byte[]{1});

        ossUtils.uploadImage(file, "merchant", 7);
    }

    @Test(expected = StoneCustomerException.class)
    public void shouldRejectMismatchedImageContentType() {
        MockMultipartFile file = new MockMultipartFile(
                "file", "menu.png", "text/html", new byte[]{1});

        ossUtils.uploadImage(file, "merchant", 7);
    }
}
