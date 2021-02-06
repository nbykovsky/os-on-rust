#![no_std] // don't link the Rust standard library
#![no_main] // disable all Rust-level entry points

use core::panic::PanicInfo;


#[no_mangle] // don't mangle the name of this function
pub extern "C" fn KMain() -> ! {
    // this function is the entry point, since the linker looks for a function
    // named `_start` by default

    let vga_buffer = 0xb8000 as *mut u8;
    unsafe {
        *vga_buffer.offset(0) = 'X' as u8;
        *vga_buffer.offset(1) = 0xa;
    }

    loop {}


}

/// This function is called on panic.
#[panic_handler]
#[cfg(not(test))] 
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}