Read me

// Caller function

 func showCameraActionSheet() {
        AttachmentHandler.shared.showAttachmentActionSheet(viewController: self)
        AttachmentHandler.shared.imagePickedBlock = { (image) in
            let chooseImage = image.resizeImage(targetSize: CGSize(width: 500, height: 600))
            self.imageList.insert(chooseImage, at: self.imageList.count-1)
            self.collectionView.reloadData()
        }
    }