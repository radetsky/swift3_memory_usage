//
//  main.swift
//  freeMemoryTest
//
//  Created by Alex Radetsky on 2/24/17.
//  Copyright © 2017 User Mac. All rights reserved.
//

import Foundation

public enum Unit : Double {
    // For going from byte to -
    case Byte     = 1
    case Kilobyte = 1024
    case Megabyte = 1048576
    case Gigabyte = 1073741824
}

func host_total_memory () -> (kern_return_t, UInt64) {
    let HOST_BASIC_INFO_COUNT : mach_msg_type_number_t =
        UInt32 ( MemoryLayout<host_basic_info_data_t>.size / MemoryLayout<integer_t>.size )
    var size = HOST_BASIC_INFO_COUNT
    
    let stat = host_info_t.allocate(capacity: 1)
    let result = host_info (mach_host_self(), HOST_BASIC_INFO, stat, &size)
    let infoPtr = unsafeBitCast(stat, to: host_basic_info_t.self)
    let info = infoPtr[0]
    stat.deallocate(capacity: 1)
    return (result, info.max_mem)
}

func vm_page_size() -> (kern_return_t, vm_size_t) {
    var pageSize: vm_size_t = 0
    let result =  host_page_size(mach_host_self(), &pageSize)
    return (result, pageSize)
}

func vm_stat_pages () -> (kern_return_t, vm_statistics) {
    let HOST_VM_INFO_COUNT : mach_msg_type_number_t =
        UInt32 ( MemoryLayout<vm_statistics_data_t>.size / MemoryLayout<integer_t>.size )
    var size = HOST_VM_INFO_COUNT

    let stat = host_info_t.allocate(capacity: Int(size))
    let result = host_statistics(mach_host_self(), HOST_VM_INFO, stat, &size)
    // print (stat) - It's a pointer
    let vmsPtr = unsafeBitCast(stat, to: vm_statistics_t.self)
    let vms = vmsPtr[0]
    stat.deallocate(capacity: Int(size))
    
    return ( result, vms )
}

func myFree() {
    let (result1, pageSize) = vm_page_size()
    guard result1 == KERN_SUCCESS else {
        fatalError("Cannot get VM page size")
    }
    
    let (result2, vm_stat ) = vm_stat_pages()
    guard result2 == KERN_SUCCESS else {
        fatalError("Cannot get VM stat")
    }

    let total = (UInt(vm_stat.free_count + vm_stat.active_count + vm_stat.inactive_count
        + vm_stat.speculative_count + vm_stat.wire_count + vm_stat.purgeable_count ) * pageSize ) >> 20
    let free = (UInt(vm_stat.free_count) * pageSize ) >> 20
    
    //print("Page size: \(pageSize)")
    print(vm_stat)
    print("Total: \(total) Mbytes")
    print("Free : \(free) Mbytes")
    
    let (result3, max_mem ) = host_total_memory()
    guard result3 == KERN_SUCCESS else {
        fatalError("Cannot get host_info()")
    }
    let memory_size = Double (max_mem) / Unit.Megabyte.rawValue
    print("Memory size: \(memory_size) Mbytes")
    
}


myFree();

//let data = UnsafeMutablePointer<Any>.allocate(capacity: 65535)
//data.deallocate(capacity: 65535)


