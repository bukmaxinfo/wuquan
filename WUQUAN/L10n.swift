//
//  L10n.swift
//  WUQUAN
//
//  Lightweight localization helper.
//  Usage: L10n.string("mode.title")  or  L10n.string("score.streak", 5)
//

import Foundation

enum L10n {
    static func string(_ key: String, _ args: CVarArg...) -> String {
        let format = NSLocalizedString(key, comment: "")
        if args.isEmpty { return format }
        return String(format: format, arguments: args)
    }
}
