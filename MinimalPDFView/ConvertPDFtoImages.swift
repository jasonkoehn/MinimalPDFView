//
//  ConvertPDFtoImages.swift
//  MinimalPDFView
//
//  Created by Jason Koehn on 2/21/24.
//

import SwiftUI

func convertPDFToImages(_ url: URL) -> [UIImage]? {
    guard let document = CGPDFDocument(url as CFURL) else { return nil }
    
    var images: [UIImage] = []
    
    for pageNum in 0..<document.numberOfPages {
        if let page = document.page(at: pageNum + 1) {
            let pageSize = page.getBoxRect(.mediaBox)
            let renderer = UIGraphicsImageRenderer(size: pageSize.size)
            
            let image = renderer.image { ctx in
                UIColor.white.set()
                ctx.fill(pageSize)
                ctx.cgContext.translateBy(x: 0.0, y: pageSize.size.height)
                ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
                
                ctx.cgContext.drawPDFPage(page)
            }
            
            images.append(image)
        }
    }
    
    return images
}
