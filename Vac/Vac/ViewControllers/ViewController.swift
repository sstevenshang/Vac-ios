//
//  ViewController.swift
//  Vac
//
//  Created by Steven Shang on 7/20/15.
//  Copyright (c) 2015 Steven Shang. All rights reserved.
//

import UIKit
import SwiftyJSON

class ViewController: UIViewController {

    @IBOutlet weak var menuButton: UIButton!

    @IBOutlet weak var searchBar: UITextField!
    
    @IBOutlet weak var resultTableView: UITableView!
    
    // MARK: Word Definition View
    
    @IBOutlet weak var definitionView: UIScrollView!
    
    @IBOutlet weak var wordLabel: UILabel!
    
    @IBOutlet weak var firstPartOfSpeech: UILabel!
    
    @IBOutlet weak var firstDefinition: UILabel!
    
    @IBOutlet weak var secondPartOfSpeech: UILabel!
    
    @IBOutlet weak var secondDefinition: UILabel!
    
    @IBOutlet weak var thirdPartOfSeech: UILabel!
    
    @IBOutlet weak var thirdDefinition: UILabel!
    
    @IBOutlet weak var synonymsLabel: UILabel!
    
    @IBOutlet weak var exampleLabel: UILabel!
    
    @IBOutlet weak var synonymsTitleLabel: UILabel!

    @IBOutlet weak var exampleTitleLabel: UILabel!
    
    @IBOutlet weak var topConstraintOfSecondPartOfSpeech: NSLayoutConstraint!
    
    @IBOutlet weak var topConstraintOfThirdPartOfSpeech: NSLayoutConstraint!
    
    @IBOutlet weak var topConstraintOfExampleTitle: NSLayoutConstraint!

    @IBOutlet weak var saveButton: UIButton!

    // MARK: Life Cycle
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        resultTableView.hidden = true
        definitionView.hidden = true
        
        searchBar.delegate = self
        searchBar.layer.cornerRadius = 15.0
        searchBar.attributedPlaceholder = NSAttributedString (string:"Search!", attributes:[NSForegroundColorAttributeName: UIColor.grayColor()])
        
        let clearButton = UIButton(frame: CGRectMake(0, 0, 15, 15))
        clearButton.setImage(UIImage(named: "ClearButton")!, forState: UIControlState.Normal)
        searchBar.rightView = clearButton
        clearButton.addTarget(self, action: "clear:", forControlEvents: UIControlEvents.TouchUpInside)
        searchBar.rightViewMode = UITextFieldViewMode.WhileEditing
        
