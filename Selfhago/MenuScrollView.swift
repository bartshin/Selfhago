//
//  MenuScrollView.swift
//  iOS
//
//  Created by bart Shin on 2021/08/04.
//

import SwiftUI

struct MenuScrollView: View {
	
	private let menus: [Menu]
	private let circleIconButtonStyle = CircleIconButton()
	@State private var selectedMenuTitle: String?
	private let tapMenu: (Menu) -> Void
	private let isIconMenu: Bool
	
    var body: some View {
		ScrollView(.horizontal, showsIndicators: false) {
			HStack (spacing: 0) {
				ForEach(menus, id: \.self.title) { menu in
					drawMenuButton(for: menu)
				}
			}
		}
    }
	
	private func drawMenuButton(for menu: Menu) -> some View {
		VStack (spacing: 10) {
			Group{
				if menu.iconImage != nil {
					Button {
						selectedMenuTitle = menu.title
						tapMenu(menu)
					} label: {
						getIconImage(for: menu)
					}
					.buttonStyle(circleIconButtonStyle)
				}
				else if menu.filterImage != nil {
					Button {
						selectedMenuTitle = menu.title
						tapMenu(menu)
					} label: {
						drawFilterButton(for: menu)
					}
				}
			}
			.padding(.horizontal, 32)
			Text(menu.title)
				.font(Constant.menuFont)
				.foregroundColor(menu.title == selectedMenuTitle ?
									Constant.titleFontColor.selected:
									Constant.titleFontColor.normal)
		}
	}
	
	private func getIconImage(for menu: Menu) -> some View {
		Image(uiImage: menu.iconImage!)
			.resizable()
			.renderingMode(menu.title == selectedMenuTitle ? .template: .original)
			.frame(width: Constant.iconImageSize.width,
				   height: Constant.iconImageSize.height)
	}
	
	private func drawFilterButton(for menu: Menu) -> some View {
		ZStack {
			Image(uiImage: menu.filterImage!)
				.resizable()
				.colorMultiply(menu.title == selectedMenuTitle ? Constant.selectedFilterOverlayColor: .white)
			if menu.title == selectedMenuTitle {
				Image(systemName: "checkmark")
					.resizable()
					.frame(width: Constant.iconImageSize.width,
						   height: Constant.iconImageSize.height)
					.foregroundColor(.white)
			}
		}
		.frame(width: Constant.filterImageSize.width,
			   height: Constant.filterImageSize.height)
	}
	
	private struct CircleIconButton: ButtonStyle {
		func makeBody(configuration: Configuration) -> some View {
			ZStack {
				(configuration.isPressed ? Constant.iconBackgroundColor.pressed: Constant.iconBackgroundColor.normal)
					.clipShape(Circle())
				configuration.label
				Circle()
					.strokeBorder(configuration.isPressed ?
									Constant.iconCircleColor.pressed: Constant.iconCircleColor.normal,
								  lineWidth: 1)
			}
			.foregroundColor(configuration.isPressed ? Constant.buttonForegroundColor.pressed: Constant.buttonForegroundColor.normal)
			.frame(width: Constant.iconCircleSize.width,
				   height: Constant.iconCircleSize.height)
		}
	}
	
	private struct Constant {
		static let iconCircleSize = CGSize(width: 52, height: 52)
		static let iconImageSize = CGSize(width: 32, height: 32)
		static let filterImageSize = CGSize(width: 65, height: 65)
		static let iconCircleColor: (normal: Color, pressed: Color) = (.black, .clear)
		static let iconBackgroundColor: (normal: Color, pressed: Color) = (.clear, .blue)
		static let titleFontColor: (normal: Color, selected: Color) = (.black, .blue)
		static let buttonForegroundColor: (normal: Color, pressed: Color) = (.black, .white)
		static let selectedFilterOverlayColor: Color = .gray.opacity(0.5)
		static let menuFont: Font = DesignConstant.getFont(.init(family: .NotoSansCJKkr, style: .Regular), size: 15)
	}
	
	
	struct Menu {
		let title: String
		let iconImage: UIImage?
		let filterImage: UIImage?
		
		init(title: String, iconImage: UIImage) {
			self.title = title
			self.iconImage = iconImage
			self.filterImage = nil
		}
		
		init(title: String, filterImage: UIImage) {
			self.title = title
			self.filterImage = filterImage
			self.iconImage = nil
		}
	}
	
	init(menus: [Menu], tapMenu: @escaping (Menu) -> Void) {
		self.menus = menus
		self.tapMenu = tapMenu
		isIconMenu = menus.first?.filterImage == nil
	}
}

#if DEBUG
fileprivate var dummyMenus: [MenuScrollView.Menu] {
	[
		.init(title: "Title Title Title", iconImage: UIImage(named: "brightness")!),
		.init(title: "Title", iconImage: UIImage(named: "brightness")!),
		.init(title: "Title Title", iconImage: UIImage(named: "brightness")!),
		.init(title: "Tle", iconImage: UIImage(named: "brightness")!),
		.init(title: "Title", iconImage: UIImage(named: "brightness")!),
		.init(title: "Tite", iconImage: UIImage(named: "brightness")!)
	]
}


struct TunningPanel_Previews: PreviewProvider {
    static var previews: some View {
		MenuScrollView(menus: dummyMenus, tapMenu: {_ in})
    }
}
#endif
