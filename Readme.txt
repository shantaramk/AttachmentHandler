Read me

// Caller function

 func showCameraActionSheet() {
        AttachmentHandler.shared.showAttachmentActionSheet([.camera, .photoLibrary], taget: self)
        AttachmentHandler.shared.imagePickedBlock = { (image) in
            self.userImageView.image = image
        }
    }
