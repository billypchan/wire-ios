//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
import Countly

protocol CountlyInterface {

    func start(with config: CountlyConfig)

    func setNewDeviceID(_ deviceID: String?, onServer: Bool)

    func beginSession()

    func updateSession()

    func endSession()

    func recordEvent(_ key: String, segmentation: [String: String]?)

}

extension Countly: CountlyInterface {}
