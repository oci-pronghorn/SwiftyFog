//
//  MacOS+Extensions.swift
//  Pods-SwiftyFog_Example
//
//  Created by Tobias Schweiger on 9/27/17.
//

import Foundation
import IOKit

/**
	This file can be renamed. This class is responsible for certain Mac-specific tasks.
*/
public class CurrentMac {
	
	/**
	 * Uses platform expert to determine serial number to be used as identifier
	 * @return Returns serial number of current device
	 */
  static func macSerialNumber() -> String {
    
		//Get the platform expert
		let platformExpert: io_service_t = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"));
    
      //Serial number as a CF String
		let serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformSerialNumberKey as CFString, kCFAllocatorDefault, 0);
    
		IOObjectRelease(platformExpert);
		
		return serialNumberAsCFString?.takeUnretainedValue() as! String
    
	}
}
