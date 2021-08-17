//
//  MenuScrollView.swift
//  iOS
//
//  Created by bart Shin on 2021/08/04.
//

import SwiftUI

struct MenuScrollView: View {
	
	private let menus: [Menu]
	@State private var selectedMenuTitle: String?
	@Binding var activeMenuTitles: [String]
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
					.buttonStyle(CircleIconButton(menu: menu, isActive: isActiveColor(menu)))
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
			.padding(.horizontal, 32 * menu.sizeRatio)
			if menu.displayTitle {
				Text(menu.title)
					.font(Constant.menuFont)
					.foregroundColor(getTitleColor(for: menu))
			}
		}
	}
	
	private func getTitleColor(for menu: Menu) -> Color {
		if menu.iconImage != nil {
			return isActiveColor(menu) ?
			Constant.iconFontColor.active:
			Constant.iconFontColor.normal
		}
		else {
			return isActiveColor(menu) ?
			Constant.filterFontColor.active:
			Constant.filterFontColor.normal
		}
	}
	
	private func getIconImage(for menu: Menu) -> some View {
		Image(uiImage: menu.iconImage!)
			.resizable()
			.renderingMode(menu.renderingMode)
			.frame(width: Constant.iconImageSize.width * menu.sizeRatio,
				   height: Constant.iconImageSize.height * menu.sizeRatio)
	}
	
	private func drawFilterButton(for menu: Menu) -> some View {
		ZStack {
			Image(uiImage: menu.filterImage!)
				.resizable()
				.renderingMode(menu.renderingMode)
				.colorMultiply(selectedMenuTitle == menu.title ? Constant.selectedFilterOverlayColor: .white)
			if selectedMenuTitle == menu.title {
				Image(systemName: "checkmark")
					.resizable()
					.renderingMode(.template)
					.frame(width: Constant.iconImageSize.width * menu.sizeRatio,
						   height: Constant.iconImageSize.height * menu.sizeRatio)
					.foregroundColor(.white)
			}
		}
		.frame(width: Constant.filterImageSize.width,
			   height: Constant.filterImageSize.height)
	}
	
	private struct CircleIconButton: ButtonStyle {
		let menu: Menu
		var isActive: Bool
		func makeBody(configuration: Configuration) -> some View {
			ZStack {
				(configuration.isPressed || isActive ? Constant.iconBackgroundColor.active: Constant.iconBackgroundColor.normal)
					.clipShape(Circle())
				configuration.label
				if menu.hasBorder {
					Circle()
						.strokeBorder(configuration.isPressed || isActive ?
									  Constant.iconCircleColor.active: Constant.iconCircleColor.normal,
									  lineWidth: 1)
				}
			}
			.foregroundColor(configuration.isPressed || isActive ? Constant.buttonForegroundColor.active: Constant.buttonForegroundColor.normal)
			.frame(width: Constant.iconCircleSize.width * menu.sizeRatio,
				   height: Constant.iconCircleSize.height * menu.sizeRatio)
		}
	}
	
	private func isActiveColor(_ menu: Menu) -> Bool {
		selectedMenuTitle == menu.title || activeMenuTitles.contains(menu.title)
	}
	
	private struct Constant {
		typealias ValiableColoor = (normal: Color, active: Color)
		static let iconCircleSize = CGSize(width: 52, height: 52)
		static let iconImageSize = CGSize(width: 32, height: 32)
		static let filterImageSize = CGSize(width: 65, height: 65)
		static let iconCircleColor: ValiableColoor = (DesignConstant.getColor(for: .onBackground), DesignConstant.getColor(for: .onPrimary))
		static let iconBackgroundColor: ValiableColoor = (DesignConstant.getColor(for: .background), DesignConstant.getColor(for: .primary))
		static let iconFontColor: ValiableColoor = (DesignConstant.getColor(for: .onBackground), DesignConstant.getColor(for: .primary))
		static let filterFontColor: ValiableColoor = (DesignConstant.getColor(for: .onBackground), DesignConstant.getColor(for: .link))
		static let buttonForegroundColor: ValiableColoor = (DesignConstant.getColor(for: .onBackground), DesignConstant.getColor(for: .background))
		static let selectedFilterOverlayColor: Color = .gray.opacity(0.5)
		static let menuFont: Font = DesignConstant.getFont(.init(family: .NotoSansCJKkr, style: .Regular), size: 15)
	}
	
	struct Menu {
		
		static let colorIconMenus = ["Saturation", "Preset"]
		let title: String
		let iconImage: UIImage?
		let filterImage: UIImage?
		var hasBorder: Bool
		var sizeRatio: CGFloat = 1
		var displayTitle = true
		
		init(title: String, iconImage: UIImage, hasBorder: Bool = true) {
			self.title = title
			self.iconImage = iconImage
			self.filterImage = nil
			self.hasBorder = hasBorder
		}
		
		init(title: String, filterImage: UIImage) {
			self.title = title
			self.filterImage = filterImage
			self.iconImage = nil
			self.hasBorder = false
		}
		
		var renderingMode: Image.TemplateRenderingMode {
		
			if filterImage != nil ||
			   Self.colorIconMenus.contains(title) {
				return .original
			}
			else {
				return .template
			}
		}
	}
	
	init(menus: [Menu], tapMenu: @escaping (Menu) -> Void, activeMenuTitles: Binding<[String]>? = nil) {
		self.menus = menus
		self.tapMenu = tapMenu
		isIconMenu = menus.first?.filterImage == nil
		_activeMenuTitles = activeMenuTitles ?? .constant([])
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
