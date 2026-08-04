package com.siam.system.modular.package_user;

import com.siam.system.modular.package_user.mapper.MemberMapper;
import com.siam.system.modular.package_user.service_impl.MemberServiceImpl;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnitRunner;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.Assert.assertEquals;
import static org.mockito.Mockito.when;

@RunWith(MockitoJUnitRunner.class)
public class MemberServiceVipNoTest {

    @Mock
    private MemberMapper memberMapper;

    private MemberServiceImpl memberService;

    @Before
    public void setUp() {
        memberService = new MemberServiceImpl();
        ReflectionTestUtils.setField(memberService, "memberMapper", memberMapper);
    }

    @Test
    public void emptyMemberTableStartsFromOne() {
        when(memberMapper.findMaxVipNo()).thenReturn("");

        assertEquals("0000000001", memberService.getNextVipNo());
    }

    @Test
    public void nullMemberTableStartsFromOne() {
        when(memberMapper.findMaxVipNo()).thenReturn(null);

        assertEquals("0000000001", memberService.getNextVipNo());
    }

    @Test
    public void existingVipNumberIsIncremented() {
        when(memberMapper.findMaxVipNo()).thenReturn("0000000041");

        assertEquals("0000000042", memberService.getNextVipNo());
    }
}
