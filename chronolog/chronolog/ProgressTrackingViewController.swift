//
//  ProgressTrackingViewController.swift
//  chronolog
//
//  Created by Janie Giron on 2/26/25.
//

import UIKit

// MARK: - Cat Model

struct Cat {
    let id: String
    let name: String  // Instead of title
    let description: String
    var isAdopted: Bool  // Instead of isCompleted
}

class ProgressTrackingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Properties
    
    private var tableView: UITableView!
    private var cats: [Cat] = []
    
    // MARK: - Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        loadCats()
    }
    
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // Set title for navigation bar
        title = "Progress Tracking"

        
        // Create table view
        tableView = UITableView(frame: view.bounds, style: .insetGrouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CatCell")
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(tableView)
        
        // Add "Add" button to navigation bar
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addCatTapped)
        )
        navigationItem.rightBarButtonItem = addButton
    }
    
    @objc private func goBack() {
        // This will navigate back to the previous view controller
        navigationController?.popViewController(animated: true)
    }
    
    private func loadCats() {
        // Sample cats
        cats = [
            Cat(id: "1", name: "Meeting", description: "attend meeting", isAdopted: false),
            Cat(id: "2", name: "Gym", description: "cardio", isAdopted: false),
            Cat(id: "3", name: "Homework", description: "homework for cybersecurity", isAdopted: true)
        ]
        tableView.reloadData()
    }
    
    // MARK: - Actions
    
    @objc private func addCatTapped() {
        // Present an alert controller to add a new cat
        let alertController = UIAlertController(
            title: "New Cat",
            message: "Enter cat details",
            preferredStyle: .alert
        )
        
        alertController.addTextField { textField in
            textField.placeholder = "Cat name"
        }
        
        alertController.addTextField { textField in
            textField.placeholder = "Cat description"
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self,
                  let nameField = alertController.textFields?[0],
                  let descriptionField = alertController.textFields?[1],
                  let name = nameField.text, !name.isEmpty else {
                return
            }
            
            // Create a new cat
            let newCat = Cat(
                id: UUID().uuidString,
                name: name,
                description: descriptionField.text ?? "",
                isAdopted: false
            )
            
            // Add to our array and update table
            self.cats.append(newCat)
            self.tableView.reloadData()
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)
        
        present(alertController, animated: true)
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CatCell", for: indexPath)
        
        let cat = cats[indexPath.row]
        
        // Configure cell
        var content = cell.defaultContentConfiguration()
        content.text = cat.name
        content.secondaryText = cat.description
        
        // Add checkmark for adopted cats
        if cat.isAdopted {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .disclosureIndicator
        }
        
        cell.contentConfiguration = content
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Tasks"
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Get the selected cat
        let selectedCat = cats[indexPath.row]
        
        // Navigate to cat detail screen
        showCatDetails(selectedCat)
    }
    
    // MARK: - Navigation
    
    private func showCatDetails(_ cat: Cat) {
        // Create a cat detail view controller
        let detailVC = CatDetailViewController(cat: cat)
        
        // When a cat is updated, refresh our list
        detailVC.catUpdated = { [weak self] updatedCat in
            guard let self = self else { return }
            
            // Find and update the cat in our array
            if let index = self.cats.firstIndex(where: { $0.id == updatedCat.id }) {
                self.cats[index] = updatedCat
                self.tableView.reloadData()
            }
        }
        
        // Push to navigation stack
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - Cat Detail View Controller

class CatDetailViewController: UIViewController {
    
    // MARK: - Properties
    
    private let cat: Cat
    var catUpdated: ((Cat) -> Void)?
    
    private let nameLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let statusSwitch = UISwitch()
    
    // MARK: - Initialization
    
    init(cat: Cat) {
        self.cat = cat
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        title = "Task Details"
        view.backgroundColor = .systemBackground
        
        // Create stack view for content
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        // Name label
        nameLabel.text = cat.name
        nameLabel.font = UIFont.boldSystemFont(ofSize: 20)
        nameLabel.numberOfLines = 0
        stackView.addArrangedSubview(nameLabel)
        
        // Description label
        descriptionLabel.text = cat.description
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textColor = .secondaryLabel
        stackView.addArrangedSubview(descriptionLabel)
        
        // Status view
        let statusView = UIStackView()
        statusView.axis = .horizontal
        statusView.spacing = 8
        stackView.addArrangedSubview(statusView)
        
        let statusLabel = UILabel()
        statusLabel.text = "Adopted:"
        statusView.addArrangedSubview(statusLabel)
        
        statusSwitch.isOn = cat.isAdopted
        statusSwitch.addTarget(self, action: #selector(statusChanged), for: .valueChanged)
        statusView.addArrangedSubview(statusSwitch)
        
        // Add constraints
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func statusChanged() {
        // Create updated cat
        var updatedCat = cat
        updatedCat.isAdopted = statusSwitch.isOn
        
        // Call the callback to update the cat in the parent view controller
        catUpdated?(updatedCat)
    }
}
