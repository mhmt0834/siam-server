package com.siam.package_common.util;

import com.siam.package_common.exception.StoneCustomerException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.util.Arrays;
import java.util.Date;
import java.util.HashSet;
import java.util.Locale;
import java.util.Set;

/**
 * OSS服务器工具类
 **/
@Slf4j
@Component
public class OSSUtils {

    private static final long MAX_IMAGE_SIZE = 10L * 1024 * 1024;
    private static final Set<String> ALLOWED_IMAGE_EXTENSIONS = new HashSet<>(Arrays.asList(
            ".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp"
    ));
    private static final Set<String> ALLOWED_IMAGE_CONTENT_TYPES = new HashSet<>(Arrays.asList(
            "image/jpeg", "image/png", "image/gif", "image/bmp", "image/webp"
    ));

    @Autowired
    private AliyunOss aliyunOSS;

    /**
     * 上传图片--前端文件上传交互
     *
     * @param file 文件对象
     * @param path 模块名称
     * @param id 表唯一标识主键id，如：用户id、商品id；类型应该定义成Object，因为mongodb数据表主键id为字符串类型
     * @return
    **/
    public String uploadImage(MultipartFile file, String path, Object id){
        validateImage(file);
        String objectName = null;
        try (InputStream inputStream = file.getInputStream()) {
            // 文件名处理
            String fileName = file.getOriginalFilename();
            String extension = fileName.substring(fileName.lastIndexOf(".")).toLowerCase(Locale.ROOT);
            fileName = "siam_" + new Date().getTime() + extension;

            // 根据模块名称、用户id作为文件夹命名
            objectName = "data/images/" + path + "/" + id + "/" + fileName;

            aliyunOSS.uploadFile(inputStream, objectName);
        } catch (IOException e) {
            //e.printStackTrace();
            throw new RuntimeException("图片上传失败");
        }
        return objectName;
    }

    private void validateImage(MultipartFile file) {
        if (file == null || file.isEmpty() || file.getSize() > MAX_IMAGE_SIZE) {
            throw new StoneCustomerException("图片不能为空且不能超过10MB");
        }
        String fileName = file.getOriginalFilename();
        int dotIndex = fileName == null ? -1 : fileName.lastIndexOf(".");
        String extension = dotIndex < 0 ? "" : fileName.substring(dotIndex).toLowerCase(Locale.ROOT);
        String contentType = file.getContentType();
        if (!ALLOWED_IMAGE_EXTENSIONS.contains(extension)
                || contentType == null
                || !ALLOWED_IMAGE_CONTENT_TYPES.contains(contentType.toLowerCase(Locale.ROOT))) {
            throw new StoneCustomerException("仅支持 JPG、PNG、GIF、BMP、WEBP 图片");
        }
    }

    /**
     * 上传图片--逻辑处理时上传文件
     *
     * @return
     **/
    public void uploadImage(InputStream inputStream, String savePath){
        try {
            aliyunOSS.uploadFile(inputStream, savePath);
        } catch (IOException e) {
            //e.printStackTrace();
            throw new RuntimeException("图片上传失败");
        }
    }

    /**
     * 判断文件是否存在
     * @param remoteFileName
     * @return
     */
    public Boolean doesObjectExist(String remoteFileName) {
        return aliyunOSS.doesObjectExist(remoteFileName);
    }
}
