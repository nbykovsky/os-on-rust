#![allow(unused_assignments, dead_code)]

extern "C" {
    fn memset(buffer: *mut u8, value: char, size: usize);
    fn memmove(dst: *mut u8, src: *mut u8, size: usize);
    fn memcpy(dst: *mut u8, src: *const u8, size: usize);
    fn memcmp(src1: *const u8, src2: *const u8, size: usize);
}
