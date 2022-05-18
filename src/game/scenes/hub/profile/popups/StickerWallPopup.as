package game.scenes.hub.profile.popups
{
	import flash.display.Bitmap;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.motion.Draggable;
	import game.components.timeline.Timeline;
	import game.components.ui.Ratio;
	import game.components.ui.Slider;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.display.BitmapWrapper;
	import game.data.ui.TransitionData;
	import game.proxy.Connection;
	import game.scenes.hub.profile.components.Sticker;
	import game.scenes.hub.profile.systems.StickerDragSystem;
	import game.systems.motion.DraggableSystem;
	import game.systems.ui.SliderSystem;
	import game.ui.popup.Popup;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	
	public class StickerWallPopup extends Popup
	{	
		//tracking constants
		private const TRACK_CLICK_WALLPAPER_TAB:String = "ClickWallpapers";
		private const TRACK_CLICK_STICKERS_TAB:String = "ClickStickers";
		private const TRACK_ADD_STICKER:String = "AddSticker";
		private const TRACK_REMOVE_STICKER:String = "RemoveSticker";
		private const TRACK_DRAG_STICKER:String = "DragSticker";
		private const TRACK_SET_WALLPAPER:String = "SetWallpaper";
		private const TRACK_CLOSE_POPUP:String = "Close";
		//tracking - is on player's profile or visiting another profile
		private var selfOrFriend:String;
		
		private var content:MovieClip;
		private var dragging:Boolean = false;
		private var prefabContainer:DisplayObjectContainer;
		public var wall:MovieClip;
		
		private var inactiveTab:Entity;
		private var activeTab:Entity;
		private var tabsSwitched:Boolean = false;
		private var onTxt:TextFormat;
		private var offTxt:TextFormat;
		private var tabTxt1:TextField;
		private var tabTxt2:TextField;
		
		private var scrollStartY:Number;
		private var scrollMax:Number;
		private var stickersAsset:MovieClip;
		private var stickerContainer:MovieClip;
		
		private var wScrollStartY:Number;
		private var wScrollMax:Number;
		private var wallpaperContainer:MovieClip;
		
		private var vars:URLVariables;
		private var stickersJSON:Object;
		private var stickerBitmaps:Vector.<BitmapWrapper> = new Vector.<BitmapWrapper>();
		private var originalStickerEntities:Vector.<Entity> = new Vector.<Entity>();
		
		private var wallpaperJSON:Object;
		private var wallpaperBitmaps:Vector.<BitmapWrapper> = new Vector.<BitmapWrapper>();
		
		public var setItems:Function;
		public var reloadWallpaper:Function;
		
		private var loginData:Object;
			
		public function StickerWallPopup(ld:Object, container:DisplayObjectContainer=null)
		{
			loginData = ld;
			super(container);
		}
		
		override public function destroy():void
		{
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			// setup the transitions 
			super.transitionIn = new TransitionData();
			super.transitionIn.duration = .3;
			super.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight);
			// this shortcut method flips the start and end position of the transitionIn
			super.transitionOut = super.transitionIn.duplicateSwitch();
			super.darkenBackground = true;
			super.groupPrefix = "scenes/hub/profile/popups/";
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(["stickerWallPopup.swf", "stickers.swf"]);
		}
		
		// all assets ready
		override public function loaded():void
		{		
			super.screen = super.getAsset("stickerWallPopup.swf", true) as MovieClip;
			content = screen.content;
			stickersAsset = super.getAsset("stickers.swf", false) as MovieClip;
			stickerContainer = content["stickerContainer"];
			wallpaperContainer = content["wallpaperContainer"];
			stickerContainer.mask = content["containerMask"];
			wallpaperContainer.mask = content["wcontainerMask"];
			
			wall = content["stickerBox"];
			wall["container"].mask = content["wallMask"];
			content["wallMask"].mouseEnabled = false;
			content["bounds"].mouseEnabled = false;
			
			addSystem(new DraggableSystem());
			addSystem(new SliderSystem());
			addSystem(new StickerDragSystem());
			
			// for tracking
			selfOrFriend = loginData.playerLogin == loginData.activeLogin ? "self" : "friend";
			
			setupStickers();
			
			// this loads the standard close button
			super.loadCloseButton();
			super.loaded();
		}
		
		private function setupStickers(event:Event=null):void
		{
			vars = new URLVariables();
			vars.login = loginData.playerLogin;
			vars.pass_hash = loginData.playerHash;
			vars.dbid = loginData.playerDBID;
			vars.lookup_user = loginData.activeLogin;
			
			var connection:Connection = new Connection();
			connection.connect(shellApi.siteProxy.secureHost + "/interface/StickerWall/list", vars, URLRequestMethod.POST, setStickers, myErrorFunction);
		}
		
		private function setStickers(event:Event):void
		{
			stickersJSON = JSON.parse(event.target.data);
			var container:MovieClip = stickersAsset["stickerContainer"];
			var counter:Number = 1;
			for each(var sticker:Object in stickersJSON.stickers){
				var name:String = sticker.item_name.slice(0, -8);				
				var s:MovieClip = container[name];
				if(s != null){
					var wrapper:BitmapWrapper = super.convertToBitmapSprite(s, null, false, 1);
					stickerBitmaps.push(wrapper);
					var wrap:BitmapWrapper = wrapper.duplicate();
					var entity:Entity = createStickerEntity(wrap, stickerContainer, Number(counter), Number(sticker.item_id), false);
					originalStickerEntities.push(entity);
					entity.get(Sticker).name = name;
				} else {
					trace("ERROR Finding Sticker "+name);
				}
				counter++;
			}
			var connection:Connection = new Connection();
			connection.connect(shellApi.siteProxy.secureHost + "/interface/StickerWall/get", vars, URLRequestMethod.POST, setUserStickers, myErrorFunction);
			setupWallpapers();
		}
		
		private function setupWallpapers():void
		{
			var connection:Connection = new Connection();
			connection.connect(shellApi.siteProxy.secureHost + "/interface/Wallpaper/list", vars, URLRequestMethod.POST, setWallpapers, myErrorFunction);
		}
		
		private function setWallpapers(event:Event):void //right now setting these to cacheasbitmap - probably should bitmap these directly in case next guy doesn't
		{
			wallpaperJSON = JSON.parse(event.target.data);
			var container:MovieClip = stickersAsset["wallpaperContainer"];
			var counter:Number = 1;
			for each(var wallpaper:Object in wallpaperJSON.wallpapers){
				var name:String = wallpaper.item_name.slice(0, -10);
				var w:MovieClip = container[name];
				if(w != null){
					var entity:Entity = EntityUtils.createMovingEntity( this, w, wallpaperContainer );
					var interaction:Interaction = InteractionCreator.addToEntity(entity, ["down"]);
					interaction.down.add(this.onWallpaperSelect);
					entity.remove(Sleep);
					entity.add(new Id(name));
				} else {
					trace("ERROR Finding Wallpaper "+name);
				}
				counter++;
			}
			setupSlider();
			setupTabs();
		}
		
		private function onWallpaperSelect(entity:Entity):void
		{
			var id:String = entity.get(Id).id;
			var wallpaperId:Number = 0;
			for each(var wallpaper:Object in wallpaperJSON.wallpapers){
				var name:String = wallpaper.item_name.slice(0, -10);
				if(name == id){
					wallpaperId = wallpaper.item_id;
				}
			}
			if(wallpaperId > 0){
				// tracking
				shellApi.track(TRACK_SET_WALLPAPER, id, selfOrFriend, "StickerWall");
			
				var urlvars:URLVariables = new URLVariables();
				urlvars.login = vars.login;
				urlvars.pass_hash = vars.pass_hash;
				urlvars.dbid = vars.dbid;
				urlvars.lookup_user = vars.lookup_user;
				urlvars.wallpaper_id = wallpaperId;
		
				var connection:Connection = new Connection();
				connection.connect(shellApi.siteProxy.secureHost + "/interface/Wallpaper/save", urlvars, URLRequestMethod.POST, saveWallpaperToServer, myErrorFunction);//not the best oncomplete...
			}
			// save to database and close
		}
		
		private function setUserStickers(event:Event):void
		{
			var obj:Object = JSON.parse(event.target.data);
			for each(var sticker:Object in obj.stickers){
				for (var i:int = 0; i < originalStickerEntities.length; i++) {
					if( sticker.item_id == originalStickerEntities[i].get(Sticker).id) {
						var s:Sticker = originalStickerEntities[i].get(Sticker);
						var wrap:BitmapWrapper = stickerBitmaps[s.num-1].duplicate();
						var e:Entity = createStickerEntity(wrap, wall["container"], Number(s.num), Number(s.id), false);
						e.get(Spatial).x = sticker.x;
						e.get(Spatial).y = sticker.y;
						e.get(Display).displayObject.name = s.name;
						e.get(Sticker).name = s.name;
						e.get(Sticker).onBoard = true;
					}
				}
			}
		}
		
		private function createStickerEntity(wrapper:BitmapWrapper, container:MovieClip, num:Number, id:Number, onBoard):Entity
		{
			var entity:Entity = EntityUtils.createMovingEntity( this, wrapper.sprite, container );
			InteractionCreator.addToEntity(entity, ["down","up",InteractionCreator.RELEASE_OUT]);
			var draggable:Draggable = new Draggable();
			draggable.drag.add(dragSticker);
			entity.add(draggable);
			entity.add( new Sticker(num, id, wrapper.sprite.x, wrapper.sprite.y, onBoard) );
			entity.remove(Sleep);
			return entity;
		}
		
		private function setupTabs():void
		{
			inactiveTab = ButtonCreator.createButtonEntity(MovieClip(content["tabBlue"]), this);
			inactiveTab.remove(Timeline);
			var chatInteraction:Interaction = inactiveTab.get(Interaction);
			chatInteraction.downNative.add( Command.create( clickInactiveTab ));
			Display(inactiveTab.get(Display)).isStatic = false;
			
			activeTab = EntityUtils.createMovingEntity( this, content["tabWhite"], content );
			
			onTxt = new TextFormat("Billy Serif", null, "0x636466");
			offTxt = new TextFormat("Billy Serif", null, "0xFFFFFF");
			tabTxt1 = content["tabTxt1"];
			tabTxt2 = content["tabTxt2"];
			tabTxt1.setTextFormat(onTxt);
			tabTxt2.setTextFormat(offTxt);
			tabTxt1.mouseEnabled = false;
			tabTxt2.mouseEnabled = false;
			wallpaperContainer.x = -1000;
			stickerContainer.x = 184;
		}
		
		private function clickInactiveTab(event:Event):void
		{
			activeTab.get(Spatial).x = tabsSwitched ? 370 : 584;
			inactiveTab.get(Spatial).x = tabsSwitched ? 584 : 370;
			if(tabsSwitched){
				// tracking
				shellApi.track(TRACK_CLICK_STICKERS_TAB, null, selfOrFriend, "StickerWall");
				
				tabTxt1.setTextFormat(onTxt);
				tabTxt2.setTextFormat(offTxt);
				wallpaperContainer.x = -1000;
				stickerContainer.x = 184;
				
			} else {
				// tracking
				shellApi.track(TRACK_CLICK_WALLPAPER_TAB, null, selfOrFriend, "StickerWall");

				tabTxt1.setTextFormat(offTxt);
				tabTxt2.setTextFormat(onTxt);
				wallpaperContainer.x = 184;
				stickerContainer.x = -1000;
			}
			tabsSwitched = !tabsSwitched;
		}
		
		private function dragSticker(entity:Entity):void
		{
			dragging = true;
			var spatial:Spatial = entity.get(Spatial);
			var display:DisplayObjectContainer = EntityUtils.getDisplayObject(entity);
			var sticker:Sticker = entity.get(Sticker);
			sticker.moving = true;
			
			//keeps it from flashing in wrong position
			var pos:Point = DisplayUtils.localToLocal(display, content);
			spatial.x = pos.x;
			spatial.y = pos.y;
			
			var draggable:Draggable = entity.get(Draggable);			
			draggable.drop.addOnce(placeOnBoard);
			content.addChild(display);
			
			if(!sticker.onBoard){
				var wrap:BitmapWrapper = stickerBitmaps[sticker.num-1].duplicate();
				var e:Entity = createStickerEntity(wrap, stickerContainer, Number(sticker.num), Number(sticker.id), false);
				e.get(Sticker).name = entity.get(Sticker).name;
			} 
		}
		private function placeOnBoard(entity:Entity):void
		{
			dragging = false;
			var display:DisplayObjectContainer = EntityUtils.getDisplayObject(entity);
			var bitmap:Bitmap = Bitmap(display.getChildAt(0));
			var sticker:Sticker = entity.get(Sticker);
			var spatial:Spatial = entity.get(Spatial);
			var place:Point = bitmap.localToGlobal(new Point(bitmap.width/2, bitmap.height/2));
			
			sticker.moving = false;
			
			var pos:Point = new Point(spatial.x, spatial.y);
			var contains:Boolean = new Rectangle(wall.x - 10, wall.y - 10, wall.width + 20, wall.height + 20).contains(pos.x, pos.y); //content["bounds"].getBounds(content).contains(pos.x, pos.y);
			
			var name:String = entity.get(Sticker).name;
			if(contains) {
				if(sticker.onBoard){
					// tracking
					shellApi.track(TRACK_DRAG_STICKER, name, selfOrFriend, "StickerWall");
				} else {
					// tracking
					shellApi.track(TRACK_ADD_STICKER, name, selfOrFriend, "StickerWall");
				}
				spatial.x = place.x - wall.x;
				spatial.y = place.y - wall.y;
				bitmap.x = -bitmap.width/2;
				bitmap.y = -bitmap.height/2;
				wall["container"].addChild(display);
				display.name = entity.get(Sticker).name;
				sticker.onBoard = true;
			} else {
				// tracking
				shellApi.track(TRACK_REMOVE_STICKER, name, selfOrFriend, "StickerWall");
				
				display.parent.removeChild(display);//***********************************NEED TO COMPLETELY DESTROY ENTITY*********************
			}
		}
		
		private function setupSlider():void
		{
			var sliderClip:MovieClip = content["slider"];
			var slider:Entity = EntityUtils.createSpatialEntity(this, sliderClip);
			InteractionCreator.addToEntity(slider, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT]);
			var draggable:Draggable = new Draggable("y");
			slider.add(draggable);
			slider.add(new Slider());
			slider.add(new MotionBounds(new Rectangle(780, 111, 10, 194)));
			slider.add(new Ratio());
			ToolTipCreator.addToEntity(slider);
			draggable.dragging.add(onSliderDrag);
			
			scrollStartY = stickerContainer.y;
			scrollMax = stickerContainer.height + 15 - 260;
			
			wScrollStartY = wallpaperContainer.y;
			wScrollMax = wallpaperContainer.height + 15 - 260;
		}
		
		private function onSliderDrag(entity:Entity):void
		{
			var ratio:Ratio = entity.get(Ratio);
			stickerContainer.y = scrollStartY - (scrollMax * ratio.decimal);
			wallpaperContainer.y = wScrollStartY - (wScrollMax * ratio.decimal);
		}
		
		override public function close( removeOnClose:Boolean = true, onClosedHandler:Function = null ):void
		{
			// tracking
			shellApi.track(TRACK_CLOSE_POPUP, null, selfOrFriend, "StickerWall");
			
			var array:Array = [];
			var postArray:Array = [];
			for (var i:int = 0; i < wall["container"].numChildren; i++) 
			{
				var sprite:Sprite = wall["container"].getChildAt(i);
				var a:Array = [];
				a.push(sprite.name);
				a.push(sprite.x);
				a.push(sprite.y);
				array.push(a);
				
				for (var j:int = 0; j < originalStickerEntities.length; j++) {
					if( sprite.name == originalStickerEntities[j].get(Sticker).name) {
						var o:Object = new Object();
						o.item_id = originalStickerEntities[j].get(Sticker).id;
						o.x = sprite.x;
						o.y = sprite.y;
						o.z = i;
						postArray.push(o);
					}
				}
			}
			setItems(array);
			var urlvars:URLVariables = new URLVariables();
			urlvars.login = vars.login;
			urlvars.pass_hash = vars.pass_hash;
			urlvars.dbid = vars.dbid;
			urlvars.lookup_user = vars.lookup_user;
			urlvars.stickers = JSON.stringify(postArray);
			
			var connection:Connection = new Connection();
			connection.connect(shellApi.siteProxy.secureHost + "/interface/StickerWall/save", urlvars, URLRequestMethod.POST, saveStickersToServer, myErrorFunction);
		}
		
		private function myErrorFunction(event:Event):void
		{
			trace(event.target.data);
		}
		
		private function saveWallpaperToServer(event:Event):void
		{
			reloadWallpaper();
			close();
			//remove();
		}
		
		private function saveStickersToServer(event:Event):void
		{
			remove();
		}
	};
}
