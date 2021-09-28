#![no_std] // don't link the Rust standard library
// #![feature(asm)]
#![allow(unused_assignments, dead_code)]
#![no_main] // disable all Rust-level entry points
            // use op_system_rs::trap;
            // #![feature(asm)]

mod trap;
mod lib;
mod print;

use core::{fmt, panic::PanicInfo};



#[no_mangle] // don't mangle the name of this function
pub extern "C" fn KMain() {
    // this function is the entry point, since the linker looks for a function
    // named `_start` by default

    // trap::create_idt_table();

    //;//.as_str().unwrap_or("1234567").chars();
    // let mut buf = &format_args!("abcde {}",1).to_string().chars();
    // let args = ;
    let mut  buf = print::ScreenBuffer{buffer: 0xb8000 as *mut u8};

    fmt::write(&mut buf,  format_args!("abcde {}","b")).unwrap();

    // let vga_buffer = 0xb8000 as *mut u8;
    // for i in 0..7 {
    //     unsafe {
    //         let x =  buf.next().unwrap_or('Z') as u8;
    //         *vga_buffer.offset(i*2) = x;
    //         *vga_buffer.offset(i*2+1) = 0xa;
    //     }
    // }

    loop {}
}

// This function is called on panic.
#[panic_handler]
#[cfg(not(test))]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}
