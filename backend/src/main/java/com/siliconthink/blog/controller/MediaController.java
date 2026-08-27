package com.siliconthink.blog.controller;

import com.siliconthink.auth.security.AuthUser;
import com.siliconthink.blog.dto.MediaUploadVO;
import com.siliconthink.blog.service.MediaUploadService;
import com.siliconthink.common.ErrorCode;
import com.siliconthink.common.Result;
import com.siliconthink.exception.BizException;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1/me/media")
@RequiredArgsConstructor
public class MediaController {

    private final MediaUploadService mediaUploadService;

    @PostMapping("/images")
    public Result<MediaUploadVO> uploadImage(
            @AuthenticationPrincipal AuthUser authUser,
            @RequestPart("file") MultipartFile file) {
        if (authUser == null) {
            throw new BizException(ErrorCode.UNAUTHORIZED);
        }
        return Result.ok(mediaUploadService.uploadImage(file));
    }
}
