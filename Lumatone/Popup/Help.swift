//
//  Help.swift
//  Lumatone
//
//  Created by SH BU on 2024/9/2.
//

import UIKit

class HelpNavigationController: UINavigationController {
    var help = HelpViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    
    required init?(coder aDecoder: NSCoder) { fatalError() }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = .systemBackground
        viewControllers.append(help)
    }
    
//    override func viewDidLoad() {
//        help.view.topAnchor.constraint(equalTo: navigationBar.bottomAnchor).isActive = true
//        help.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
//        help.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
//        help.view.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
//    }
    
    override func viewWillDisappear(_ animated: Bool) {
        UserDefaults.standard.set(true, forKey: "firstRunHelpShown_Bool")
    }
}


class HelpViewController: UIPageViewController, UIPageViewControllerDataSource {
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return Self.helpData.count
    }
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
    
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let index = (viewController as! PageController).pageIndex
        if index == 0 { return nil }
        return PageController(index - 1, Self.helpData[index - 1])
    }
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let index = (viewController as! PageController).pageIndex
        if index == Self.helpData.count - 1 { return nil }
        return PageController(index + 1, Self.helpData[index + 1])
    }
    
    
    required init?(coder: NSCoder) { fatalError() }
    
    init(transitionStyle: UIPageViewController.TransitionStyle, navigationOrientation: UIPageViewController.NavigationOrientation) {
        super.init(transitionStyle: transitionStyle, navigationOrientation: navigationOrientation)
        navigationItem.title = "Help"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(done))
        dataSource = self
        setViewControllers([PageController(0, Self.helpData[0])], direction: .forward, animated: false)
        view.translatesAutoresizingMaskIntoConstraints = false
    }
    @objc func done() {
        dismiss(animated: true, completion: nil)
    }
    
    static private var helpData: [NSAttributedString] = {
        let rawMD = (try? String(contentsOf: Bundle.main.url(forResource: "help", withExtension: "md")!)) ?? ""
        let pagesMD = rawMD.split(separator: "\n\n\n")
        return pagesMD.map { String($0).parseMarkdown() }
    }()
    
}

class PageController: UIViewController {
    let pageIndex: Int
    let labelView = UILabel()
    let scrollView = UIScrollView()
    
    required init?(coder: NSCoder) { fatalError() }
    
    init(_ index: Int, _ astr: NSAttributedString) {
        pageIndex = index
        
        super.init(nibName: nil, bundle: nil)
        scrollView.addSubview(labelView)
        view.addSubview(scrollView)
        
        labelView.attributedText = astr
        labelView.lineBreakMode = .byWordWrapping
        labelView.numberOfLines = 0
        
        // positioning scrollView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 56).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        scrollView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        scrollView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -32).isActive = true
        
        // positioning labelView
        labelView.translatesAutoresizingMaskIntoConstraints = false
        labelView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
    }
    
    override func viewDidLayoutSubviews() {
        scrollView.contentSize = labelView.intrinsicContentSize
    }
}


extension String {
    func parseMarkdown() -> NSAttributedString {
        let headerStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        headerStyle.firstLineHeadIndent = 0
        headerStyle.headIndent = 0
        headerStyle.paragraphSpacing = 8
        let bodyStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        bodyStyle.lineSpacing = 3
        bodyStyle.firstLineHeadIndent = 10
        bodyStyle.headIndent = 10
        bodyStyle.paragraphSpacing = 20
        
        let output = NSMutableAttributedString()
        let lines = self.split(separator: "\n")
        for line in lines {
            if let match = line.firstMatch(of: /^\ *(#+)\ *(.*)$/) {
                // line is a header
                var style = UIFont.TextStyle.body
                switch match.1.count {
                    case 1: style = .title1
                    case 2: style = .title2
//                    case 3: style = .title3
                    default: break
                }
                let parsed = (try? NSMutableAttributedString(markdown: String(match.2)))
                ?? NSMutableAttributedString(string: "Title parse failed")
                parsed.append(NSAttributedString(string: "\n"))
                parsed.addAttributes([.font: UIFont.preferredFont(forTextStyle: style),
                                      .paragraphStyle: headerStyle], range: NSRange(0..<parsed.string.count))
                output.append(parsed)
                continue
            }
            // default case
            let parsed = (try? NSMutableAttributedString(markdown: String(line)))
            ?? NSMutableAttributedString(string: "Paragraph parse failed")
            parsed.append(NSAttributedString("\n"))
            parsed.addAttributes([.paragraphStyle: bodyStyle], range: NSRange(0..<parsed.string.count))
            output.append(parsed)
        }
        return output
    }
}
