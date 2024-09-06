//: A Cocoa based Playground to present user interface

import AppKit
import PlaygroundSupport

let nibFile = NSNib.Name("MyView")
var topLevelObjects : NSArray?

Bundle.main.loadNibNamed(nibFile, owner:nil, topLevelObjects: &topLevelObjects)
let views = (topLevelObjects as! Array<Any>).filter { $0 is NSView }
let view = views[0] as! NSView


extension String {
    func parseMarkDownHeaders() -> NSAttributedString {
        let output = NSMutableAttributedString()
        let lines = self.split(separator: "\n")
        for line in lines {
            if let match = line.firstMatch(of: /^\ *(#+)\ *(.*)$/) {
                // line is a header
                var style = NSFont.TextStyle.body
                switch match.1.count {
                case 1:
                    style = .largeTitle
                case 2:
                    style = .title2
                case 3:
                    style = .title3
                default:
                    break;
                }
                output.append(NSAttributedString(string: String(match.2) + "\n", attributes: [.font: NSFont.preferredFont(forTextStyle: style)]))
                continue
            }
            // default case
            output.append(NSAttributedString(string: String(line) + "\n"))
        }
        return output
    }
}


let raw = "# Keyboard\n## The keyboard\n supports **multitouch** and\nseveral _functionality_ settings."


let label = NSTextField(labelWithAttributedString: raw.parseMarkDownHeaders())
view.frame = CGRectMake(0, 0, 300, 100)
label.frame = view.frame
view.addSubview(label)
PlaygroundPage.current.liveView = view