        searchBar.addTarget(self, action: "textFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    // MARK: Search Function
    
    func clear(clearButton: UIButton) {
        searchBar.text = ""
        resultTableView.hidden = true
        definitionView.hidden = true
    }
    
    let dictionary = DictionaryHelper()
    var searchResult: [String]?
    
    func textFieldDidChange(searchBar: UITextField) {
        
        if !searchBar.text.isEmpty{
            
            definitionView.hidden = true
            
            let searchWord = searchBar.text
            
            dictionary.callSession(searchWord, type: "words", completionBlock: { (data: NSData) -> Void in
                
                var wordsFound: [String] = []
                
                let json = JSON(data: data)
                let anyWord = json[("searchResults")]
                
                for (index: String, subJson: JSON) in anyWord {
                    
                    wordsFound.append(subJson["word"].stringValue)
                }
                
                self.searchResult = wordsFound
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    self.resultTableView.reloadData()
                    self.resultTableView.hidden = false
                })
            })
            
        } else {
            
            self.resultTableView.hidden = true
        }
    }
    
    // MARK: Get Definition
    
    func getDefinition(word: String, completionHandler: (([String], definitons: [String], synonyms: [String], example: String) -> Void)) {
        
        wordLabel.text = word
        
        var partOfSpeech: [String] = []
        var definitions: [String] = []
        var synonyms: [String] = []
        var example: String = ""
        
        dictionary.callSession(word, type: "definition", completionBlock: {(data: NSData) -> Void in
            
            let json = JSON(data: data)
            
            for (index: String, subJson: JSON) in json {
                
                if subJson["partOfSpeech"].stringValue != ""{
                    
                    partOfSpeech.append(subJson["partOfSpeech"].stringValue)
                    
                    let definition: String = self.modifyDefinition(subJson["text"].stringValue)
                    definitions.append(definition)
                }
            }
            
            self.dictionary.callSession(word, type: "synonyms", completionBlock: {(data: NSData) -> Void in
                
                let json = JSON(data: data)
                let anyWord = json[0]
                let anyWords = anyWord["words"]
                
                for (index: String, subJson: JSON) in anyWords {
                    
                    let synonym: String = self.modifySynonym(subJson.stringValue)
                    synonyms.append(synonym)
                }
                
                self.dictionary.callSession(word, type: "example", completionBlock: {(data: NSData) -> Void in
                    
                    let json = JSON(data: data)
                    let anyJson = json["examples"]
                    let anyAnyJson = anyJson[0]
                    
                    
                    let aExample: String = self.modifyExample(anyAnyJson["text"].stringValue)
                    example = aExample
                    
                    completionHandler(partOfSpeech, definitons: definitions, synonyms: synonyms, example: example)
                    
                })
            })
        })
    }
    
    func modifyExample(example: String) -> String {
        
        var newExample: String = example.stringByReplacingOccurrencesOfString("*", withString: "")
        newExample = newExample.stringByReplacingOccurrencesOfString("_", withString: "")
        newExample = newExample.stringByReplacingOccurrencesOfString("~", withString: "")
        newExample = newExample.stringByReplacingOccurrencesOfString("™", withString: "")
        newExample = newExample.stringByReplacingOccurrencesOfString("-- ", withString: "")
        newExample = newExample.stringByReplacingOccurrencesOfString("　　 ", withString: "")
        newExample = newExample.stringByReplacingOccurrencesOfString("�", withString: "")
        
        return newExample
    }
    
    func modifySynonym(synonym: String) -> String {
        
        var newSynonym: String = synonym.stringByReplacingOccurrencesOfString("<er>", withString: "")
        newSynonym = newSynonym.stringByReplacingOccurrencesOfString("</er", withString: "")
        
        return newSynonym
    }
    
    func modifyDefinition(definition: String) -> String {
        
        var newDefinition: String = definition.stringByReplacingOccurrencesOfString("  ", withString: ": ")
        newDefinition = newDefinition.stringByReplacingOccurrencesOfString(":: ", withString: ": ")
        newDefinition = newDefinition.stringByReplacingOccurrencesOfString(": (", withString: " (")
        newDefinition = newDefinition.stringByReplacingOccurrencesOfString("( ", withString: "(")
        newDefinition = newDefinition.stringByReplacingOccurrencesOfString(".: ", withString: ".")
        
        return newDefinition
    }
    
    // MARK: Show Definition
    
    func handleDefinitionView(partOfSpeech:[String], definitions:[String], synonyms:[String], example: String) -> Void {
        
        println(partOfSpeech)
        println(definitions)
        println(synonyms)
        println(example)
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            self.firstPartOfSpeech.text = partOfSpeech[0]
            self.firstDefinition.text = definitions[0]
            
            let numberOfDefinitions = partOfSpeech.count
            
            println(numberOfDefinitions)
            
            switch numberOfDefinitions {
                
            case 1:
                
                self.hideSecondSection(true)
                self.hideThirdSection(true)
                self.topConstraintOfSecondPartOfSpeech.constant = -107
                // default: 15
                
            case 2:
                
                self.secondPartOfSpeech.text = partOfSpeech[1]
                self.secondDefinition.text = definitions[1]
                
                self.hideSecondSection(false)
                self.hideThirdSection(true)
                self.topConstraintOfThirdPartOfSpeech.constant = -46
                // default: 15
                
            case 3:
                
                self.secondPartOfSpeech.text = partOfSpeech[1]
                self.secondDefinition.text = definitions[1]
                self.thirdPartOfSeech.text = partOfSpeech[2]
                self.thirdDefinition.text = definitions[2]
                
                self.hideSecondSection(false)
                self.hideThirdSection(false)
                
            default:
                
                println("oops")
                
            }
            
            if synonyms.count != 0 {

                var synonymsString: String = ", ".join(synonyms)
                self.synonymsLabel.text = synonymsString
                
                self.hideSynonyms(false)
                
            } else {
                
                self.hideSynonyms(true)
                self.topConstraintOfExampleTitle.constant = -48
                // default: 20

            }
            
            if example != "" {
                
                self.hideExample(false)
                self.exampleLabel.text = example
                
            } else {
                
                self.hideExample(true)
            }
            
            self.definitionView.hidden = false
            
            println("definition view handled")
            
        })
        
    }
    
    func hideSecondSection(show: Bool) -> Void {
        
        self.secondPartOfSpeech.hidden = show
        self.secondDefinition.hidden = show
    }
    
    func hideThirdSection(show: Bool) -> Void {
        
        self.thirdDefinition.hidden = show
        self.thirdPartOfSeech.hidden = show
    }
    
    func hideSynonyms(show: Bool) -> Void {
        
        self.synonymsLabel.hidden = show
        self.synonymsTitleLabel.hidden = show
    }
    
    func hideExample(show: Bool) -> Void {
        
        self.exampleTitleLabel.hidden = show
        self.exampleLabel.hidden = show
    }
    
    // MARK: Handle User Data
    
    func saveWord(partOfSpeech:[String], definitions:[String], synonyms:[String], example: String) {
        
     //   let word = Word()
        
        
        
    }

    
    // MARK: Guillotine Menu
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if (segue.identifier == "showMenu") {
            
            let destinationVC = segue.destinationViewController as! GuillotineMenuViewController
            destinationVC.hostNavigationBarHeight = self.navigationController!.navigationBar.frame.size.height
            destinationVC.view.backgroundColor = self.navigationController!.navigationBar.barTintColor
            destinationVC.setMenuButtonWithImage(menuButton.imageView!.image!)
            
        }
    }
    
    
}

// MARK: TableView

extension ViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if searchResult != nil{
            println(searchResult!.count)
            return searchResult!.count
        }
        else{
            println(0)
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let wordCell = tableView.dequeueReusableCellWithIdentifier("WordCell") as! WordCell
        
        if let result = searchResult?[indexPath.row] {
            
            wordCell.wordLabel.text = result
            println(result)
        }
        
        return wordCell
    }
}

extension ViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        self.topConstraintOfExampleTitle.constant = 20
        self.topConstraintOfThirdPartOfSpeech.constant = 15
        self.topConstraintOfSecondPartOfSpeech.constant = 15
        
        let wordSelected = searchResult![indexPath.row]
        
        searchBar.text = wordSelected
        
        getDefinition(wordSelected, completionHandler: self.handleDefinitionView)
        
        searchBar.resignFirstResponder()
        
        resultTableView.hidden = true
    }
    
}

// MARK: TextField

extension ViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(searchBar: UITextField) -> Bool{
        
        searchBar.resignFirstResponder()
        return true
        
    }
}





