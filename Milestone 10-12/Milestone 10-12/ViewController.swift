//
//  ViewController.swift
//  Milestone 10-12
//
//  Created by nikita on 07.02.2023.
//

import UIKit

class ViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var backFromDetailed = false

    var pictures = [Picture]()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addPic))

        tableView.rowHeight = 100
        pictures = loadPics()
        tableView.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        if backFromDetailed {
        pictures = loadPics()
        tableView.reloadData()
        backFromDetailed = false
    }

}

    func loadPics() -> [Picture] {
        if let loadedPictures = UserDefaults.standard.object(forKey: "Pictures") as? Data {
            if let decodedPictures = try? JSONDecoder().decode([Picture].self, from: loadedPictures) {
                return decodedPictures
            }
        }
        return [Picture]()
    }

    @objc func addPic() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let ac = UIAlertController(title: "Source", message: nil, preferredStyle: .actionSheet)
            ac.addAction(UIAlertAction(title: "Photos", style: .default, handler: { [weak self] _ in
                self?.showPicker(fromCamera: false)
            }))
            ac.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
                self?.showPicker(fromCamera: true)
            }))
            ac.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
            present(ac, animated: true)
        }
        else {
            showPicker(fromCamera: false)
        }
    }

    func showPicker(fromCamera: Bool) {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        if fromCamera {
            picker.sourceType = .camera
        }
        present(picker, animated: true)
    }

    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }


        let imageID = UUID().uuidString

        if let jpegData = image.jpegData(compressionQuality: 0.8) {
            try? jpegData.write(to: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(imageID))
            }


        self.dismiss(animated: true)

            let ac = UIAlertController(title: "New name", message: "Enter new name for this image", preferredStyle: .alert)
            ac.addTextField()
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak ac] _ in
                guard let imageName = ac?.textFields?[0].text else { return }
                self.savePicture(imageID: imageID, imageName: imageName)
                }))
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        self.present(ac, animated: true)


    }

    func savePicture(imageID: String, imageName: String) {
        let picture = Picture(imageID: imageID, imageName: imageName)
        pictures.append(picture)

        DispatchQueue.global().async { [weak self] in
            if let pictures = self?.pictures {
                if let encodedPictures = try? JSONEncoder().encode(pictures) {
                    UserDefaults.standard.set(encodedPictures, forKey: "Pictures")
                }
            }

            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pictures.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Picture", for: indexPath)

        if let cell = cell as? PictureCell {
            cell.labelImage?.text = pictures[indexPath.row].imageName
            _ = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(pictures[indexPath.row].imageID)

            cell.pictureImage?.image = UIImage(contentsOfFile: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(pictures[indexPath.row].imageID).path)
            cell.pictureImage?.layer.borderColor = UIColor.black.cgColor
            cell.pictureImage?.layer.borderWidth = 0.1

        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let detailViewController = storyboard?.instantiateViewController(withIdentifier: "Detail") as? DetailViewController {
            detailViewController.pictures = pictures
            backFromDetailed = true
            detailViewController.current = indexPath.row
            navigationController?.pushViewController(detailViewController, animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            pictures.remove(at: indexPath.row)

            DispatchQueue.global().async { [weak self] in
                if let pictures = self?.pictures {
                    if let encodedPictures = try? JSONEncoder().encode(pictures) {
                        UserDefaults.standard.set(encodedPictures, forKey: "Pictures")
                    }
                }

                DispatchQueue.main.async {
                    self?.tableView.deleteRows(at: [indexPath], with: .automatic)
                }
            }
        }
    }
}

