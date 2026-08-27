package com.siliconthink.auth.service;

import com.siliconthink.auth.dto.LoginRequest;
import com.siliconthink.auth.dto.RegisterRequest;
import com.siliconthink.auth.dto.TokenResponse;
import com.siliconthink.auth.dto.UserInfoVO;
import com.siliconthink.user.entity.UserDO;

public interface AuthService {

    TokenResponse register(RegisterRequest request);

    TokenResponse login(LoginRequest request);

    UserInfoVO me(Long userId);

    TokenResponse issueToken(UserDO user);
}
