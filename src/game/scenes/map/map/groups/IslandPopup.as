package game.scenes.map.map.groups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.text.TextField;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.SpatialAddition;
	import engine.creators.InteractionCreator;
	import engine.creators.ObjectCreator;
	
	import game.components.entity.Sleep;
	import game.components.ui.Book;
	import game.components.ui.Button;
	import game.creators.ui.ButtonCreator;
	import game.data.ads.AdTrackingConstants;
	import game.data.ads.AdvertisingConstants;
	import game.managers.ads.AdManager;
	import game.scenes.map.map.swipe.Swipe;
	import game.scenes.map.map.swipe.SwipeSystem;
	import game.systems.timeline.BitmapSequenceSystem;
	import game.systems.ui.BookSystem;
	import game.ui.popup.Popup;
	import game.util.Alignment;
	import game.util.ClassUtils;
	import game.util.DisplayPositions;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.TextUtils;
	
	public class IslandPopup extends Popup
	{
		private const MIN_SWIPE_DISTANCE:int = 50;
		
		public var islandXML:XML;
		
		public var autoFlipPage:int = -1;
		
		private var _book:Entity;
		private var _arrowLeft:Entity;
		private var _arrowRight:Entity;
		
		public function IslandPopup(container:DisplayObjectContainer = null)
		{
			super(container);
			
			this.id 				= "IslandPopup";
			this.groupPrefix 		= "scenes/map/map/";
			this.screenAsset 		= "islandPopup.swf";
			this.pauseParent 		= true;
			this.darkenBackground 	= true;
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.init(container);
			
			this.load();
		}
		
		override public function destroy():void
		{
			//stops possible loading of zips before error with lack of reference occurs.
			if(PlatformUtils.isMobileOS)
			{
				var islandParts:Array = String(this.islandXML.islandFolder).split("/");
				//Subtracting 2 because the last "/" splits the islandFolder path into: scenes,map,map,islands,[island]," " (empty).
				var island:String = islandParts[islandParts.length - 2];
				
				if(islandParts[0] == AdvertisingConstants.AD_PATH_KEYWORD)
				{
					island = islandParts[islandParts.length - 3];
				}
				
				super.shellApi.fileManager.stopLoad([island]);
			}
			
			super.destroy();
		}
		
		override public function load():void
		{
			super.load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			var entity:Entity = this.loadCloseButton(DisplayPositions.TOP_RIGHT, 40, 35);
			entity.add(new Sleep());
			
			this.addSystem(new SwipeSystem());
			this.addSystem(new BookSystem());
			this.addSystem(new BitmapSequenceSystem());
			
			this.resizePopup();
			this.setupPages();
			
			this.shellApi.loadFile(this.shellApi.assetPrefix + this.islandXML.islandFolder + "icon.swf", this.islandIconLoaded);		
		}
		
		private function resizePopup():void
		{
			var width:Number 	= this.shellApi.viewportWidth;
			var height:Number 	= this.shellApi.viewportHeight;
			var clip:MovieClip;
			
			clip = this.screen["header"];
			clip.width = width;
			
			clip 	= this.screen["pageContainer"];
			clip.x 	= width * 0.5 - 418; //418 is half of the width of an IslandPage.
			clip.y 	*= height / 640;
			
			clip 	= this.screen["fadeLeft"];
			clip.x 	= 0;
			clip.y 	= height * 0.5;
			
			clip 	= this.screen["fadeRight"];
			clip.x 	= width;
			clip.y 	= height * 0.5;
			
			clip 	= this.screen["arrowLeft"];
			clip.x 	= 15;
			clip.y 	*= height / 640;
			
			clip 	= this.screen["arrowRight"];
			clip.x 	= width - 15;
			clip.y 	*= height / 640;
			
			clip 		= this.screen["background"];
			clip.width 	= width;
			clip.height = height;
		}
		
		private function islandIconLoaded(clip:MovieClip):void
		{
			if(clip)
			{
				clip.width = 45;
				clip.height = 45;
				this.screen["iconContainer"].addChild(clip);
			}
		}
		
		private function setupPages():void
		{
			var islandName:TextField 	= TextUtils.refreshText(this.screen["island"]);
			islandName.text 			= this.islandXML.name;
			var islandFolder:String		= this.islandXML.islandFolder;
			
			//var bitmap:Bitmap = BitmapUtils.toBitmap(islandName);
			//DisplayUtils.swap(bitmap, islandName);
			//this.bitmaps.push(bitmap);
			
			var pagesXML:XMLList 	= this.islandXML.pages.children();
			var numPages:int 		= pagesXML.length();
			
			// if MMQ, then track
			if (islandFolder.indexOf(AdvertisingConstants.AD_PATH_KEYWORD) != -1)
			{
				var arr:Array = islandFolder.split("/");
				var campaignName:String = arr[1];
				AdManager(super.shellApi.adManager).track(campaignName, AdTrackingConstants.TRACKING_MAP_POPUP_IMPRESSION, "Slide 1");
			}
			
			this.setupPageButtons(numPages);
			
			for(var i:int = numPages - 1; i >= 0; --i)
			{
				var pageXML:XML = pagesXML[i];
				
				var pageClass:Class = ClassUtils.getClassByName(pageXML.attribute("class"));
				if(pageClass)
				{
					var page:IslandPopupPage 	= new pageClass(this.screen["pageContainer"]);
					page.page					= i + 1;
					page.islandFolder			= this.islandXML.islandFolder;
					ObjectCreator.parsePropertiesXML(pageXML, page);
					this.addChildGroup(page);
				}
				else
				{
					trace("IslandPopup ::", pageXML.attribute("class"), "is an invalid Class definition. Not creating the page.");
				}
			}
		}
		
		private function setupPageButtons(numPages:int):void
		{
			for(var index:int = 0; index < numPages; ++index)
			{
				this.shellApi.loadFile(this.shellApi.assetPrefix + "scenes/map/map/shared/buttonPage.swf", this.onPageButtonLoaded, index, numPages);
			}
		}
		
		private function onPageButtonLoaded(clip:MovieClip, page:int, numPages:int):void
		{
			this.screen.addChild(clip);
			Alignment.centerAtIndex(clip, "x", this.shellApi.viewportWidth * 0.5, 30, page, numPages);
			clip.y = this.shellApi.viewportHeight - 15;
			
			var entity:Entity = ButtonCreator.createButtonEntity(clip, this, this.onPageButtonClicked, null, null, null, true, true);
			entity.get(Button).value = ++page;
			entity.add(new Id("pageButton" + page));
			
			for(var index:int = 0; index < numPages; ++index)
			{
				if(!this.getEntityById("pageButton" + (index + 1)))
				{
					return;
				}
			}
			this.setupBook(numPages);
		}
		
		private function setupBook(numPages:int):void
		{
			if(numPages == 1)
			{
				this.screen.removeChild(this.screen["arrowLeft"]);
				this.screen.removeChild(this.screen["arrowRight"]);
				this.invalidateButton(1, true);
				return;
			}
			
			this._arrowLeft = ButtonCreator.createButtonEntity(this.screen["arrowLeft"], this, this.onPageArrowClicked, null, null, null, true, true);
			this._arrowLeft.get(Button).value = -1;
			
			this._arrowRight = ButtonCreator.createButtonEntity(this.screen["arrowRight"], this, this.onPageArrowClicked, null, null, null, true, true);
			this._arrowRight.get(Button).value = 1;
			
			this._book = EntityUtils.createSpatialEntity(this, this.screen["pageContainer"]);
			this._book.add(new Id("swipeEntity"));
			this._book.add(new SpatialAddition());
			
			var page:int = 1;
			if(this.autoFlipPage > 0 && this.autoFlipPage <= numPages)
			{
				page = this.autoFlipPage;
			}
			
			var book:Book 	= new Book(page, numPages, IslandPopupPage.PAGE_WIDTH + IslandPopupPage.PAGE_BUFFER_X, IslandPopupPage.PAGE_HEIGHT);
			book.rate 		= 4;
			book.section = book.SECTION_HORIZONTAL;
			this._book.add(book);
			
			this._arrowLeft.get(Display).visible 	= (book.page == 1) ? false : true;
			this._arrowRight.get(Display).visible 	= (book.page == book.numPages) ? false : true;
			
			InteractionCreator.addToEntity(this._book, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.OUT]);
			
			var swipe:Swipe = new Swipe();
			swipe.stop.add(this.onSwipe);
			this._book.add(swipe);
			
			this.turnToPage(page);
		}
		
		private function onPageButtonClicked(pageButton:Entity):void
		{
			this.turnToPage(pageButton.get(Button).value);
		}
		
		private function turnToPage(page:int):void
		{
			if(!this._book) return;
				
			var book:Book = this._book.get(Book);
			
			this.invalidateButton(book.page, false);
			book.page = page;
			this.invalidateButton(book.page, true);
			
			this._arrowLeft.get(Display).visible 	= (book.page == 1) ? false : true;
			this._arrowRight.get(Display).visible 	= (book.page == book.numPages) ? false : true;
		}
		
		private function onPageArrowClicked(entity:Entity):void
		{
			this.turnPage(entity.get(Button).value);
		}
		
		private function turnPage(direction:int):void
		{
			var book:Book = this._book.get(Book);
			switch(direction)
			{
				case -1:
					if(book.page - 1 >= 1)
					{
						this.invalidateButton(book.page, false);
						this.invalidateButton(book.page - 1, true);
						book.page--;
					}
					break;
				
				case 1:
					if(book.page + 1 <= book.numPages)
					{
						this.invalidateButton(book.page, false);
						this.invalidateButton(book.page + 1, true);
						book.page++;
					}
					break;
			}
			
			this._arrowLeft.get(Display).visible 	= (book.page == 1) ? false : true;
			this._arrowRight.get(Display).visible 	= (book.page == book.numPages) ? false : true;
		}
		
		private function invalidateButton(page:int, isSelected:Boolean):void
		{
			var button:Button 	= this.getEntityById("pageButton" + page).get(Button);
			button.isSelected 	= isSelected;
			button.invalidate 	= true;
			
			isSelected ? button.downHandler() : button.outHandler();
		}
		
		private function onSwipe(entity:Entity):void
		{
			var swipe:Swipe = entity.get(Swipe);
			var book:Book 	= entity.get(Book);
			
			var distanceX:Number = swipe.stopX - swipe.startX;
			if(Math.abs(distanceX) < MIN_SWIPE_DISTANCE) return;
			
			this.turnPage((distanceX < 0) ? 1 : -1);
			
			// if MMQ, then track
			var island:String = this.islandXML.islandFolder;
			if (island.indexOf(AdvertisingConstants.AD_PATH_KEYWORD) != -1)
			{
				super.shellApi.adManager.track(island, AdTrackingConstants.TRACKING_SWIPE_ON_MAP_POPUP);
			}
		}
	}
}