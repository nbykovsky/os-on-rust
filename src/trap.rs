// #![allow(unused_assignments, dead_code)]
// #![no_std] // don't link the Rust standard library
// #![no_main] // disable all Rust-level entry points
// #![feature(lang_items, llvm_asm)]

// use core::panic::PanicInfo;

const IDT_START_ADDRESS: u64 = 0x11000;
const IDT_REGISTER_ADDRESS: u64 = 0x11800;


extern "C" {
    fn vector0();
    fn vector1();
    fn vector2();
    fn vector3();
    fn vector4();
    fn vector5();
    fn vector6();
    fn vector7();
    fn vector8();
    fn vector10();
    fn vector11();
    fn vector12();
    fn vector13();
    fn vector14();
    fn vector16();
    fn vector17();
    fn vector18();
    fn vector19();
    fn vector32();
    fn vector39();
    fn init_idt();
    fn halt();
    fn eoi();
    fn load_idt(ptr: &IdtPrt);
    fn read_isr() -> u8;
}

#[repr(packed)]
struct IdtEntry {
    low: u16,
    selector: u16,
    res0: u8,
    attr: u8,
    mid: u16,
    high: u32,
    res1: u32
}


#[repr(packed)]
struct IdtPrt {
    limit: u16,
    addr: u64
}

fn init_idt_entry(index: usize, handler_address: u64) {
    const IDT_DESCRIPTOR_SIZE: u64 = 16;

    let descriptor_address = IDT_START_ADDRESS + (
        IDT_DESCRIPTOR_SIZE * (index as u64)
    );

    unsafe {
        *((descriptor_address) as *mut IdtEntry) = IdtEntry {
            low: handler_address as u16,
            selector: 8,
            res0: 0,
            attr: 0x8e,
            mid: (handler_address >> 16) as u16,
            high: (handler_address >> 32) as u32,
            res1: 0
        }
    }


}

#[cfg(any(target_arch = "x86", target_arch = "x86_64"))]
pub fn create_idt_table() {

    const IDT_DESCRIPTORS_AMOUNT: usize = 256;

    for index in 0..IDT_DESCRIPTORS_AMOUNT {
        init_idt_entry(index, (vector32 as *const ()) as u64);
    }
    init_idt_entry(0, (vector0 as *const ()) as u64);
    init_idt_entry(1, (vector1 as *const ()) as u64);
    init_idt_entry(2, (vector2 as *const ()) as u64);
    init_idt_entry(3, (vector3 as *const ()) as u64);
    init_idt_entry(4, (vector4 as *const ()) as u64);
    init_idt_entry(5, (vector5 as *const ()) as u64);
    init_idt_entry(6, (vector6 as *const ()) as u64);
    init_idt_entry(7, (vector7 as *const ()) as u64);
    init_idt_entry(8, (vector8 as *const ()) as u64);
    init_idt_entry(10, (vector10 as *const ()) as u64);
    init_idt_entry(11, (vector11 as *const ()) as u64);
    init_idt_entry(12, (vector12 as *const ()) as u64);
    init_idt_entry(13, (vector13 as *const ()) as u64);
    init_idt_entry(14, (vector14 as *const ()) as u64);
    init_idt_entry(16, (vector16 as *const ()) as u64);
    init_idt_entry(17, (vector17 as *const ()) as u64);
    init_idt_entry(18, (vector18 as *const ()) as u64);
    init_idt_entry(19, (vector19 as *const ()) as u64);
    init_idt_entry(32, (vector32 as *const ()) as u64);
    init_idt_entry(39, (vector39 as *const ()) as u64);

    unsafe {
        *(IDT_REGISTER_ADDRESS as *mut IdtPrt) = IdtPrt {
            limit: (8* IDT_DESCRIPTORS_AMOUNT) as u16,
            addr: IDT_START_ADDRESS
        }
    }
    unsafe {
        load_idt(&*(IDT_REGISTER_ADDRESS as *mut IdtPrt));
    }
    // unsafe {llvm_asm!("lidt ($0)" :: "r" (IDT_REGISTER_ADDRESS));}

}


#[repr(C, packed)]
pub struct TrapFrame {
    r15: i64,
    r14: i64,
    r13: i64,
    r12: i64,
    r11: i64,
    r10: i64,
    r9: i64,
    r8: i64,
    rbp: i64,
    rdi: i64,
    rsi: i64,
    rdx: i64,
    rcx: i64,
    rbx: i64,
    rax: i64,
    trapno: i64,
    errorcode: i64,
    rip: i64,
    cs: i64,
    rflags: i64,
    rsp: i64,
    ss: i64
}


#[no_mangle]
pub extern "C" fn handler(tf: &TrapFrame) {
    
    match tf.trapno {
        32 => unsafe {eoi()},
        39 => {
            
            let isr_value = unsafe {read_isr()};

            if isr_value&(1<<7)!=0 {
                unsafe {eoi()};
            }
        }
        _ => loop {}
    }
    
}