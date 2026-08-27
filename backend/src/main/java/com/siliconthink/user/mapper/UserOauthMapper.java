package com.siliconthink.user.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.siliconthink.user.entity.UserOauthDO;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface UserOauthMapper extends BaseMapper<UserOauthDO> {
}
