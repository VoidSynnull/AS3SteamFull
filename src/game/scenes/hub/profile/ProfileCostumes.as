package game.scenes.hub.profile
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.MotionBounds;
	import engine.creators.InteractionCreator;
	
	import game.components.motion.Draggable;
	import game.components.ui.Ratio;
	import game.components.ui.Slider;
	import game.creators.entity.character.CharacterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.character.LookAspectData;
	import game.data.character.LookConverter;
	import game.data.character.LookData;
	import game.data.display.BitmapWrapper;
	import game.proxy.Connection;
	import game.ui.costumizer.CostumizerPop;
	import game.util.EntityUtils;
	import game.util.SkinUtils;

	public class ProfileCostumes
	{
		private const TRACK_CLICK_COSTUME:String = "ClickFriend";
		private const TRACK_SCROLLBAR:String = "Scroll";
		
		private var profile:Profile;
		private var _interactive:MovieClip;
		
		private var costumeBox:MovieClip;
		private var slider:Entity;
		private var inventory:MovieClip;
		private var bgWrapper:BitmapWrapper;
		private var noCostumes:Boolean = false;
		private var costumesLoaded:uint;
		
		private var costumes:Dictionary = new Dictionary();
		public var costumesArray:Array = [];
		
		private var scrollStartX:Number;
		private var scrollMax:Number;
		
		public function ProfileCostumes(p:Profile, int:MovieClip)
		{
			profile = p;
			_interactive = int;
			getCostumesList();
		}
		
		private function getCostumesList():void
		{
			var vars:URLVariables = new URLVariables();
			vars.login = profile.loginData.playerLogin;
			vars.pass_hash = profile.loginData.playerHash;
			vars.dbid = profile.loginData.playerDBID;
			vars.quantity = 20;
			vars.offset = 0;
			vars.lookup_user = profile.loginData.activeLogin;
			
			var connection:Connection = new Connection();
			connection.connect(profile.shellApi.siteProxy.secureHost + "/lookCloset/get_look_closet.php", vars, URLRequestMethod.POST, loadCostumes, myErrorFunction);
		}
		
		private function loadCostumes(event:Event):void 
		{	
			costumesLoaded = 0;
			
			var return_vars:URLVariables = new URLVariables(event.target.data);
			var counter:Number = 0;
			var lookConverter:LookConverter = new LookConverter();
			if(return_vars.answer == "ok"){
				var obj:Object = JSON.parse(return_vars.json);
				for each(var a:* in obj){
					var array:Array = String(a).split(",");
					var lookData:LookData = lookConverter.lookDataFromLookString(a);
					var c:Object = {login:array[0], name:array[1], look:lookData}; //this is almost certainly broken... array won't have login in it...
					costumes["costume"+counter] = c;
					costumesArray.push("costume"+counter);
					counter++;
				}
				setupCostumeBox();
			}
		}
		
		private function setupCostumeBox():void
		{	
			costumeBox = _interactive["costumeBox"];
			inventory = costumeBox["costumeInventory"];
			var itemUIBackground:MovieClip = inventory["itemUIBackground"];
			
			costumeBox.mouseEnabled = false;
			costumeBox.mouseChildren = true;
			
			bgWrapper = profile.convertToBitmapSprite(itemUIBackground, itemUIBackground.parent, false);
			
			inventory.removeChild(itemUIBackground);
			inventory.mask = costumeBox["costumeMask"];		
			
			for (var i:int = 0; i < costumesArray.length; i++)
			{
				createCostumeItem(costumesArray[i], i);
			}
			
			bgWrapper.sprite.visible = false;
			
			if(costumesArray.length == 0)
			{
				noCostumes = true;
				allCostumeItemsLoaded();
			}
		}
		
		private function createCostumeItem(itemId:String, num:Number):void
		{
			++costumesLoaded;
			
			var wrapper:BitmapWrapper = bgWrapper.duplicate();
			wrapper.sprite.x = num * 80 + 50;
			wrapper.sprite.y = 55;
			var assetContainer:Sprite = new Sprite();
			var type:String = CharacterCreator.TYPE_DUMMY;
			var lookData:LookData = costumes[itemId].look;
			
			var npc:Entity = profile.charGroup.createDummy("npclist"+num, lookData, "left", "", assetContainer, profile, profile.stillNPCLoaded,false,0.5,type,new Point(0,60));
			
			assetContainer.scaleX = assetContainer.scaleY = 1;
			wrapper.sprite.addChild(assetContainer);
			var entity:Entity = EntityUtils.createMovingEntity( profile, wrapper.sprite, inventory );
			var interaction:Interaction = InteractionCreator.addToEntity( entity, ["click"], wrapper.sprite ); 
			interaction.click.add(clickCostumeItem);
			ToolTipCreator.addUIRollover(entity);
			
			entity.add( new Id(itemId) );
			
			if(costumesLoaded >= costumesArray.length)
				allCostumeItemsLoaded();
		}
		
		private function allCostumeItemsLoaded():void
		{
			trace("****************AllCostumesLoaded");
			setupSlider();
		}
		
		private function clickCostumeItem(item:Entity):void
		{
			// tracking
			var name:String = item.get(Id).id.substr(7,12);
			profile.shellApi.track(TRACK_CLICK_COSTUME, name, profile.selfOrFriend, "Closet");
			
			var lookData:LookData = costumes[item.get(Id).id].look;
			lookData.applyAspect( new LookAspectData( SkinUtils.EYES, "eyes" ) );
			var costumizer:CostumizerPop = new CostumizerPop(profile.overlayContainer, lookData);
			profile.addChildGroup(costumizer);
			costumizer.popupRemoved.add(costumizerClosed);
		}
		
		private function costumizerClosed():void 
		{
			profile.checkPlayerLook();
		}
		
		private function setupSlider():void
		{
			var sliderClip:MovieClip = _interactive["costumeBox"]["slider"];
			slider = EntityUtils.createSpatialEntity(profile, sliderClip);
			InteractionCreator.addToEntity(slider, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT]);
			var draggable:Draggable = new Draggable("x");
			slider.add(draggable);
			slider.add(new Slider());
			slider.add(new MotionBounds(new Rectangle(62, 171, 340, 10)));
			slider.add(new Ratio());
			ToolTipCreator.addToEntity(slider);
			draggable.dragging.add(onSliderDrag);
			draggable.drag.add(onSliderStart);
			draggable.drop.add(onSliderDrop);
			
			scrollStartX = inventory.x;
			scrollMax = inventory.width - 500;
		}
		private var sliderStart:Number;
		private function onSliderStart(entity:Entity):void
		{
			sliderStart = entity.get(Ratio).decimal;
		}
		private function onSliderDrop(entity:Entity):void
		{
			if(sliderStart - entity.get(Ratio).decimal > 0){
				// tracking
				profile.shellApi.track(TRACK_SCROLLBAR, "back", profile.selfOrFriend, "Closet");
			} else {
				// tracking
				profile.shellApi.track(TRACK_SCROLLBAR, "forward", profile.selfOrFriend, "Closet");
			}
			
		}
		
		private function onSliderDrag(entity:Entity):void
		{
			var ratio:Ratio = entity.get(Ratio);
			inventory.x = scrollStartX - (scrollMax * ratio.decimal);
		}
		
		private function myErrorFunction(event:Event):void
		{
			
		}
	}
}