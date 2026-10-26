package com.lilystudio.wheretosleepinnju.liveactivity;
interface IIslandFirewall {
    boolean setBlocked(int uid, boolean blocked) = 0;
    String diagnostics() = 1;
    void destroy() = 16777114;
}
