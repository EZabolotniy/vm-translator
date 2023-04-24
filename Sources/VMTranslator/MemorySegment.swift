//
//  MemorySegment.swift
//  
//
//  Created by Evgeniy Zabolotniy on 09.04.2023.
//

enum MemorySegment: String {
  case argument
  case local
  case `static`
  case constant
  case this
  case that
  case pointer
  case temp

  var RAMAddress: Int {
    switch self {
    case .local: return 1
    case .argument: return 2
    case .pointer: return 3
    case .this: return 3
    case .that: return 4
    case .temp: return 5
    case .static: return 16
    case .constant:
      fatalError("Constant is a virtual memory segment and has no RAM address")
    }
  }
}
