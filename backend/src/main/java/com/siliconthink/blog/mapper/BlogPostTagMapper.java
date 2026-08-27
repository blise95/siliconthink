package com.siliconthink.blog.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.siliconthink.blog.entity.BlogPostTagDO;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface BlogPostTagMapper extends BaseMapper<BlogPostTagDO> {
}
