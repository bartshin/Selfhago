//
//  LocaleManager.swift
//  Selfhago
//
//  Created by bart Shin on 2021/08/06.
//

import Foundation

class LocaleManager {
	static let shared  = LocaleManager()
	private var languageCode: LanguageCode = .en
	static var currentLanguageCode: LanguageCode {
		shared.languageCode
	}
	enum LanguageCode: Int {
		case en
		case ko
		
		init?(identifier: String) {
			if identifier.lowercased() == "ko" {
				self = .ko
			}
			else if identifier.lowercased() == "en" {
				self = .en
			}
			else {
				return nil
			}
		}
	}
}
