//
//  ViewModelsFactory.swift
//  DiaryApp
//
//  Created by Lyubomyr Semkiv on 9/30/15.
//  Copyright © 2015 Lyubomyr Semkiv. All rights reserved.
//

import Foundation

////////////////////////////////////////////////////////////////////////

class ViewModelsFactory {
  static func getCreationDateCategorizationViewModel(dataModel dataModel: DataModel) -> CreationDateCategorizationViewModel {
    let proxy = DataModelIndexingProxy(dataModel: dataModel)
    return CreationDateCategorizationViewModel(proxy: proxy)
  }
  
  static func getMoodCategorizationViewModel(dataModel: DataModel) -> MoodCategorizationViewModel {
    let proxy = DataModelIndexingProxy(dataModel: dataModel)
    return MoodCategorizationViewModel(proxy: proxy)
  }
}

