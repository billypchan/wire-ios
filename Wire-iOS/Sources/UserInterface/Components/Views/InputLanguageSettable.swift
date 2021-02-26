//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import Foundation
import UIKit

protocol InputLanguageSettable {
    var language: String? {get set}
    var originalTextInputMode: UITextInputMode? {get}
}

extension TextView: InputLanguageSettable {

    var originalTextInputMode: UITextInputMode? {
        get {
            return super.textInputMode
        }
    }

    var overriddenTextInputMode: UITextInputMode? {
        get {
            guard let language = language, language.count > 0 else {
                return super.textInputMode
            }

            for textInputMode: UITextInputMode in UITextInputMode.activeInputModes {
                if textInputMode.primaryLanguage == language {
                    return textInputMode
                }
            }

            return super.textInputMode
        }
    }
}
